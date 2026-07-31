import config from "@server/lib/config";

/**
 * Validate post-OIDC redirect targets to prevent open redirects (#3335).
 * Allows:
 *  - relative same-origin paths (must start with single "/")
 *  - absolute http(s) URLs whose host matches the dashboard host
 *    or is a subdomain of a configured domains.base_domain
 */
export function isSafePostAuthRedirect(input: string): boolean {
    if (!input || typeof input !== "string") {
        return false;
    }

    const trimmed = input.trim();
    if (!trimmed) {
        return false;
    }

    const lower = trimmed.toLowerCase();
    if (
        lower.startsWith("javascript:") ||
        lower.startsWith("data:") ||
        lower.startsWith("vbscript:") ||
        lower.startsWith("file:")
    ) {
        return false;
    }

    // Protocol-relative URLs are open redirects
    if (trimmed.startsWith("//")) {
        return false;
    }

    // Relative path — same host as the dashboard
    if (trimmed.startsWith("/")) {
        // block path tricks that escape to another origin via backslash etc.
        if (trimmed.includes("\\") || trimmed.includes("\0")) {
            return false;
        }
        return true;
    }

    let url: URL;
    try {
        url = new URL(trimmed);
    } catch {
        return false;
    }

    if (url.protocol !== "http:" && url.protocol !== "https:") {
        return false;
    }

    const host = url.hostname.toLowerCase();
    if (!host) {
        return false;
    }

    const allowedHosts = new Set<string>();

    try {
        const dashboardUrl = config.getRawConfig().app.dashboard_url;
        if (dashboardUrl) {
            const dashHost = new URL(dashboardUrl).hostname.toLowerCase();
            if (dashHost) {
                allowedHosts.add(dashHost);
            }
        }
    } catch {
        // ignore invalid dashboard_url
    }

    if (allowedHosts.has(host)) {
        return true;
    }

    // Allow resource hosts under configured base domains (NS/CNAME/wildcard)
    try {
        const domains = config.getRawConfig().domains;
        if (domains && typeof domains === "object") {
            for (const value of Object.values(domains)) {
                const base =
                    value &&
                    typeof value === "object" &&
                    "base_domain" in value
                        ? String(
                              (value as { base_domain?: string }).base_domain ||
                                  ""
                          ).toLowerCase()
                        : "";
                if (!base) continue;
                if (host === base || host.endsWith("." + base)) {
                    return true;
                }
            }
        }
    } catch {
        // ignore
    }

    // server.base_domain if present on app/server config shapes
    try {
        const raw = config.getRawConfig() as any;
        const baseDomain = (
            raw?.app?.base_domain ||
            raw?.server?.base_domain ||
            ""
        )
            .toString()
            .toLowerCase();
        if (baseDomain && (host === baseDomain || host.endsWith("." + baseDomain))) {
            return true;
        }
    } catch {
        // ignore
    }

    return false;
}
