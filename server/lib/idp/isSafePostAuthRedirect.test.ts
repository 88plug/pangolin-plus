import { assertEquals } from "../../../test/assert";
import {
    hasBlockedScheme,
    isSafeRelativeRedirectPath
} from "./isSafeRedirectPath";

const pathCases: Array<[string, boolean, string]> = [
    ["/", true, "root path"],
    ["/org/abc/settings", true, "normal path"],
    ["//evil.com", false, "protocol-relative"],
    ["/\\evil", false, "backslash escape"],
    ["/\r\nLocation: x", false, "CRLF"],
    ["/\0x", false, "null byte"],
    ["/\thost", false, "tab"],
    ["/foo://bar", false, "scheme mid-path"],
    ["", false, "empty"],
    ["relative", false, "not absolute path"]
];

for (const [input, want, name] of pathCases) {
    assertEquals(isSafeRelativeRedirectPath(input), want, name);
}

assertEquals(hasBlockedScheme("javascript:alert(1)"), true, "js scheme");
assertEquals(hasBlockedScheme("data:text/html"), true, "data scheme");
assertEquals(hasBlockedScheme("/ok"), false, "path not scheme");

console.log("isSafePostAuthRedirect.test.ts: all assertions passed");
