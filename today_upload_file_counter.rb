require 'flickr_fu'
require 'dotenv'

Dotenv.load

def today?(time)
  @today ||= Date.today

  time.year == @today.year && time.month == @today.month && time.day == @today.day
end

# flickr = Flickr.new('flickr.yml')
flickr = Flickr.new(
  {
    key: ENV['API_KEY'],
    secret: ENV['API_SECRET'],
    token: ENV['TOKEN']
  })
ps = Flickr::Photosets.new(flickr)
# flickr.auth.url(:read)
# flickr.auth.cache_token
list = ps.get_list

photoset = list.find {|i| i.title == 'すず' }

photo = photoset.get_photos(extras: 'date_upload', per_page: 1).first

puts "#{today?(photo.uploaded_at)}"

