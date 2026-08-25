import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, fireEvent, act } from "@testing-library/react";
import { RecognitionPhase } from "./RecognitionPhase";

vi.mock("../lib/dataWriter", () => ({
  writeRow: vi.fn().mockResolvedValue({ ok: true }),
}));

import { writeRow } from "../lib/dataWriter";

const items = [
  {
    item_id: 33,
    category: "verb",
    irish_target: "tabhair",
    english_gloss: "to give/grant",
    english_gloss_alternatives: ["to give", "grant"],
    word_length: 7,
    freq_rank: 24,
  },
  {
    item_id: 39,
    category: "verb",
    irish_target: "éirigh",
    english_gloss: "to get up/to rise",
    english_gloss_alternatives: ["to get up", "to rise"],
    word_length: 6,
    freq_rank: 101,
  },
];

beforeEach(() => {
  vi.clearAllMocks();
});

async function flush() {
  await act(async () => {
    await new Promise((resolve) => setTimeout(resolve, 0));
  });
}

async function submitCurrentTrial(responseText) {
  fireEvent.change(screen.getByLabelText(/what this word means/i), { target: { value: responseText } });
  fireEvent.click(screen.getByRole("button", { name: /submit/i }));
  await flush();
}

describe("RecognitionPhase", () => {
  it("shows the Irish target and records a match against an unlisted-'to' alternative", async () => {
    const onComplete = vi.fn();
    render(<RecognitionPhase items={items} participantId="p1" onComplete={onComplete} />);

    expect(screen.getByText("tabhair")).toBeInTheDocument();
    await submitCurrentTrial("grant");

    expect(writeRow).toHaveBeenCalledWith(
      "trials",
      expect.objectContaining({ item_id: 33, phase: "recognition", live_match_result: true })
    );
  });

  it("matches when 'to' is stripped from a dual-'to' alternative set", async () => {
    const onComplete = vi.fn();
    render(<RecognitionPhase items={[items[1]]} participantId="p1" onComplete={onComplete} />);

    await submitCurrentTrial("rise");

    expect(writeRow).toHaveBeenCalledWith(
      "trials",
      expect.objectContaining({ item_id: 39, live_match_result: true })
    );
    expect(onComplete).toHaveBeenCalledTimes(1);
  });

  it("advances through all items and calls onComplete once after the last", async () => {
    const onComplete = vi.fn();
    render(<RecognitionPhase items={items} participantId="p1" onComplete={onComplete} />);

    await submitCurrentTrial("grant");
    expect(screen.getByText("éirigh")).toBeInTheDocument();
    await submitCurrentTrial("an unlisted wrong answer");

    expect(onComplete).toHaveBeenCalledTimes(1);
    expect(writeRow).toHaveBeenCalledTimes(2);
  });
});
