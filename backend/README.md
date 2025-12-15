# Backend - Movie Search API

Ruby on Rails 8.x API-only application for searching movies and TV shows using the TMDb API with intelligent caching to minimize external API calls.

## Table of Contents

- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Search and Caching Flow](#search-and-caching-flow)
- [API Endpoints](#api-endpoints)
- [Setup Instructions](#setup-instructions)
- [Testing](#testing)
- [Deployment](#deployment)
- [Environment Variables](#environment-variables)

## Project Structure

```
backend/
├── app/
│   ├── controllers/
│   │   └── api/v1/
│   │       ├── genres_controller.rb      # Genre management endpoints
│   │       └── media_items_controller.rb   # Media search endpoint with caching
│   ├── models/
│   │   ├── genre.rb                      # Genre model with TMDb sync
│   │   └── query_result_cache.rb         # Caching model for search results
│   └── services/
│       ├── media_service.rb              # Business logic for media operations
│       └── tmdb_service.rb               # TMDb API client
├── config/
│   ├── routes.rb                         # API route definitions
│   └── environments/
│       └── production.rb                 # Production configuration
├── db/
│   ├── migrate/                          # Database migrations
│   └── schema.rb                         # Current database schema
└── spec/                                 # RSpec test suite
    ├── models/                           # Model unit tests
    ├── services/                         # Service unit tests
    └── swagger/v1/                       # API integration tests
```

## Architecture Overview

### Controllers

**`Api::V1::MediaItemsController`**

- Handles search requests for movies and TV shows
- Implements caching logic to avoid repeated TMDb API calls
- Validates input parameters (dates, media_type, page)
- Returns serialized media items with pagination info

**`Api::V1::GenresController`**

- Lists available genres for movies or TV shows
- Provides endpoint to sync genres from TMDb API

### Models

**`QueryResultCache`**

- Stores cached search results in JSON format
- Uses SHA256 hash of normalized query parameters as unique key
- Implements cache expiry logic (24 hours for filtered queries, 1 hour for unfiltered)
- Tracks pagination metadata (total_pages, total_results)

**`Genre`**

- Stores genre information synced from TMDb
- Supports both movies and TV shows (media_type)
- Provides scopes for filtering by media type

### Services

**`MediaService`**

- Orchestrates media search operations
- Normalizes search parameters
- Transforms TMDb API responses into consistent format
- Handles genre syncing

**`TmdbService`**

- HTTP client for TMDb API v3
- Builds query parameters for discover endpoint
- Handles authentication with Bearer token
- Maps TMDb date fields (primary_release_date for movies, first_air_date for TV)

## Search and Caching Flow

### How Search Works

1. **Request Received**: `MediaItemsController#index` receives search parameters
2. **Parameter Normalization**: Parameters are normalized and validated
3. **Query Key Generation**: A SHA256 hash is generated from normalized parameters

   ```ruby
   # Example: { media_type: "movie", start_date: "2020-01-01", end_date: "2020-12-31", page: 1 }
   # Becomes: "a1b2c3d4e5f6..." (SHA256 hash)
   ```

4. **Cache Lookup**: System checks if a cached result exists for this query key
5. **Cache Decision**:
   - **Cache Hit**: If cache exists and hasn't expired, return cached results
   - **Cache Miss/Expired**: Fetch from TMDb API, cache results, return fresh data

### Caching Strategy

**QueryResultCache Model**

The caching system uses a database-backed cache with the following characteristics:

- **Unique Query Identification**: Each unique combination of search parameters generates a unique SHA256 hash (`query_key`)
- **Cache Storage**: Results stored as JSON in PostgreSQL `json` column
- **Expiry Logic**:
  - **Filtered queries** (with dates, genres, or ratings): 24 hours
  - **Unfiltered queries**: 1 hour
- **Pagination Support**: Each page is cached separately (page number included in query key)

**Cache Flow Diagram**

```
Request → Normalize Params → Generate Query Key
                              ↓
                    Check Cache by Query Key
                              ↓
                    ┌─────────┴─────────┐
                    │                    │
              Cache Hit?            Cache Miss/Expired?
                    │                    │
                    ↓                    ↓
            Return Cached         Fetch from TMDb API
            Results (fast)         ↓
                            Store in Cache
                                    ↓
                            Return Fresh Results
```

**Example Cache Entry**

```ruby
QueryResultCache {
  query_key: "a1b2c3d4e5f6...",  # SHA256 of normalized params
  page: 1,
  results: [{ id: 123, title: "Movie Title", ... }],  # JSON array
  last_queried_at: "2024-01-15 10:30:00",
  total_pages: 50,
  total_results: 1000
}
```

**Cache Expiry Check**

```ruby
# In QueryResultCache model
def cache_expired?(params = nil)
  return true if last_queried_at.nil?
  
  expiry_time = has_filters?(params) ? 24.hours.ago : 1.hour.ago
  last_queried_at < expiry_time
end
```

### Parameter Normalization

Before generating a cache key, parameters are normalized to ensure consistency:

- `media_type`: Required, must be "movie" or "tv"
- `start_date`: Optional, YYYY-MM-DD format
- `end_date`: Optional, YYYY-MM-DD format
- `genre_ids`: Optional, normalized to sorted array of integers
- `min_rating`: Optional, converted to float
- `sort_by`: Optional, defaults to "popularity.desc"
- `page`: Optional, defaults to 1, capped at 500

This normalization ensures that `{media_type: "movie", page: 1}` and `{page: 1, media_type: "movie"}` generate the same cache key.

## API Endpoints

### Search Media Items

```
GET /api/v1/media_items
```

**Query Parameters:**

- `media_type` (required): "movie" or "tv"
- `start_date` (optional): YYYY-MM-DD format
- `end_date` (optional): YYYY-MM-DD format
- `genre_ids` (optional): Comma-separated genre IDs
- `min_rating` (optional): Minimum vote average (0-10)
- `sort_by` (optional): Sort parameter (default: "popularity.desc")
- `page` (optional): Page number (default: 1, max: 500)

**Response:**

```json
{
  "data": [
    {
      "id": 123,
      "tmdb_id": 123,
      "media_type": "movie",
      "title": "Movie Title",
      "release_date": "2020-01-15",
      "overview": "Movie description...",
      "poster_path": "/path/to/poster.jpg",
      "popularity": 85.5,
      "vote_average": 8.2,
      "vote_count": 1500,
      "original_language": "en",
      "adult": false,
      "genres": [...]
    }
  ],
  "query_key": "a1b2c3d4e5f6...",
  "cached": true,
  "last_updated": "2024-01-15T10:30:00Z",
  "pagination": {
    "page": 1,
    "total_pages": 50,
    "total_results": 1000,
    "per_page": 20
  }
}
```

### List Genres

```
GET /api/v1/genres?media_type=movie
```

**Query Parameters:**

- `media_type` (required): "movie" or "tv"

**Response:**

```json
[
  {
    "id": 1,
    "tmdb_id": 28,
    "name": "Action",
    "media_type": "movie"
  }
]
```

### Sync Genres

```
POST /api/v1/genres/sync
```

**Request Body:**

```json
{
  "media_type": "movie"
}
```

**Response:**

```json
{
  "success": true,
  "message": "Genres synced successfully"
}
```

### API Documentation

Interactive Swagger documentation available at `/api-docs` when the server is running.

## Setup Instructions

### Prerequisites

- Ruby 3.4.7+ (use `mise` or `rbenv`)
- PostgreSQL 14+
- Bundler gem

### Installation

1. **Install dependencies:**

   ```bash
   bundle install
   ```

2. **Set up database:**

   ```bash
   bundle exec rails db:create db:migrate
   ```

3. **Configure environment:**

   ```bash
   cp .env.example .env
   ```

   Edit `.env` and add:

   ```bash
   TMDB_ACCESS_TOKEN=your_tmdb_access_token_here
   RAILS_ENV=development
   ```

4. **Start the server:**

   ```bash
   rails server
   ```

   Server will be available at `http://localhost:3000`

### Database Setup

The application uses PostgreSQL with the following main tables:

- `query_result_caches`: Stores cached search results
- `genres`: Stores genre information from TMDb
- `media_items`: (Optional) Can store individual media items
- `media_genres`: Join table for media items and genres

## Testing

### Running Tests

```bash
# Run all tests
bundle exec rspec

# Run specific test file
bundle exec rspec spec/models/query_result_cache_spec.rb

# Run with coverage
COVERAGE=true bundle exec rspec
```

### Test Structure

- **Model Tests** (`spec/models/`): Unit tests for ActiveRecord models
- **Service Tests** (`spec/services/`): Unit tests for service classes
- **Integration Tests** (`spec/swagger/v1/`): API endpoint tests with Swagger documentation

### Test Coverage

The test suite covers:

- QueryResultCache model (caching logic, expiry, key generation)
- MediaService (search normalization, parameter handling)
- TmdbService (API client, query building)
- Genre model (sync from TMDb, validations)
- API endpoints (request/response, validation, error handling)

## Deployment

### Build Steps

1. **Install dependencies:**

   ```bash
   bundle install
   ```

2. **Build assets and prepare:**

   ```bash
   bundle exec rails assets:precompile
   ```

3. **Run database migrations:**

   ```bash
   bundle exec rails db:migrate
   ```

4. **Start the server:**

   ```bash
   bundle exec rails server
   ```

### Production Environment

The production environment (`config/environments/production.rb`) is configured for:

- Eager loading for better performance
- STDOUT logging for containerized deployments
- Solid Cache and Solid Queue for background jobs
- SSL termination at reverse proxy level
- Environment variable-based configuration

## Environment Variables

### Required

- `TMDB_ACCESS_TOKEN`: Your TMDb API access token
- `RAILS_ENV`: Environment (development/production)
- `DATABASE_URL`: PostgreSQL connection URL (usually provided by hosting platform)
- `RAILS_MASTER_KEY`: Master key for encrypted credentials (from `config/master.key`)

### Optional

- `RAILS_MAX_THREADS`: Puma thread count (default: 3)
- `RAILS_LOG_LEVEL`: Log level (default: info)
- `PORT`: Server port (default: 3000)
- `WEB_CONCURRENCY`: Number of Puma workers
- `SOLID_QUEUE_IN_PUMA`: Run Solid Queue in Puma (default: false)

### Getting a TMDb Access Token

1. Visit <https://www.themoviedb.org/settings/api>
2. Sign up for a free account
3. Request an API key
4. Add it to your environment variables

## Code Quality

### Linting

```bash
# Run RuboCop
bundle exec rubocop

# Auto-correct issues
bundle exec rubocop -A
```

### Security Scanning

```bash
# Brakeman (Rails security scanner)
bin/brakeman

# Bundler audit (gem vulnerability scanner)
bin/bundler-audit
```

## Troubleshooting

### Database Connection Issues

- Ensure PostgreSQL is running: `pg_isready -h localhost`
- Check database credentials in `config/database.yml`
- Verify `DATABASE_URL` environment variable if using it

### TMDb API Issues

- Verify `TMDB_ACCESS_TOKEN` is set correctly
- Check API rate limits (TMDb has rate limits)
- Review logs for API error messages

### Cache Issues

- Check `query_result_caches` table for stale entries
- Verify cache expiry logic is working: `QueryResultCache.first.cache_expired?`
- Clear cache manually if needed: `QueryResultCache.delete_all`

## Design Decisions

### Why Database Caching?

- Simple to implement and maintain
- No additional infrastructure (Redis, Memcached)
- Persistent across server restarts
- Easy to inspect and debug
- Sufficient for the scale of this application

### Why SHA256 for Query Keys?

- Deterministic: Same parameters always generate same key
- Collision-resistant: Extremely unlikely to have collisions
- Fast: Hash computation is very fast
- Human-readable: Can be stored and compared easily

### Why 24-Hour Cache Expiry?

- Balances freshness with API call reduction
- TMDb data doesn't change frequently for historical movies
- Reduces load on TMDb API
- Can be adjusted based on needs

## Future Improvements

- [ ] Redis caching for better performance at scale
- [ ] Background job to refresh popular queries
- [ ] Cache warming on application startup
- [ ] Cache statistics and monitoring
- [ ] Rate limiting to protect TMDb API
- [ ] GraphQL API option
- [ ] WebSocket support for real-time updates
