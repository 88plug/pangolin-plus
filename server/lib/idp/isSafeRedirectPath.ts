/** Pure path/scheme checks for post-auth redirects (no config I/O). */

const BLOCKED_SCHEMES = [
    "javascript:",
    "data:",
    "vbscript:",
    "file:"
] as const;

export function hasBlockedScheme(input: string): boolean {
    const lower = input.toLowerCase();
    return BLOCKED_SCHEMES.some((s) => lower.startsWith(s));
}

export function isSafeRelativeRedirectPath(path: string): boolean {
    if (!path.startsWith("/")) return false;
    if (path.includes("\\") || /[\x00-\x1F\x7F]/.test(path)) return false;
    if (path.startsWith("//") || path.includes("://")) return false;
    return true;
}
