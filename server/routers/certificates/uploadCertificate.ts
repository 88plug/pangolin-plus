import { Request, Response, NextFunction } from "express";
import { z } from "zod";
import { db, domains, orgDomains } from "@server/db";
import response from "@server/lib/response";
import HttpCode from "@server/types/HttpCode";
import createHttpError from "http-errors";
import logger from "@server/logger";
import { fromError } from "zod-validation-error";
import { eq, and } from "drizzle-orm";
import { OpenAPITags, registry } from "@server/openApi";
import config from "@server/lib/config";
import fs from "fs/promises";
import * as fsSync from "fs";
import path from "path";
import * as yaml from "js-yaml";

const paramsSchema = z
    .object({
        orgId: z.string(),
        domainId: z.string()
    })
    .strict();

const bodySchema = z
    .object({
        certFile: z.string().min(1, "Certificate file is required"),
        keyFile: z.string().min(1, "Private key file is required"),
        wildcard: z.boolean().optional()
    })
    .strict();

export type UploadCertificateResponse = {
    domainId: string;
    domain: string;
    status: "valid";
    path: string;
};

registry.registerPath({
    method: "post",
    path: "/org/{orgId}/domain/{domainId}/certificate/upload",
    description:
        "Upload a custom TLS certificate (PEM) for a domain. Writes files under traefik.certificates_path so TraefikConfigManager can load them (Cloudflare Origin Certs, etc.).",
    tags: [OpenAPITags.Domain],
    request: {
        params: z.object({
            domainId: z.string(),
            orgId: z.string()
        })
    },
    responses: {}
});

const VALID_KEY_HEADERS = [
    "-----BEGIN PRIVATE KEY-----",
    "-----BEGIN RSA PRIVATE KEY-----",
    "-----BEGIN EC PRIVATE KEY-----"
];

/**
 * PEM upload for OSS self-host: filesystem layout matches TraefikConfigManager.scanLocalCertificateState
 *   {certificates_path}/{baseDomain}/cert.pem
 *   {certificates_path}/{baseDomain}/key.pem
 *   {certificates_path}/{baseDomain}/.last_update
 *   {certificates_path}/{baseDomain}/.wildcard   (optional)
 * Also merges an entry into traefik.dynamic_cert_config_path when set.
 */
export async function uploadCertificate(
    req: Request,
    res: Response,
    next: NextFunction
): Promise<any> {
    try {
        const parsedParams = paramsSchema.safeParse(req.params);
        if (!parsedParams.success) {
            return next(
                createHttpError(
                    HttpCode.BAD_REQUEST,
                    fromError(parsedParams.error).toString()
                )
            );
        }

        const parsedBody = bodySchema.safeParse(req.body);
        if (!parsedBody.success) {
            return next(
                createHttpError(
                    HttpCode.BAD_REQUEST,
                    fromError(parsedBody.error).toString()
                )
            );
        }

        const { orgId, domainId } = parsedParams.data;
        const { certFile, keyFile, wildcard } = parsedBody.data;

        if (!certFile.includes("-----BEGIN CERTIFICATE-----")) {
            return next(
                createHttpError(
                    HttpCode.BAD_REQUEST,
                    "Invalid certificate format. Must be PEM encoded."
                )
            );
        }

        if (!VALID_KEY_HEADERS.some((h) => keyFile.includes(h))) {
            return next(
                createHttpError(
                    HttpCode.BAD_REQUEST,
                    "Invalid private key format. Must be PEM encoded (RSA or ECC)."
                )
            );
        }

        const [orgDomain] = await db
            .select()
            .from(orgDomains)
            .where(
                and(
                    eq(orgDomains.orgId, orgId),
                    eq(orgDomains.domainId, domainId)
                )
            );

        if (!orgDomain) {
            return next(
                createHttpError(
                    HttpCode.NOT_FOUND,
                    "Domain not found or does not belong to this organization"
                )
            );
        }

        const [existingDomain] = await db
            .select()
            .from(domains)
            .where(eq(domains.domainId, domainId));

        if (!existingDomain) {
            return next(
                createHttpError(HttpCode.NOT_FOUND, "Domain not found")
            );
        }

        const certificatesPath =
            config.getRawConfig().traefik.certificates_path;
        if (!certificatesPath) {
            return next(
                createHttpError(
                    HttpCode.INTERNAL_SERVER_ERROR,
                    "traefik.certificates_path is not configured"
                )
            );
        }

        const domainName = existingDomain.baseDomain;
        const domainDir = path.join(certificatesPath, domainName);
        await fs.mkdir(domainDir, { recursive: true });

        const certPath = path.join(domainDir, "cert.pem");
        const keyPath = path.join(domainDir, "key.pem");
        await fs.writeFile(certPath, certFile, { mode: 0o600 });
        await fs.writeFile(keyPath, keyFile, { mode: 0o600 });
        await fs.writeFile(
            path.join(domainDir, ".last_update"),
            new Date().toISOString(),
            { mode: 0o644 }
        );

        const isWildcard =
            wildcard === true || domainName.startsWith("*.");
        if (isWildcard) {
            await fs.writeFile(path.join(domainDir, ".wildcard"), "true", {
                mode: 0o644
            });
        }

        logger.info(`Custom certificate written to ${domainDir}`);

        const dynamicConfigPath =
            config.getRawConfig().traefik.dynamic_cert_config_path;
        if (dynamicConfigPath) {
            try {
                let dynamicConfig: any = { tls: { certificates: [] } };
                if (fsSync.existsSync(dynamicConfigPath)) {
                    const fileContent = fsSync.readFileSync(
                        dynamicConfigPath,
                        "utf8"
                    );
                    dynamicConfig = yaml.load(fileContent) || dynamicConfig;
                    if (!dynamicConfig.tls) {
                        dynamicConfig.tls = { certificates: [] };
                    }
                    if (!Array.isArray(dynamicConfig.tls.certificates)) {
                        dynamicConfig.tls.certificates = [];
                    }
                }

                dynamicConfig.tls.certificates =
                    dynamicConfig.tls.certificates.filter((entry: any) => {
                        const cf = entry.certFile || "";
                        return (
                            !cf.includes(`/${domainName}/`) &&
                            !cf.endsWith(`/${domainName}.crt`)
                        );
                    });

                dynamicConfig.tls.certificates.push({
                    certFile: certPath,
                    keyFile: keyPath
                });

                fsSync.writeFileSync(
                    dynamicConfigPath,
                    yaml.dump(dynamicConfig, { noRefs: true }),
                    "utf8"
                );
                logger.info(
                    `Traefik dynamic cert config updated for ${domainName}`
                );
            } catch (configError) {
                logger.error(
                    `Failed to update Traefik dynamic config: ${configError}`
                );
            }
        }

        return response<UploadCertificateResponse>(res, {
            data: {
                domainId,
                domain: domainName,
                status: "valid",
                path: domainDir
            },
            success: true,
            error: false,
            message: "Certificate uploaded successfully",
            status: HttpCode.OK
        });
    } catch (error) {
        logger.error(error);
        return next(
            createHttpError(
                HttpCode.INTERNAL_SERVER_ERROR,
                "An error occurred uploading the certificate"
            )
        );
    }
}
