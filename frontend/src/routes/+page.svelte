<script lang="ts">
  import MovieSearch from "$lib/components/MovieSearch.svelte";
  import MediaList from "$lib/components/MediaList.svelte";
  import {
    searchMediaItems,
    type MediaItem,
    type SearchParams,
    type Pagination,
  } from "$lib/api";
  import * as PaginationComponent from "$lib/components/ui/pagination";
  import ChevronLeftIcon from "@lucide/svelte/icons/chevron-left";
  import ChevronRightIcon from "@lucide/svelte/icons/chevron-right";

  const MAX_PAGES = 500;
  const PER_PAGE = 20;

  let mediaItems = $state<MediaItem[]>([]);
  let loading = $state(false);
  let error = $state<string | null>(null);
  let pagination = $state<Pagination | null>(null);
  let currentPage = $state(1);
  let searchParams = $state<SearchParams | null>(null);
  let previousPage = $state(1);
  let isSettingPageProgrammatically = $state(false);

  async function handleSearch(params: SearchParams) {
    loading = true;
    error = null;
    isSettingPageProgrammatically = true;
    currentPage = 1;
    previousPage = 1;
    searchParams = params;
    isSettingPageProgrammatically = false;

    try {
      const response = await searchMediaItems({ ...params, page: 1 });
      mediaItems = response.data;
      pagination = {
        ...response.pagination,
        total_pages: Math.min(response.pagination.total_pages, MAX_PAGES)
      };
      currentPage = Math.min(response.pagination.page, MAX_PAGES);
    } catch (err) {
      error =
        err instanceof Error
          ? err.message
          : "An error occurred while searching";
      mediaItems = [];
      pagination = null;
    } finally {
      loading = false;
    }
  }

  $effect(() => {
    if (isSettingPageProgrammatically) {
      previousPage = currentPage;
      return;
    }

    if (currentPage !== previousPage && searchParams && !loading) {
      previousPage = currentPage;
      handlePageChange(currentPage);
    }
  });

  async function handlePageChange(page: number) {
    if (!searchParams || loading) return;

    const cappedPage = Math.min(Math.max(1, page), MAX_PAGES);
    if (page !== cappedPage) {
      currentPage = cappedPage;
      return;
    }

    loading = true;
    error = null;
    isSettingPageProgrammatically = true;
    currentPage = page;
    previousPage = page;
    isSettingPageProgrammatically = false;

    try {
      const response = await searchMediaItems({ ...searchParams, page });
      mediaItems = response.data;
      pagination = {
        ...response.pagination,
        total_pages: Math.min(response.pagination.total_pages, MAX_PAGES)
      };
      currentPage = Math.min(response.pagination.page, MAX_PAGES);
    } catch (err) {
      error =
        err instanceof Error
          ? err.message
          : "An error occurred while loading page";
      mediaItems = [];
    } finally {
      loading = false;
    }
  }
</script>

<svelte:head>
  <title>MyMovie</title>
</svelte:head>

<div class="container mx-auto py-8 px-4">
  <div class="max-w-7xl mx-auto">
    <h1 class="text-4xl font-bold mb-8 text-center">Movie & TV Show Search</h1>

    <div class="mb-8">
      <MovieSearch onSearch={handleSearch} bind:loading />
    </div>

    {#if error}
      <div
        class="mb-6 p-4 bg-destructive/10 border border-destructive rounded-md"
      >
        <p class="text-destructive font-semibold">Error: {error}</p>
      </div>
    {/if}

    <MediaList items={mediaItems} bind:loading />

    {#if pagination && pagination.total_pages > 0 && !loading}
      <div class="mt-8 flex justify-center">
        <PaginationComponent.Root
          count={Math.min(pagination.total_results, MAX_PAGES * PER_PAGE)}
          perPage={PER_PAGE}
          bind:page={currentPage}
          siblingCount={1}
        >
          {#snippet children({ pages, currentPage: activePage })}
            <PaginationComponent.Content>
              <PaginationComponent.Item>
                <PaginationComponent.PrevButton>
                  <ChevronLeftIcon class="size-4" />
                  <span class="hidden sm:block">Previous</span>
                </PaginationComponent.PrevButton>
              </PaginationComponent.Item>
              {#each pages as page (page.key)}
                {#if page.type === "ellipsis"}
                  <PaginationComponent.Item>
                    <PaginationComponent.Ellipsis />
                  </PaginationComponent.Item>
                {:else}
                  <PaginationComponent.Item>
                    <PaginationComponent.Link
                      {page}
                      isActive={activePage === page.value}
                    >
                      {page.value}
                    </PaginationComponent.Link>
                  </PaginationComponent.Item>
                {/if}
              {/each}
              <PaginationComponent.Item>
                <PaginationComponent.NextButton>
                  <span class="hidden sm:block">Next</span>
                  <ChevronRightIcon class="size-4" />
                </PaginationComponent.NextButton>
              </PaginationComponent.Item>
            </PaginationComponent.Content>
          {/snippet}
        </PaginationComponent.Root>
      </div>
    {/if}
  </div>
</div>
