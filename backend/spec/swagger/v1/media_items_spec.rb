# frozen_string_literal: true

require "swagger_helper"

RSpec.describe "Media Items API", type: :request do
  path "/api/v1/media_items" do
    get "Search media items" do
      tags "Media Items"
      produces "application/json"
      parameter name: :start_date, in: :query, type: :string, required: false,
                description: "Start date (YYYY-MM-DD format)"
      parameter name: :end_date, in: :query, type: :string, required: false,
                description: "End date (YYYY-MM-DD format)"
      parameter name: :media_type, in: :query, type: :string, required: true,
                description: "Media type: 'movie' or 'tv'",
                enum: %w[movie tv]
      parameter name: :genre_ids, in: :query, type: :string, required: false,
                description: "Comma-separated genre IDs"
      parameter name: :min_rating, in: :query, type: :number, required: false,
                description: "Minimum rating (0-10)"
      parameter name: :sort_by, in: :query, type: :string, required: false,
                description: "Sort parameter (e.g., 'release_date.asc', 'popularity.desc')"
      parameter name: :page, in: :query, type: :integer, required: false,
                description: "Page number (default: 1)"

      response "200", "Media items retrieved successfully" do
        schema type: :object,
               properties: {
                 data: {
                   type: :array,
                   items: {
                     type: :object,
                     properties: {
                       id: { type: :integer },
                       tmdb_id: { type: :integer },
                       media_type: { type: :string, enum: %w[movie tv] },
                       title: { type: :string },
                       release_date: { type: :string, format: :date },
                       overview: { type: :string },
                       poster_path: { type: :string, nullable: true },
                       popularity: { type: :number },
                       vote_average: { type: :number },
                       vote_count: { type: :integer },
                       original_language: { type: :string },
                       adult: { type: :boolean },
                       genres: {
                         type: :array,
                         items: {
                           type: :object,
                           properties: {
                             id: { type: :integer },
                             tmdb_id: { type: :integer },
                             name: { type: :string },
                             media_type: { type: :string }
                           }
                         }
                       }
                     },
                     required: %w[id tmdb_id media_type title release_date]
                   }
                 },
                 query_key: { type: :string },
                 cached: { type: :boolean },
                 last_updated: { type: :string, format: :datetime, nullable: true },
                 pagination: {
                   type: :object,
                   properties: {
                     page: { type: :integer },
                     total_pages: { type: :integer, nullable: true },
                     total_results: { type: :integer, nullable: true },
                     per_page: { type: :integer }
                   }
                 }
               },
               required: %w[data query_key cached pagination]

        let(:media_type) { "movie" }
        let(:start_date) { "2020-01-01" }
        let(:end_date) { "2020-12-31" }
        run_test!
      end

      response "422", "Validation error" do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }

        context "when media_type is missing" do
          let(:media_type) { nil }
          let(:start_date) { "2020-01-01" }
          let(:end_date) { "2020-12-31" }
          run_test!
        end

        context "when media_type is invalid" do
          let(:media_type) { "invalid" }
          run_test!
        end

        context "when start_date > end_date" do
          let(:media_type) { "movie" }
          let(:start_date) { "2020-12-31" }
          let(:end_date) { "2020-01-01" }
          run_test!
        end

        context "when date format is invalid" do
          let(:media_type) { "movie" }
          let(:start_date) { "invalid-date" }
          let(:end_date) { "2020-12-31" }
          run_test!
        end
      end

      response "500", "Internal server error" do
        schema type: :object,
               properties: {
                 error: { type: :string }
               }

        let(:media_type) { "movie" }
        let(:start_date) { "2020-01-01" }
        let(:end_date) { "2020-12-31" }
        before do
          allow(QueryResultCache).to receive(:generate_query_key).and_raise(StandardError.new("Database Error"))
        end
        run_test!
      end
    end
  end
end
