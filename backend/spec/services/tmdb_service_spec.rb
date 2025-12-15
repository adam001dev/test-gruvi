# frozen_string_literal: true

require "rails_helper"

RSpec.describe TmdbService do
  let(:service) { TmdbService.new }
  let(:access_token) { "test_token" }
  let(:response_double) { instance_double(HTTParty::Response) }

  before do
    stub_const("TmdbService::ACCESS_TOKEN", access_token)
  end

  describe "#fetch_genres" do
    let(:movie_response) do
      {
        "genres" => [
          { "id" => 28, "name" => "Action" },
          { "id" => 35, "name" => "Comedy" }
        ]
      }
    end

    it "fetches movie genres" do
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:parsed_response).and_return(movie_response)
      allow(HTTParty).to receive(:get).and_return(response_double)

      result = service.fetch_genres("movie")

      expect(HTTParty).to have_received(:get).with(
        "https://api.themoviedb.org/3/genre/movie/list?language=en",
        headers: hash_including(
          "accept" => "application/json",
          "Authorization" => "Bearer #{access_token}"
        )
      )
      expect(result).to eq([
        { id: 28, name: "Action" },
        { id: 35, name: "Comedy" }
      ])
    end

    it "fetches TV genres" do
      tv_response = {
        "genres" => [
          { "id" => 18, "name" => "Drama" }
        ]
      }

      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:parsed_response).and_return(tv_response)
      allow(HTTParty).to receive(:get).and_return(response_double)

      result = service.fetch_genres("tv")

      expect(HTTParty).to have_received(:get).with(
        "https://api.themoviedb.org/3/genre/tv/list?language=en",
        headers: hash_including(
          "accept" => "application/json",
          "Authorization" => "Bearer #{access_token}"
        )
      )
      expect(result).to eq([
        { id: 18, name: "Drama" }
      ])
    end

    it "raises error on API failure" do
      allow(response_double).to receive(:success?).and_return(false)
      allow(response_double).to receive(:code).and_return(401)
      allow(response_double).to receive(:body).and_return("Unauthorized")
      allow(HTTParty).to receive(:get).and_return(response_double)

      expect {
        service.fetch_genres("movie")
      }.to raise_error("TMDb API error: 401")
    end
  end

  describe "#discover" do
    let(:discover_response) do
      {
        "results" => [
          {
            "id" => 123,
            "title" => "Test Movie",
            "release_date" => "2020-01-15"
          }
        ],
        "total_pages" => 10,
        "total_results" => 200
      }
    end

    it "discovers movies with date range" do
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:parsed_response).and_return(discover_response)
      allow(HTTParty).to receive(:get).and_return(response_double)

      params = {
        start_date: "2020-01-01",
        end_date: "2020-12-31"
      }

      result = service.discover("movie", params)

      expect(HTTParty).to have_received(:get).with(
        "https://api.themoviedb.org/3/discover/movie",
        query: hash_including(
          "primary_release_date.gte" => "2020-01-01",
          "primary_release_date.lte" => "2020-12-31",
          "page" => 1,
          "sort_by" => "popularity.desc"
        ),
        headers: hash_including(
          "accept" => "application/json",
          "Authorization" => "Bearer #{access_token}"
        )
      )
      expect(result["results"].length).to eq(1)
    end

    it "discovers TV shows with date range" do
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:parsed_response).and_return(discover_response)
      allow(HTTParty).to receive(:get).and_return(response_double)

      params = {
        start_date: "2020-01-01",
        end_date: "2020-12-31"
      }

      result = service.discover("tv", params)

      expect(HTTParty).to have_received(:get).with(
        "https://api.themoviedb.org/3/discover/tv",
        query: hash_including(
          "first_air_date.gte" => "2020-01-01",
          "first_air_date.lte" => "2020-12-31",
          "page" => 1,
          "sort_by" => "popularity.desc"
        ),
        headers: hash_including(
          "accept" => "application/json",
          "Authorization" => "Bearer #{access_token}"
        )
      )
      expect(result["results"].length).to eq(1)
    end

    it "handles start_date only for movies" do
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:parsed_response).and_return(discover_response)
      allow(HTTParty).to receive(:get).and_return(response_double)

      params = { start_date: "2020-01-01" }
      service.discover("movie", params)

      expect(HTTParty).to have_received(:get).with(
        "https://api.themoviedb.org/3/discover/movie",
        query: hash_including(
          "primary_release_date.gte" => "2020-01-01",
          "page" => 1,
          "sort_by" => "popularity.desc"
        ),
        headers: hash_including(
          "accept" => "application/json",
          "Authorization" => "Bearer #{access_token}"
        )
      )
    end

    it "handles end_date only for movies" do
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:parsed_response).and_return(discover_response)
      allow(HTTParty).to receive(:get).and_return(response_double)

      params = { end_date: "2020-12-31" }
      service.discover("movie", params)

      expect(HTTParty).to have_received(:get).with(
        "https://api.themoviedb.org/3/discover/movie",
        query: hash_including(
          "primary_release_date.lte" => "2020-12-31",
          "page" => 1,
          "sort_by" => "popularity.desc"
        ),
        headers: hash_including(
          "accept" => "application/json",
          "Authorization" => "Bearer #{access_token}"
        )
      )
    end

    it "includes genre_ids in query" do
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:parsed_response).and_return(discover_response)
      allow(HTTParty).to receive(:get).and_return(response_double)

      params = { genre_ids: [ 28, 35 ] }
      service.discover("movie", params)

      expect(HTTParty).to have_received(:get).with(
        "https://api.themoviedb.org/3/discover/movie",
        query: hash_including(
          "with_genres" => "28,35",
          "page" => 1,
          "sort_by" => "popularity.desc"
        ),
        headers: hash_including(
          "accept" => "application/json",
          "Authorization" => "Bearer #{access_token}"
        )
      )
    end

    it "includes min_rating in query" do
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:parsed_response).and_return(discover_response)
      allow(HTTParty).to receive(:get).and_return(response_double)

      params = { min_rating: 7.5 }
      service.discover("movie", params)

      expect(HTTParty).to have_received(:get).with(
        "https://api.themoviedb.org/3/discover/movie",
        query: hash_including(
          "vote_average.gte" => 7.5,
          "page" => 1,
          "sort_by" => "popularity.desc"
        ),
        headers: hash_including(
          "accept" => "application/json",
          "Authorization" => "Bearer #{access_token}"
        )
      )
    end

    it "includes max_rating in query" do
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:parsed_response).and_return(discover_response)
      allow(HTTParty).to receive(:get).and_return(response_double)

      params = { max_rating: 9.0 }
      service.discover("movie", params)

      expect(HTTParty).to have_received(:get).with(
        "https://api.themoviedb.org/3/discover/movie",
        query: hash_including(
          "vote_average.lte" => 9.0,
          "page" => 1,
          "sort_by" => "popularity.desc"
        ),
        headers: hash_including(
          "accept" => "application/json",
          "Authorization" => "Bearer #{access_token}"
        )
      )
    end

    it "includes both min_rating and max_rating in query" do
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:parsed_response).and_return(discover_response)
      allow(HTTParty).to receive(:get).and_return(response_double)

      params = { min_rating: 7.5, max_rating: 9.0 }
      service.discover("movie", params)

      expect(HTTParty).to have_received(:get).with(
        "https://api.themoviedb.org/3/discover/movie",
        query: hash_including(
          "vote_average.gte" => 7.5,
          "vote_average.lte" => 9.0,
          "page" => 1,
          "sort_by" => "popularity.desc"
        ),
        headers: hash_including(
          "accept" => "application/json",
          "Authorization" => "Bearer #{access_token}"
        )
      )
    end

    it "defaults sort_by to popularity.desc" do
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:parsed_response).and_return(discover_response)
      allow(HTTParty).to receive(:get).and_return(response_double)

      service.discover("movie", {})

      expect(HTTParty).to have_received(:get).with(
        "https://api.themoviedb.org/3/discover/movie",
        query: hash_including(
          "sort_by" => "popularity.desc",
          "page" => 1
        ),
        headers: hash_including(
          "accept" => "application/json",
          "Authorization" => "Bearer #{access_token}"
        )
      )
    end

    it "uses custom sort_by" do
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:parsed_response).and_return(discover_response)
      allow(HTTParty).to receive(:get).and_return(response_double)

      params = { sort_by: "primary_release_date.asc" }
      service.discover("movie", params)

      expect(HTTParty).to have_received(:get).with(
        "https://api.themoviedb.org/3/discover/movie",
        query: hash_including(
          "sort_by" => "primary_release_date.asc",
          "page" => 1
        ),
        headers: hash_including(
          "accept" => "application/json",
          "Authorization" => "Bearer #{access_token}"
        )
      )
    end

    it "defaults page to 1" do
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:parsed_response).and_return(discover_response)
      allow(HTTParty).to receive(:get).and_return(response_double)

      service.discover("movie", {})

      expect(HTTParty).to have_received(:get).with(
        "https://api.themoviedb.org/3/discover/movie",
        query: hash_including(
          "page" => 1,
          "sort_by" => "popularity.desc"
        ),
        headers: hash_including(
          "accept" => "application/json",
          "Authorization" => "Bearer #{access_token}"
        )
      )
    end

    it "caps page at 500" do
      allow(response_double).to receive(:success?).and_return(true)
      allow(response_double).to receive(:parsed_response).and_return(discover_response)
      allow(HTTParty).to receive(:get).and_return(response_double)

      params = { page: 1000 }
      service.discover("movie", params)

      expect(HTTParty).to have_received(:get).with(
        "https://api.themoviedb.org/3/discover/movie",
        query: hash_including(
          "page" => 500,
          "sort_by" => "popularity.desc"
        ),
        headers: hash_including(
          "accept" => "application/json",
          "Authorization" => "Bearer #{access_token}"
        )
      )
    end

    it "raises error on API failure" do
      allow(response_double).to receive(:success?).and_return(false)
      allow(response_double).to receive(:code).and_return(500)
      allow(response_double).to receive(:body).and_return("Internal Server Error")
      allow(HTTParty).to receive(:get).and_return(response_double)

      expect {
        service.discover("movie", {})
      }.to raise_error("TMDb API error: 500")
    end
  end
end
