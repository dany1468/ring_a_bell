require 'active_support'
require 'active_support/core_ext'
require 'dotenv'
require 'dotenv/tasks'
require 'flickr_fu'
require 'pony'

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
  flickr = Flickr.new({key: ENV['API_KEY'], secret: ENV['API_SECRET'], token_cache: 'token_cache.yml'})

  puts 'visit the following url, then click <enter> once you have authorized.'
  puts 'and see token_cache.yml. '
  puts 'set the token that is written in it to the environment variable of heroku.'

  puts flickr.auth.url(:read)

  STDIN.gets

  puts flickr.auth.cache_token ? 'success' : 'failure'
end

task notify: :dotenv do
  flickr = Flickr.new({key: ENV['API_KEY'], secret: ENV['API_SECRET'], token: ENV['TOKEN']})

  ps = Flickr::Photosets.new(flickr)

  list = ps.get_list

  photoset = list.find {|i| i.title == ENV['TARGET_ALBUM'] }

  photos = photoset.get_photos(extras: 'date_upload', per_page: 20)

  if photos.find {|photo| photo.uploaded_at.in_time_zone('Tokyo').yesterday? }
    body = <<-BODY.strip_heredoc
      #{ENV['MAIL_MESSAGE']}

      #{ENV['ALBUM_URL']}
    BODY

    Pony.mail(to: ENV['SEND_TARGET_EMAILS'], subject: ENV['MAIL_SUBJECT'], body: body)
  end
end
