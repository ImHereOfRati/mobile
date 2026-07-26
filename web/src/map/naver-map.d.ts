interface NaverCoordinate {
  lat(): number;
  lng(): number;
}

interface NaverMap {
  setCenter(position: NaverCoordinate): void;
}

interface NaverMarker {
  setPosition(position: NaverCoordinate): void;
}

interface NaverCircle {
  setCenter(position: NaverCoordinate): void;
  setRadius(radius: number): void;
}

interface NaverMapsApi {
  Circle: new (options: Record<string, unknown>) => NaverCircle;
  Event: {
    addListener(
      target: object,
      event: string,
      listener: (event: { coord: NaverCoordinate }) => void,
    ): object;
    removeListener(listener: object): void;
  };
  LatLng: new (latitude: number, longitude: number) => NaverCoordinate;
  Map: new (element: HTMLElement, options: Record<string, unknown>) => NaverMap;
  Marker: new (options: Record<string, unknown>) => NaverMarker;
}

interface Window {
  naver?: { maps: NaverMapsApi };
}
