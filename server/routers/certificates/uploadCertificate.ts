import { Request, Response, NextFunction } from "express";
import { z } from "zod";
import response from "@server/lib/response";
import HttpCode from "@server/types/HttpCode";
import createHttpError from "http-errors";
import logger from "@server/logger";
import { fromError } from "zod-validation-error";
import { OpenAPITags, registry } from "@server/openApi";
import {
    isPemCertificate,
    isPemPrivateKey,
    getCertificatesRoot,
    resolveOrgDomain,
    writeLocalCertPem,
    mergeDynamicCertConfig
} from "@server/lib/certificates/localCertFs";

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

        if (!isPemCertificate(certFile)) {
            return next(
                createHttpError(
                    HttpCode.BAD_REQUEST,
                    "Invalid certificate format. Must be PEM encoded."
                )
            );
        }

        if (!isPemPrivateKey(keyFile)) {
            return next(
                createHttpError(
                    HttpCode.BAD_REQUEST,
                    "Invalid private key format. Must be PEM encoded (RSA or ECC)."
                )
            );
        }

        const domain = await resolveOrgDomain(orgId, domainId);
        if (!domain) {
            return next(
                createHttpError(
                    HttpCode.NOT_FOUND,
                    "Domain not found or does not belong to this organization"
                )
            );
        }

        if (!getCertificatesRoot()) {
            return next(
                createHttpError(
                    HttpCode.INTERNAL_SERVER_ERROR,
                    "traefik.certificates_path is not configured"
                )
            );
        }

        const paths = await writeLocalCertPem({
            baseDomain: domain.baseDomain,
            certPem: certFile,
            keyPem: keyFile,
            wildcard
        });
        logger.info(`Custom certificate written to ${paths.domainDir}`);

        try {
            mergeDynamicCertConfig(paths);
            logger.info(
                `Traefik dynamic cert config updated for ${domain.baseDomain}`
            );
        } catch (configError) {
            logger.error(
                `Failed to update Traefik dynamic config: ${configError}`
            );
        }

        return response<UploadCertificateResponse>(res, {
            data: {
                domainId,
                domain: domain.baseDomain,
                status: "valid",
                path: paths.domainDir
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
