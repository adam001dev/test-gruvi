<script lang="ts">
  import { Badge } from "$lib/components/ui/badge";
  import {
    Card,
    CardContent,
    CardDescription,
    CardHeader,
    CardTitle,
  } from "$lib/components/ui/card";
  import { Skeleton } from "$lib/components/ui/skeleton";
  import * as Empty from "$lib/components/ui/empty";
  import SearchIcon from "@lucide/svelte/icons/search";
  import type { MediaItem } from "$lib/api";

  let {
    items,
    loading = $bindable(false),
    filterEmpty = $bindable(false),
  } = $props<{
    items: MediaItem[];
    loading?: boolean;
    filterEmpty?: boolean;
  }>();

  function formatDate(dateString: string): string {
    const date = new Date(dateString);
    return date.toLocaleDateString("en-US", {
      year: "numeric",
      month: "short",
      day: "numeric",
    });
  }

  function getPosterUrl(posterPath: string | null): string {
    if (!posterPath) {
      return "https://via.placeholder.co/300x450?text=No+Image";
    }
    return `https://image.tmdb.org/t/p/original${posterPath}`;
  }

  function handleImageError(event: any): void {
    if (event?.currentTarget) {
      event.currentTarget.src = "https://placeholder.co/300x450?text=No+Image";
    }
  }

  function truncateText(text: string, maxLength: number): string {
    if (text.length <= maxLength) return text;
    return text.slice(0, maxLength) + "...";
  }
</script>

{#if loading}
  <div
    class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
  >
    {#each Array(8) as _}
      <Card>
        <CardHeader>
          <Skeleton class="h-6 w-3/4" />
          <Skeleton class="h-4 w-1/2 mt-2" />
        </CardHeader>
        <CardContent>
          <Skeleton class="h-48 w-full mb-4" />
          <Skeleton class="h-4 w-full mb-2" />
          <Skeleton class="h-4 w-full mb-2" />
          <Skeleton class="h-4 w-2/3" />
        </CardContent>
      </Card>
    {/each}
  </div>
{:else if items.length === 0 && filterEmpty === true}
  <Empty.Root>
    <Empty.Header>
      <Empty.Media variant="icon">
        <SearchIcon class="size-8" />
      </Empty.Media>
      <Empty.Title>No results found</Empty.Title>
      <Empty.Description>
        Try adjusting your search criteria or date range to find more movies and
        TV shows.
      </Empty.Description>
    </Empty.Header>
  </Empty.Root>
{:else}
  <div
    class="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6"
  >
    {#each items as item (item.id)}
      <Card class="overflow-hidden pt-0 cursor-pointer hover:shadow-lg transition-shadow duration-300">
        <div class="aspect-square w-full overflow-hidden bg-muted relative">
          <img
            src={getPosterUrl(item.poster_path)}
            alt={item.title}
            class="w-full h-full object-contain"
            loading="lazy"
            onerror={handleImageError}
          />
          <div class="absolute top-2 right-2 flex gap-1 shrink-0">
            {#if item.adult}
              <Badge variant="destructive" class="bg-white text-black">Adult</Badge>
            {:else}
              <Badge variant="outline" class="bg-white text-black">General</Badge>
            {/if}
          </div>
        </div>
        <CardHeader>
          <CardTitle class="text-lg line-clamp-2 min-h-[56px]">{item.title}</CardTitle>
          <CardDescription>
            {item.release_date
              ? formatDate(item.release_date)
              : "Release date unknown"}
          </CardDescription>
        </CardHeader>
        <CardContent>
          <p class="text-sm text-muted-foreground line-clamp-3 mb-4">
            {truncateText(item.overview || "No description available", 150)}
          </p>
          <div class="flex items-center justify-between text-sm">
            <div class="flex items-center gap-1">
              <span class="font-semibold">Rating:</span>
              {#if item.vote_average === 0 || item.vote_count === 0}
                <span>None</span>
              {:else}
                <span>{item.vote_average.toFixed(1)}</span>
                <span class="text-muted-foreground">({item.vote_count})</span>
              {/if}
            </div>
          </div>
        </CardContent>
      </Card>
    {/each}
  </div>
{/if}
