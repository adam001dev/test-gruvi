# Local Development Setup Guide

This guide covers two ways to run the application locally:

1. **Direct Setup** (without Docker) - Recommended for development
2. **Docker Compose** (with Docker) - Quick setup with containers

## Prerequisites Check

1. **Check Ruby version:**

   ```bash
   ruby --version
   # Should be 3.4.7 or compatible
   ```

2. **Check Node.js and pnpm:**

   ```bash
   node --version  # Should be 24+
   pnpm --version  # Should be installed
   ```

3. **Check PostgreSQL (for Direct Setup):**

   ```bash
   pg_isready -h localhost
   # If not running, start it:
   brew services start postgresql@14
   ```

4. **Check Docker (for Docker Compose):**

   ```bash
   docker --version
   docker-compose --version
   ```

---

## Option 1: Direct Setup (No Docker)

### Step 1: Backend Setup

```bash
# Navigate to backend
cd backend

# Install Ruby dependencies
bundle install

# Create and setup database
bundle exec rails db:create db:migrate

# Create .env file (if not exists)
cp .env.example .env

# Edit .env file - add your TMDb Access Token
# TMDB_ACCESS_TOKEN=your_access_token_here
# DATABASE_URL=postgresql://localhost/my_movie_development
# RAILS_ENV=development

# Start Rails server
bundle exec rails s
```

**Backend will run on:** <http://localhost:3000>

**Test backend:**

- Open <http://localhost:3000/api-docs> (Swagger UI)
- Or test API: `curl http://localhost:3000/api/v1/genres?media_type=movie`

### Step 2: Frontend Setup (New Terminal)

```bash
# Navigate to frontend
cd frontend

# Install dependencies
pnpm install

# Create .env file (if not exists)
cp .env.example .env

# Edit .env file - set API URL
# VITE_API_BASE_URL=http://localhost:3000

# Start dev server
pnpm run dev
```

**Frontend will run on:** <http://localhost:5173>

### Step 3: Access the Application

1. Open browser: <http://localhost:5173>
2. You should see the Movie Search interface
3. Try searching with:
   - Start Date: 2024-01-01
   - End Date: 2024-12-31
   - Media Type: Movie or TV

---

## Option 2: Docker Compose Setup (Backend + Database Only)

**Note:** Docker Compose runs only the backend and PostgreSQL. Frontend should be run locally (see Option 1: Frontend Setup).

### Quick Start

1. **Create environment file:**

```bash
cp backend/.env.example backend/.env
```

2. **Set your TMDb API key in `backend/.env`:**

```bash
TMDB_ACCESS_TOKEN=your_access_token_here
```

3. **Start backend and database:**

```bash
docker-compose up
```

Or run in detached mode (background):

```bash
docker-compose up -d
```

4. **Access the services:**

- Backend API: <http://localhost:3000>
- Swagger Docs: <http://localhost:3000/api-docs>
- PostgreSQL: localhost:5432

5. **Run frontend locally** (in a separate terminal):

```bash
cd frontend
pnpm install
cp .env.example .env
# Edit .env: VITE_API_BASE_URL=http://localhost:3000
pnpm run dev
```

Frontend will be available at: <http://localhost:5173>

### Docker Compose Commands

**Start services:**

```bash
docker-compose up
```

**Start in background:**

```bash
docker-compose up -d
```

**Stop services:**

```bash
cd backend
docker-compose down
```

**Stop and remove volumes (clean slate):**

```bash
cd backend
docker-compose down -v
```

**View logs:**

```bash
# All services
cd backend
docker-compose logs

# Specific service
docker-compose logs backend
docker-compose logs postgres

# Follow logs
docker-compose logs -f backend
```

**Rebuild after dependency changes:**

```bash
# Rebuild backend
cd backend
docker-compose build backend

# Rebuild and restart
docker-compose up --build
```

**Run commands in containers:**

```bash
# Backend Rails console
cd backend
docker-compose exec backend bundle exec rails console

# Backend database migration
docker-compose exec backend bundle exec rails db:migrate

# PostgreSQL shell
docker-compose exec postgres psql -U mymovie -d my_movie_development
```

---

## Troubleshooting

### Backend Issues

**Database connection error:**

```bash
# Check PostgreSQL is running (for Direct Setup)
pg_isready -h localhost

# If not, start it
brew services start postgresql@14

# Recreate database
cd backend
bundle exec rails db:drop db:create db:migrate
```

**Port 3000 already in use:**

```bash
# Find process using port 3000
lsof -ti:3000

# Kill it
kill -9 $(lsof -ti:3000)

# Or use different port
bundle exec rails s -p 3001
```

**Missing TMDb API key:**

- Get free API key from: <https://www.themoviedb.org/settings/api>
- Add to `backend/.env`: `TMDB_ACCESS_TOKEN=your_access_token_here`

### Frontend Issues

**Port 5173 already in use:**

```bash
# Find and kill process
lsof -ti:5173 | xargs kill -9

# Or use different port
pnpm run dev -- --port 5174
```

**API connection error:**

- Check `frontend/.env` has: `VITE_API_BASE_URL=http://localhost:3000`
- Verify backend is running on port 3000
- Check browser console for CORS errors

### Docker Issues

**Port conflicts:**

If ports 3000, 5173, or 5432 are already in use, change them in `backend/docker-compose.yml`:

```yaml
ports:
  - "3001:3000"  # Change host port
```

**Database connection issues:**

```bash
cd backend
# Check PostgreSQL is healthy
docker-compose ps postgres

# View PostgreSQL logs
docker-compose logs postgres

# Reset database
docker-compose exec backend bundle exec rails db:reset
```

**Clean start:**

```bash
cd backend
# Stop and remove everything
docker-compose down -v

# Remove images
docker-compose rm -f

# Rebuild and start
docker-compose up --build
```

---

## Useful Commands

### Backend

```bash
# Check database status
bundle exec rails db:migrate:status

# Reset database
bundle exec rails db:reset

# Generate Swagger docs
bundle exec rake rswag:specs:swaggerize

# Run linter
bundle exec rubocop -A

# Check routes
bundle exec rails routes
```

### Frontend

```bash
# Type check
pnpm type-check

# Lint
pnpm lint

# Format code
pnpm format

# Build for production
pnpm run build
```

---

## Testing the Application

1. **Test Backend API directly:**

   ```bash
   # Get genres
   curl "http://localhost:3000/api/v1/genres?media_type=movie"
   
   # Search movies
   curl "http://localhost:3000/api/v1/media_items?start_date=2024-01-01&end_date=2024-12-31&media_type=movie"
   ```

2. **Test Frontend:**

   - Open <http://localhost:5173>
   - Fill in date range
   - Select media type (Movie or TV)
   - Click Search
   - Should see results displayed

3. **Check Swagger Documentation:**

   - Open <http://localhost:3000/api-docs>
   - Test endpoints directly from Swagger UI

---

## Next Steps

Once everything is running:

- ✅ Test search functionality
- ✅ Verify date validation works
- ✅ Check media type filtering
- ✅ Test with different date ranges
- ✅ Verify caching (search same query twice)

## Development Workflow

### Direct Setup

1. **Code changes** are automatically reflected (hot-reload)
2. **Database changes** require running migrations:

   ```bash
   bundle exec rails db:migrate
   ```

3. **Dependency changes** require reinstall:

   ```bash
   bundle install  # Backend
   pnpm install     # Frontend
   ```

### Docker Compose

1. **Code changes** are automatically reflected (hot-reload via volumes)
2. **Database changes** require running migrations:

   ```bash
   cd backend
   docker-compose exec backend bundle exec rails db:migrate
   ```

3. **Dependency changes** require rebuild:

   ```bash
   cd backend
   docker-compose build backend
   docker-compose up
   ```
