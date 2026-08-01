import { assertEquals } from "../../../test/assert";
import {
    pathsForDomainRoot,
    readWildcardFlag,
    writeWildcardFlag
} from "./localCertPaths";
import * as fs from "fs";
import * as os from "os";
import * as path from "path";

const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "localcert-"));
const paths = pathsForDomainRoot(tmp, "example.com");
fs.mkdirSync(paths.domainDir, { recursive: true });

assertEquals(paths.domainName, "example.com", "domain name");
assertEquals(paths.certPath.endsWith("cert.pem"), true, "cert.pem path");
assertEquals(paths.wildcardPath.endsWith(".wildcard"), true, "wildcard path");

assertEquals(readWildcardFlag(paths.wildcardPath), false, "missing = false");

writeWildcardFlag(paths.wildcardPath, true);
assertEquals(readWildcardFlag(paths.wildcardPath), true, "true content");

writeWildcardFlag(paths.wildcardPath, false);
assertEquals(readWildcardFlag(paths.wildcardPath), false, "deleted marker");
assertEquals(fs.existsSync(paths.wildcardPath), false, "file gone");

// stale "false" content must not count as wildcard
fs.writeFileSync(paths.wildcardPath, "false", "utf8");
assertEquals(readWildcardFlag(paths.wildcardPath), false, "false content");

fs.rmSync(tmp, { recursive: true, force: true });
console.log("localCertPaths.test.ts: all assertions passed");
