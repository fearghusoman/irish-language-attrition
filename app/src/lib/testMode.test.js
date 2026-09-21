import { describe, it, expect, afterEach, vi } from "vitest";
import { isTestModeEnabled, selectWordlist } from "./testMode";

const FULL_WORDLIST = [
  { item_id: 1, english_gloss: "house" },
  { item_id: 2, english_gloss: "woman" },
  { item_id: 25, english_gloss: "care/attention" },
  { item_id: 33, english_gloss: "to give/grant" },
  { item_id: 39, english_gloss: "to get up/to rise" },
  { item_id: 50, english_gloss: "tall/high" },
  { item_id: 60, english_gloss: "old" },
];

afterEach(() => {
  vi.unstubAllEnvs();
});

describe("isTestModeEnabled", () => {
  it("is false when VITE_TEST_MODE is unset", () => {
    expect(isTestModeEnabled()).toBe(false);
  });

  it("is true only when VITE_TEST_MODE is exactly 'true'", () => {
    vi.stubEnv("VITE_TEST_MODE", "true");
    expect(isTestModeEnabled()).toBe(true);
  });

  it("is false for any other value", () => {
    vi.stubEnv("VITE_TEST_MODE", "1");
    expect(isTestModeEnabled()).toBe(false);
  });
});

describe("selectWordlist", () => {
  it("returns the full wordlist unchanged when test mode is off", () => {
    expect(selectWordlist(FULL_WORDLIST)).toBe(FULL_WORDLIST);
  });

  it("filters to the curated default item IDs when test mode is on", () => {
    vi.stubEnv("VITE_TEST_MODE", "true");
    const result = selectWordlist(FULL_WORDLIST);
    expect(result.map((i) => i.item_id).sort((a, b) => a - b)).toEqual([1, 25, 33, 39, 50]);
  });

  it("respects VITE_TEST_ITEM_IDS as an override", () => {
    vi.stubEnv("VITE_TEST_MODE", "true");
    vi.stubEnv("VITE_TEST_ITEM_IDS", "2, 60");
    const result = selectWordlist(FULL_WORDLIST);
    expect(result.map((i) => i.item_id)).toEqual([2, 60]);
  });
});
