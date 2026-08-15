import { useEffect, useRef, useState } from "react";

import { Button, EmptyState, TextField } from "@/design-system";
import { loadNaverMapSdk } from "@/map/naver-map-sdk";
import type { PlaceSearchResult } from "@/map/map-proxy-service";

import "./naver-location-picker.css";

export interface MapSelection {
  address?: string;
  latitude: number;
  longitude: number;
  name?: string;
  radiusMeters: 250 | 500 | 1000;
}

interface NaverLocationPickerProps {
  clientId: string;
  onChange: (selection: MapSelection) => void;
  searchPlaces: (
    query: string,
    signal?: AbortSignal,
  ) => Promise<PlaceSearchResult[]>;
  value: MapSelection;
  loadSdk?: (clientId: string) => Promise<void>;
}

const radiusOptions = [250, 500, 1000] as const;

export function NaverLocationPicker({
  clientId,
  loadSdk = loadNaverMapSdk,
  onChange,
  searchPlaces,
  value,
}: NaverLocationPickerProps) {
  const elementRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<NaverMap | undefined>(undefined);
  const markerRef = useRef<NaverMarker | undefined>(undefined);
  const circleRef = useRef<NaverCircle | undefined>(undefined);
  const valueRef = useRef(value);
  const browserPreview = clientId === "browser";
  const [mapFailed, setMapFailed] = useState(false);
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<PlaceSearchResult[]>([]);
  const [searching, setSearching] = useState(false);

  useEffect(() => {
    valueRef.current = value;
  }, [value]);

  useEffect(() => {
    let cancelled = false;
    let mapClickListener: object | undefined;
    let dragListener: object | undefined;

    if (browserPreview) {
      return () => {
        cancelled = true;
      };
    }

    void loadSdk(clientId)
      .then(() => {
        const maps = window.naver?.maps;
        const element = elementRef.current;
        if (cancelled || element === null) return;
        if (maps == null) {
          setMapFailed(true);
          return;
        }
        const currentValue = valueRef.current;
        const center = new maps.LatLng(
          currentValue.latitude,
          currentValue.longitude,
        );
        const primaryColor =
          getComputedStyle(document.documentElement)
            .getPropertyValue("--color-primary")
            .trim() || "blue";
        const map = new maps.Map(element, { center, zoom: 14 });
        const marker = new maps.Marker({
          map,
          position: center,
          draggable: true,
        });
        const circle = new maps.Circle({
          map,
          center,
          radius: currentValue.radiusMeters,
          strokeColor: primaryColor,
          strokeOpacity: 1,
          strokeWeight: 5,
          fillColor: primaryColor,
          fillOpacity: 0,
        });
        markerRef.current = marker;
        circleRef.current = circle;
        mapRef.current = map;

        const select = (coord: NaverCoordinate) => {
          const next = {
            ...valueRef.current,
            latitude: coord.lat(),
            longitude: coord.lng(),
          };
          marker.setPosition(coord);
          circle.setCenter(coord);
          onChange(next);
        };
        mapClickListener = maps.Event.addListener(map, "click", (event) =>
          select(event.coord),
        );
        dragListener = maps.Event.addListener(marker, "dragend", (event) =>
          select(event.coord),
        );
      })
      .catch(() => {
        if (!cancelled) setMapFailed(true);
      });

    return () => {
      cancelled = true;
      const maps = window.naver?.maps;
      mapRef.current = undefined;
      if (maps != null && mapClickListener !== undefined) {
        maps.Event.removeListener(mapClickListener);
      }
      if (maps != null && dragListener !== undefined) {
        maps.Event.removeListener(dragListener);
      }
    };
  }, [browserPreview, clientId, loadSdk, onChange]);

  useEffect(() => {
    const maps = window.naver?.maps;
    if (maps == null) return;
    const center = new maps.LatLng(value.latitude, value.longitude);
    markerRef.current?.setPosition(center);
    circleRef.current?.setCenter(center);
    circleRef.current?.setRadius(value.radiusMeters);
  }, [value]);

  async function submitSearch() {
    const trimmed = query.trim();
    if (trimmed.length === 0) return;
    setSearching(true);
    try {
      setResults(await searchPlaces(trimmed));
    } finally {
      setSearching(false);
    }
  }

  function selectPlace(place: PlaceSearchResult) {
    const maps = window.naver?.maps;
    const center = maps?.LatLng
      ? new maps.LatLng(place.latitude, place.longitude)
      : undefined;
    if (center !== undefined) {
      mapRef.current?.setCenter(center);
      markerRef.current?.setPosition(center);
      circleRef.current?.setCenter(center);
    }
    setResults([]);
    onChange({
      ...value,
      address: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
      name: value.name?.trim() || place.title,
    });
  }

  return (
    <section className="location-picker" aria-label="장소와 반경 선택">
      <form
        className="location-picker__search"
        onSubmit={(event) => {
          event.preventDefault();
          void submitSearch();
        }}
      >
        <TextField
          label="장소 검색"
          placeholder="주소 또는 장소명을 입력하세요"
          value={query}
          onChange={(event) => setQuery(event.target.value)}
        />
        <Button type="submit" loading={searching}>
          검색
        </Button>
      </form>

      {results.length === 0 ? null : (
        <div className="location-picker__results-panel">
          <div className="location-picker__results-heading">
            <strong>검색 결과</strong>
            <span>{results.length}개</span>
          </div>
          <ul className="location-picker__results">
            {results.map((place) => (
              <li key={`${place.latitude}:${place.longitude}`}>
                <button type="button" onClick={() => selectPlace(place)}>
                  <strong>{place.title}</strong>
                  <span>{place.address}</span>
                </button>
              </li>
            ))}
          </ul>
        </div>
      )}

      {browserPreview || mapFailed ? (
        <EmptyState
          title="지도를 불러오지 못했어요"
          description="주소 검색으로 장소를 선택할 수 있어요."
        />
      ) : (
        <div
          ref={elementRef}
          className="location-picker__map"
          data-clarity-mask="true"
          aria-label="네이버 지도"
        />
      )}

      <fieldset className="location-picker__radius">
        <legend>알림 반경</legend>
        {radiusOptions.map((radius) => (
          <Button
            key={radius}
            variant={value.radiusMeters === radius ? "primary" : "secondary"}
            aria-pressed={value.radiusMeters === radius}
            onClick={() => onChange({ ...value, radiusMeters: radius })}
          >
            {radius === 1000 ? "1km" : `${radius}m`}
          </Button>
        ))}
      </fieldset>
    </section>
  );
}
