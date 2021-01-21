class VideoWrapper
  BASE_URL = "https://api.themoviedb.org/3/"
  KEY = ENV["MOVIEDB_KEY"]

  BASE_IMG_URL = "https://image.tmdb.org/t/p/"
  DEFAULT_IMG_SIZE = "w185"
  DEFAULT_IMG_URL = "http://lorempixel.com/185/278/"

  def self.search(query, retries_left=3)
    raise ArgumentError.new("Can't search without a MOVIEDB_KEY.  Please check your .env file!") unless KEY

    url = BASE_URL + "search/movie?api_key=" + KEY + "&query=" + query

    response =  HTTParty.get(url)

    if response.success?
      if response["total_results"] == 0
        return []
      else
        videos = response["results"].map do |result|
          self.construct_video(result)
        end
        return videos
      end
    elsif retries_left > 0
      sleep(1.0 / (2 ** retries_left))

      return self.search(query, retries_left - 1)
    else
      raise "Request failed: #{url}"
    end
  end

  # Gets a movie from tmDB by ID
  # Returns video object or nil if not found
  def self.get_movie(id, retries_left=3)
    raise ArgumentError.new("Can't search without a MOVIEDB_KEY.  Please check your .env file!") unless KEY

    url = BASE_URL + "movie/" + id.to_s + "?api_key=" + KEY

    response = HTTParty.get(url)

    if response.success?
      return self.construct_video(response)
    elsif response["status_code"] == 34 # No movie by that ID
      return nil
    elsif retries_left > 0
      sleep(1.0 / (2 ** retries_left))

      return self.get_movie(query, retries_left - 1)
    else
      raise ArgumentError.new("Request failed: #{url}")
    end
  end

  private

  def self.construct_video(api_result)
    Video.new(
      title: api_result["title"],
      overview: api_result["overview"],
      release_date: api_result["release_date"],
      image_url: self.construct_image_url(api_result["poster_path"]),
      external_id: api_result["id"]
    )
  end

  def self.construct_image_url(img_name)
    if img_name.nil?
      return nil
    else
      return BASE_IMG_URL + DEFAULT_IMG_SIZE + img_name
    end
  end
end
