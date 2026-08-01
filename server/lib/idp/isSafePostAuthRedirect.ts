import config from "@server/lib/config";
import {
    hasBlockedScheme,
    isSafeRelativeRedirectPath
} from "@server/lib/idp/isSafeRedirectPath";

export { isSafeRelativeRedirectPath } from "@server/lib/idp/isSafeRedirectPath";

function hostAllowed(host: string, allowed: string): boolean {
    return host === allowed || host.endsWith("." + allowed);
}

function collectAllowedHosts(): string[] {
    const hosts: string[] = [];
    const raw = config.getRawConfig();

    try {
        const dashboardUrl = raw.app?.dashboard_url;
        if (dashboardUrl) {
            const dashHost = new URL(dashboardUrl).hostname.toLowerCase();
            if (dashHost) hosts.push(dashHost);
        }
    } catch {
        // invalid dashboard_url
    }

    const domains = raw.domains;
    if (domains && typeof domains === "object") {
        for (const value of Object.values(domains)) {
            if (value && typeof value === "object" && "base_domain" in value) {
                const base = String(
                    (value as { base_domain?: string }).base_domain || ""
                ).toLowerCase();
                if (base) hosts.push(base);
            }
        }
    }

    const appBase = (raw.app as { base_domain?: string } | undefined)
        ?.base_domain;
    const serverBase = (
        raw as { server?: { base_domain?: string } }
    ).server?.base_domain;
    for (const base of [appBase, serverBase]) {
        if (base) hosts.push(String(base).toLowerCase());
    }

    return hosts;
}

/**
 * Validate post-OIDC redirect targets to prevent open redirects (#3335).
 * Allows relative same-origin paths and absolute http(s) URLs whose host
 * matches the dashboard host or a configured base_domain.
 */
export function isSafePostAuthRedirect(input: string): boolean {
    if (!input || typeof input !== "string") return false;

    const trimmed = input.trim();
    if (!trimmed) return false;

    if (hasBlockedScheme(trimmed)) return false;
    if (trimmed.startsWith("//")) return false;

    if (trimmed.startsWith("/")) {
        return isSafeRelativeRedirectPath(trimmed);
    }

    let url: URL;
    try {
        url = new URL(trimmed);
    } catch {
        return false;
    }

    if (url.protocol !== "http:" && url.protocol !== "https:") return false;

    const host = url.hostname.toLowerCase();
    if (!host) return false;

    return collectAllowedHosts().some((allowed) => hostAllowed(host, allowed));
}
