import { db } from "@server/db/pg/driver";
import { sql } from "drizzle-orm";

const version = "1.21.2";

/**
 * pangolin-plus: WireGuard tunnel profiles + routing mode on sites.
 * See server/lib/tunnels/tunnelProfiles.ts
 */
export default async function migration() {
    console.log(`Running setup script ${version}...`);

    try {
        await db.execute(sql`BEGIN`);

        await db.execute(sql`
            ALTER TABLE "sites" ADD COLUMN IF NOT EXISTS "routingMode" varchar DEFAULT 'selective' NOT NULL;
        `);
        await db.execute(sql`
            ALTER TABLE "sites" ADD COLUMN IF NOT EXISTS "tunnelProfile" varchar DEFAULT 'standard' NOT NULL;
        `);

        await db.execute(sql`COMMIT`);
        console.log(`Migrated database for ${version}`);
    } catch (e) {
        await db.execute(sql`ROLLBACK`);
        console.log("Failed to migrate db:", e);
        throw e;
    }

    console.log(`${version} migration complete`);
}
