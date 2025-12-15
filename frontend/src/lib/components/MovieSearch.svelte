<script lang="ts" module>
  import { z } from "zod";

  const searchSchema = z.object({
    start_date: z.string().optional().default(""),
    end_date: z.string().optional().default(""),
    media_type: z.enum(["movie", "tv"]),
  });

  export { searchSchema };
</script>

<script lang="ts">
  import type { DateRange } from "bits-ui";
  import { LoaderIcon } from "lucide-svelte";
  import { superForm } from "sveltekit-superforms";

  import type { SearchParams } from "$lib/api";
  import * as Alert from "$lib/components/ui/alert";
  import { Button, buttonVariants } from "$lib/components/ui/button";
  import {
    Card,
    CardContent,
    CardHeader,
    CardTitle,
  } from "$lib/components/ui/card";
  import { Label } from "$lib/components/ui/label";
  import * as Popover from "$lib/components/ui/popover";
  import { RangeCalendar } from "$lib/components/ui/range-calendar";
  import * as Select from "$lib/components/ui/select";
  import { cn } from "$lib/utils";
  import { validateDateRange } from "$lib/validation";
  import {
    DateFormatter,
    type DateValue,
    getLocalTimeZone,
    parseDate,
  } from "@internationalized/date";
  import CalendarIcon from "@lucide/svelte/icons/calendar";
  import CircleAlertIcon from "@lucide/svelte/icons/circle-alert";
  import XIcon from "@lucide/svelte/icons/x";

  interface MovieSearchProps {
    onSearch: (params: SearchParams) => void;
    loading?: boolean;
  }

  let { onSearch, loading = $bindable(false) }: MovieSearchProps = $props();

  const form = superForm(
    {
      start_date: "",
      end_date: "",
      media_type: "movie",
    },
    {
      SPA: true,
      invalidateAll: false,
      resetForm: false,
      onUpdate: async ({ form: f }) => {
        const data = f.data as {
          start_date: string;
          end_date: string;
          media_type: string;
        };
        const validation = validateDateRange(
          data.start_date || undefined,
          data.end_date || undefined,
        );
        if (!validation.valid) {
          validationError = validation.error || "Invalid date range";
          return;
        }

        validationError = null;

        const params: SearchParams = {
          media_type: data.media_type as "movie" | "tv",
        };
        if (data.start_date) params.start_date = data.start_date;
        if (data.end_date) params.end_date = data.end_date;

        onSearch(params);
      },
    },
  );

  const { form: formData, enhance } = form;

  const df = new DateFormatter("en-US", {
    dateStyle: "medium",
  });

  let dateRange: DateRange | undefined = $state(undefined);
  let startValue: DateValue | undefined = $state(undefined);
  let validationError: string | null = $state(null);

  function updateDateRangeFromForm() {
    const start = $formData.start_date
      ? parseDate($formData.start_date)
      : undefined;
    const end = $formData.end_date ? parseDate($formData.end_date) : undefined;

    if (start && end) {
      dateRange = { start, end };
    } else if (start) {
      dateRange = { start, end: undefined };
    } else {
      dateRange = undefined;
    }
  }

  $effect(() => {
    updateDateRangeFromForm();
  });

  function handleDateRangeChange(newRange: DateRange | undefined) {
    dateRange = newRange;
    if (newRange?.start) {
      $formData.start_date = newRange.start.toString();
    } else {
      $formData.start_date = "";
    }
    if (newRange?.end) {
      $formData.end_date = newRange.end.toString();
    } else {
      $formData.end_date = "";
    }
    validationError = null;
  }

  function handleStartValueChange(v: DateValue | undefined) {
    startValue = v;
  }

  function hasFilters(): boolean {
    return (
      ($formData.start_date && $formData.start_date !== "") ||
      ($formData.end_date && $formData.end_date !== "") ||
      $formData.media_type !== "movie"
    );
  }

  function handleClear() {
    $formData.start_date = "";
    $formData.end_date = "";
    $formData.media_type = "movie";
    dateRange = undefined;
    startValue = undefined;
    validationError = null;
  }
</script>

<Card>
  <CardHeader>
    <CardTitle>Filters</CardTitle>
  </CardHeader>
  <CardContent>
    <form method="POST" class="space-y-4" use:enhance>
      {#if validationError}
        <Alert.Root variant="destructive">
          <CircleAlertIcon class="size-4" />
          <Alert.Title>Validation Error</Alert.Title>
          <Alert.Description>{validationError}</Alert.Description>
        </Alert.Root>
      {/if}

      <div class="flex flex-col gap-4 items-end lg:flex-row w-full max-w-lg">
        <div class="space-y-2 w-full md:min-w-[300px]">
          <Label for="date-range">Date Range</Label>
          <Popover.Root>
            <Popover.Trigger
              id="date-range"
              disabled={loading}
              class={cn(
                buttonVariants({ variant: "outline" }),
                "w-full justify-start text-start font-normal m-0",
                !dateRange && "text-muted-foreground",
              )}
            >
              <CalendarIcon class="me-2 size-4" />
              {#if dateRange && dateRange.start}
                {#if dateRange.end}
                  {df.format(dateRange.start.toDate(getLocalTimeZone()))} - {df.format(
                    dateRange.end.toDate(getLocalTimeZone()),
                  )}
                {:else}
                  {df.format(dateRange.start.toDate(getLocalTimeZone()))}
                {/if}
              {:else if startValue}
                {df.format(startValue.toDate(getLocalTimeZone()))}
              {:else}
                Pick a date range
              {/if}
            </Popover.Trigger>
            <Popover.Content class="w-auto p-0" align="start">
              <RangeCalendar
                bind:value={dateRange}
                onValueChange={handleDateRangeChange}
                onStartValueChange={handleStartValueChange}
                numberOfMonths={2}
              />
            </Popover.Content>
          </Popover.Root>
          <input type="hidden" name="start_date" value={$formData.start_date} />
          <input
            type="hidden"
            name="end_date"
            value={$formData.end_date || ""}
          />
        </div>

        <div class="space-y-2 w-full md:min-w-[200px]">
          <Label for="media-type">Media Type</Label>
          <Select.Root
            type="single"
            bind:value={$formData.media_type}
            disabled={loading}
          >
            <Select.Trigger id="media-type" class="w-full m-0">
              {$formData.media_type === "movie" ? "Movie" : "TV"}
            </Select.Trigger>
            <Select.Content>
              <Select.Item value="movie" label="Movie">Movie</Select.Item>
              <Select.Item value="tv" label="TV">TV</Select.Item>
            </Select.Content>
          </Select.Root>
          <input type="hidden" name="media_type" value={$formData.media_type} />
        </div>

        <Button
          type="button"
          variant="outline"
          disabled={loading || !hasFilters()}
          onclick={handleClear}
          class="w-full max-w-[80px] cursor-pointer"
        >
          <XIcon class="size-4" />
          Clear
        </Button>

        <Button
          type="submit"
          disabled={loading}
          class="w-full max-w-[100px] cursor-pointer"
        >
          {#if loading}
            <LoaderIcon class="animate-spin" />
          {/if}
          Search
        </Button>
      </div>
    </form>
  </CardContent>
</Card>
