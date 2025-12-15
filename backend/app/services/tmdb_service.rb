class TmdbService
  BASE_URL = "https://api.themoviedb.org/3".freeze
  ACCESS_TOKEN = ENV.fetch("TMDB_ACCESS_TOKEN", nil)
  MAX_PAGE = 500

  def fetch_genres(media_type)
    endpoint = media_type == "movie" ? "genre/movie/list" : "genre/tv/list"
    url = "#{BASE_URL}/#{endpoint}?language=en"

    response = HTTParty.get(url, headers: request_headers)

    unless response.success?
      Rails.logger.error("TMDb API error: Code #{response.code}, Body: #{response.body}")
      raise "TMDb API error: #{response.code}"
    end

    data = response.parsed_response
    data["genres"].map { |genre| { id: genre["id"], name: genre["name"] } }
  rescue StandardError => e
    Rails.logger.error("TMDb API error fetching genres: #{e.message}")
    raise
  end

  def discover(media_type, params = {})
    endpoint = media_type == "movie" ? "discover/movie" : "discover/tv"
    url = "#{BASE_URL}/#{endpoint}"

    query_params = build_query_params(media_type, params)
    response = HTTParty.get(url, query: query_params, headers: request_headers)

    unless response.success?
      Rails.logger.error("TMDb API error: Code #{response.code}, Body: #{response.body}")
      raise "TMDb API error: #{response.code}"
    end

    response.parsed_response
  rescue StandardError => e
    Rails.logger.error("TMDb API error discovering media: #{e.message}")
    raise
  end

  private

  def request_headers
    token = ACCESS_TOKEN
    if token.blank?
      Rails.logger.warn("TMDB_ACCESS_TOKEN environment variable is not set!")
    end
    {
      "accept" => "application/json",
      "Authorization" => "Bearer #{token}"
    }
  end

  def build_query_params(media_type, params)
    query = {}

    if params[:start_date].present? && params[:end_date].present?
      if media_type == "movie"
        query["primary_release_date.gte"] = params[:start_date]
        query["primary_release_date.lte"] = params[:end_date]
      else
        query["first_air_date.gte"] = params[:start_date]
        query["first_air_date.lte"] = params[:end_date]
      end
    elsif params[:start_date].present?
      date_key = media_type == "movie" ? "primary_release_date.gte" : "first_air_date.gte"
      query[date_key] = params[:start_date]
    elsif params[:end_date].present?
      date_key = media_type == "movie" ? "primary_release_date.lte" : "first_air_date.lte"
      query[date_key] = params[:end_date]
    end

    query["with_genres"] = params[:genre_ids].join(",") if params[:genre_ids].present?
    query["vote_average.gte"] = params[:min_rating] if params[:min_rating].present?
    query["vote_average.lte"] = params[:max_rating] if params[:max_rating].present?
    query["sort_by"] = params[:sort_by] || "popularity.desc"
    page = params[:page] || 1
    query["page"] = [ page.to_i, MAX_PAGE ].min

    query
  end
end
