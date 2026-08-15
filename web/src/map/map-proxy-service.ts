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

export interface ReverseGeocodeResponse {
  results?: ReverseGeocodeResult[];
}

export interface ReverseGeocodeResult {
  land?: {
    name?: string;
    number1?: string;
    number2?: string;
  };
  name?: string;
  region?: {
    [key: string]: { name?: string } | undefined;
    area1?: { name?: string };
    area2?: { name?: string };
  };
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
        try {
          const geocode = await this.api.request<{
            addresses: GeocodeAddress[];
          }>(`/api/maps/geocode?query=${encodeURIComponent(address)}`, {
            signal,
          });
          const coordinate = geocode.addresses[0];
          if (coordinate === undefined) return null;
          return {
            title: stripHtml(item.title),
            address:
              coordinate.roadAddress || coordinate.jibunAddress || address,
            latitude: Number(coordinate.y),
            longitude: Number(coordinate.x),
          };
        } catch (error) {
          if (signal?.aborted === true) throw error;
          return null;
        }
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
    return this.api.request<ReverseGeocodeResponse>(
      `/api/maps/reverse-geocode?latitude=${latitude}&longitude=${longitude}`,
      { signal },
    );
  }
}

export function reverseGeocodeLabel(
  response: ReverseGeocodeResponse,
  latitude: number,
  longitude: number,
) {
  const region = response.results?.[0]?.region;
  const label = [region?.area1?.name, region?.area2?.name]
    .filter((part): part is string => part !== undefined && part.trim() !== "")
    .join(" ");
  return label || `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;
}

export function reverseGeocodePlaceName(response: ReverseGeocodeResponse) {
  return response.results?.[0]?.name?.trim() ?? "";
}

export function reverseGeocodeAddress(
  response: ReverseGeocodeResponse,
  latitude: number,
  longitude: number,
) {
  const result = response.results?.[0];
  if (result === undefined) return "";
  const region = Object.entries(result.region ?? {})
    .filter(([key]) => /^area[1-4]$/.test(key))
    .sort(([left], [right]) => left.localeCompare(right))
    .map(([, area]) => area?.name?.trim() ?? "")
    .filter((name) => name.length > 0);
  const land = result.land;
  const number = [land?.number1, land?.number2]
    .filter((part): part is string => part !== undefined && part.length > 0)
    .join("-");
  const address = [...region, land?.name?.trim() ?? "", number].filter(
    (part) => part.length > 0,
  );
  return address.join(" ") || `${latitude.toFixed(4)}, ${longitude.toFixed(4)}`;
}

function stripHtml(value: string) {
  const document = new DOMParser().parseFromString(value, "text/html");
  return document.body.textContent ?? value;
}

export type PlaceSearchPage = SliceResponse<PlaceSearchResult>;
