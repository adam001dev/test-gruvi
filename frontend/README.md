# Frontend - Movie Search Application

SvelteKit application with TypeScript for searching movies and TV shows. Built with Svelte 5, Tailwind CSS, and shadcn-svelte components.

## Table of Contents

- [Project Structure](#project-structure)
- [Architecture Overview](#architecture-overview)
- [Component Architecture](#component-architecture)
- [API Integration](#api-integration)
- [Setup Instructions](#setup-instructions)
- [Building and Deployment](#building-and-deployment)
- [Development](#development)

## Project Structure

```
frontend/
├── src/
│   ├── lib/
│   │   ├── api.ts                    # API client functions
│   │   ├── validation.ts             # Date validation utilities
│   │   ├── utils.ts                  # Utility functions (cn, etc.)
│   │   └── components/
│   │       ├── MovieSearch.svelte    # Search form component
│   │       ├── MediaList.svelte      # Results display component
│   │       └── ui/                   # shadcn-svelte components
│   │           ├── button/
│   │           ├── card/
│   │           ├── calendar/
│   │           ├── pagination/
│   │           └── ...
│   └── routes/
│       ├── +page.svelte              # Main page
│       ├── +layout.svelte            # App layout
│       └── layout.css                # Global styles
├── static/                           # Static assets
├── package.json
├── svelte.config.js
├── tailwind.config.js
└── tsconfig.json
```

## Architecture Overview

### Technology Stack

- **SvelteKit 2.x**: Full-stack framework with file-based routing
- **Svelte 5.x**: Modern reactive framework with runes
- **TypeScript**: Type-safe development
- **Tailwind CSS 4.x**: Utility-first CSS framework
- **shadcn-svelte**: Pre-built accessible UI components
- **Vite**: Fast build tool and dev server
- **Zod**: Schema validation

### Key Libraries

- `sveltekit-superforms`: Form handling and validation
- `@internationalized/date`: Date handling and formatting
- `bits-ui`: Headless UI primitives
- `lucide-svelte`: Icon library
- `zod`: Runtime type validation

## Component Architecture

### Main Page (`src/routes/+page.svelte`)

The main page orchestrates the search flow:

1. **State Management**: Uses Svelte 5 runes (`$state`) for reactive state
2. **Search Handler**: Calls API and updates results
3. **Pagination**: Handles page changes and fetches new data
4. **Error Handling**: Displays error messages from API

**Key State:**

```typescript
let mediaItems = $state<MediaItem[]>([]);
let loading = $state(false);
let error = $state<string | null>(null);
let pagination = $state<Pagination | null>(null);
let currentPage = $state(1);
let searchParams = $state<SearchParams | null>(null);
```

### MovieSearch Component (`src/lib/components/MovieSearch.svelte`)

Search form component with date range picker and media type selector.

**Features:**

- Date range selection with calendar UI
- Media type selector (Movie/TV)
- Real-time validation
- Form submission handling
- Loading state management

**Props:**

```typescript
interface MovieSearchProps {
  onSearch: (params: SearchParams) => void;
  loading?: boolean;
}
```

**Validation:**

- Validates date range (start <= end)
- Uses Zod schema for type safety
- Displays validation errors inline

### MediaList Component (`src/lib/components/MediaList.svelte`)

Displays search results in a responsive grid layout.

**Features:**

- Responsive grid (1-4 columns based on screen size)
- Movie/TV show cards with:
  - Poster image (with fallback)
  - Title and release date
  - Description (truncated)
  - Rating and vote count
  - Adult content indicator
- Loading skeletons
- Empty state message

**Props:**

```typescript
interface MediaListProps {
  items: MediaItem[];
  loading?: boolean;
  filterEmpty?: boolean;
}
```

### UI Components (`src/lib/components/ui/`)

Built with shadcn-svelte, providing accessible, customizable components:

- **Button**: Various variants and sizes
- **Card**: Container for content sections
- **Calendar/RangeCalendar**: Date selection
- **Pagination**: Page navigation
- **Select**: Dropdown selection
- **Alert**: Error and info messages
- **Badge**: Status indicators
- **Skeleton**: Loading placeholders

All components are built on top of `bits-ui` for accessibility and follow WAI-ARIA guidelines.

## API Integration

### API Client (`src/lib/api.ts`)

Centralized API client with TypeScript interfaces.

**Key Functions:**

1. **`searchMediaItems(params: SearchParams)`**
   - Fetches media items from backend
   - Handles query parameters
   - Returns typed response with pagination

2. **`fetchGenres(mediaType?: "movie" | "tv")`**
   - Fetches available genres
   - Optional media type filter

3. **`syncGenres(mediaType: "movie" | "tv")`**
   - Triggers genre sync from TMDb

**Error Handling:**

```typescript
async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const error = await response.json().catch(() => ({
      error: `HTTP ${response.status}: ${response.statusText}`,
    }));
    throw new Error(error.error || error.message);
  }
  return response.json();
}
```

**Type Definitions:**

- `MediaItem`: Media item structure
- `SearchParams`: Search parameters
- `Pagination`: Pagination metadata
- `SearchQueryResponse`: API response structure

### API Base URL

Configured via environment variable:

```typescript
const API_BASE_URL = import.meta.env.VITE_API_BASE_URL || "http://localhost:3000";
```

Set in `.env`:

```bash
VITE_API_BASE_URL=http://localhost:3000
```

## Setup Instructions

### Prerequisites

- Node.js 24+
- pnpm (or npm/yarn)

### Installation

1. **Install dependencies:**

   ```bash
   pnpm install
   ```

2. **Configure environment:**

   ```bash
   cp .env.example .env
   ```

   Edit `.env`:

   ```bash
   VITE_API_BASE_URL=http://localhost:3000
   ```

3. **Start development server:**

   ```bash
   pnpm run dev
   ```

   Application will be available at `http://localhost:5173`

### Development Scripts

```bash
# Start dev server
pnpm run dev

# Build for production
pnpm run build

# Preview production build
pnpm run preview

# Type checking
pnpm run type-check

# Linting
pnpm run lint

# Format code
pnpm run format
```

## Building and Deployment

### Build Steps

1. **Install dependencies:**

   ```bash
   pnpm install
   ```

2. **Build the application:**

   ```bash
   pnpm run build
   ```

3. **Output directory:**
   - Built files are in `.svelte-kit/` directory
   - Static assets in `static/`
   - The build process creates optimized production bundles

### Production Build

The build process:

- Compiles Svelte components
- Bundles JavaScript with code splitting
- Optimizes CSS with Tailwind
- Generates static assets
- Creates server-side rendering (SSR) routes if needed

### Environment Variables

**Development:**

- `VITE_API_BASE_URL`: Backend API URL (default: http://localhost:3000)

**Production:**

- `VITE_API_BASE_URL`: Production backend API URL (required)

Note: Vite requires the `VITE_` prefix for environment variables to be exposed to the client.

## Development

### Code Quality

**TypeScript:**

```bash
# Type check
pnpm run type-check
```

**Linting:**

```bash
# Run ESLint
pnpm run lint
```

**Formatting:**

```bash
# Format with Prettier
pnpm run format
```

### Component Development

**Creating New Components:**

1. Create component file in `src/lib/components/`
2. Use TypeScript for props and state
3. Follow Svelte 5 runes syntax (`$state`, `$derived`, `$effect`)
4. Use shadcn-svelte components for UI primitives

**Example Component:**

```svelte
<script lang="ts">
  interface Props {
    title: string;
    count?: number;
  }

  let { title, count = 0 }: Props = $props();
  let localCount = $state(count);

  $effect(() => {
    localCount = count;
  });
</script>

<div>
  <h1>{title}</h1>
  <p>Count: {localCount}</p>
</div>
```

### Styling

**Tailwind CSS:**

- Utility-first approach
- Responsive breakpoints: `sm:`, `md:`, `lg:`, `xl:`
- Dark mode support (if configured)

**Component Styling:**

- Use Tailwind utilities in class attributes
- Use `cn()` utility for conditional classes
- Follow shadcn-svelte patterns for component variants

### State Management

**Svelte 5 Runes:**

- `$state`: Reactive state
- `$derived`: Computed values
- `$effect`: Side effects
- `$props`: Component props

**Example:**

```typescript
let count = $state(0);
let doubled = $derived(count * 2);

$effect(() => {
  console.log(`Count is ${count}`);
});
```

### Form Handling

**Superforms:**

- Uses `sveltekit-superforms` for form management
- Zod schemas for validation
- Automatic error handling
- Type-safe form data

**Example:**

```typescript
import { superForm } from "sveltekit-superforms";
import { z } from "zod";

const schema = z.object({
  start_date: z.string().optional(),
  end_date: z.string().optional(),
});

const form = superForm({
  start_date: "",
  end_date: "",
}, {
  onUpdate: async ({ form }) => {
    // Handle form submission
  },
});
```

## Design Patterns

### Component Composition

- **Container/Presentational**: Main page handles logic, components handle presentation
- **Props Down, Events Up**: Data flows down, events flow up
- **Single Responsibility**: Each component has one clear purpose

### Error Handling

- **API Errors**: Caught in API client, thrown as Error objects
- **Validation Errors**: Displayed inline in forms
- **Network Errors**: Shown in error banner on main page

### Loading States

- **Skeleton Loaders**: Show while data is loading
- **Disabled States**: Disable forms during submission
- **Loading Indicators**: Spinner icons during async operations

## Browser Support

- Modern browsers (Chrome, Firefox, Safari, Edge)
- ES2020+ features required
- CSS Grid and Flexbox support
- No IE11 support

## Performance

### Optimizations

- **Code Splitting**: Automatic route-based code splitting
- **Lazy Loading**: Images use `loading="lazy"` attribute
- **Tree Shaking**: Unused code removed in production
- **CSS Purging**: Unused Tailwind classes removed

### Best Practices

- Use `$derived` for computed values instead of recalculating
- Minimize `$effect` usage (only for side effects)
- Lazy load heavy components
- Optimize images before adding to static/

## Troubleshooting

### Build Issues

- **Type Errors**: Run `pnpm run type-check` to see detailed errors
- **Import Errors**: Check path aliases in `svelte.config.js`
- **CSS Issues**: Ensure Tailwind is properly configured

### Runtime Issues

- **API Connection**: Verify `VITE_API_BASE_URL` is correct
- **CORS Errors**: Ensure backend CORS is configured
- **Date Format**: Use YYYY-MM-DD format for dates

### Development Server

- **Port Already in Use**: Change port with `pnpm run dev -- --port 5174`
- **Hot Reload Not Working**: Restart dev server
- **Type Errors**: Run `svelte-kit sync` to update types

## Future Improvements

- [ ] Add advanced filters (genres, ratings) to UI
- [ ] Implement favorites/bookmarks
- [ ] Add search history
- [ ] Dark mode toggle
- [ ] Progressive Web App (PWA) support
- [ ] Image optimization and lazy loading
- [ ] Virtual scrolling for large result sets
- [ ] Accessibility improvements (ARIA labels, keyboard navigation)
- [ ] Unit tests with Vitest
- [ ] E2E tests with Playwright
