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
import * as fsSync from "fs";
import path from "path";

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
        const domainName = existingDomain.baseDomain;
        const domainDir = path.join(certificatesPath, domainName);
        const certPath = path.join(domainDir, "cert.pem");
        const keyPath = path.join(domainDir, "key.pem");
        const lastUpdatePath = path.join(domainDir, ".last_update");
        const wildcardPath = path.join(domainDir, ".wildcard");

        const exists =
            fsSync.existsSync(certPath) && fsSync.existsSync(keyPath);

        let lastUpdate: string | null = null;
        if (exists && fsSync.existsSync(lastUpdatePath)) {
            try {
                lastUpdate = fsSync.readFileSync(lastUpdatePath, "utf8").trim();
            } catch {
                lastUpdate = null;
            }
        }

        return response<GetLocalCertificateResponse>(res, {
            data: {
                domainId,
                domain: domainName,
                status: exists ? "valid" : "none",
                lastUpdate,
                wildcard: exists && fsSync.existsSync(wildcardPath)
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
