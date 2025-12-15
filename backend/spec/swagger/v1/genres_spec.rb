# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Genres API", type: :request do
  path "/api/v1/genres" do
    get "List genres" do
      tags "Genres"
      produces "application/json"
      parameter name: :media_type, in: :query, type: :string, required: true,
                description: "Media type: 'movie' or 'tv'",
                enum: %w[movie tv]

      response "200", "Genres retrieved successfully" do
        schema type: :array,
               items: {
                 type: :object,
                 properties: {
                   id: { type: :integer },
                   tmdb_id: { type: :integer },
                   name: { type: :string },
                   media_type: { type: :string, enum: %w[movie tv] },
                   created_at: { type: :string, format: :datetime },
                   updated_at: { type: :string, format: :datetime }
                 },
                 required: %w[id tmdb_id name media_type]
               }

        let(:media_type) { "movie" }
        run_test!
      end

      response "422", "Invalid media_type" do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }

        let(:media_type) { "invalid" }
        run_test!
      end
    end
  end

  path "/api/v1/genres/sync" do
    post "Sync genres from TMDb" do
      tags "Genres"
      consumes "application/json"
      produces "application/json"
      parameter name: :genre, in: :body, schema: {
        type: :object,
        properties: {
          media_type: { type: :string, enum: %w[movie tv], description: "Media type: 'movie' or 'tv'" }
        },
        required: [ "media_type" ]
      }

      response "200", "Genres synced successfully" do
        schema type: :object,
               properties: {
                 success: { type: :boolean },
                 message: { type: :string }
               }

        let(:genre) { { media_type: "movie" } }
        run_test!
      end

      response "422", "Invalid media_type or sync failed" do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }

        let(:genre) { { media_type: "invalid" } }
        run_test!
      end

      response "500", "Internal server error" do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }

        let(:genre) { { media_type: "movie" } }
        before do
          allow_any_instance_of(MediaService).to receive(:sync_genres).and_raise(StandardError.new("API Error"))
        end
        run_test!
      end
    end
  end
end
