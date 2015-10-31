require 'active_support'
require 'active_support/core_ext'
require 'dotenv'
require 'dotenv/tasks'
require 'flickr_fu'
require 'open-uri'
require 'pony'
require 'pry'

Dotenv.load

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
    authentication: :login,
  }
}

task auth: :dotenv do
  flickr = Flickr.new({key: ENV['API_KEY'], secret: ENV['API_SECRET']}, token_cache: 'token_cache.yml')

  puts 'visit the following url, then click <enter> once you have authorized.'
  puts 'and see token_cache.yml. '
  puts 'set the token that is written in it to the environment variable of heroku.'

  puts flickr.auth.url(:read)

  STDIN.gets

  puts flickr.auth.cache_token ? 'success' : 'failure'
end

task notify: :dotenv do
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
  yesterday = jst_now.yesterday.to_date

  if photo = photos.find {|photo| photo.uploaded_at.in_time_zone('Tokyo').to_date == yesterday }
    subject = "[#{jst_now.strftime('%-m/%-d')}] #{ENV['MAIL_SUBJECT']}"
    body = <<-BODY.strip_heredoc
      #{ENV['MAIL_MESSAGE']}

      #{ENV['ALBUM_URL']}
    BODY

    Pony.mail(
      to: ENV['SEND_TARGET_EMAILS'],
      subject: subject,
      body: body,
      attachments: {"#{jst_now.strftime('%Y%m%d')}.jpg" => image_file(photo.url(:medium))}
    )
    puts 'Send mail done.'
  end
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
