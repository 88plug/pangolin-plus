import { APP_PATH } from "@server/lib/consts";
import Database from "better-sqlite3";
import path from "path";

const version = "1.21.2";

/**
 * pangolin-plus: WireGuard tunnel profiles + routing mode on sites.
 * See server/lib/tunnels/tunnelProfiles.ts
 */
export default async function migration() {
    console.log(`Running setup script ${version}...`);

    const location = path.join(APP_PATH, "db", "db.sqlite");
    const db = new Database(location);

    try {
        db.pragma("foreign_keys = OFF");

        db.transaction(() => {
            // selective = current 1.21 behavior (targets only via getAllowedIps)
            db.prepare(
                `ALTER TABLE 'sites' ADD 'routingMode' text DEFAULT 'selective' NOT NULL;`
            ).run();
            db.prepare(
                `ALTER TABLE 'sites' ADD 'tunnelProfile' text DEFAULT 'standard' NOT NULL;`
            ).run();
        })();

        db.pragma("foreign_keys = ON");
        console.log(`Migrated database for ${version}`);
    } catch (e: any) {
        // Column may already exist on re-run
        if (
            typeof e?.message === "string" &&
            e.message.includes("duplicate column")
        ) {
            console.log(`${version}: columns already present, skipping`);
            return;
        }
        console.log("Failed to migrate db:", e);
        throw e;
    }

    console.log(`${version} migration complete`);
}
