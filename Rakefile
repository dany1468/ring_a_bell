require 'active_support'
require 'active_support/core_ext'
require 'dotenv'
require 'dotenv/tasks'
require 'flickr_fu'
require 'open-uri'
require 'pony'
require 'pry'
require 'retriable'

task auth: :dotenv do
  flickr = Flickr.new({key: ENV['API_KEY'], secret: ENV['API_SECRET']}, token_cache: 'token_cache.yml')

  puts 'visit the following url, then click <enter> once you have authorized.'
  puts 'and see token_cache.yml. '
  puts 'set the token that is written in it to the environment variable of heroku.'

  puts flickr.auth.url(:write)

  STDIN.gets

  puts flickr.auth.cache_token ? 'success' : 'failure'
end

task reorder_and_notify: %i(reorder notify)

task reorder: :dotenv do
  def get_photos(photoset, page)
    Retriable.retriable do
      photoset.get_photos(extras: 'date_upload', per_page: 100, page: page)
    end
  end

  # NOTE photosets の reorder は、並べ替えたい写真の前後関係だけ指定すればいいので、最後に回ってしまっている
  #      新規アップロード写真のみを現在先頭の写真に対して前に持ってくるように指定している。
  #      全部並べ替えると 30 sec の timeout にひっかかるための対処である。
  def load_photos(photoset)
    all_pages = ((photoset.num_photos.to_i + photoset.num_videos.to_i) / 100) + 1

    all_pages.downto(1).each_with_object([]) {|page, all_photos|
      puts "app page fetching... #{page}/#{all_pages}"

      all_photos << get_photos(photoset, page)

      sleep 0.5
    }.flatten
  end

  flickr = Flickr.new({key: ENV['API_KEY'], secret: ENV['API_SECRET'], token: ENV['TOKEN']})

  photoset = Flickr::Photosets.new(flickr).get_list.find {|i| i.title == ENV['TARGET_ALBUM'] }

  all_photos = load_photos(photoset)

  reordered_ids = all_photos.sort_by(&:uploaded_at).reverse.map(&:id).uniq

  retried = false


  Retriable.retriable do
    puts "reorder start size:#{reordered_ids.size}"

    flickr.send_request('flickr.photosets.reorderPhotos', {photoset_id: photoset.id, photo_ids: reordered_ids.join(',')}, :post)
  end

  puts 'reorder done'
end

task :notify => [:dotenv, :set_mail_client] do
  # NOTE ビデオの URL が指定されてしまうとリダイレクトがかかるため現在は利用していません
  def image_file(image_url)
    open(image_url) do |data|
      return data.read
    end
  end

  flickr = Flickr.new({key: ENV['API_KEY'], secret: ENV['API_SECRET'], token: ENV['TOKEN']})

  ps = Flickr::Photosets.new(flickr)

  list = ps.get_list

  photoset = list.find {|i| i.title == ENV['TARGET_ALBUM'] }

  photos = photoset.get_photos(extras: 'date_upload', per_page: 20)

  jst_now = Time.now.in_time_zone('Tokyo')

  r = (jst_now.yesterday.beginning_of_day...jst_now)
  if photo = photos.find {|photo| r.cover?(photo.uploaded_at.in_time_zone('Tokyo')) }
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

task download_photos: :dotenv do
  MAX_DOWNLOAD_SIZE = 500

  def save_image(image_url, file_name)
    full_path = File.join('download', file_name)

    open(full_path, 'wb') do |output|
      open(image_url) do |data|
        output.write data.read
      end
    end
  end

  flickr = Flickr.new({key: ENV['API_KEY'], secret: ENV['API_SECRET'], token: ENV['TOKEN']})

  ps = Flickr::Photosets.new(flickr)

  list = ps.get_list

  photoset = list.find {|i| i.title == ENV['TARGET_ALBUM'] }

  photos = photoset.get_photos(extras: 'date_upload,original_format', per_page: MAX_DOWNLOAD_SIZE, media: 'photos')

  puts "downloading photo count: #{photos.size}"

  Dir.mkdir('download') unless Dir.exist?('download')

  photos.each do |photo|
    save_image photo.url(:original), "#{photo.title}.#{photo.original_format}"
  end
end

def save_image(image_url, file_name)
  full_path = File.join('download', file_name)

  open(full_path, 'wb') do |output|
    open(image_url) do |data|
      output.write data.read
    end
  end
end

task :export_by_tag, ['user_id', 'tag'] => :dotenv do |task, args|
  flickr = Flickr.new({key: ENV['API_KEY'], secret: ENV['API_SECRET'], token: ENV['TOKEN']})
  binding.pry

  photos = []
  page = 1

  loop do
    res = Flickr::Photos.new(flickr).search(user_id: args.user_id, tags: args.tag, page: page)

    break if res.photos.blank?

    page = res.page + 1

    photos << res.photos
  end

  photos.flatten.each do |photo|
    next unless photo.url(:original)

    save_image photo.url(:original), "#{photo.taken_at.strftime('%Y%m%d_%H%M%S')}.#{photo.original_format}"
  end
end

task export_print_photos: :dotenv do
  flickr = Flickr.new({key: ENV['API_KEY'], secret: ENV['API_SECRET'], token: ENV['TOKEN']})

  photoset = Flickr::Photosets.new(flickr).get_list.find {|i| i.title == ENV['TARGET_ALBUM'] }

  all_photo_size = photoset.num_photos.to_i

  all_photos = []

  all_pages = (all_photo_size / 100) + 1

  for page in 1..all_pages
    photos = photoset.get_photos(extras: 'date_upload,original_format,tags', per_page: 100, page: page)

    all_photos << photos
  end

  Dir.mkdir('download') unless Dir.exist?('download')

  all_photos.flatten.reject {|photo| photo.tags.include?('printed') }.each do |photo|
    puts "title:#{photo.title} url:#{photo.url(:original)}"
    next unless photo.url(:original)

    save_image photo.url(:original), "#{photo.title}.#{photo.original_format}"

    puts "It failed to add tags. photo_id:#{photo.id}" unless photo.add_tags('printed')
  end
end

require 'rake/testtask'

Rake::TestTask.new do |t|
  t.libs << 'lib'
  t.pattern = 'test/**/*_test.rb'
  t.verbose = true
end
