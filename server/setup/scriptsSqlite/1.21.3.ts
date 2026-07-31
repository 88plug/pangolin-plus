import { APP_PATH } from "@server/lib/consts";
import Database from "better-sqlite3";
import path from "path";

const version = "1.21.3";

/**
 * pangolin-plus / PR #3172: rename resources.headers → requestHeaders
 * and add responseHeaders for Traefik custom response headers.
 */
export default async function migration() {
    console.log(`Running setup script ${version}...`);

    const location = path.join(APP_PATH, "db", "db.sqlite");
    const db = new Database(location);

    try {
        db.pragma("foreign_keys = OFF");

        db.transaction(() => {
            const cols = db
                .prepare(`PRAGMA table_info('resources')`)
                .all() as { name: string }[];
            const names = new Set(cols.map((c) => c.name));

            if (names.has("headers") && !names.has("requestHeaders")) {
                db.prepare(
                    `ALTER TABLE 'resources' RENAME COLUMN 'headers' TO 'requestHeaders';`
                ).run();
            } else if (!names.has("requestHeaders")) {
                db.prepare(
                    `ALTER TABLE 'resources' ADD 'requestHeaders' text;`
                ).run();
            }

            if (!names.has("responseHeaders")) {
                db.prepare(
                    `ALTER TABLE 'resources' ADD 'responseHeaders' text;`
                ).run();
            }
        })();

        db.pragma("foreign_keys = ON");
        console.log(`Migrated database for ${version}`);
    } catch (e) {
        console.log("Failed to migrate db:", e);
        throw e;
    }

    console.log(`${version} migration complete`);
}
