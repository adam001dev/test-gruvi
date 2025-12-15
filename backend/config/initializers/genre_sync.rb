Rails.application.config.after_initialize do
  Rails.logger.info("Syncing genres from TMDb...")
  [ "movie", "tv" ].each do |media_type|
    begin
      Genre.sync_from_tmdb(media_type)
      Rails.logger.info("Successfully synced #{media_type} genres from TMDb")
    rescue StandardError => e
      Rails.logger.error("Failed to sync #{media_type} genres: #{e.message}")
    end
  end
end
