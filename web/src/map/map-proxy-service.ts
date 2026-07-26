import type { ApiClient, SliceResponse } from "@/api/api-client";

export interface PlaceSearchResult {
  address: string;
  latitude: number;
  longitude: number;
  title: string;
}

interface LocalSearchItem {
  address?: string;
  roadAddress?: string;
  title: string;
}

interface GeocodeAddress {
  roadAddress?: string;
  jibunAddress?: string;
  x: string;
  y: string;
}

export class MapProxyService {
  constructor(private readonly api: ApiClient) {}

  async searchPlaces(query: string, signal?: AbortSignal) {
    const search = await this.api.request<{ items: LocalSearchItem[] }>(
      `/api/maps/local-search?query=${encodeURIComponent(query)}`,
      { signal },
    );
    const results = await Promise.all(
      search.items.map(async (item): Promise<PlaceSearchResult | null> => {
        const address = item.roadAddress || item.address;
        if (address === undefined) return null;
        const geocode = await this.api.request<{ addresses: GeocodeAddress[] }>(
          `/api/maps/geocode?query=${encodeURIComponent(address)}`,
          { signal },
        );
        const coordinate = geocode.addresses[0];
        if (coordinate === undefined) return null;
        return {
          title: stripHtml(item.title),
          address: coordinate.roadAddress || coordinate.jibunAddress || address,
          latitude: Number(coordinate.y),
          longitude: Number(coordinate.x),
        };
      }),
    );
    return results.filter(
      (value): value is PlaceSearchResult => value !== null,
    );
  }

  async reverseGeocode(
    latitude: number,
    longitude: number,
    signal?: AbortSignal,
  ) {
    return this.api.request<{ results: unknown[] }>(
      `/api/maps/reverse-geocode?latitude=${latitude}&longitude=${longitude}`,
      { signal },
    );
  }
}

function stripHtml(value: string) {
  const document = new DOMParser().parseFromString(value, "text/html");
  return document.body.textContent ?? value;
}

export type PlaceSearchPage = SliceResponse<PlaceSearchResult>;
