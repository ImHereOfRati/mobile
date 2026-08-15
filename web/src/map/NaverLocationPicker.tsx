import { useEffect, useRef, useState } from "react";

import { Button, EmptyState, TextField } from "@/design-system";
import { loadNaverMapSdk } from "@/map/naver-map-sdk";
import {
  reverseGeocodeAddress,
  reverseGeocodePlaceName,
  type PlaceSearchResult,
  type ReverseGeocodeResponse,
} from "@/map/map-proxy-service";

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
  resolveInitialLocation?: boolean;
  reverseGeocode: (
    latitude: number,
    longitude: number,
    signal?: AbortSignal,
  ) => Promise<ReverseGeocodeResponse>;
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
  resolveInitialLocation = true,
  reverseGeocode,
  searchPlaces,
  value,
}: NaverLocationPickerProps) {
  const elementRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<NaverMap | undefined>(undefined);
  const markerRef = useRef<NaverMarker | undefined>(undefined);
  const circleRef = useRef<NaverCircle | undefined>(undefined);
  const valueRef = useRef(value);
  // 이미 역지오코딩한 좌표. 같은 좌표면 다시 요청하지 않으므로 StrictMode의
  // 이중 effect 실행에도 안전하다. 수정 모드(resolveInitialLocation=false)는
  // 초기 좌표를 미리 기록해 최초 요청 자체를 막는다.
  const lastGeocodedRef = useRef<{ lat: number; lng: number } | null>(
    resolveInitialLocation
      ? null
      : { lat: value.latitude, lng: value.longitude },
  );
  const browserPreview = clientId === "browser";
  const [mapFailed, setMapFailed] = useState(false);
  const [query, setQuery] = useState("");
  const [results, setResults] = useState<PlaceSearchResult[]>([]);
  const [searching, setSearching] = useState(false);
  const [searchError, setSearchError] = useState(false);

  useEffect(() => {
    valueRef.current = value;
  }, [value]);

  useEffect(() => {
    const last = lastGeocodedRef.current;
    if (
      last !== null &&
      last.lat === value.latitude &&
      last.lng === value.longitude
    ) {
      return;
    }
    lastGeocodedRef.current = { lat: value.latitude, lng: value.longitude };

    let settled = false;
    const controller = new AbortController();
    void reverseGeocode(value.latitude, value.longitude, controller.signal)
      .then((response) => {
        settled = true;
        if (controller.signal.aborted) return;
        const current = valueRef.current;
        onChange({
          ...current,
          address:
            reverseGeocodeAddress(response, value.latitude, value.longitude) ||
            current.address,
          // 빈 문자열이면 폼이 기존 장소 이름을 유지한다.
          name: reverseGeocodePlaceName(response),
        });
      })
      .catch(() => {
        settled = true;
        // 실패 시 사용자가 입력한 값을 덮어쓰지 않는다.
      });
    return () => {
      // 응답 전에 정리되면(StrictMode 이중 마운트 등) 좌표 기록을 되돌려
      // 다음 실행이 같은 좌표를 다시 조회할 수 있게 한다.
      if (!settled) lastGeocodedRef.current = last;
      controller.abort();
    };
  }, [onChange, reverseGeocode, value.latitude, value.longitude]);

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
  }, [value.latitude, value.longitude, value.radiusMeters]);

  async function submitSearch() {
    const trimmed = query.trim();
    if (trimmed.length === 0) return;
    setSearching(true);
    setSearchError(false);
    try {
      setResults(await searchPlaces(trimmed));
    } catch {
      setResults([]);
      setSearchError(true);
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
    // 검색 결과는 주소와 장소명을 이미 갖고 있다. 좌표를 처리 완료로 기록해
    // 뒤따르는 역지오코딩이 검색 결과 이름을 덮어쓰지 않게 한다.
    lastGeocodedRef.current = { lat: place.latitude, lng: place.longitude };
    onChange({
      ...value,
      address: place.address,
      latitude: place.latitude,
      longitude: place.longitude,
      name: place.title,
    });
  }

  return (
    <section className="location-picker" aria-label="장소와 반경 선택">
      <div
        className="location-picker__search"
        role="search"
        onKeyDown={(event) => {
          if (event.key !== "Enter") return;
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
        <Button
          type="button"
          loading={searching}
          onClick={() => void submitSearch()}
        >
          검색
        </Button>
      </div>

      {searchError ? (
        <p className="feature-page__error" role="alert">
          검색 결과를 불러오지 못했어요. 다시 시도해 주세요.
        </p>
      ) : null}

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
