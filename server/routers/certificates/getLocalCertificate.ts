import { Request, Response, NextFunction } from "express";
import { z } from "zod";
import response from "@server/lib/response";
import HttpCode from "@server/types/HttpCode";
import createHttpError from "http-errors";
import logger from "@server/logger";
import { fromError } from "zod-validation-error";
import { OpenAPITags, registry } from "@server/openApi";
import {
    getCertificatesRoot,
    resolveOrgDomain,
    readLocalCertStatus
} from "@server/lib/certificates/localCertFs";

const paramsSchema = z
    .object({
        orgId: z.string(),
        domainId: z.string()
    })
    .strict();

export type GetLocalCertificateResponse = {
    domainId: string;
    domain: string;
    status: "valid" | "none";
    lastUpdate: string | null;
    wildcard: boolean;
};

registry.registerPath({
    method: "get",
    path: "/org/{orgId}/domain/{domainId}/certificate/local",
    description:
        "Report whether a custom on-disk TLS certificate exists for this domain under traefik.certificates_path.",
    tags: [OpenAPITags.Domain],
    request: {
        params: z.object({
            domainId: z.string(),
            orgId: z.string()
        })
    },
    responses: {}
});

export async function getLocalCertificate(
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

        const { orgId, domainId } = parsedParams.data;
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
            return response<GetLocalCertificateResponse>(res, {
                data: {
                    domainId,
                    domain: domain.baseDomain,
                    status: "none",
                    lastUpdate: null,
                    wildcard: false
                },
                success: true,
                error: false,
                message: "Local certificate status",
                status: HttpCode.OK
            });
        }

        const status = readLocalCertStatus(domain.baseDomain);

        return response<GetLocalCertificateResponse>(res, {
            data: {
                domainId,
                domain: domain.baseDomain,
                status: status.exists ? "valid" : "none",
                lastUpdate: status.lastUpdate,
                wildcard: status.wildcard
            },
            success: true,
            error: false,
            message: "Local certificate status",
            status: HttpCode.OK
        });
    } catch (error) {
        logger.error(error);
        return next(
            createHttpError(
                HttpCode.INTERNAL_SERVER_ERROR,
                "An error occurred reading local certificate status"
            )
        );
    }
}
