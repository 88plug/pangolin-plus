import { assertEquals } from "../../../test/assert";
import {
    defaultsForTunnelProfile,
    applyRoutingModeToAllowedIps,
    resolveTunnelFields,
    asRoutingMode
} from "./tunnelProfiles";

assertEquals(
    defaultsForTunnelProfile("secure-vpn").routingMode,
    "full-tunnel",
    "secure-vpn → full-tunnel"
);
assertEquals(
    defaultsForTunnelProfile("split-tunnel").routingMode,
    "selective",
    "split-tunnel → selective"
);
assertEquals(
    defaultsForTunnelProfile("privacy-gateway").routingMode,
    "full-tunnel",
    "privacy-gateway → full-tunnel"
);
assertEquals(
    defaultsForTunnelProfile("standard").routingMode,
    "selective",
    "standard → selective"
);

const selective = applyRoutingModeToAllowedIps(
    ["10.0.0.1/32", "192.168.1.0/24"],
    "selective"
);
assertEquals(selective.includes("0.0.0.0/0"), false, "selective no default route");

const full = applyRoutingModeToAllowedIps(
    ["10.0.0.1/32"],
    "full-tunnel"
);
assertEquals(full.includes("0.0.0.0/0"), true, "full-tunnel has IPv4 default");
assertEquals(full.includes("::/0"), true, "full-tunnel has IPv6 default");
assertEquals(full.includes("10.0.0.1/32"), true, "full-tunnel keeps subnet");

// dedupe
const deduped = applyRoutingModeToAllowedIps(
    ["10.0.0.1/32", "10.0.0.1/32", "0.0.0.0/0"],
    "full-tunnel"
);
assertEquals(
    deduped.filter((x) => x === "0.0.0.0/0").length,
    1,
    "dedupe 0.0.0.0/0"
);

assertEquals(asRoutingMode("full-tunnel"), "full-tunnel", "asRoutingMode full");
assertEquals(asRoutingMode("bogus"), null, "asRoutingMode rejects junk");

const wg = resolveTunnelFields({
    siteType: "wireguard",
    tunnelProfile: "secure-vpn"
});
assertEquals(wg.routingMode, "full-tunnel", "resolveTunnelFields profile default");
assertEquals(
    resolveTunnelFields({ siteType: "newt" }).routingMode,
    "selective",
    "non-wg forced selective"
);

console.log("tunnelProfiles.test.ts: all assertions passed");
