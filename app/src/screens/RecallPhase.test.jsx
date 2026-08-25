import { describe, it, expect, vi, beforeEach } from "vitest";
import { render, screen, fireEvent, act } from "@testing-library/react";
import { RecallPhase } from "./RecallPhase";

vi.mock("../lib/dataWriter", () => ({
  writeRow: vi.fn().mockResolvedValue({ ok: true }),
}));

function makeItems(count) {
  return Array.from({ length: count }, (_, i) => ({
    item_id: i + 1,
    category: "concrete_noun",
    irish_target: `focal${i + 1}`,
    english_gloss: `word${i + 1}`,
    english_gloss_alternatives: [`word${i + 1}`],
    word_length: 6,
    freq_rank: 100,
  }));
}

// handleSubmit is async (it awaits the mocked writeRow), so the resulting
// state update lands on a later microtask than fireEvent.click itself —
// flush explicitly rather than asserting immediately after the click.
async function flush() {
  await act(async () => {
    await new Promise((resolve) => setTimeout(resolve, 0));
  });
}

async function submitCurrentTrial(responseText) {
  fireEvent.change(screen.getByLabelText(/type the irish word/i), { target: { value: responseText } });
  fireEvent.click(screen.getByRole("button", { name: /submit/i }));
  await flush();
}

// Submits the current trial, then clicks through the break screen if one appears
// (it's an expected, valid state at the halfway point, not something every test cares about).
async function submitAndAdvance(responseText) {
  await submitCurrentTrial(responseText);
  const breakContinue = screen.queryByRole("button", { name: /^continue$/i });
  if (breakContinue) fireEvent.click(breakContinue);
}

beforeEach(() => {
  vi.clearAllMocks();
});

describe("RecallPhase", () => {
  it("shows a break screen at the halfway point, then resumes on the next item", async () => {
    const items = makeItems(4); // break after item 2
    const onComplete = vi.fn();
    render(<RecallPhase items={items} participantId="p1" onComplete={onComplete} />);

    await submitCurrentTrial("focal1");
    await submitCurrentTrial("focal2");

    expect(screen.getByText(/halfway there/i)).toBeInTheDocument();
    expect(screen.getByText(/completed 2 of 4/i)).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /continue/i }));
    expect(screen.getByText("word3")).toBeInTheDocument();
  });

  it("accumulates non-matching items into the recognition queue passed to onComplete", async () => {
    const items = makeItems(2);
    const onComplete = vi.fn();
    render(<RecallPhase items={items} participantId="p1" onComplete={onComplete} />);

    await submitAndAdvance("focal1"); // correct match
    await submitAndAdvance("wrong answer"); // no match -> queued for recognition

    expect(onComplete).toHaveBeenCalledTimes(1);
    const queue = onComplete.mock.calls[0][0];
    expect(queue).toHaveLength(1);
    expect(queue[0].item_id).toBe(2);
  });

  it("calls onComplete with an empty queue when every item is recalled correctly", async () => {
    const items = makeItems(2);
    const onComplete = vi.fn();
    render(<RecallPhase items={items} participantId="p1" onComplete={onComplete} />);

    await submitAndAdvance("focal1");
    await submitAndAdvance("focal2");

    expect(onComplete).toHaveBeenCalledWith([]);
  });
});
