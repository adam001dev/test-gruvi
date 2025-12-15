# frozen_string_literal: true

require "rails_helper"

RSpec.describe MediaService do
  let(:service) { MediaService.new }
  let(:tmdb_service) { instance_double(TmdbService) }

  before do
    allow(TmdbService).to receive(:new).and_return(tmdb_service)
  end

  describe "#sync_genres" do
    it "calls Genre.sync_from_tmdb" do
      allow(Genre).to receive(:sync_from_tmdb).and_return([])

      result = service.sync_genres("movie")

      expect(Genre).to have_received(:sync_from_tmdb).with("movie")
      expect(result[:success]).to be true
    end

    it "returns error on failure" do
      allow(Genre).to receive(:sync_from_tmdb).and_raise(StandardError.new("Sync failed"))

      result = service.sync_genres("movie")

      expect(result[:success]).to be false
      expect(result[:error]).to eq("Sync failed")
    end
  end

  describe "#search_by_date_range" do
    let(:tmdb_response) do
      {
        "results" => [
          {
            "id" => 123,
            "title" => "Test Movie",
            "release_date" => "2020-01-15",
            "overview" => "Test overview",
            "poster_path" => "/poster.jpg",
            "popularity" => 85.5,
            "vote_average" => 8.2,
            "vote_count" => 1500,
            "original_language" => "en",
            "adult" => false,
            "genre_ids" => [ 28, 35 ]
          }
        ],
        "total_pages" => 10,
        "total_results" => 200
      }
    end

    it "searches movies with date range" do
      allow(tmdb_service).to receive(:discover).and_return(tmdb_response)

      params = {
        media_type: "movie",
        start_date: "2020-01-01",
        end_date: "2020-12-31",
        page: 1
      }

      result = service.search_by_date_range(params)

      expect(tmdb_service).to have_received(:discover).with(
        "movie",
        hash_including(
          start_date: "2020-01-01",
          end_date: "2020-12-31",
          page: 1
        )
      )

      expect(result[:items].length).to eq(1)
      expect(result[:items].first[:title]).to eq("Test Movie")
      expect(result[:total_pages]).to eq(10)
      expect(result[:total_results]).to eq(200)
    end

    it "searches TV shows" do
      tv_response = tmdb_response.dup
      tv_response["results"][0]["name"] = "Test TV Show"
      tv_response["results"][0]["first_air_date"] = "2020-01-15"
      tv_response["results"][0].delete("title")
      tv_response["results"][0].delete("release_date")

      allow(tmdb_service).to receive(:discover).and_return(tv_response)

      params = {
        media_type: "tv",
        start_date: "2020-01-01",
        end_date: "2020-12-31"
      }

      result = service.search_by_date_range(params)

      expect(result[:items].first[:title]).to eq("Test TV Show")
      expect(result[:items].first[:release_date]).to eq("2020-01-15")
    end

    it "normalizes item data for movies" do
      allow(tmdb_service).to receive(:discover).and_return(tmdb_response)

      params = { media_type: "movie" }
      result = service.search_by_date_range(params)

      item = result[:items].first
      expect(item[:id]).to eq(123)
      expect(item[:media_type]).to eq("movie")
      expect(item[:title]).to eq("Test Movie")
      expect(item[:release_date]).to eq("2020-01-15")
      expect(item[:genre_ids]).to eq([ 28, 35 ])
    end

    it "normalizes item data for TV shows" do
      tv_response = {
        "results" => [ {
          "id" => 456,
          "name" => "Test TV",
          "first_air_date" => "2020-06-15",
          "overview" => "TV overview",
          "poster_path" => "/tv-poster.jpg",
          "popularity" => 75.0,
          "vote_average" => 7.5,
          "vote_count" => 800,
          "original_language" => "en",
          "adult" => false,
          "genre_ids" => [ 18 ]
        } ],
        "total_pages" => 5,
        "total_results" => 100
      }

      allow(tmdb_service).to receive(:discover).and_return(tv_response)

      params = { media_type: "tv" }
      result = service.search_by_date_range(params)

      item = result[:items].first
      expect(item[:id]).to eq(456)
      expect(item[:media_type]).to eq("tv")
      expect(item[:title]).to eq("Test TV")
      expect(item[:release_date]).to eq("2020-06-15")
    end

    it "caps total_pages at 500" do
      large_response = tmdb_response.dup
      large_response["total_pages"] = 1000

      allow(tmdb_service).to receive(:discover).and_return(large_response)

      params = { media_type: "movie" }
      result = service.search_by_date_range(params)

      expect(result[:total_pages]).to eq(500)
    end

    it "defaults page to 1" do
      allow(tmdb_service).to receive(:discover).and_return(tmdb_response)

      params = { media_type: "movie" }
      service.search_by_date_range(params)

      expect(tmdb_service).to have_received(:discover).with(
        "movie",
        hash_including(page: 1)
      )
    end

    it "caps page at 500" do
      allow(tmdb_service).to receive(:discover).and_return(tmdb_response)

      params = { media_type: "movie", page: 1000 }
      service.search_by_date_range(params)

      expect(tmdb_service).to have_received(:discover).with(
        "movie",
        hash_including(page: 500)
      )
    end

    it "normalizes genre_ids from string" do
      allow(tmdb_service).to receive(:discover).and_return(tmdb_response)

      params = { media_type: "movie", genre_ids: "1,2,3" }
      service.search_by_date_range(params)

      expect(tmdb_service).to have_received(:discover).with(
        "movie",
        hash_including(genre_ids: [ 1, 2, 3 ])
      )
    end

    it "normalizes genre_ids from array" do
      allow(tmdb_service).to receive(:discover).and_return(tmdb_response)

      params = { media_type: "movie", genre_ids: [ 1, 2, 3 ] }
      service.search_by_date_range(params)

      expect(tmdb_service).to have_received(:discover).with(
        "movie",
        hash_including(genre_ids: [ 1, 2, 3 ])
      )
    end

    it "converts min_rating to float" do
      allow(tmdb_service).to receive(:discover).and_return(tmdb_response)

      params = { media_type: "movie", min_rating: "7.5" }
      service.search_by_date_range(params)

      expect(tmdb_service).to have_received(:discover).with(
        "movie",
        hash_including(min_rating: 7.5)
      )
    end

    it "converts max_rating to float" do
      allow(tmdb_service).to receive(:discover).and_return(tmdb_response)

      params = { media_type: "movie", max_rating: "9.0" }
      service.search_by_date_range(params)

      expect(tmdb_service).to have_received(:discover).with(
        "movie",
        hash_including(max_rating: 9.0)
      )
    end

    it "defaults sort_by to popularity.desc" do
      allow(tmdb_service).to receive(:discover).and_return(tmdb_response)

      params = { media_type: "movie" }
      service.search_by_date_range(params)

      expect(tmdb_service).to have_received(:discover).with(
        "movie",
        hash_including(sort_by: "popularity.desc")
      )
    end

    it "validates sort_by for movies" do
      allow(tmdb_service).to receive(:discover).and_return(tmdb_response)

      params = { media_type: "movie", sort_by: "title.asc" }
      service.search_by_date_range(params)

      expect(tmdb_service).to have_received(:discover).with(
        "movie",
        hash_including(sort_by: "title.asc")
      )
    end

    it "validates sort_by for TV shows" do
      allow(tmdb_service).to receive(:discover).and_return(tmdb_response)

      params = { media_type: "tv", sort_by: "name.asc" }
      service.search_by_date_range(params)

      expect(tmdb_service).to have_received(:discover).with(
        "tv",
        hash_including(sort_by: "name.asc")
      )
    end

    it "raises error for invalid sort_by for movies" do
      params = { media_type: "movie", sort_by: "invalid.sort" }

      expect {
        service.search_by_date_range(params)
      }.to raise_error(ArgumentError, /Invalid sort_by value/)
    end

    it "raises error for invalid sort_by for TV shows" do
      params = { media_type: "tv", sort_by: "title.asc" }

      expect {
        service.search_by_date_range(params)
      }.to raise_error(ArgumentError, /Invalid sort_by value/)
    end

    it "raises error for invalid media_type" do
      params = { media_type: "invalid" }

      expect {
        service.search_by_date_range(params)
      }.to raise_error(ArgumentError, "media_type must be movie or tv")
    end

    it "handles empty results" do
      empty_response = {
        "results" => [],
        "total_pages" => 0,
        "total_results" => 0
      }

      allow(tmdb_service).to receive(:discover).and_return(empty_response)

      params = { media_type: "movie" }
      result = service.search_by_date_range(params)

      expect(result[:items]).to eq([])
      expect(result[:total_pages]).to eq(0)
      expect(result[:total_results]).to eq(0)
    end
  end
end
