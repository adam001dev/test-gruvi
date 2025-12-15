# frozen_string_literal: true

require "rails_helper"

RSpec.describe Genre, type: :model do
  before do
    Genre.delete_all
  end
  describe "validations" do
    it "requires tmdb_id" do
      genre = Genre.new(name: "Action", media_type: "movie")
      expect(genre).not_to be_valid
      expect(genre.errors[:tmdb_id]).to include("can't be blank")
    end

    it "requires name" do
      genre = Genre.new(tmdb_id: 28, media_type: "movie")
      expect(genre).not_to be_valid
      expect(genre.errors[:name]).to include("can't be blank")
    end

    it "requires media_type" do
      genre = Genre.new(tmdb_id: 28, name: "Action")
      expect(genre).not_to be_valid
      expect(genre.errors[:media_type]).to include("can't be blank")
    end

    it "requires media_type to be movie or tv" do
      genre = Genre.new(tmdb_id: 28, name: "Action", media_type: "invalid")
      expect(genre).not_to be_valid
      expect(genre.errors[:media_type]).to be_present
    end

    it "requires unique tmdb_id per media_type" do
      Genre.create!(tmdb_id: 28, name: "Action", media_type: "movie")
      duplicate = Genre.new(tmdb_id: 28, name: "Action", media_type: "movie")
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:tmdb_id]).to be_present
    end

    it "allows same tmdb_id for different media_types" do
      Genre.create!(tmdb_id: 28, name: "Action", media_type: "movie")
      different_type = Genre.new(tmdb_id: 28, name: "Action", media_type: "tv")
      expect(different_type).to be_valid
    end
  end

  describe "scopes" do
    before do
      Genre.create!(tmdb_id: 28, name: "Action", media_type: "movie")
      Genre.create!(tmdb_id: 35, name: "Comedy", media_type: "movie")
      Genre.create!(tmdb_id: 28, name: "Action", media_type: "tv")
    end

    it ".for_movies returns only movie genres" do
      movies = Genre.for_movies
      expect(movies.count).to eq(2)
      expect(movies.pluck(:media_type).uniq).to eq([ "movie" ])
    end

    it ".for_tv returns only tv genres" do
      tv = Genre.for_tv
      expect(tv.count).to eq(1)
      expect(tv.pluck(:media_type).uniq).to eq([ "tv" ])
    end
  end

  describe ".sync_from_tmdb" do
    let(:tmdb_service) { instance_double(TmdbService) }
    let(:genres_data) do
      [
        { id: 28, name: "Action" },
        { id: 35, name: "Comedy" }
      ]
    end

    before do
      allow(TmdbService).to receive(:new).and_return(tmdb_service)
      allow(tmdb_service).to receive(:fetch_genres).and_return(genres_data)
    end

    it "creates genres that don't exist" do
      expect {
        Genre.sync_from_tmdb("movie")
      }.to change(Genre, :count).by(2)

      expect(Genre.where(tmdb_id: 28, media_type: "movie").first.name).to eq("Action")
      expect(Genre.where(tmdb_id: 35, media_type: "movie").first.name).to eq("Comedy")
    end

    it "does not update existing genres (find_or_create_by only creates)" do
      genre = Genre.create!(tmdb_id: 28, name: "Old Action", media_type: "movie")
      original_name = genre.name

      Genre.sync_from_tmdb("movie")

      genre.reload
      expect(genre.name).to eq(original_name)
    end

    it "does not update if genre already exists with correct name" do
      genre = Genre.create!(tmdb_id: 28, name: "Action", media_type: "movie")
      original_updated_at = genre.updated_at

      sleep 0.1
      Genre.sync_from_tmdb("movie")

      genre.reload
      expect(genre.name).to eq("Action")
    end

    it "handles different media types separately" do
      Genre.sync_from_tmdb("movie")
      Genre.sync_from_tmdb("tv")

      expect(Genre.where(media_type: "movie").count).to eq(2)
      expect(Genre.where(media_type: "tv").count).to eq(2)
    end

    it "returns genres data" do
      result = Genre.sync_from_tmdb("movie")
      expect(result).to eq(genres_data)
    end

    it "raises error if TMDb service fails" do
      allow(tmdb_service).to receive(:fetch_genres).and_raise(StandardError.new("API Error"))

      expect {
        Genre.sync_from_tmdb("movie")
      }.to raise_error(StandardError, "API Error")
    end
  end
end
