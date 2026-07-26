import {
  forwardRef,
  useEffect,
  useImperativeHandle,
  useRef,
  useState,
} from "react";
import {
  AmbientLight,
  BoxGeometry,
  BufferGeometry,
  CircleGeometry,
  Color,
  CurvePath,
  CylinderGeometry,
  DirectionalLight,
  DoubleSide,
  Group,
  Line,
  LineCurve3,
  LineDashedMaterial,
  Mesh,
  MeshBasicMaterial,
  MeshStandardMaterial,
  PerspectiveCamera,
  PlaneGeometry,
  Scene,
  SphereGeometry,
  Vector3,
  WebGLRenderer,
} from "three";
import { OrbitControls } from "three/examples/jsm/controls/OrbitControls.js";
import {
  CSS2DObject,
  CSS2DRenderer,
} from "three/examples/jsm/renderers/CSS2DRenderer.js";

import type { DestinationId } from "@/landing/landing-flow";

export type JourneyMapHandle = {
  zoomIn: () => void;
  zoomOut: () => void;
  resetView: () => void;
  resetRoute: () => void;
};

type JourneyMapProps = {
  destination: DestinationId;
  radius: number;
  friendAccepted: boolean;
  running: boolean;
  speed: number;
  onProgress: (progress: number) => void;
  onDeparture: () => void;
  onArrival: () => void;
};

type MapController = JourneyMapHandle & {
  setDestination: (destination: DestinationId) => void;
  setRadius: (radius: number) => void;
  setFriendAccepted: (accepted: boolean) => void;
};

type PlaceDefinition = {
  label: string;
  position: [number, number, number];
  colorToken: string;
};

const places: Record<"start" | DestinationId, PlaceDefinition> = {
  start: {
    label: "광화문 출발 지점",
    position: [-15, 0, 2.5],
    colorToken: "--color-landing-amber",
  },
  cityhall: {
    label: "서울 시청",
    position: [5, 0, -6],
    colorToken: "--color-primary",
  },
  station: {
    label: "서울역",
    position: [-5, 0, -14],
    colorToken: "--color-success",
  },
  terminal: {
    label: "고속 버스 터미널",
    position: [5, 0, 12],
    colorToken: "--color-error",
  },
};

const routeCoordinates: Record<DestinationId, Array<[number, number]>> = {
  cityhall: [
    [-15, 2.5],
    [5, 2.5],
    [5, -6],
  ],
  station: [
    [-15, 2.5],
    [-5, 2.5],
    [-5, -14],
  ],
  terminal: [
    [-15, 2.5],
    [5, 2.5],
    [5, 12],
  ],
};

function readColorToken(name: string) {
  return getComputedStyle(document.documentElement)
    .getPropertyValue(name)
    .trim();
}

function tokenColor(name: string) {
  return new Color(readColorToken(name));
}

function createBuilding(
  width: number,
  height: number,
  depth: number,
  x: number,
  z: number,
  accent = false,
) {
  const building = new Mesh(
    new BoxGeometry(width, height, depth),
    new MeshStandardMaterial({
      color: tokenColor(
        accent ? "--color-landing-building-accent" : "--color-landing-building",
      ),
      roughness: 0.84,
    }),
  );
  building.position.set(x, height / 2, z);
  return building;
}

function addRoad(
  scene: Scene,
  x: number,
  z: number,
  length: number,
  width: number,
  rotation: number,
) {
  const road = new Mesh(
    new PlaneGeometry(length, width),
    new MeshStandardMaterial({
      color: tokenColor("--color-landing-road"),
      roughness: 0.94,
    }),
  );
  road.rotation.x = -Math.PI / 2;
  road.rotation.z = rotation;
  road.position.set(x, 0.03, z);
  scene.add(road);

  const dashCount = Math.floor(length / 3);
  for (let index = 0; index < dashCount; index += 1) {
    const dash = new Mesh(
      new BoxGeometry(1.2, 0.025, 0.08),
      new MeshBasicMaterial({ color: tokenColor("--color-landing-grid") }),
    );
    dash.position.set(-length / 2 + 1.5 + index * 3, 0.06, 0);
    road.add(dash);
  }
}

function addCity(scene: Scene) {
  const ground = new Mesh(
    new PlaneGeometry(56, 44),
    new MeshStandardMaterial({
      color: tokenColor("--color-landing-map"),
      roughness: 1,
    }),
  );
  ground.rotation.x = -Math.PI / 2;
  scene.add(ground);

  addRoad(scene, 0, 2.5, 48, 3.5, 0);
  addRoad(scene, -5, -3, 32, 3.2, Math.PI / 2);
  addRoad(scene, 5, 5, 29, 3.2, Math.PI / 2);

  const park = new Mesh(
    new PlaneGeometry(10, 7),
    new MeshStandardMaterial({
      color: tokenColor("--color-landing-park"),
      roughness: 1,
    }),
  );
  park.rotation.x = -Math.PI / 2;
  park.position.set(0, 0.045, 10);
  scene.add(park);

  const river = new Mesh(
    new PlaneGeometry(58, 5),
    new MeshStandardMaterial({
      color: tokenColor("--color-landing-water"),
      roughness: 0.55,
    }),
  );
  river.rotation.x = -Math.PI / 2;
  river.position.set(0, 0.02, -19);
  scene.add(river);

  const buildingData = [
    [-19, -8, 4, 6, 4, false],
    [-14, -7, 3.5, 8, 3.5, true],
    [-10, 9, 4, 5, 4, false],
    [-2, -7, 4.5, 9, 4, true],
    [4, -7, 4, 6, 4, false],
    [12, -10, 5, 10, 4.5, true],
    [17, -3, 4, 7, 4, false],
    [13, 7, 4.5, 5, 4, true],
    [18, 12, 4, 8, 4, false],
    [-17, 13, 5, 7, 4.5, true],
  ] as const;
  for (const [x, z, width, height, depth, accent] of buildingData) {
    scene.add(createBuilding(width, height, depth, x, z, accent));
  }

  const hill = new Mesh(
    new CylinderGeometry(3.2, 4.5, 1.2, 32),
    new MeshStandardMaterial({
      color: tokenColor("--color-landing-hill"),
      roughness: 1,
    }),
  );
  hill.position.set(20, 0.55, 18);
  scene.add(hill);

  const tower = new Group();
  const towerMaterial = new MeshStandardMaterial({
    color: tokenColor("--color-surface"),
    roughness: 0.65,
  });
  const towerBody = new Mesh(
    new CylinderGeometry(0.3, 0.55, 5.5, 14),
    towerMaterial,
  );
  towerBody.position.y = 3.4;
  const observatory = new Mesh(
    new CylinderGeometry(0.9, 0.7, 0.8, 18),
    new MeshStandardMaterial({
      color: tokenColor("--color-landing-building-accent"),
      roughness: 0.45,
    }),
  );
  observatory.position.y = 5.9;
  tower.add(towerBody, observatory);
  tower.position.set(20, 0.7, 18);
  scene.add(tower);
}

function createPlaceMarker(
  id: "start" | DestinationId,
  definition: PlaceDefinition,
) {
  const marker = new Group();
  marker.position.set(...definition.position);
  const color = tokenColor(definition.colorToken);
  const base = new Mesh(
    new CylinderGeometry(0.8, 0.8, 0.12, 28),
    new MeshStandardMaterial({
      color: tokenColor("--color-surface"),
      roughness: 0.8,
    }),
  );
  base.position.y = 0.06;
  const pole = new Mesh(
    new CylinderGeometry(0.07, 0.07, 0.8, 12),
    new MeshStandardMaterial({ color }),
  );
  pole.position.y = 0.5;
  const pin = new Mesh(
    new SphereGeometry(0.28, 18, 18),
    new MeshStandardMaterial({ color, roughness: 0.5 }),
  );
  pin.position.y = 0.98;
  marker.add(base, pole, pin);

  const labelElement = document.createElement("div");
  labelElement.className = "map-place-label";
  labelElement.dataset.place = id;
  labelElement.textContent = definition.label;
  const label = new CSS2DObject(labelElement);
  label.position.set(0, 1.65, 0);
  marker.add(label);
  return { marker, labelElement };
}

function createCar() {
  const car = new Group();
  const bodyMaterial = new MeshStandardMaterial({
    color: tokenColor("--color-primary"),
    roughness: 0.48,
  });
  const body = new Mesh(new BoxGeometry(1.25, 0.45, 2.1), bodyMaterial);
  body.position.y = 0.5;
  const cabin = new Mesh(
    new BoxGeometry(1.05, 0.55, 1),
    new MeshStandardMaterial({
      color: tokenColor("--color-landing-building-accent"),
      roughness: 0.35,
    }),
  );
  cabin.position.set(0, 0.93, -0.08);
  car.add(body, cabin);

  const wheelMaterial = new MeshStandardMaterial({
    color: tokenColor("--color-landing-rubber"),
    roughness: 0.9,
  });
  const wheels: Mesh[] = [];
  for (const x of [-0.7, 0.7]) {
    for (const z of [-0.65, 0.65]) {
      const wheel = new Mesh(
        new CylinderGeometry(0.24, 0.24, 0.18, 16),
        wheelMaterial,
      );
      wheel.rotation.z = Math.PI / 2;
      wheel.position.set(x, 0.3, z);
      wheels.push(wheel);
      car.add(wheel);
    }
  }
  car.userData.wheels = wheels;

  const driver = new Mesh(
    new SphereGeometry(0.2, 16, 16),
    new MeshStandardMaterial({
      color: tokenColor("--color-landing-person"),
      roughness: 0.7,
    }),
  );
  driver.position.set(0, 1.34, 0.1);
  car.add(driver);

  const nameElement = document.createElement("div");
  nameElement.className = "map-runner-label";
  nameElement.textContent = "철수";
  const nameLabel = new CSS2DObject(nameElement);
  nameLabel.position.set(0, 2, 0);
  car.add(nameLabel);
  return car;
}

function createRoute(destination: DestinationId) {
  const points = routeCoordinates[destination].map(
    ([x, z]) => new Vector3(x, 0.14, z),
  );
  const route = new CurvePath<Vector3>();
  for (let index = 1; index < points.length; index += 1) {
    route.add(new LineCurve3(points[index - 1], points[index]));
  }
  return route;
}

export const JourneyMap = forwardRef<JourneyMapHandle, JourneyMapProps>(
  function JourneyMap(
    {
      destination,
      radius,
      friendAccepted,
      running,
      speed,
      onProgress,
      onDeparture,
      onArrival,
    },
    forwardedRef,
  ) {
    const hostRef = useRef<HTMLDivElement>(null);
    const controllerRef = useRef<MapController | null>(null);
    const propsRef = useRef({
      running,
      speed,
      onProgress,
      onDeparture,
      onArrival,
    });
    const initialSettingsRef = useRef({
      destination,
      radius,
      friendAccepted,
    });
    const [webGlFailed, setWebGlFailed] = useState(false);

    useEffect(() => {
      propsRef.current = {
        running,
        speed,
        onProgress,
        onDeparture,
        onArrival,
      };
    }, [onArrival, onDeparture, onProgress, running, speed]);

    useImperativeHandle(
      forwardedRef,
      () => ({
        zoomIn: () => controllerRef.current?.zoomIn(),
        zoomOut: () => controllerRef.current?.zoomOut(),
        resetView: () => controllerRef.current?.resetView(),
        resetRoute: () => controllerRef.current?.resetRoute(),
      }),
      [],
    );

    useEffect(() => {
      controllerRef.current?.setDestination(destination);
    }, [destination]);

    useEffect(() => {
      controllerRef.current?.setRadius(radius);
    }, [radius]);

    useEffect(() => {
      controllerRef.current?.setFriendAccepted(friendAccepted);
    }, [friendAccepted]);

    useEffect(() => {
      const host = hostRef.current;
      if (host === null) return;

      let renderer: WebGLRenderer;
      try {
        renderer = new WebGLRenderer({
          antialias: true,
          powerPreference: "high-performance",
        });
      } catch {
        const fallbackTimer = window.setTimeout(() => setWebGlFailed(true), 0);
        return () => window.clearTimeout(fallbackTimer);
      }

      renderer.setPixelRatio(Math.min(window.devicePixelRatio, 1.5));
      renderer.outputColorSpace = "srgb";
      renderer.domElement.setAttribute("aria-hidden", "true");
      host.append(renderer.domElement);

      const labelRenderer = new CSS2DRenderer();
      labelRenderer.domElement.className = "map-label-layer";
      host.append(labelRenderer.domElement);

      const scene = new Scene();
      scene.background = tokenColor("--color-landing-sky");
      addCity(scene);
      scene.add(new AmbientLight(tokenColor("--color-surface"), 2.1));
      const sun = new DirectionalLight(tokenColor("--color-surface"), 3.1);
      sun.position.set(-12, 28, 18);
      scene.add(sun);

      const camera = new PerspectiveCamera(38, 1, 0.1, 140);
      const resetCamera = () => {
        camera.position.set(25, 30, 34);
        controls.target.set(0, 0, 0);
        controls.update();
      };
      const controls = new OrbitControls(camera, renderer.domElement);
      controls.enableDamping = true;
      controls.dampingFactor = 0.07;
      controls.minDistance = 22;
      controls.maxDistance = 65;
      controls.maxPolarAngle = Math.PI * 0.47;
      resetCamera();

      const labelElements: Partial<
        Record<"start" | DestinationId, HTMLDivElement>
      > = {};
      for (const [id, definition] of Object.entries(places) as Array<
        ["start" | DestinationId, PlaceDefinition]
      >) {
        const { marker, labelElement } = createPlaceMarker(id, definition);
        scene.add(marker);
        labelElements[id] = labelElement;
      }

      const car = createCar();
      scene.add(car);

      const accuracyRing = new Mesh(
        new CircleGeometry(1.25, 40),
        new MeshBasicMaterial({
          color: tokenColor("--color-primary"),
          transparent: true,
          opacity: 0.15,
          side: DoubleSide,
          depthWrite: false,
        }),
      );
      accuracyRing.rotation.x = -Math.PI / 2;
      scene.add(accuracyRing);

      const destinationRing = new Mesh(
        new CircleGeometry(1.7, 48),
        new MeshBasicMaterial({
          color: tokenColor("--color-primary"),
          transparent: true,
          opacity: 0.38,
          side: DoubleSide,
          depthWrite: false,
        }),
      );
      destinationRing.rotation.x = -Math.PI / 2;
      scene.add(destinationRing);

      let activeDestination = initialSettingsRef.current.destination;
      let route = createRoute(activeDestination);
      let routeLine: Line | null = null;
      let progress = 0;
      let departureSent = false;
      let arrivalSent = false;
      let lastReportedPercent = -1;

      const renderRoute = () => {
        if (routeLine !== null) {
          scene.remove(routeLine);
          routeLine.geometry.dispose();
          if (Array.isArray(routeLine.material)) {
            routeLine.material.forEach((material) => material.dispose());
          } else {
            routeLine.material.dispose();
          }
        }
        const geometry = new BufferGeometry().setFromPoints(
          route.getPoints(90),
        );
        const material = new LineDashedMaterial({
          color: tokenColor("--color-landing-route"),
          dashSize: 0.55,
          gapSize: 0.3,
          transparent: true,
          opacity: 0.9,
        });
        routeLine = new Line(geometry, material);
        routeLine.computeLineDistances();
        routeLine.visible = initialSettingsRef.current.friendAccepted;
        scene.add(routeLine);
      };

      const placeCar = () => {
        const point = route.getPointAt(progress);
        const next = route.getPointAt(Math.min(1, progress + 0.01));
        car.position.copy(point);
        car.lookAt(next.x, point.y, next.z);
        accuracyRing.position.set(point.x, 0.07, point.z);
      };

      const updateDestination = () => {
        const destinationPlace = places[activeDestination];
        destinationRing.position.set(
          destinationPlace.position[0],
          0.06,
          destinationPlace.position[2],
        );
        Object.entries(labelElements).forEach(([id, element]) => {
          element?.classList.toggle("is-selected", id === activeDestination);
        });
      };

      const resetRoute = () => {
        progress = 0;
        departureSent = false;
        arrivalSent = false;
        lastReportedPercent = -1;
        car.visible = true;
        accuracyRing.visible = true;
        placeCar();
        resetCamera();
        propsRef.current.onProgress(0);
      };

      renderRoute();
      updateDestination();
      destinationRing.scale.setScalar(
        Math.max(0.85, initialSettingsRef.current.radius / 150),
      );
      placeCar();

      controllerRef.current = {
        zoomIn: () => {
          camera.position.multiplyScalar(0.88);
          controls.update();
        },
        zoomOut: () => {
          camera.position.multiplyScalar(1.12);
          controls.update();
        },
        resetView: resetCamera,
        resetRoute,
        setDestination: (nextDestination) => {
          activeDestination = nextDestination;
          route = createRoute(activeDestination);
          resetRoute();
          renderRoute();
          updateDestination();
        },
        setRadius: (nextRadius) => {
          destinationRing.scale.setScalar(Math.max(0.85, nextRadius / 150));
        },
        setFriendAccepted: (accepted) => {
          if (routeLine !== null) routeLine.visible = accepted;
          destinationRing.visible = accepted;
        },
      };

      destinationRing.visible = initialSettingsRef.current.friendAccepted;

      const resize = () => {
        const width = host.clientWidth;
        const height = host.clientHeight;
        renderer.setSize(width, height, false);
        labelRenderer.setSize(width, height);
        camera.aspect = width / Math.max(height, 1);
        camera.updateProjectionMatrix();
      };
      const resizeObserver = new ResizeObserver(resize);
      resizeObserver.observe(host);
      resize();

      let previousTime = performance.now();
      let animationFrame = 0;
      const point = new Vector3();
      const next = new Vector3();
      const desiredFollowTarget = new Vector3();
      const desiredCameraPosition = new Vector3();
      const travelDirection = new Vector3();
      const animate = (now: number) => {
        const delta = Math.min(Math.max((now - previousTime) / 1000, 0), 0.05);
        previousTime = now;

        if (propsRef.current.running && progress < 1) {
          progress = Math.min(
            1,
            progress + delta * 0.052 * propsRef.current.speed,
          );
          route.getPointAt(progress, point);
          route.getPointAt(Math.min(1, progress + 0.006), next);
          car.position.copy(point);
          car.lookAt(next.x, point.y, next.z);
          accuracyRing.position.set(point.x, 0.07, point.z);
          travelDirection.copy(next).sub(point).normalize();
          desiredFollowTarget
            .set(point.x, 0.8, point.z)
            .addScaledVector(travelDirection, 2.2);
          desiredCameraPosition
            .set(point.x, 5.2, point.z)
            .addScaledVector(travelDirection, -7.2);
          const followAmount = 1 - Math.exp(-delta * 3.8);
          controls.target.lerp(desiredFollowTarget, followAmount);
          camera.position.lerp(desiredCameraPosition, followAmount);
          camera.lookAt(controls.target);
          accuracyRing.rotation.z += delta * 0.45;
          for (const wheel of car.userData.wheels as Mesh[]) {
            wheel.rotation.x -= delta * 8 * propsRef.current.speed;
          }

          const percent = Math.round(progress * 100);
          if (percent - lastReportedPercent >= 2 || percent === 100) {
            lastReportedPercent = percent;
            propsRef.current.onProgress(progress);
          }
          if (progress >= 0.08 && !departureSent) {
            departureSent = true;
            propsRef.current.onDeparture();
          }
          if (progress >= 1 && !arrivalSent) {
            arrivalSent = true;
            car.visible = false;
            accuracyRing.visible = false;
            propsRef.current.onArrival();
          }
        }

        const ringMaterial = destinationRing.material;
        if (ringMaterial instanceof MeshBasicMaterial) {
          ringMaterial.opacity = 0.38 + Math.sin(now * 0.003) * 0.12;
        }
        controls.enabled = !propsRef.current.running;
        if (controls.enabled) controls.update();
        renderer.render(scene, camera);
        labelRenderer.render(scene, camera);
        animationFrame = requestAnimationFrame(animate);
      };
      animationFrame = requestAnimationFrame(animate);

      return () => {
        cancelAnimationFrame(animationFrame);
        resizeObserver.disconnect();
        controls.dispose();
        controllerRef.current = null;
        scene.traverse((object) => {
          if (object instanceof Mesh || object instanceof Line) {
            object.geometry.dispose();
            if (Array.isArray(object.material)) {
              object.material.forEach((material) => material.dispose());
            } else {
              object.material.dispose();
            }
          }
        });
        renderer.dispose();
        renderer.domElement.remove();
        labelRenderer.domElement.remove();
      };
    }, []);

    if (webGlFailed) {
      return (
        <div className="map-fallback" role="status">
          <strong>3D 지도를 불러오지 못했어요</strong>
          <span>WebGL을 지원하는 최신 브라우저에서 다시 열어 주세요.</span>
        </div>
      );
    }

    return <div ref={hostRef} className="journey-map" />;
  },
);
