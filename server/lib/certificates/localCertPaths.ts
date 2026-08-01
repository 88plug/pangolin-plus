/**
 * Pure on-disk layout for OSS custom TLS certs (no config/db I/O).
 * Shared by TraefikConfigManager and localCertFs.
 *
 *   {certificates_path}/{baseDomain}/cert.pem
 *   {certificates_path}/{baseDomain}/key.pem
 *   {certificates_path}/{baseDomain}/.last_update
 *   {certificates_path}/{baseDomain}/.wildcard   (content "true" only)
 */
import * as fsSync from "fs";
import path from "path";

export type LocalCertPaths = {
    domainName: string;
    domainDir: string;
    certPath: string;
    keyPath: string;
    lastUpdatePath: string;
    wildcardPath: string;
};

/** Build paths under an explicit certificates root. */
export function pathsForDomainRoot(
    certificatesRoot: string,
    baseDomain: string
): LocalCertPaths {
    const domainDir = path.join(certificatesRoot, baseDomain);
    return {
        domainName: baseDomain,
        domainDir,
        certPath: path.join(domainDir, "cert.pem"),
        keyPath: path.join(domainDir, "key.pem"),
        lastUpdatePath: path.join(domainDir, ".last_update"),
        wildcardPath: path.join(domainDir, ".wildcard")
    };
}

/**
 * Wildcard marker semantics (Traefik + OSS upload must agree):
 * - file missing → not wildcard
 * - content trimmed === "true" → wildcard
 * - content "false" or anything else → not wildcard
 */
export function readWildcardFlag(wildcardPath: string): boolean {
    if (!fsSync.existsSync(wildcardPath)) return false;
    try {
        return fsSync.readFileSync(wildcardPath, "utf8").trim() === "true";
    } catch {
        return false;
    }
}

/** Write or remove wildcard marker. Prefer delete over writing "false". */
export function writeWildcardFlag(
    wildcardPath: string,
    isWildcard: boolean
): void {
    if (isWildcard) {
        fsSync.writeFileSync(wildcardPath, "true", "utf8");
        try {
            fsSync.chmodSync(wildcardPath, 0o644);
        } catch {
            // best-effort chmod
        }
        return;
    }
    try {
        fsSync.unlinkSync(wildcardPath);
    } catch {
        // no prior marker
    }
}
