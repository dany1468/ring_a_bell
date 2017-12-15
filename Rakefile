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

def create_photoset(photoset_name, primary_photo_id, user_id)
  puts "creating monthly photoset"

  result_of_creating_photoset = with_retry { flickr.photosets.create(title: photoset_name, primary_photo_id: primary_photo_id) }
  photoset = with_retry { flickr.photosets.getInfo(photoset_id: result_of_creating_photoset.id, user_id: user_id) }

  puts "created photoset #{photoset.inspect}"

  photoset
end

def add_photos(photoset_id, photo_ids)
  photo_ids.each_with_object([]) {|photo_id, added_photos|
    begin
      puts "adding photo... #{photo_id}"

      with_retry { flickr.photosets.addPhoto(photoset_id: photoset_id, photo_id: photo_id) }

      added_photos << photo_id
    rescue FlickRaw::FailedResponse => e
      puts "Flickr::Error #{e.message}"
    end

    sleep 0.5
  }
end

def fetch_photo_ids_to_move(tags: ENV['TARGET_TAGS'], min_upload_date: Time.now.yesterday)
  photos = with_retry { flickr.photos.search(user_id: 'me', tags: tags, min_upload_date: min_upload_date, extras: 'date_upload,date_taken') }

  photos.sort_by(&:dateupload).reverse.map(&:id).uniq
end

def move_new_photos_to_photoset_head(new_photo_ids, photoset_id, user_id)
  if new_photo_ids.none?
    puts 'skip moving new photos to photoset head because new photos have only cover photo of photoset.'

    return
  end

  puts "new photos are here #{added_photo_ids}"

  first_photo_in_photoset = with_retry { flickr.photosets.getPhotos(photoset_id: photoset_id, user_id: user_id, page: 1, per_page: 1) }

  puts "first photo in photoset #{first_photo_in_photoset.photo[0].id}"

  with_retry { flickr.photosets.reorderPhotos(photoset_id: photoset_id, photo_ids: (new_photo_ids + [first_photo_in_photoset.photo[0].id]).join(',')) }
end

task move: [:dotenv, :set_flickr_auth, :set_mail_client] do
  login = with_retry { flickr.test.login }

  puts "login success as #{login.username}"

  ids_of_photos = fetch_photo_ids_to_move

  puts "number of photos moving to album is #{ids_of_photos.size}"

  if ids_of_photos.size < 1
    puts 'execution skip because we have no moving photos'

    exit 1
  end

  current_month_album_name = "#{ENV['ALBUM_PREFIX']}_#{Time.now.yesterday.strftime('%Y%m')}"

  photoset = with_retry { flickr.photosets.getList.find {|i| i.title == current_month_album_name } }

  puts "got monthly photoset #{photoset.inspect}"

  new_photoset_created = false

  unless photoset
    photoset = create_photoset(current_month_album_name, ids_of_photos.shift, login.id)
    new_photoset_created = true
    sleep 1
  end

  added_photo_ids = add_photos(photoset.id, ids_of_photos)

  if added_photo_ids.any? || new_photoset_created
    move_new_photos_to_photoset_head(added_photo_ids, photoset.id, login.id)

    jst_now = Time.now.in_time_zone('Tokyo')

    subject = "[#{jst_now.strftime('%-m/%-d')}] #{ENV['MAIL_SUBJECT']}"
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

task :set_flickr_auth do
  FlickRaw.api_key = ENV['API_KEY']
  FlickRaw.shared_secret = ENV['API_SECRET']
  with_retry { flickr.access_token = ENV['ACCESS_TOKEN'] }
  flickr.access_secret = ENV['ACCESS_SECRET']
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
