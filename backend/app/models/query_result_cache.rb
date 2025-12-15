class QueryResultCache < ApplicationRecord
  validates :query_key, presence: true, uniqueness: true
  validates :page, presence: true, numericality: { greater_than: 0 }

  CACHE_EXPIRY_HOURS = 24

  def self.generate_query_key(params)
    normalized = normalize_params(params)
    json_string = normalized.sort.to_h.to_json
    Digest::SHA256.hexdigest(json_string)
  end

  def self.normalize_params(params)
    normalized = params.to_h.with_indifferent_access
    media_type = normalized[:media_type].presence

    raise ArgumentError, "media_type is required" unless media_type
    raise ArgumentError, "media_type must be movie or tv" unless %w[movie tv].include?(media_type)

    {
      start_date: normalized[:start_date].presence,
      end_date: normalized[:end_date].presence,
      media_type: media_type,
      genre_ids: normalize_genre_ids(normalized[:genre_ids]),
      min_rating: normalized[:min_rating].presence&.to_f,
      max_rating: normalized[:max_rating].presence&.to_f,
      sort_by: normalized[:sort_by].presence || "popularity.desc",
      page: normalized[:page].presence&.to_i || 1
    }
  end

  def self.find_or_initialize_by_params(params)
    query_key = generate_query_key(params)
    normalized = normalize_params(params)

    cache = find_or_initialize_by(query_key: query_key) do |c|
      c.page = normalized[:page]
    end

    if cache.new_record?
      begin
        cache.save!
      rescue ActiveRecord::RecordNotUnique, ActiveRecord::RecordInvalid
        cache = find_by!(query_key: query_key)
      end
    end

    cache
  end

  def cache_expired?(params = nil)
    return true if last_queried_at.nil?

    expiry_time = has_filters?(params) ? CACHE_EXPIRY_HOURS.hours.ago : 1.hour.ago
    last_queried_at < expiry_time
  end

  def update_results(media_items_json, pagination_info = {})
    results_json = if media_items_json.is_a?(String)
                     media_items_json
    else
                     media_items_json.to_json
    end

    update_columns(
      results: results_json,
      last_queried_at: Time.current,
      total_pages: pagination_info[:total_pages],
      total_results: pagination_info[:total_results],
      updated_at: Time.current
    )
  end

  def cached_results
    return [] if results.blank?

    parsed = if results.is_a?(String)
               JSON.parse(results)
    else
               results
    end

    parsed.is_a?(Array) ? parsed : []
  rescue JSON::ParserError => e
    Rails.logger.error("Error parsing cached results: #{e.message}")
    []
  end

  private

  def has_filters?(params = nil)
    return false unless params

    normalized = self.class.normalize_params(params)
    normalized[:start_date].present? || normalized[:end_date].present? || normalized[:genre_ids].present? || normalized[:min_rating].present? || normalized[:max_rating].present?
  end

  def self.normalize_genre_ids(genre_ids)
    return nil if genre_ids.blank?

    ids = if genre_ids.is_a?(String)
            genre_ids.split(",").map(&:strip).reject(&:blank?)
    else
            Array(genre_ids)
    end

    ids.map(&:to_i).sort.uniq
  end
end
