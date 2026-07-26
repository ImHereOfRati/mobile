import type { NativeBridge } from "@imhere/bridge-contract";
import { createContext, useContext } from "react";

export const BridgeContext = createContext<NativeBridge | null>(null);

export function useBridge() {
  const bridge = useContext(BridgeContext);
  if (bridge === null) throw new Error("BridgeProvider is missing");
  return bridge;
}
