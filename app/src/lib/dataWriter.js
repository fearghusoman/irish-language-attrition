import { supabase } from "./supabaseClient";

const QUEUE_STORAGE_KEY = "irish-attrition:pending-writes";
const MAX_ATTEMPTS = 3;
const RETRY_BASE_DELAY_MS = 400;

function sleep(ms) {
  return new Promise((resolve) => setTimeout(resolve, ms));
}

export function loadPendingQueue() {
  try {
    const raw = sessionStorage.getItem(QUEUE_STORAGE_KEY);
    return raw ? JSON.parse(raw) : [];
  } catch {
    return [];
  }
}

function savePendingQueue(queue) {
  try {
    sessionStorage.setItem(QUEUE_STORAGE_KEY, JSON.stringify(queue));
  } catch {
    // sessionStorage unavailable (private browsing quota, etc.) — best-effort only.
  }
}

function enqueuePending(table, row) {
  const queue = loadPendingQueue();
  queue.push({ table, row, queuedAt: Date.now() });
  savePendingQueue(queue);
}

async function insertOnce(table, row) {
  try {
    // Deliberately no .select() chained: PostgREST's default is `Prefer: return=minimal`
    // for inserts, which is required here since none of our tables grant anon a SELECT
    // policy — chaining .select() would ask for the row back and fail under that RLS setup.
    const { error } = await supabase.from(table).insert(row);
    if (error) console.error(`[dataWriter] insert into "${table}" failed:`, error);
    return error;
  } catch (thrown) {
    // A rejected/thrown promise (network failure, DNS error, etc.) — as opposed to
    // Supabase resolving with an { error } response — must still surface as a
    // regular "there was an error" result. Letting this propagate uncaught would
    // reject writeRow()'s promise entirely, leaving the caller's `await writeRow(...)`
    // stuck forever with no retry, no queueing, and no visible failure to the user.
    console.error(`[dataWriter] insert into "${table}" threw:`, thrown);
    return thrown;
  }
}

/**
 * Writes a single row with retry-with-backoff. If all attempts fail (e.g. the
 * participant is briefly offline), the row is queued in sessionStorage and
 * retried later via flushPendingWrites() — this bounds data loss on a crash/
 * tab-close to "written but not yet flushed", not "never captured at all".
 */
export async function writeRow(table, row) {
  for (let attempt = 1; attempt <= MAX_ATTEMPTS; attempt += 1) {
    const error = await insertOnce(table, row);
    if (!error) return { ok: true };
    if (attempt < MAX_ATTEMPTS) await sleep(RETRY_BASE_DELAY_MS * attempt);
  }
  enqueuePending(table, row);
  return { ok: false, queued: true };
}

/**
 * Retries any writes stashed by a previous failed writeRow() call. Safe to call
 * on app mount and on the browser 'online' event; a no-op when the queue is empty.
 */
export async function flushPendingWrites() {
  const queue = loadPendingQueue();
  if (queue.length === 0) return;

  const stillPending = [];
  for (const item of queue) {
    const error = await insertOnce(item.table, item.row);
    if (error) stillPending.push(item);
  }
  savePendingQueue(stillPending);
}
