class MediaService
  VALID_MOVIE_SORT_OPTIONS = %w[
    original_title.asc original_title.desc
    popularity.asc popularity.desc
    revenue.asc revenue.desc
    primary_release_date.asc primary_release_date.desc
    title.asc title.desc
    vote_average.asc vote_average.desc
    vote_count.asc vote_count.desc
  ].freeze

  VALID_TV_SORT_OPTIONS = %w[
    first_air_date.asc first_air_date.desc
    name.asc name.desc
    original_name.asc original_name.desc
    popularity.asc popularity.desc
    vote_average.asc vote_average.desc
    vote_count.asc vote_count.desc
  ].freeze

  def initialize
    @tmdb_service = TmdbService.new
  end

  def sync_genres(media_type)
    Genre.sync_from_tmdb(media_type)
    { success: true }
  rescue StandardError => e
    Rails.logger.error("Failed to sync genres: #{e.message}")
    { success: false, error: e.message }
  end

  def search_by_date_range(params)
    normalized_params = normalize_search_params(params)
    media_type = normalized_params[:media_type]

    search_media_type(media_type, normalized_params)
  end

  private

  def search_media_type(media_type, params)
    page = params[:page] || 1
    page_params = params.merge(page: page)
    response = @tmdb_service.discover(media_type, page_params)

    results = response["results"] || []
    total_pages = response["total_pages"] || 1
    total_pages = [ total_pages, 500 ].min
    total_results = response["total_results"] || 0

    normalized_results = results.map do |item|
      normalize_item(item, media_type)
    end

    {
      items: normalized_results,
      total_pages: total_pages,
      total_results: total_results
    }
  end

  def normalize_item(item, media_type)
    item_hash = item.with_indifferent_access

    {
      id: item_hash[:id],
      media_type: media_type,
      title: media_type == "tv" ? item_hash[:name] : item_hash[:title],
      release_date: media_type == "tv" ? item_hash[:first_air_date] : item_hash[:release_date],
      overview: item_hash[:overview],
      poster_path: item_hash[:poster_path],
      popularity: item_hash[:popularity],
      vote_average: item_hash[:vote_average],
      vote_count: item_hash[:vote_count],
      original_language: item_hash[:original_language],
      adult: item_hash[:adult] || false,
      genre_ids: item_hash[:genre_ids] || []
    }
  end

  def normalize_search_params(params)
    normalized = params.to_h.with_indifferent_access
    media_type = normalized[:media_type].presence

    unless %w[movie tv].include?(media_type)
      raise ArgumentError, "media_type must be movie or tv"
    end

    sort_by = normalized[:sort_by].presence || "popularity.desc"
    validate_sort_by(sort_by, media_type)

    {
      start_date: normalized[:start_date].presence,
      end_date: normalized[:end_date].presence,
      media_type: media_type,
      genre_ids: normalize_genre_ids(normalized[:genre_ids]),
      min_rating: normalized[:min_rating].presence&.to_f,
      max_rating: normalized[:max_rating].presence&.to_f,
      sort_by: sort_by,
      page: [ normalized[:page].presence&.to_i || 1, 500 ].min
    }
  end

  def validate_sort_by(sort_by, media_type)
    valid_options = media_type == "movie" ? VALID_MOVIE_SORT_OPTIONS : VALID_TV_SORT_OPTIONS
    return if valid_options.include?(sort_by)

    raise ArgumentError, "Invalid sort_by value '#{sort_by}' for media_type '#{media_type}'. Valid options: #{valid_options.join(', ')}"
  end

  def normalize_genre_ids(genre_ids)
    return [] if genre_ids.blank?

    if genre_ids.is_a?(String)
      genre_ids.split(",").map(&:strip).reject(&:blank?).map(&:to_i)
    else
      Array(genre_ids).map(&:to_i)
    end
  end
end
