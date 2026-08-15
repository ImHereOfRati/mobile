import { describe, expect, it } from "vitest";

import {
  initialLandingFlowState,
  landingFlowReducer,
} from "@/landing/landing-flow";

describe("landingFlowReducer", () => {
  it("preserves the original friend, place, and journey setup order", () => {
    const accepted = landingFlowReducer(initialLandingFlowState, {
      type: "accept-friend",
    });
    const selected = landingFlowReducer(accepted, {
      type: "select-destination",
      destination: "station",
    });
    const recipientSelected = landingFlowReducer(selected, {
      type: "select-recipient",
    });
    const configured = landingFlowReducer(recipientSelected, {
      type: "save-place",
    });
    const running = landingFlowReducer(configured, { type: "toggle-run" });
    const arrived = landingFlowReducer(running, { type: "arrive" });

    expect(accepted.step).toBe("place");
    expect(configured).toMatchObject({
      step: "run",
      destination: "station",
      placeConfigured: true,
    });
    expect(running.running).toBe(true);
    expect(arrived).toMatchObject({
      running: false,
      progress: 1,
      completed: true,
    });
  });

  it("does not allow place setup before accepting the friend", () => {
    const invalid = landingFlowReducer(initialLandingFlowState, {
      type: "save-place",
    });

    expect(invalid).toBe(initialLandingFlowState);
  });

  it("requires the accepted friend to be selected as the notification target", () => {
    const accepted = landingFlowReducer(initialLandingFlowState, {
      type: "accept-friend",
    });
    const missingRecipient = landingFlowReducer(accepted, {
      type: "save-place",
    });
    const selected = landingFlowReducer(accepted, {
      type: "select-recipient",
    });

    expect(missingRecipient.placeConfigured).toBe(false);
    expect(selected.recipientSelected).toBe(true);
    expect(
      landingFlowReducer(selected, { type: "save-place" }).placeConfigured,
    ).toBe(true);
  });

  it("keeps the original 100m to 300m notification range", () => {
    const accepted = landingFlowReducer(initialLandingFlowState, {
      type: "accept-friend",
    });

    expect(
      landingFlowReducer(accepted, { type: "set-radius", radius: 50 }).radius,
    ).toBe(100);
    expect(
      landingFlowReducer(accepted, { type: "set-radius", radius: 500 }).radius,
    ).toBe(300);
  });
});
