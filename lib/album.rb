class Album
  def initialize(album_name)
    @photoset = all_photoset.find {|i| i.title == album_name }
  end

  def reorder_by_taken_date
    all_photos = load_photos(@photoset)

    reordered_ids = all_photos.sort_by(&:uploaded_at).reverse.map(&:id).uniq

    # TODO place in flickr_fu gem
    # flickr.send_request('flickr.photosets.reorderPhotos', {photoset_id: photoset.id, photo_ids: reordered_ids.join(',')}, :post)
    puts reordered_ids
    puts 'reorder done'
  end

  private

  def load_photos(photoset)
    all_pages = ((photoset.num_photos.to_i + photoset.num_videos.to_i) / 100) + 1
    latest_photo = photoset.get_photos(extras: 'date_upload', per_page: 1, page: 1).first
    latest_uploaded_at = latest_photo.uploaded_at

    unordered_photos = (all_pages..1).inject([]) {|all_photos, page|
      puts page
      photos = photoset.get_photos(extras: 'date_upload', per_page: 100, page: page)
      new_photos = photos.select {|photo| photo.uploaded_at >= latest_uploaded_at }

      binding.pry
      all_photos << new_photos

      break all_photos if photos.size != new_photos.size
    }

    (unordered_photos << latest_photo).flatten
  end

  def all_photoset
    @all_photoset ||= Flickr::Photosets.new(flickr).get_list
  end

  def flickr
    @flickr ||= Flickr.new({key: ENV['API_KEY'], secret: ENV['API_SECRET'], token: ENV['TOKEN']})
  end
end
