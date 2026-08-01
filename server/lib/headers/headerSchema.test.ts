import { assertEquals } from "../../../test/assert";
import {
    HeaderSchema,
    isValidHttpHeader,
    headersPassValidation
} from "./headerSchema";

assertEquals(
    isValidHttpHeader({ name: "X-Custom", value: "ok" }),
    true,
    "valid header"
);
assertEquals(
    isValidHttpHeader({ name: "Bad Name", value: "x" }),
    false,
    "space in name"
);
assertEquals(
    isValidHttpHeader({ name: "X-T", value: "{{inject}}" }),
    false,
    "template value"
);
assertEquals(
    isValidHttpHeader({ name: "X-T", value: "a\nb" }),
    false,
    "CRLF value"
);

const bad = HeaderSchema.safeParse({ name: "Ok", value: "{{x}}" });
assertEquals(bad.success, false, "zod rejects template");

const good = HeaderSchema.safeParse({ name: "X-Foo", value: "bar" });
assertEquals(good.success, true, "zod accepts good header");

assertEquals(
    headersPassValidation([{ name: "A", value: "1" }, { name: "B", value: "" }]),
    true,
    "empty value ok"
);
assertEquals(
    headersPassValidation([{ name: "Bad\n", value: "1" }]),
    false,
    "bad name rejected"
);

console.log("headerSchema.test.ts: all assertions passed");
