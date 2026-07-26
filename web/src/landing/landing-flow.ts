export type DemoStep = "friend" | "place" | "run";
export type DestinationId = "cityhall" | "station" | "terminal";

export type Destination = {
  id: DestinationId;
  label: string;
  shortLabel: string;
};

export type LandingFlowState = {
  step: DemoStep;
  friendAccepted: boolean;
  placeConfigured: boolean;
  destination: DestinationId;
  radius: number;
  running: boolean;
  speed: number;
  progress: number;
  completed: boolean;
};

export type LandingFlowAction =
  | { type: "accept-friend" }
  | { type: "select-destination"; destination: DestinationId }
  | { type: "set-radius"; radius: number }
  | { type: "save-place" }
  | { type: "toggle-run" }
  | { type: "set-speed"; speed: number }
  | { type: "set-progress"; progress: number }
  | { type: "reset-route" }
  | { type: "arrive" };

export const destinations: Destination[] = [
  { id: "cityhall", label: "서울 시청", shortLabel: "시청" },
  { id: "station", label: "서울역", shortLabel: "서울역" },
  {
    id: "terminal",
    label: "고속 버스 터미널",
    shortLabel: "터미널",
  },
];

export const initialLandingFlowState: LandingFlowState = {
  step: "friend",
  friendAccepted: false,
  placeConfigured: false,
  destination: "cityhall",
  radius: 150,
  running: false,
  speed: 1,
  progress: 0,
  completed: false,
};

export function landingFlowReducer(
  state: LandingFlowState,
  action: LandingFlowAction,
): LandingFlowState {
  switch (action.type) {
    case "accept-friend":
      return state.step === "friend"
        ? { ...state, step: "place", friendAccepted: true }
        : state;
    case "select-destination":
      return state.step === "place" && !state.placeConfigured
        ? { ...state, destination: action.destination, progress: 0 }
        : state;
    case "set-radius":
      return state.step === "place" && !state.placeConfigured
        ? { ...state, radius: Math.min(300, Math.max(100, action.radius)) }
        : state;
    case "save-place":
      return state.step === "place"
        ? { ...state, step: "run", placeConfigured: true }
        : state;
    case "toggle-run":
      return state.placeConfigured
        ? {
            ...state,
            running: state.progress >= 1 ? true : !state.running,
            progress: state.progress >= 1 ? 0 : state.progress,
            completed: state.progress >= 1 ? false : state.completed,
          }
        : state;
    case "set-speed":
      return { ...state, speed: action.speed };
    case "set-progress":
      return {
        ...state,
        progress: Math.min(1, Math.max(0, action.progress)),
      };
    case "reset-route":
      return {
        ...state,
        running: false,
        progress: 0,
        completed: false,
      };
    case "arrive":
      return {
        ...state,
        running: false,
        progress: 1,
        completed: true,
      };
  }
}

export function destinationById(id: DestinationId) {
  return destinations.find((destination) => destination.id === id)!;
}
