import {
  MINIMUM_BRIDGE_VERSION,
  type BridgeMethodName,
  type BridgeMethodResult,
} from "./contract";

export type BridgeHandshake = BridgeMethodResult<"getCapabilities">;

export interface BridgeCompatibility {
  compatible: boolean;
  nativeVersion: string;
  requiredVersion: string;
  reason?: "invalidVersion" | "majorMismatch" | "versionTooOld";
  missingCapabilities: string[];
}

interface SemanticVersion {
  major: number;
  minor: number;
  patch: number;
}

function parseVersion(version: string): SemanticVersion | null {
  const match = /^(\d+)\.(\d+)\.(\d+)$/.exec(version);
  if (match === null) return null;

  return {
    major: Number(match[1]),
    minor: Number(match[2]),
    patch: Number(match[3]),
  };
}

function compareVersion(left: SemanticVersion, right: SemanticVersion) {
  if (left.major !== right.major) return left.major - right.major;
  if (left.minor !== right.minor) return left.minor - right.minor;
  return left.patch - right.patch;
}

export function negotiateBridge(
  handshake: BridgeHandshake,
  options: {
    minimumVersion?: string;
    requiredMethods?: readonly BridgeMethodName[];
  } = {},
): BridgeCompatibility {
  const requiredVersion = options.minimumVersion ?? MINIMUM_BRIDGE_VERSION;
  const nativeVersion = parseVersion(handshake.bridgeVersion);
  const minimumVersion = parseVersion(requiredVersion);
  const requiredCapabilities = (options.requiredMethods ?? []).map(
    (method) => `method:${method}`,
  );
  const missingCapabilities = requiredCapabilities.filter(
    (capability) => !handshake.capabilities.includes(capability),
  );

  if (nativeVersion === null || minimumVersion === null) {
    return {
      compatible: false,
      nativeVersion: handshake.bridgeVersion,
      requiredVersion,
      reason: "invalidVersion",
      missingCapabilities,
    };
  }

  if (nativeVersion.major !== minimumVersion.major) {
    return {
      compatible: false,
      nativeVersion: handshake.bridgeVersion,
      requiredVersion,
      reason: "majorMismatch",
      missingCapabilities,
    };
  }

  if (compareVersion(nativeVersion, minimumVersion) < 0) {
    return {
      compatible: false,
      nativeVersion: handshake.bridgeVersion,
      requiredVersion,
      reason: "versionTooOld",
      missingCapabilities,
    };
  }

  return {
    compatible: missingCapabilities.length === 0,
    nativeVersion: handshake.bridgeVersion,
    requiredVersion,
    missingCapabilities,
  };
}
