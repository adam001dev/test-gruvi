const API_BASE_URL =
  import.meta.env.VITE_API_BASE_URL || "http://localhost:3000";

export interface Genre {
  id: number;
  tmdb_id: number;
  name: string;
  media_type: "movie" | "tv";
}

export interface MediaItem {
  id: number;
  tmdb_id: number;
  media_type: "movie" | "tv";
  title: string;
  release_date: string;
  overview: string;
  poster_path: string | null;
  popularity: number;
  vote_average: number;
  vote_count: number;
  original_language: string;
  adult: boolean;
  genres: Genre[];
}

export interface SearchParams {
  start_date?: string;
  end_date?: string;
  media_type: "movie" | "tv";
  genre_ids?: number[];
  min_rating?: number;
  sort_by?: string;
  page?: number;
}

export interface Pagination {
  page: number;
  total_pages: number;
  total_results: number;
  per_page: number;
}

export interface SearchQueryResponse {
  data: MediaItem[];
  query_key: string;
  cached: boolean;
  last_updated: string;
  pagination: Pagination;
}

export interface ErrorResponse {
  error: string;
  message?: string;
  details?: unknown;
}

async function handleResponse<T>(response: Response): Promise<T> {
  if (!response.ok) {
    const error: ErrorResponse = await response.json().catch(() => ({
      error: `HTTP ${response.status}: ${response.statusText}`,
    }));
    throw new Error(error.error || error.message || `HTTP ${response.status}`);
  }
  return response.json();
}

export async function fetchGenres(
  mediaType?: "movie" | "tv",
): Promise<Genre[]> {
  const url = new URL(`${API_BASE_URL}/api/v1/genres`);
  if (mediaType) {
    url.searchParams.set("media_type", mediaType);
  }

  const response = await fetch(url.toString());
  return handleResponse<Genre[]>(response);
}

export async function syncGenres(
  mediaType: "movie" | "tv",
): Promise<{ success: boolean }> {
  const response = await fetch(`${API_BASE_URL}/api/v1/genres/sync`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ media_type: mediaType }),
  });

  return handleResponse<{ success: boolean }>(response);
}

export async function searchMediaItems(
  params: SearchParams,
): Promise<SearchQueryResponse> {
  const url = new URL(`${API_BASE_URL}/api/v1/media_items`);

  if (params.start_date) url.searchParams.set("start_date", params.start_date);
  if (params.end_date) url.searchParams.set("end_date", params.end_date);
  if (params.media_type) url.searchParams.set("media_type", params.media_type);
  if (params.genre_ids?.length)
    url.searchParams.set("genre_ids", params.genre_ids.join(","));
  if (params.min_rating)
    url.searchParams.set("min_rating", params.min_rating.toString());
  if (params.sort_by) url.searchParams.set("sort_by", params.sort_by);
  if (params.page) url.searchParams.set("page", params.page.toString());

  const response = await fetch(url.toString());
  return handleResponse<SearchQueryResponse>(response);
}
