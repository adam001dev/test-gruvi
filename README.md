# Movie Search Application

A full-stack web application for searching movies and TV shows by date range. Built with Ruby on Rails API, SvelteKit frontend, TypeScript, and Tailwind CSS.

## Documentation

For detailed documentation on each part of the application:

- **[Backend README](backend/README.md)** - Backend architecture, API endpoints, caching strategy, and setup
- **[Frontend README](frontend/README.md)** - Frontend structure, components, API integration, and development guide

## Features

- Search movies and TV shows by date range (optional start/end dates)
- Filter by media type (Movie or TV only)
- Display adult content indicators
- Query result caching (24-hour expiration for filtered queries, 1-hour for unfiltered)
- Real-time date validation
- Responsive design with shadcn-svelte components
- RESTful API with Swagger documentation
- Media type is required (no "all" option)

## Tech Stack

- **Backend**: Ruby on Rails 8.x (API-only mode)
- **Frontend**: SvelteKit with Svelte 5.x, TypeScript
- **Database**: PostgreSQL
- **Styling**: Tailwind CSS with shadcn-svelte components
- **API**: TMDb (The Movie Database) v3
- **Code Quality**: RuboCop, Prettier, ESLint

## Prerequisites

- Ruby 3.4.7+ (use `mise` or `rbenv`)
- Node.js 24+ and pnpm
- PostgreSQL 14+ (running locally)

## Setup Instructions

### Backend Setup

1. Navigate to backend directory:

```bash
cd backend
```

2. Install dependencies:

```bash
bundle install
```

3. Ensure PostgreSQL is running:

```bash
# macOS with Homebrew
brew services start postgresql@14

# Or check if running
pg_isready -h localhost
```

4. Create and migrate database:

```bash
bundle exec rails db:create db:migrate
```

5. Create environment file:

```bash
cp .env.example .env
```

6. Edit `.env` and add your TMDb Access Token:

```bash
TMDB_ACCESS_TOKEN=your_access_token_here
RAILS_ENV=development
```

**Note:** The database connection uses your system's default PostgreSQL user (your macOS username). Rails will automatically use your system user (e.g., `allen`) to connect to PostgreSQL. You don't need to set `DATABASE_URL` in `.env` for local development unless you're using custom credentials.

**To check your PostgreSQL user:**

```bash
# Check your system username (this is what Rails uses by default)
whoami

# Check what user Rails is using to connect
cd backend
rails runner "puts ActiveRecord::Base.connection.execute('SELECT current_user').first['current_user']"

# List all PostgreSQL users
psql -U postgres -c "\du"
```

7. Start Rails server:

```bash
rails server
```

Backend will be available at: <http://localhost:3000>

### Frontend Setup

1. Navigate to frontend directory:

```bash
cd frontend
```

2. Install dependencies:

```bash
pnpm install
```

3. Create environment file:

```bash
cp .env.example .env
```

4. Edit `.env` and set API base URL:

```bash
VITE_API_BASE_URL=http://localhost:3000
```

5. Start dev server:

```bash
pnpm run dev
```

Frontend will be available at: <http://localhost:5173>

## Running Both Services

In two separate terminal windows:

**Terminal 1 - Backend:**

```bash
cd backend
rails server
```

**Terminal 2 - Frontend:**

```bash
cd frontend
pnpm run dev
```

Access the application at <http://localhost:5173>

## Environment Variables

### Backend (`backend/.env`)

- `TMDB_ACCESS_TOKEN`: Your TMDb Access Token (required)
- `RAILS_ENV`: Environment (development/production) - optional, defaults to development
- `DATABASE_URL`: PostgreSQL connection URL (optional) - only needed if using custom credentials. By default, Rails uses the configuration from `config/database.yml` with your system's default PostgreSQL user.

### Frontend (`frontend/.env`)

- `VITE_API_BASE_URL`: Backend API base URL (default: <http://localhost:3000>)

### Production Environment Variables

**Backend Production Variables:**

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `TMDB_ACCESS_TOKEN` | ✅ Yes | Your TMDb API access token | `eyJhbGciOiJIUzI1NiJ9...` |
| `RAILS_ENV` | ✅ Yes | Rails environment | `production` |
| `RAILS_MASTER_KEY` | ✅ Yes | Master key for encrypted credentials | From `config/master.key` |
| `DATABASE_URL` | ✅ Yes | PostgreSQL connection URL | `postgresql://user:pass@host:5432/dbname` |
| `MY_MOVIE_DATABASE_PASSWORD` | ⚠️ Conditional | Database password (if not in DATABASE_URL) | `your_secure_password` |
| `RAILS_MAX_THREADS` | ❌ No | Max threads for Puma (default: 5) | `5` |
| `RAILS_LOG_LEVEL` | ❌ No | Log level (default: info) | `info`, `debug`, `warn`, `error` |
| `PORT` | ❌ No | Server port (default: 3000) | `3000` |
| `WEB_CONCURRENCY` | ❌ No | Number of Puma workers | `2` |
| `JOB_CONCURRENCY` | ❌ No | Solid Queue job concurrency (default: 1) | `2` |

**Frontend Production Variables:**

| Variable | Required | Description | Example |
|----------|----------|-------------|---------|
| `VITE_API_BASE_URL` | ✅ Yes | Backend API base URL | `https://api.yourdomain.com` |

**Notes:**

- Most hosting platforms (Render, Fly.io, Railway, Heroku) automatically provide `DATABASE_URL` when you provision a PostgreSQL database
- `RAILS_MASTER_KEY` is required for Rails encrypted credentials. Keep this secure and never commit it to version control
- For production, always use `RAILS_ENV=production`
- The `PORT` variable is usually set automatically by hosting platforms

## API Endpoints

### Get Genres

```
GET /api/v1/genres?media_type=movie
```

### Sync Genres

```
POST /api/v1/genres/sync
Body: { "media_type": "movie" }
```

### Search Media Items

```
GET /api/v1/media_items?start_date=2024-01-01&end_date=2024-12-31&media_type=movie
```

Query parameters:

- `start_date` (optional): YYYY-MM-DD format
- `end_date` (optional): YYYY-MM-DD format
- `media_type` (required): 'movie' or 'tv' (no 'all' option)
- `genre_ids` (optional): comma-separated genre IDs
- `min_rating` (optional): minimum vote average
- `sort_by` (optional): sort parameter
- `page` (optional): page number

See Swagger documentation at `/api-docs` for full API details.

## Code Formatting

### Backend (Ruby)

```bash
cd backend
bundle exec rubocop -A  # Auto-correct formatting
```

### Frontend (TypeScript/Svelte)

```bash
cd frontend
pnpm format        # Format code with Prettier
pnpm lint          # Check with ESLint
pnpm type-check    # TypeScript type checking
```

## Design Decisions

### API-Only Rails

We chose an API-only Rails application to keep the backend focused on data operations and to enable flexibility in frontend technology choices. This allows for clear separation of concerns and easier testing.

### Query Caching Strategy

Results are cached in the database with a 24-hour expiration window for filtered queries (with dates, genres, or ratings) and 1-hour for unfiltered queries. Each unique query (combination of filters) gets a SHA256 hash (`query_key`). Cached results are returned if available and not expired, otherwise the API is called and results are updated. This balances freshness with performance and eliminates unnecessary external API calls.

For detailed information about the caching implementation, see the [Backend README](backend/README.md#search-and-caching-flow).

### PostgreSQL

We selected PostgreSQL for its robust support of date range queries, which are essential for filtering movies by release date. It's also production-ready and scales well.

### Svelte + TypeScript

SvelteKit with TypeScript provides a modern, type-safe frontend with excellent developer experience. Svelte's reactivity system is elegant and performant, and TypeScript catches errors at development time.

### shadcn-svelte Components

We use shadcn-svelte for UI components to maintain consistency and reduce development time. These components are built on top of Tailwind CSS and bits-ui, providing accessible, customizable components.

### Tailwind CSS

Tailwind CSS provides a utility-first approach to styling, enabling rapid UI development without writing custom CSS. It's paired with shadcn-svelte for pre-built components.

## Trade-offs & Future Improvements

### Current Limitations

1. **No pagination UI**: While the API supports pagination, the frontend currently loads all results from a single page. Multiple page fetching could be added in the future.
2. **Simple caching**: Database-based caching is simple but not as fast as Redis. For high-traffic applications, Redis would be beneficial.
3. **Genre display**: Genres are not shown on cards to prevent UI layout issues. They're available in the API response.
4. **Limited filters**: Only date range and media type are exposed in the frontend. Genre and rating filters are available in the API.

### Future Enhancements

- [ ] Pagination UI with ability to load more results
- [ ] Advanced filtering (genres, ratings, popularity)
- [ ] User favorites system (requires user authentication)
- [ ] Background jobs to refresh cache automatically
- [ ] Image optimization and caching
- [ ] Rate limiting on API endpoints
- [ ] Full-text search capability
- [ ] User preferences and bookmarks
- [ ] Social sharing features

## Media Type Requirement

**Important**: Media type is a **required** field and only accepts `movie` or `tv`. The `all` option is not supported. Users must explicitly select either Movies or TV Shows when searching.

## Troubleshooting

### Database Connection Issues

If you see "cannot connect to database" errors:

1. Ensure PostgreSQL is running:

   ```bash
   # macOS
   brew services start postgresql@14
   pg_isready -h localhost
   ```

2. Create the database:

   ```bash
   cd backend
   rails db:create
   ```

3. Run migrations:

   ```bash
   rails db:migrate
   ```

4. **If you see "role does not exist" errors:**
   - Remove or comment out `DATABASE_URL` from your `.env` file
   - Rails will use the default PostgreSQL user (your system username) from `config/database.yml`
   - The default setup doesn't require a password for local development
   - **Check your PostgreSQL user:**

     ```bash
     # Check your system username (default PostgreSQL user)
     whoami
     
     # Check what user Rails is connecting as
     cd backend
     rails runner "puts ActiveRecord::Base.connection.execute('SELECT current_user').first['current_user']"
     
     # List all PostgreSQL users
     psql -U postgres -c "\du"
     ```

5. Verify database name in `config/database.yml` matches your setup (`my_movie_development`)

### TMDb API Key Issues

If searches return errors:

1. Verify your TMDb API key is valid
2. Check that `TMDB_ACCESS_TOKEN` environment variable is set
3. Ensure the key has proper permissions

### Media Type Validation

If you receive "media_type must be 'movie' or 'tv'" errors:

1. Ensure you're sending either `movie` or `tv` as the media_type parameter
2. The `all` option is no longer supported
3. Always include media_type in search requests

### Port Already in Use

If ports 3000 or 5173 are already in use, stop the processes using them or specify different ports:

```bash
# For backend (use a different port)
rails server -p 3001

# For frontend (use a different port)
pnpm run dev -- --port 5174
```

## Getting a TMDb API Key

1. Visit <https://www.themoviedb.org/settings/api>
2. Sign up for a free account if needed
3. Request an API key
4. Add it to your `.env` file

## Development Workflow

1. Frontend changes auto-reload in dev mode
2. Backend changes auto-reload for most files (controllers, models, services). The `listen` gem enables auto-restart for initializers, routes, and other files that require a full restart.
3. Environment variables from `.env` are automatically loaded by `dotenv-rails` when the server starts
4. Database migrations: `rails db:migrate`
5. Run tests: `bundle exec rspec` (when tests are added)

## Deployment

### Backend

1. **Install dependencies:**

   ```bash
   cd backend
   bundle install
   ```

2. **Build and prepare:**

   ```bash
   bundle exec rails assets:precompile
   bundle exec rails db:migrate
   ```

3. **Run the server:**

   ```bash
   bundle exec rails server
   ```

See [Backend README](backend/README.md#deployment) for detailed deployment information.

### Frontend

1. **Install dependencies:**

   ```bash
   cd frontend
   pnpm install
   ```

2. **Build the application:**

   ```bash
   pnpm run build
   ```

3. **Deploy the built files** (location depends on your hosting platform)

See [Frontend README](frontend/README.md#building-and-deployment) for detailed deployment information.

## API Documentation

Full API documentation is available at `/api-docs` when the backend is running. This includes:

- All available endpoints
- Request/response schemas
- Example requests and responses
- Parameter descriptions

## Contributing

When contributing, please:

1. Follow the code style (RuboCop for Ruby, Prettier for TypeScript)
2. Run `pnpm format` and `pnpm lint` in frontend
3. Run `bundle exec rubocop -A` in backend
4. Keep commits atomic and descriptive
5. Follow the no-comments rule for step-by-step logic (only `console.debug()` for debugging)

## License

MIT
