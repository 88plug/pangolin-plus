/**
 * Tunnel profile redesign (pangolin-plus).
 *
 * sites.type stays newt | wireguard | local (backend transport).
 * sites.tunnelProfile is UX/intent metadata for WireGuard sites.
 * sites.routingMode drives Gerbil peer AllowedIPs:
 *   selective   → site subnet + resource target IPs (default)
 *   full-tunnel → above + 0.0.0.0/0 and ::/0 (dual-stack default route)
 */

/** Default routes injected for full-tunnel (IPv4 + IPv6). */
export const FULL_TUNNEL_DEFAULT_ROUTES = ["0.0.0.0/0", "::/0"] as const;
import { z } from "zod";

export const ROUTING_MODES = ["full-tunnel", "selective"] as const;
export type RoutingMode = (typeof ROUTING_MODES)[number];

export const TUNNEL_PROFILES = [
    "standard",
    "secure-vpn",
    "split-tunnel",
    "privacy-gateway"
] as const;
export type TunnelProfile = (typeof TUNNEL_PROFILES)[number];

/** Shared zod enums — import these in create/update site schemas (no string drift). */
export const routingModeSchema = z.enum(ROUTING_MODES);
export const tunnelProfileSchema = z.enum(TUNNEL_PROFILES);

const PROFILE_ROUTING: Record<TunnelProfile, RoutingMode> = {
    standard: "selective",
    "secure-vpn": "full-tunnel",
    "split-tunnel": "selective",
    "privacy-gateway": "full-tunnel"
};

export type TunnelProfileDefaults = {
    routingMode: RoutingMode;
    siteType: "wireguard";
};

export function defaultsForTunnelProfile(
    profile: TunnelProfile
): TunnelProfileDefaults {
    return {
        routingMode: PROFILE_ROUTING[profile] ?? "selective",
        siteType: "wireguard"
    };
}

/** Coerce DB text columns / unknown JSON into a RoutingMode (or null). */
export function asRoutingMode(
    value: string | null | undefined
): RoutingMode | null {
    if (value === "full-tunnel" || value === "selective") return value;
    return null;
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
        for (const route of FULL_TUNNEL_DEFAULT_ROUTES) {
            if (!ips.includes(route)) ips.push(route);
        }
    }
    return ips;
}

/** Resolve profile + routing for wireguard creates; non-wg always selective/standard. */
export function resolveTunnelFields(input: {
    siteType: string;
    tunnelProfile?: TunnelProfile;
    routingMode?: RoutingMode;
}): { tunnelProfile: TunnelProfile; routingMode: RoutingMode } {
    if (input.siteType !== "wireguard") {
        return { tunnelProfile: "standard", routingMode: "selective" };
    }
    const tunnelProfile = input.tunnelProfile ?? "standard";
    const routingMode =
        input.routingMode ??
        defaultsForTunnelProfile(tunnelProfile).routingMode;
    return { tunnelProfile, routingMode };
}
