/**
 * One-off cleanup for the CGM reading collection.
 *
 * Removes two kinds of bad data created by the old mobile-app timestamp bug
 * (timestamp-less readings stamped with receive-time, then bulk-uploaded):
 *
 *   1. "Collapsed clusters" — many distinct readings jammed into the SAME
 *      second. A real CGM reports every few minutes, so >3 readings inside
 *      one second is physically impossible. The whole offending second is
 *      deleted (mirrors the app's client-side guard).
 *
 *   2. Exact duplicates — more than one reading sharing the exact same
 *      (userId, deviceId, readingAt). One is kept, the rest deleted. This
 *      must run before the unique index on those fields can build.
 *
 * SAFE BY DEFAULT: dry run unless you pass --apply.
 *
 *   node src/scripts/cleanupCollapsedReadings.js              # preview only
 *   node src/scripts/cleanupCollapsedReadings.js --apply      # actually delete
 *   node src/scripts/cleanupCollapsedReadings.js --apply --threshold 3
 */

import "../config/env.js";
import mongoose from "mongoose";
import CGMReading from "../modules/cgmReading/cgmReading.model.js";

const APPLY = process.argv.includes("--apply");
const thArgIdx = process.argv.indexOf("--threshold");
const THRESHOLD =
  thArgIdx !== -1 ? Number(process.argv[thArgIdx + 1]) : 3;

async function findCollapsedIds() {
  // Group by user + device + second-of-readingAt; flag buckets that exceed
  // the threshold and collect every reading id in them.
  const groups = await CGMReading.aggregate([
    {
      $group: {
        _id: {
          userId: "$userId",
          deviceId: "$deviceId",
          second: {
            $floor: {
              $divide: [{ $toLong: "$readingAt" }, 1000],
            },
          },
        },
        count: { $sum: 1 },
        ids: { $push: "$_id" },
      },
    },
    { $match: { count: { $gt: THRESHOLD } } },
  ]);

  const ids = [];
  for (const g of groups) ids.push(...g.ids);
  return { ids, buckets: groups.length };
}

async function findExactDuplicateIds() {
  // Group by exact (userId, deviceId, readingAt); keep the first id, mark the
  // rest for deletion.
  const groups = await CGMReading.aggregate([
    {
      $group: {
        _id: {
          userId: "$userId",
          deviceId: "$deviceId",
          readingAt: "$readingAt",
        },
        count: { $sum: 1 },
        ids: { $push: "$_id" },
      },
    },
    { $match: { count: { $gt: 1 } } },
  ]);

  const ids = [];
  for (const g of groups) ids.push(...g.ids.slice(1)); // keep one
  return { ids, groups: groups.length };
}

async function main() {
  if (!process.env.MONGO_URI) {
    console.error("MONGO_URI is not set (check your .env).");
    process.exit(1);
  }

  await mongoose.connect(process.env.MONGO_URI);
  console.log("Connected to MongoDB");

  const total = await CGMReading.estimatedDocumentCount();
  console.log(`Total readings: ${total}`);

  const collapsed = await findCollapsedIds();
  console.log(
    `Collapsed clusters (>${THRESHOLD}/sec): ${collapsed.buckets} bucket(s), ` +
      `${collapsed.ids.length} reading(s)`
  );

  // Dedup the remaining exact-duplicate timestamps too (so the unique index
  // can build). Skip ids already slated for collapsed deletion.
  const collapsedSet = new Set(collapsed.ids.map((i) => i.toString()));
  const dupes = await findExactDuplicateIds();
  const dupeIds = dupes.ids.filter(
    (i) => !collapsedSet.has(i.toString())
  );
  console.log(
    `Exact duplicate timestamps: ${dupes.groups} group(s), ` +
      `${dupeIds.length} extra reading(s) to remove`
  );

  const toDelete = [...collapsed.ids, ...dupeIds];
  console.log(`\nTotal to delete: ${toDelete.length}`);

  if (toDelete.length === 0) {
    console.log("Nothing to clean. ✅");
  } else if (!APPLY) {
    console.log(
      "\nDRY RUN — nothing deleted. Re-run with --apply to delete."
    );
  } else {
    const res = await CGMReading.deleteMany({
      _id: { $in: toDelete },
    });
    console.log(`\nDeleted ${res.deletedCount} reading(s). ✅`);
  }

  await mongoose.disconnect();
  process.exit(0);
}

main().catch(async (err) => {
  console.error(err);
  try {
    await mongoose.disconnect();
  } catch {}
  process.exit(1);
});
