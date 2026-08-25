import { describe, it, expect, vi, beforeEach } from "vitest";

vi.mock("./supabaseClient", () => ({
  supabase: { from: vi.fn() },
}));

import { supabase } from "./supabaseClient";
import { writeRow, flushPendingWrites, loadPendingQueue } from "./dataWriter";

function mockInsertResult(errorOnCallIndexes = new Set()) {
  let callIndex = 0;
  const insert = vi.fn(() => {
    const error = errorOnCallIndexes.has(callIndex) ? { message: "insert failed" } : null;
    callIndex += 1;
    return Promise.resolve({ error });
  });
  supabase.from.mockReturnValue({ insert });
  return insert;
}

beforeEach(() => {
  vi.clearAllMocks();
  sessionStorage.clear();
});

describe("writeRow", () => {
  it("succeeds on the first attempt without retrying", async () => {
    const insert = mockInsertResult();
    const result = await writeRow("trials", { participant_id: "p1" });
    expect(result).toEqual({ ok: true });
    expect(insert).toHaveBeenCalledTimes(1);
    expect(loadPendingQueue()).toEqual([]);
  });

  it("retries on transient failure and succeeds", async () => {
    const insert = mockInsertResult(new Set([0])); // fail once, then succeed
    const result = await writeRow("trials", { participant_id: "p1" });
    expect(result).toEqual({ ok: true });
    expect(insert).toHaveBeenCalledTimes(2);
    expect(loadPendingQueue()).toEqual([]);
  });

  it("queues the row for later after exhausting retries", async () => {
    mockInsertResult(new Set([0, 1, 2]));
    const row = { participant_id: "p1", item_id: 1 };
    const result = await writeRow("trials", row);
    expect(result).toEqual({ ok: false, queued: true });

    const queue = loadPendingQueue();
    expect(queue).toHaveLength(1);
    expect(queue[0].table).toBe("trials");
    expect(queue[0].row).toEqual(row);
  });

  it("resolves (never rejects) when the network call itself throws, and still queues", async () => {
    const insert = vi.fn(() => Promise.reject(new TypeError("Failed to fetch")));
    supabase.from.mockReturnValue({ insert });

    const row = { participant_id: "p1" };
    // Must not throw — a caller doing `await writeRow(...)` should always get a
    // result back, never an unhandled rejection that leaves it stuck forever.
    const result = await writeRow("questionnaire_part2", row);

    expect(result).toEqual({ ok: false, queued: true });
    expect(loadPendingQueue()).toEqual([{ table: "questionnaire_part2", row, queuedAt: expect.any(Number) }]);
  });
});

describe("flushPendingWrites", () => {
  it("is a no-op when the queue is empty", async () => {
    await flushPendingWrites();
    expect(supabase.from).not.toHaveBeenCalled();
  });

  it("retries queued rows and clears them on success", async () => {
    mockInsertResult(new Set([0, 1, 2])); // force writeRow to queue
    await writeRow("trials", { participant_id: "p1" });
    expect(loadPendingQueue()).toHaveLength(1);

    mockInsertResult(); // subsequent flush succeeds
    await flushPendingWrites();
    expect(loadPendingQueue()).toEqual([]);
  });

  it("leaves rows queued if the flush attempt also fails", async () => {
    mockInsertResult(new Set([0, 1, 2]));
    await writeRow("trials", { participant_id: "p1" });

    mockInsertResult(new Set([0]));
    await flushPendingWrites();
    expect(loadPendingQueue()).toHaveLength(1);
  });
});
