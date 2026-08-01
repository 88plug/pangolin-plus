/**
 * Canonical HTTP header name/value validation for resources and blueprints.
 * Keeps Traefik emit path free of CRLF / template injection.
 */
import { z } from "zod";

/** RFC 7230 token characters for header field-name */
export const HEADER_NAME_RE = /^[a-zA-Z0-9!#$%&'*+\-.^_`|~]+$/;
/** Printable ASCII + horizontal tab for header field-value */
export const HEADER_VALUE_RE = /^[\t\x20-\x7E]*$/;
export const HEADER_TEMPLATE_RE = /\{\{[^}]+\}\}/;

export type HttpHeader = { name: string; value: string };

export function isValidHeaderName(name: string): boolean {
    return HEADER_NAME_RE.test(name) && !HEADER_TEMPLATE_RE.test(name);
}

export function isValidHeaderValue(value: string): boolean {
    return HEADER_VALUE_RE.test(value) && !HEADER_TEMPLATE_RE.test(value);
}

export function isValidHttpHeader(h: HttpHeader): boolean {
    return (
        h.name.length > 0 &&
        isValidHeaderName(h.name) &&
        isValidHeaderValue(h.value)
    );
}

/** Zod schema used by blueprints and resource API. Empty values allowed (HTTP). */
export const HeaderSchema = z
    .object({
        name: z.string().min(1),
        value: z.string()
    })
    .superRefine((h, ctx) => {
        if (!HEADER_NAME_RE.test(h.name)) {
            ctx.addIssue({
                code: "custom",
                path: ["name"],
                message:
                    "Header names may only contain valid HTTP token characters (letters, digits, and !#$%&'*+-.^_`|~)."
            });
        }
        if (!HEADER_VALUE_RE.test(h.value)) {
            ctx.addIssue({
                code: "custom",
                path: ["value"],
                message:
                    "Header values may only contain printable ASCII characters and horizontal whitespace."
            });
        }
        if (HEADER_TEMPLATE_RE.test(h.name) || HEADER_TEMPLATE_RE.test(h.value)) {
            ctx.addIssue({
                code: "custom",
                message:
                    "Header names and values must not contain template expressions such as {{value}}."
            });
        }
    });

export const headerArraySchema = z.array(HeaderSchema);

/** Refine helper for resource update schemas that still accept deprecated `headers`. */
export function headersPassValidation(
    headers: HttpHeader[] | null | undefined
): boolean {
    if (!headers?.length) return true;
    return headers.every(isValidHttpHeader);
}
