/** Pure PEM shape checks — no filesystem or config side effects. */

const VALID_KEY_HEADERS = [
    "-----BEGIN PRIVATE KEY-----",
    "-----BEGIN RSA PRIVATE KEY-----",
    "-----BEGIN EC PRIVATE KEY-----"
] as const;

export function isPemCertificate(pem: string): boolean {
    return pem.includes("-----BEGIN CERTIFICATE-----");
}

export function isPemPrivateKey(pem: string): boolean {
    return VALID_KEY_HEADERS.some((h) => pem.includes(h));
}
