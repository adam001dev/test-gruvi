# frozen_string_literal: true

require "rails_helper"

RSpec.describe QueryResultCache, type: :model do
  describe "validations" do
    it "requires query_key" do
      cache = QueryResultCache.new(page: 1)
      expect(cache).not_to be_valid
      expect(cache.errors[:query_key]).to include("can't be blank")
    end

    it "has default page value" do
      cache = QueryResultCache.new(query_key: "test-key")
      expect(cache.page).to eq(1)
    end

    it "requires page to be greater than 0" do
      cache = QueryResultCache.new(query_key: "test-key", page: 0)
      expect(cache).not_to be_valid
      expect(cache.errors[:page]).to be_present
    end

    it "requires unique query_key" do
      QueryResultCache.create!(query_key: "test-key", page: 1)
      duplicate = QueryResultCache.new(query_key: "test-key", page: 1)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:query_key]).to include("has already been taken")
    end
  end

  describe ".generate_query_key" do
    it "generates consistent hash for same parameters" do
      params1 = { media_type: "movie", start_date: "2020-01-01", end_date: "2020-12-31", page: 1 }
      params2 = { media_type: "movie", start_date: "2020-01-01", end_date: "2020-12-31", page: 1 }

      key1 = QueryResultCache.generate_query_key(params1)
      key2 = QueryResultCache.generate_query_key(params2)

      expect(key1).to eq(key2)
    end

    it "generates different hash for different parameters" do
      params1 = { media_type: "movie", start_date: "2020-01-01", page: 1 }
      params2 = { media_type: "tv", start_date: "2020-01-01", page: 1 }

      key1 = QueryResultCache.generate_query_key(params1)
      key2 = QueryResultCache.generate_query_key(params2)

      expect(key1).not_to eq(key2)
    end

    it "generates different hash for different pages" do
      params1 = { media_type: "movie", page: 1 }
      params2 = { media_type: "movie", page: 2 }

      key1 = QueryResultCache.generate_query_key(params1)
      key2 = QueryResultCache.generate_query_key(params2)

      expect(key1).not_to eq(key2)
    end

    it "normalizes parameters before hashing" do
      params1 = { media_type: "movie", page: 1, start_date: "2020-01-01" }
      params2 = { page: 1, start_date: "2020-01-01", media_type: "movie" }

      key1 = QueryResultCache.generate_query_key(params1)
      key2 = QueryResultCache.generate_query_key(params2)

      expect(key1).to eq(key2)
    end

    it "raises error if media_type is missing" do
      params = { start_date: "2020-01-01" }
      expect {
        QueryResultCache.generate_query_key(params)
      }.to raise_error(ArgumentError, "media_type is required")
    end

    it "raises error if media_type is invalid" do
      params = { media_type: "invalid" }
      expect {
        QueryResultCache.generate_query_key(params)
      }.to raise_error(ArgumentError, "media_type must be movie or tv")
    end
  end

  describe ".normalize_params" do
    it "normalizes genre_ids from string" do
      params = { media_type: "movie", genre_ids: "1,2,3" }
      normalized = QueryResultCache.normalize_params(params)

      expect(normalized[:genre_ids]).to eq([ 1, 2, 3 ])
    end

    it "normalizes genre_ids from array" do
      params = { media_type: "movie", genre_ids: [ 1, 2, 3 ] }
      normalized = QueryResultCache.normalize_params(params)

      expect(normalized[:genre_ids]).to eq([ 1, 2, 3 ])
    end

    it "sorts and uniques genre_ids" do
      params = { media_type: "movie", genre_ids: "3,1,2,1" }
      normalized = QueryResultCache.normalize_params(params)

      expect(normalized[:genre_ids]).to eq([ 1, 2, 3 ])
    end

    it "defaults sort_by to popularity.desc" do
      params = { media_type: "movie" }
      normalized = QueryResultCache.normalize_params(params)

      expect(normalized[:sort_by]).to eq("popularity.desc")
    end

    it "defaults page to 1" do
      params = { media_type: "movie" }
      normalized = QueryResultCache.normalize_params(params)

      expect(normalized[:page]).to eq(1)
    end

    it "does not cap page in normalize_params" do
      params = { media_type: "movie", page: 1000 }
      normalized = QueryResultCache.normalize_params(params)

      expect(normalized[:page]).to eq(1000)
    end

    it "converts min_rating to float" do
      params = { media_type: "movie", min_rating: "7.5" }
      normalized = QueryResultCache.normalize_params(params)

      expect(normalized[:min_rating]).to eq(7.5)
    end

    it "converts max_rating to float" do
      params = { media_type: "movie", max_rating: "9.0" }
      normalized = QueryResultCache.normalize_params(params)

      expect(normalized[:max_rating]).to eq(9.0)
    end
  end

  describe ".find_or_initialize_by_params" do
    it "creates new cache if not exists" do
      params = { media_type: "movie", page: 1 }
      cache = QueryResultCache.find_or_initialize_by_params(params)

      expect(cache).to be_persisted
      expect(cache.query_key).to eq(QueryResultCache.generate_query_key(params))
      expect(cache.page).to eq(1)
    end

    it "finds existing cache if exists" do
      params = { media_type: "movie", page: 1 }
      existing = QueryResultCache.create!(
        query_key: QueryResultCache.generate_query_key(params),
        page: 1
      )

      cache = QueryResultCache.find_or_initialize_by_params(params)

      expect(cache.id).to eq(existing.id)
    end

    it "handles race condition when creating" do
      params = { media_type: "movie", page: 1 }
      query_key = QueryResultCache.generate_query_key(params)

      allow(QueryResultCache).to receive(:find_or_initialize_by).and_call_original
      allow(QueryResultCache).to receive(:find_by!).and_return(
        QueryResultCache.create!(query_key: query_key, page: 1)
      )

      cache = QueryResultCache.find_or_initialize_by_params(params)
      expect(cache).to be_persisted
    end
  end

  describe "#cache_expired?" do
    let(:cache) do
      QueryResultCache.create!(
        query_key: "test-key",
        page: 1,
        last_queried_at: 2.hours.ago
      )
    end

    it "returns true if last_queried_at is nil" do
      cache.update_column(:last_queried_at, nil)
      expect(cache.cache_expired?).to be true
    end

    it "returns false for filtered query within 24 hours" do
      cache.update_column(:last_queried_at, 12.hours.ago)
      params = { media_type: "movie", start_date: "2020-01-01" }

      expect(cache.cache_expired?(params)).to be false
    end

    it "returns true for filtered query after 24 hours" do
      cache.update_column(:last_queried_at, 25.hours.ago)
      params = { media_type: "movie", start_date: "2020-01-01" }

      expect(cache.cache_expired?(params)).to be true
    end

    it "returns false for unfiltered query within 1 hour" do
      cache.update_column(:last_queried_at, 30.minutes.ago)
      params = { media_type: "movie" }

      expect(cache.cache_expired?(params)).to be false
    end

    it "returns true for unfiltered query after 1 hour" do
      cache.update_column(:last_queried_at, 2.hours.ago)
      params = { media_type: "movie" }

      expect(cache.cache_expired?(params)).to be true
    end
  end

  describe "#update_results" do
    let(:cache) do
      QueryResultCache.create!(
        query_key: "test-key",
        page: 1
      )
    end

    it "updates results with array" do
      results = [ { id: 1, title: "Test" } ]
      cache.update_results(results, { total_pages: 10, total_results: 100 })

      expect(cache.cached_results).to eq([ { "id" => 1, "title" => "Test" } ])
      expect(cache.total_pages).to eq(10)
      expect(cache.total_results).to eq(100)
      expect(cache.last_queried_at).to be_present
    end

    it "updates results with JSON string" do
      results_json = '[{"id":1,"title":"Test"}]'
      cache.update_results(results_json, { total_pages: 10, total_results: 100 })

      expect(cache.cached_results).to eq([ { "id" => 1, "title" => "Test" } ])
    end

    it "updates last_queried_at timestamp" do
      old_time = Time.current
      cache.update_column(:last_queried_at, old_time)
      sleep 0.1
      cache.update_results([ { id: 1 } ], {})
      cache.reload
      expect(cache.last_queried_at).to be > old_time
    end
  end

  describe "#cached_results" do
    it "returns empty array if results is blank" do
      cache = QueryResultCache.create!(query_key: "test-key", page: 1)
      expect(cache.cached_results).to eq([])
    end

    it "parses JSON string results" do
      cache = QueryResultCache.create!(
        query_key: "test-key",
        page: 1,
        results: '[{"id":1,"title":"Test"}]'
      )

      expect(cache.cached_results).to eq([ { "id" => 1, "title" => "Test" } ])
    end

    it "returns array results as-is" do
      results = [ { id: 1, title: "Test" } ]
      cache = QueryResultCache.create!(
        query_key: "test-key",
        page: 1,
        results: results.to_json
      )

      expect(cache.cached_results).to eq([ { "id" => 1, "title" => "Test" } ])
    end

    it "handles invalid JSON gracefully" do
      cache = QueryResultCache.create!(
        query_key: "test-key",
        page: 1,
        results: "invalid json"
      )

      expect(cache.cached_results).to eq([])
    end

    it "returns empty array for non-array results" do
      cache = QueryResultCache.create!(
        query_key: "test-key",
        page: 1,
        results: '{"not": "an array"}'
      )

      expect(cache.cached_results).to eq([])
    end
  end
end
