require 'active_support'
require 'active_support/core_ext'
require 'dotenv'
require 'dotenv/tasks'
require 'flickraw'
require 'open-uri'
require 'pony'
require 'pry'
require 'retriable'

def with_retry
  Retriable.retriable(on: Timeout::Error, tries: 10) do
    yield
  end
end

task move: [:dotenv, :set_mail_client] do
  FlickRaw.api_key = ENV['API_KEY']
  FlickRaw.shared_secret = ENV['API_SECRET']
  with_retry { flickr.access_token = ENV['ACCESS_TOKEN'] }
  flickr.access_secret = ENV['ACCESS_SECRET']

  login = with_retry { flickr.test.login }

  puts "login success as #{login.username}"

  photos_uploaded_yesterday = with_retry { flickr.photos.search(user_id: 'me', tags: ENV['TARGET_TAGS'], min_upload_date: Time.now.yesterday, extras: 'date_upload,date_taken') }
  ids_of_photos = photos_uploaded_yesterday.sort_by(&:dateupload).reverse.map(&:id).uniq

  puts "number of photos moving to album is #{ids_of_photos.size}"

  if ids_of_photos.size < 1
    puts 'execution skip because we have no moving photos'

    exit 1
  end

  current_month_album_name = "#{ENV['ALBUM_PREFIX']}_#{Time.now.yesterday.strftime('%Y%m')}"

  photoset = with_retry { flickr.photosets.getList.find {|i| i.title == current_month_album_name } }

  puts "got monthly photoset #{photoset.inspect}"

  unless photoset
    puts "creating monthly photoset"

    result_of_creating_photoset = with_retry { flickr.photosets.create(title: current_month_album_name, primary_photo_id: ids_of_photos.shift) }
    photoset = with_retry { flickr.photosets.getInfo(photoset_id: result_of_creating_photoset.id, user_id: login.id) }

    puts "created photoset #{photoset.inspect}"

    sleep 1
  end

  added_photo_ids = ids_of_photos.each_with_object([]) {|photo_id, added_photos|
    begin
      puts "adding photo... #{photo_id}"

      with_retry { flickr.photosets.addPhoto(photoset_id: photoset.id, photo_id: photo_id) }

      added_photos << photo_id
    rescue FlickRaw::FailedResponse => e
      puts "Flickr::Error #{e.message}"
    end

    sleep 0.5
  }

  if added_photo_ids.any?
    puts "new photos are here #{added_photo_ids}"

    first_photo_in_photoset = with_retry { flickr.photosets.getPhotos(photoset_id: photoset.id, user_id: login.id, page: 1, per_page: 1) }

    puts "first photo in photoset #{first_photo_in_photoset.photo[0].id}"

    with_retry { flickr.photosets.reorderPhotos(photoset_id: photoset.id, photo_ids: (added_photo_ids + [first_photo_in_photoset.photo[0].id]).join(',')) }

    jst_now = Time.now.in_time_zone('Tokyo')

    subject = "[#{jst_now.strftime('%-m/%-d')}] #{ENV['MAIL_SUBJECT']} #{added_photo_ids.size}枚"
    body = <<-BODY.strip_heredoc
      #{ENV['MAIL_MESSAGE']}

      #{ENV['ALBUM_URL']}
    BODY

    Pony.mail(
      to: ENV['SEND_TARGET_EMAILS'],
      subject: subject,
      body: body
    )
    puts 'Send mail done.'
  end

  puts 'done'
end

task :set_mail_client do
  Pony.options = {
    charset: 'utf-8',
    via: :smtp,
    via_options: {
      address: 'smtp.gmail.com',
      port: '587',
      enable_starttls_auto: true,
      user_name: ENV['GMAIL_ACCOUNT'],
      password: ENV['GMAIL_PASSWORD'],
      domain: 'gmail.com',
      authentication: :plain,
    }
  }
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end
