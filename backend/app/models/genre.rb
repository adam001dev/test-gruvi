class Genre < ApplicationRecord
  validates :tmdb_id, presence: true, uniqueness: { scope: :media_type }
  validates :name, presence: true
  validates :media_type, presence: true, inclusion: { in: %w[movie tv] }

  has_many :media_genres, dependent: :destroy
  has_many :media_items, through: :media_genres

  scope :for_movies, -> { where(media_type: "movie") }
  scope :for_tv, -> { where(media_type: "tv") }

  def self.sync_from_tmdb(media_type)
    service = TmdbService.new
    genres_data = service.fetch_genres(media_type)

    genres_data.each do |genre_data|
      find_or_create_by(tmdb_id: genre_data[:id], media_type: media_type) do |genre|
        genre.name = genre_data[:name]
      end
    end

    genres_data
  rescue StandardError => e
    Rails.logger.error("Failed to sync genres: #{e.message}")
    raise
  end
end
