module Api
  module V1
    class MediaItemsController < ApplicationController
      before_action :validate_date_range, only: [ :index ]
      before_action :validate_media_type, only: [ :index ]
      before_action :validate_page, only: [ :index ]

      def index
        search_params = permitted_search_params
        query_key = QueryResultCache.generate_query_key(search_params)
        cache = QueryResultCache.find_or_initialize_by_params(search_params)

        if cache.persisted? && !cache.cache_expired?(search_params)
          media_items = cache.cached_results
          if media_items.present?
            render_cached_response(media_items, query_key, cache)
          else
            fetch_and_cache_results(cache, search_params, query_key)
          end
        else
          fetch_and_cache_results(cache, search_params, query_key)
        end
      rescue ArgumentError => e
        render json: { error: e.message }, status: :unprocessable_entity
      rescue StandardError => e
        Rails.logger.error("Error in media_items#index: #{e.message}")
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def permitted_search_params
        params.permit(:start_date, :end_date, :media_type, :genre_ids, :min_rating, :max_rating, :sort_by, :page)
      end

      def validate_date_range
        start_date = params[:start_date]
        end_date = params[:end_date]

        return unless start_date.present? && end_date.present?

        begin
          start = Date.parse(start_date)
          end_d = Date.parse(end_date)

          return if start <= end_d

          render json: { error: "start_date must be less than or equal to end_date" },
                 status: :unprocessable_entity
        rescue ArgumentError
          render json: { error: "Invalid date format. Use YYYY-MM-DD" },
                 status: :unprocessable_entity
        end
      end

      def validate_media_type
        media_type = params[:media_type]
        return if %w[movie tv].include?(media_type)

        render json: { error: "media_type must be 'movie' or 'tv'" },
               status: :unprocessable_entity
      end

      def validate_page
        page = params[:page]
        return if page.blank?

        page_num = page.to_i
        return if page_num >= 1 && page_num <= 500

        render json: { error: "Invalid page: Pages must be between 1 and 500" },
               status: :unprocessable_entity
      end

      def fetch_and_cache_results(cache, search_params, query_key)
        media_service = MediaService.new
        result = media_service.search_by_date_range(search_params)

        if result[:items].blank?
          render json: {
            data: [],
            query_key: query_key,
            cached: false,
            last_updated: nil,
            pagination: {
              page: cache.page || 1,
              total_pages: [ (result[:total_pages] || 0), 500 ].min,
              total_results: result[:total_results] || 0,
              per_page: 20
            }
          }, status: :ok
          return
        end

        cache.reload
        cache.update_results(
          result[:items],
          {
            total_pages: [ (result[:total_pages] || 0), 500 ].min,
            total_results: result[:total_results]
          }
        )

        render_fresh_response(result[:items], query_key, cache, result)
      rescue StandardError => e
        Rails.logger.error("Error in fetch_and_cache_results: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        render json: { error: e.message }, status: :internal_server_error
      end

      def render_cached_response(media_items, query_key, cache)
        render json: {
          data: serialize_media_items(media_items),
          query_key: query_key,
          cached: true,
          last_updated: cache.last_queried_at&.iso8601,
          pagination: {
            page: cache.page,
            total_pages: [ cache.total_pages || 0, 500 ].min,
            total_results: cache.total_results,
            per_page: 20
          }
        }, status: :ok
      end

      def render_fresh_response(media_items, query_key, cache, result)
        render json: {
          data: serialize_media_items(media_items),
          query_key: query_key,
          cached: false,
          last_updated: cache.last_queried_at&.iso8601,
          pagination: {
            page: cache.page,
            total_pages: [ (result[:total_pages] || 0), 500 ].min,
            total_results: result[:total_results],
            per_page: 20
          }
        }, status: :ok
      end

      def serialize_media_items(media_items)
        return [] if media_items.blank?

        all_genre_ids_by_type = {}
        media_items.each do |item|
          item_hash = item.is_a?(Hash) ? item.with_indifferent_access : item
          media_type = item_hash[:media_type]
          genre_ids = item_hash[:genre_ids] || []
          next if genre_ids.blank?

          all_genre_ids_by_type[media_type] ||= []
          all_genre_ids_by_type[media_type].concat(genre_ids)
        end

        genres_by_id_and_type = {}
        all_genre_ids_by_type.each do |media_type, tmdb_ids|
          Genre.where(tmdb_id: tmdb_ids.uniq, media_type: media_type).each do |genre|
            genres_by_id_and_type[[ genre.tmdb_id, genre.media_type ]] = {
              id: genre.id,
              tmdb_id: genre.tmdb_id,
              name: genre.name,
              media_type: genre.media_type
            }
          end
        end

        media_items.map do |item|
          item_hash = item.is_a?(Hash) ? item.with_indifferent_access : item
          media_type = item_hash[:media_type]
          genre_ids = item_hash[:genre_ids] || []

          genres = genre_ids.map do |genre_id|
            genres_by_id_and_type[[ genre_id, media_type ]]
          end.compact

          {
            id: item_hash[:id] || item_hash[:tmdb_id],
            tmdb_id: item_hash[:id] || item_hash[:tmdb_id],
            media_type: media_type,
            title: item_hash[:title] || item_hash[:name],
            release_date: item_hash[:release_date] || item_hash[:first_air_date],
            overview: item_hash[:overview],
            poster_path: item_hash[:poster_path],
            popularity: item_hash[:popularity],
            vote_average: item_hash[:vote_average],
            vote_count: item_hash[:vote_count],
            original_language: item_hash[:original_language],
            adult: item_hash[:adult] || false,
            genres: genres
          }
        end
      rescue StandardError => e
        Rails.logger.error("Error serializing media items: #{e.message}")
        Rails.logger.error(e.backtrace.join("\n"))
        []
      end
    end
  end
end
