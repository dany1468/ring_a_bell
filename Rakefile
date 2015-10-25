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
  def today?(time)
    @today ||= Date.today

    time.year == @today.year && time.month == @today.month && time.day == @today.day
  end

  flickr = Flickr.new({key: ENV['API_KEY'], secret: ENV['API_SECRET'], token: ENV['TOKEN']})

  ps = Flickr::Photosets.new(flickr)

  list = ps.get_list

  photoset = list.find {|i| i.title == 'すず' }

  photo = photoset.get_photos(extras: 'date_upload', per_page: 1).first

  if today?(photo.uploaded_at)
    Pony.mail(to: 'dany1468+test@gmail.com', subject: 'しゃしんが追加されました')
  end
end
