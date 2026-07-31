import { db } from "@server/db/pg/driver";
import { sql } from "drizzle-orm";

const version = "1.21.3";

/**
 * pangolin-plus / PR #3172: rename resources.headers → requestHeaders
 * and add responseHeaders for Traefik custom response headers.
 */
export default async function migration() {
    console.log(`Running setup script ${version}...`);

    try {
        await db.execute(sql`BEGIN`);

        // Rename headers → requestHeaders when the old column still exists
        await db.execute(sql`
            DO $$
            BEGIN
                IF EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_name = 'resources' AND column_name = 'headers'
                ) AND NOT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_name = 'resources' AND column_name = 'requestHeaders'
                ) THEN
                    ALTER TABLE "resources" RENAME COLUMN "headers" TO "requestHeaders";
                ELSIF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_name = 'resources' AND column_name = 'requestHeaders'
                ) THEN
                    ALTER TABLE "resources" ADD COLUMN "requestHeaders" text;
                END IF;

                IF NOT EXISTS (
                    SELECT 1 FROM information_schema.columns
                    WHERE table_name = 'resources' AND column_name = 'responseHeaders'
                ) THEN
                    ALTER TABLE "resources" ADD COLUMN "responseHeaders" text;
                END IF;
            END $$;
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
