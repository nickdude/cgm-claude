import CGMReading from "./cgmReading.model.js";

import CGMDevice from "../cgmDevice/cgmDevice.model.js";

// Resolves the user's active CGM device and flips WARMUP → ACTIVE once the
// 60-min warmup window has elapsed. Shared by the single + bulk write paths.
async function resolveActiveDevice(userId) {
  const activeDevice = await CGMDevice.findOne({
    userId,
    status: { $in: ["WARMUP", "ACTIVE"] },
  });

  if (!activeDevice) {
    throw new Error("No active CGM device found");
  }

  const now = new Date();

  const warmupCompleted =
    now - activeDevice.warmupStartedAt >= 60 * 60 * 1000;

  if (warmupCompleted && !activeDevice.isWarmupCompleted) {
    activeDevice.isWarmupCompleted = true;
    activeDevice.status = "ACTIVE";
    activeDevice.activatedAt = now;
    await activeDevice.save();
  }

  return activeDevice;
}

// Builds the idempotency filter for one reading. Prefer the sensor's native
// key (sensorSerial, sequenceNumber) — stable across reconnects/restarts — and
// fall back to (userId, deviceId, readingAt) only when the client sent no
// sequence (e.g. an older app build).
function readingFilter(userId, device, payload) {
  if (payload.sequenceNumber != null && payload.sensorSerial) {
    return {
      sensorSerial: payload.sensorSerial,
      sequenceNumber: payload.sequenceNumber,
    };
  }

  return {
    userId,
    deviceId: device._id,
    readingAt: payload.readingAt || new Date(),
  };
}

function upsertUpdate(userId, device, payload) {
  return {
    $set: {
      glucoseValue: payload.glucoseValue,
      trend: payload.trend,
      readingAt: payload.readingAt || new Date(),
    },
    $setOnInsert: {
      userId,
      deviceId: device._id,
      sensorSerial: payload.sensorSerial,
      sequenceNumber: payload.sequenceNumber,
    },
  };
}

export const addReadingService = async (userId, payload) => {
  const device = await resolveActiveDevice(userId);

  try {
    return await CGMReading.findOneAndUpdate(
      readingFilter(userId, device, payload),
      upsertUpdate(userId, device, payload),
      { upsert: true, new: true, setDefaultsOnInsert: true }
    );
  } catch (err) {
    // A stale legacy (userId, deviceId, readingAt) unique index can still exist
    // in the DB and collide when a backfilled reading's real time coincides
    // with an old now-stamped row. The reading is effectively already stored —
    // treat the duplicate-key error as an idempotent success.
    if (err && err.code === 11000) {
      return await CGMReading.findOne(readingFilter(userId, device, payload));
    }
    throw err;
  }
};

// Bulk idempotent upsert for the reconnect backfill — one round-trip for the
// whole sensor buffer instead of N sequential POSTs. Returns the stored rows
// for the synced sequences so the client can render from the backend.
export const addReadingsBulkService = async (userId, readings) => {
  if (!Array.isArray(readings) || readings.length === 0) return [];

  const device = await resolveActiveDevice(userId);

  const ops = readings.map((p) => ({
    updateOne: {
      filter: readingFilter(userId, device, p),
      update: upsertUpdate(userId, device, p),
      upsert: true,
    },
  }));

  try {
    // ordered:false → a single duplicate doesn't abort the rest of the batch.
    await CGMReading.bulkWrite(ops, { ordered: false });
  } catch (err) {
    // bulkWrite throws an aggregate error even when only duplicate-key (11000)
    // failures occurred and every non-dup op was already applied. Rethrow only
    // if something other than a duplicate-key error happened.
    const writeErrors = err?.writeErrors || [];
    const nonDup = writeErrors.filter(
      (e) => (e.err?.code ?? e.code) !== 11000
    );
    const isPureDupError =
      err?.code === 11000 ||
      (writeErrors.length > 0 && nonDup.length === 0);
    if (!isPureDupError) {
      throw err;
    }
  }

  const seqs = readings
    .map((p) => p.sequenceNumber)
    .filter((s) => s != null);

  const serials = [
    ...new Set(readings.map((p) => p.sensorSerial).filter(Boolean)),
  ];

  if (seqs.length && serials.length) {
    return await CGMReading.find({
      sensorSerial: { $in: serials },
      sequenceNumber: { $in: seqs },
    }).sort({ readingAt: 1 });
  }

  return [];
};

// Restart-safe checkpoint: the highest sequence number the backend has stored
// for this sensor. The client requests everything after it on reconnect.
export const getCheckpointService = async (userId, sensorSerial) => {
  const top = await CGMReading.findOne({
    userId,
    sensorSerial,
    sequenceNumber: { $exists: true },
  })
    .sort({ sequenceNumber: -1 })
    .select("sequenceNumber readingAt");

  return {
    maxSequence: top?.sequenceNumber ?? 0,
    lastReadingAt: top?.readingAt ?? null,
  };
};

export const getReadingsService = async (userId) => {
  return await CGMReading.find({
    userId,
  }).sort({
    readingAt: -1,
  });
};
