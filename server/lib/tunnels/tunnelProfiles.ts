/**
 * Tunnel profile redesign (pangolin-plus).
 *
 * Old Dec-2025 work stored fake site types ("secure-vpn", "split-tunnel",
 * "privacy-gateway") that were coerced back to "wireguard". That fought the
 * 1.21 model (sites.type is only newt | wireguard | local).
 *
 * Redesign:
 *  - sites.type stays newt | wireguard | local (backend transport)
 *  - sites.tunnelProfile is UX/intent metadata for WireGuard sites
 *  - sites.routingMode drives Gerbil peer AllowedIPs
 *      selective  → site subnet + resource target IPs (default, current 1.21 behavior)
 *      full-tunnel → above + 0.0.0.0/0 (all client traffic via exit node)
 *
 * Profile → defaults:
 *  secure-vpn      → full-tunnel   (encrypted default route)
 *  split-tunnel    → selective    (only targets/LAN-via-targets)
 *  privacy-gateway → full-tunnel  (same routing; UI copy points at edge DNS/ODoH)
 *  standard        → selective    (plain WireGuard site)
 */

export const ROUTING_MODES = ["full-tunnel", "selective"] as const;
export type RoutingMode = (typeof ROUTING_MODES)[number];

export const TUNNEL_PROFILES = [
    "standard",
    "secure-vpn",
    "split-tunnel",
    "privacy-gateway"
] as const;
export type TunnelProfile = (typeof TUNNEL_PROFILES)[number];

export type TunnelProfileDefaults = {
    routingMode: RoutingMode;
    /** Backend site type — always wireguard for tunnel profiles */
    siteType: "wireguard";
};

export function defaultsForTunnelProfile(
    profile: TunnelProfile
): TunnelProfileDefaults {
    switch (profile) {
        case "secure-vpn":
            return { routingMode: "full-tunnel", siteType: "wireguard" };
        case "split-tunnel":
            return { routingMode: "selective", siteType: "wireguard" };
        case "privacy-gateway":
            return { routingMode: "full-tunnel", siteType: "wireguard" };
        case "standard":
        default:
            return { routingMode: "selective", siteType: "wireguard" };
    }
}

/**
 * Build Gerbil peer allowedIps for a WireGuard site given its routing mode.
 * Newt sites are unchanged (always [subnet]).
 */
export function applyRoutingModeToAllowedIps(
    baseAllowedIps: string[],
    routingMode: RoutingMode | null | undefined
): string[] {
    const ips = [...new Set(baseAllowedIps.filter(Boolean))];
    if (routingMode === "full-tunnel") {
        if (!ips.includes("0.0.0.0/0")) {
            ips.push("0.0.0.0/0");
        }
    }
    return ips;
}
