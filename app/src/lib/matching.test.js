import { describe, it, expect } from "vitest";
import { stripFadas, checkRecallMatch, checkRecognitionMatch } from "./matching";

describe("stripFadas", () => {
  it("strips all five Irish fada characters", () => {
    expect(stripFadas("áéíóú")).toBe("aeiou");
  });

  it("leaves non-fada characters untouched", () => {
    expect(stripFadas("teach")).toBe("teach");
  });
});

describe("checkRecallMatch", () => {
  it("matches an exact response", () => {
    expect(checkRecallMatch("teach", "teach")).toBe(true);
  });

  it("matches when the participant omits a fada", () => {
    expect(checkRecallMatch("scriobh", "scríobh")).toBe(true);
  });

  it("matches when the target has multiple fadas and response has none", () => {
    expect(checkRecallMatch("eirigh", "éirigh")).toBe(true);
  });

  it("is case-insensitive and trims whitespace", () => {
    expect(checkRecallMatch("  Teach  ", "teach")).toBe(true);
  });

  it("rejects a blank response", () => {
    expect(checkRecallMatch("", "teach")).toBe(false);
    expect(checkRecallMatch("   ", "teach")).toBe(false);
  });

  it("rejects an incorrect response", () => {
    expect(checkRecallMatch("bean", "teach")).toBe(false);
  });

  it("does not accept edit-distance-close typos (that's post-hoc manual review, not live)", () => {
    expect(checkRecallMatch("teac", "teach")).toBe(false);
  });
});

describe("checkRecognitionMatch", () => {
  it("matches a plain single-alternative gloss", () => {
    expect(checkRecognitionMatch("house", ["house"])).toBe(true);
  });

  it("accepts the response with or without a leading 'to' for a verb target", () => {
    expect(checkRecognitionMatch("put", ["to put"])).toBe(true);
    expect(checkRecognitionMatch("to put", ["to put"])).toBe(true);
  });

  it("accepts any listed alternative, not just the first", () => {
    expect(checkRecognitionMatch("attention", ["care", "attention"])).toBe(true);
    expect(checkRecognitionMatch("path", ["way", "path"])).toBe(true);
  });

  it("strips 'to ' independently per alternative when more than one carries it", () => {
    // real item from the wordlist: "to get up/to rise"
    const alternatives = ["to get up", "to rise"];
    expect(checkRecognitionMatch("get up", alternatives)).toBe(true);
    expect(checkRecognitionMatch("rise", alternatives)).toBe(true);
    expect(checkRecognitionMatch("to rise", alternatives)).toBe(true);
  });

  it("does not require 'to' on an alternative that never had one", () => {
    // real item: "to give/grant" — second alternative has no leading "to"
    const alternatives = ["to give", "grant"];
    expect(checkRecognitionMatch("grant", alternatives)).toBe(true);
    expect(checkRecognitionMatch("give", alternatives)).toBe(true);
  });

  it("does not catch unlisted synonyms (by design — that's manual review)", () => {
    expect(checkRecognitionMatch("route", ["way", "path"])).toBe(false);
  });

  it("rejects a blank response", () => {
    expect(checkRecognitionMatch("", ["house"])).toBe(false);
  });
});
