/**
 * I/O helpers for OSS custom TLS certs (org resolve, write PEM, dynamic config).
 * Pure path layout lives in localCertPaths (safe for TraefikConfigManager).
 */
import config from "@server/lib/config";
import * as fsSync from "fs";
import fs from "fs/promises";
import path from "path";
import * as yaml from "js-yaml";
import { db, domains, orgDomains } from "@server/db";
import { and, eq } from "drizzle-orm";
import {
    pathsForDomainRoot,
    readWildcardFlag,
    writeWildcardFlag,
    type LocalCertPaths
} from "@server/lib/certificates/localCertPaths";

export {
    isPemCertificate,
    isPemPrivateKey
} from "@server/lib/certificates/localCertPem";

export {
    pathsForDomainRoot,
    readWildcardFlag,
    writeWildcardFlag,
    type LocalCertPaths
} from "@server/lib/certificates/localCertPaths";

export function getCertificatesRoot(): string | null {
    return config.getRawConfig().traefik.certificates_path ?? null;
}

export function pathsForDomain(baseDomain: string): LocalCertPaths {
    const root = getCertificatesRoot();
    if (!root) {
        throw new Error("traefik.certificates_path is not configured");
    }
    return pathsForDomainRoot(root, baseDomain);
}

export type OrgDomainRow = {
    domainId: string;
    baseDomain: string;
};

/** Resolve a domain that belongs to the org, or null if missing. */
export async function resolveOrgDomain(
    orgId: string,
    domainId: string
): Promise<OrgDomainRow | null> {
    const [orgDomain] = await db
        .select()
        .from(orgDomains)
        .where(
            and(eq(orgDomains.orgId, orgId), eq(orgDomains.domainId, domainId))
        );

    if (!orgDomain) return null;

    const [existingDomain] = await db
        .select()
        .from(domains)
        .where(eq(domains.domainId, domainId));

    if (!existingDomain) return null;

    return {
        domainId,
        baseDomain: existingDomain.baseDomain
    };
}

export type LocalCertStatus = {
    exists: boolean;
    lastUpdate: string | null;
    wildcard: boolean;
};

export function readLocalCertStatus(baseDomain: string): LocalCertStatus {
    const paths = pathsForDomain(baseDomain);
    const exists =
        fsSync.existsSync(paths.certPath) && fsSync.existsSync(paths.keyPath);

    let lastUpdate: string | null = null;
    if (exists && fsSync.existsSync(paths.lastUpdatePath)) {
        try {
            lastUpdate = fsSync.readFileSync(paths.lastUpdatePath, "utf8").trim();
        } catch {
            lastUpdate = null;
        }
    }

    return {
        exists,
        lastUpdate,
        wildcard: exists && readWildcardFlag(paths.wildcardPath)
    };
}

const MAX_PEM_BYTES = 256 * 1024;

export function assertPemSize(pem: string, label: string): void {
    if (Buffer.byteLength(pem, "utf8") > MAX_PEM_BYTES) {
        throw new Error(`${label} exceeds ${MAX_PEM_BYTES} byte limit`);
    }
}

export async function writeLocalCertPem(opts: {
    baseDomain: string;
    certPem: string;
    keyPem: string;
    wildcard?: boolean;
}): Promise<LocalCertPaths> {
    assertPemSize(opts.certPem, "certificate");
    assertPemSize(opts.keyPem, "private key");

    const paths = pathsForDomain(opts.baseDomain);
    const root = path.resolve(getCertificatesRoot()!);
    const domainDir = path.resolve(paths.domainDir);
    if (domainDir !== root && !domainDir.startsWith(root + path.sep)) {
        throw new Error("certificate path escapes certificates_path");
    }

    await fs.mkdir(paths.domainDir, { recursive: true });
    await fs.writeFile(paths.certPath, opts.certPem);
    await fs.writeFile(paths.keyPath, opts.keyPem);
    await fs.chmod(paths.certPath, 0o644);
    await fs.chmod(paths.keyPath, 0o600);
    await fs.writeFile(paths.lastUpdatePath, new Date().toISOString());
    await fs.chmod(paths.lastUpdatePath, 0o644);

    const isWildcard =
        opts.wildcard === true || opts.baseDomain.startsWith("*.");
    writeWildcardFlag(paths.wildcardPath, isWildcard);
    return paths;
}

type DynamicCertConfig = {
    tls?: { certificates?: Array<{ certFile?: string; keyFile?: string }> };
};

/**
 * Merge cert paths into Traefik dynamic cert config when configured.
 * @returns true if a dynamic config file was written, false if not configured.
 */
export function mergeDynamicCertConfig(paths: LocalCertPaths): boolean {
    const dynamicConfigPath =
        config.getRawConfig().traefik.dynamic_cert_config_path;
    if (!dynamicConfigPath) return false;

    let dynamicConfig: DynamicCertConfig = { tls: { certificates: [] } };
    if (fsSync.existsSync(dynamicConfigPath)) {
        const fileContent = fsSync.readFileSync(dynamicConfigPath, "utf8");
        const loaded = yaml.load(fileContent) as DynamicCertConfig | null;
        dynamicConfig = loaded || dynamicConfig;
        if (!dynamicConfig.tls) dynamicConfig.tls = { certificates: [] };
        if (!Array.isArray(dynamicConfig.tls.certificates)) {
            dynamicConfig.tls.certificates = [];
        }
    }

    const certs = dynamicConfig.tls!.certificates!;
    dynamicConfig.tls!.certificates = certs.filter((entry) => {
        const cf = entry.certFile || "";
        return (
            !cf.includes(`/${paths.domainName}/`) &&
            !cf.endsWith(`/${paths.domainName}.crt`)
        );
    });

    dynamicConfig.tls!.certificates.push({
        certFile: paths.certPath,
        keyFile: paths.keyPath
    });

    fsSync.writeFileSync(
        dynamicConfigPath,
        yaml.dump(dynamicConfig, { noRefs: true }),
        "utf8"
    );
    return true;
}
