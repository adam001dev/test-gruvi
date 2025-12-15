module Api
  module V1
    class GenresController < ApplicationController
      def index
        media_type = params[:media_type]
        return render_invalid_media_type unless valid_media_type?(media_type)

        genres = media_type == "tv" ? Genre.for_tv : Genre.for_movies
        render json: genres, status: :ok
      end

      def sync
        media_type = sync_params[:media_type]
        return render_invalid_media_type unless valid_media_type?(media_type)

        media_service = MediaService.new
        result = media_service.sync_genres(media_type)

        if result[:success]
          render json: { success: true, message: "Genres synced successfully" }, status: :ok
        else
          render json: { error: result[:error] || "Failed to sync genres" }, status: :unprocessable_entity
        end
      rescue StandardError => e
        Rails.logger.error("Error syncing genres: #{e.message}")
        render json: { error: e.message }, status: :internal_server_error
      end

      private

      def sync_params
        if params[:genre].present?
          params.require(:genre).permit(:media_type)
        else
          params.permit(:media_type)
        end
      end

      def valid_media_type?(media_type)
        %w[movie tv].include?(media_type)
      end

      def render_invalid_media_type
        render json: { error: "media_type must be 'movie' or 'tv'" }, status: :unprocessable_entity
      end
    end
  end
end
