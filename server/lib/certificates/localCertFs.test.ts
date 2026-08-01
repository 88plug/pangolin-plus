import { assertEquals } from "../../../test/assert";
import { isPemCertificate, isPemPrivateKey } from "./localCertPem";

assertEquals(
    isPemCertificate("-----BEGIN CERTIFICATE-----\nMII\n-----END CERTIFICATE-----"),
    true,
    "accepts certificate PEM"
);
assertEquals(isPemCertificate("not a cert"), false, "rejects non-PEM");

assertEquals(
    isPemPrivateKey("-----BEGIN PRIVATE KEY-----\nx"),
    true,
    "PKCS8 key"
);
assertEquals(
    isPemPrivateKey("-----BEGIN RSA PRIVATE KEY-----\nx"),
    true,
    "RSA key"
);
assertEquals(
    isPemPrivateKey("-----BEGIN EC PRIVATE KEY-----\nx"),
    true,
    "EC key"
);
assertEquals(
    isPemPrivateKey("-----BEGIN CERTIFICATE-----\nx"),
    false,
    "cert is not a key"
);

console.log("localCertFs.test.ts: all assertions passed");
