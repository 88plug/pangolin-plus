/**
 * On-disk layout for OSS custom TLS certs (TraefikConfigManager.scanLocalCertificateState):
 *   {certificates_path}/{baseDomain}/cert.pem
 *   {certificates_path}/{baseDomain}/key.pem
 *   {certificates_path}/{baseDomain}/.last_update
 *   {certificates_path}/{baseDomain}/.wildcard   (optional)
 */
import config from "@server/lib/config";
import * as fsSync from "fs";
import fs from "fs/promises";
import path from "path";
import * as yaml from "js-yaml";
import { db, domains, orgDomains } from "@server/db";
import { and, eq } from "drizzle-orm";

export {
    isPemCertificate,
    isPemPrivateKey
} from "@server/lib/certificates/localCertPem";

export type LocalCertPaths = {
    domainName: string;
    domainDir: string;
    certPath: string;
    keyPath: string;
    lastUpdatePath: string;
    wildcardPath: string;
};

export function getCertificatesRoot(): string | null {
    return config.getRawConfig().traefik.certificates_path ?? null;
}

export function pathsForDomain(baseDomain: string): LocalCertPaths {
    const root = getCertificatesRoot();
    if (!root) {
        throw new Error("traefik.certificates_path is not configured");
    }
    const domainDir = path.join(root, baseDomain);
    return {
        domainName: baseDomain,
        domainDir,
        certPath: path.join(domainDir, "cert.pem"),
        keyPath: path.join(domainDir, "key.pem"),
        lastUpdatePath: path.join(domainDir, ".last_update"),
        wildcardPath: path.join(domainDir, ".wildcard")
    };
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
        wildcard: exists && fsSync.existsSync(paths.wildcardPath)
    };
}

export async function writeLocalCertPem(opts: {
    baseDomain: string;
    certPem: string;
    keyPem: string;
    wildcard?: boolean;
}): Promise<LocalCertPaths> {
    const paths = pathsForDomain(opts.baseDomain);
    await fs.mkdir(paths.domainDir, { recursive: true });
    await fs.writeFile(paths.certPath, opts.certPem, { mode: 0o600 });
    await fs.writeFile(paths.keyPath, opts.keyPem, { mode: 0o600 });
    await fs.writeFile(paths.lastUpdatePath, new Date().toISOString(), {
        mode: 0o644
    });

    const isWildcard =
        opts.wildcard === true || opts.baseDomain.startsWith("*.");
    if (isWildcard) {
        await fs.writeFile(paths.wildcardPath, "true", { mode: 0o644 });
    }
    return paths;
}

type DynamicCertConfig = {
    tls?: { certificates?: Array<{ certFile?: string; keyFile?: string }> };
};

/** Merge cert paths into Traefik dynamic cert config when configured. */
export function mergeDynamicCertConfig(paths: LocalCertPaths): void {
    const dynamicConfigPath =
        config.getRawConfig().traefik.dynamic_cert_config_path;
    if (!dynamicConfigPath) return;

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
}
