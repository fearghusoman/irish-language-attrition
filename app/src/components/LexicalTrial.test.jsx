import { describe, it, expect, vi, beforeEach, afterEach } from "vitest";
import { render, screen, fireEvent, act } from "@testing-library/react";
import { LexicalTrial } from "./LexicalTrial";

describe("LexicalTrial", () => {
  beforeEach(() => {
    vi.useFakeTimers();
  });

  afterEach(() => {
    vi.useRealTimers();
  });

  it("submits the typed response with timedOut=false on manual submit", () => {
    const onSubmit = vi.fn();
    render(<LexicalTrial promptWord="house" instructionText="Type the Irish word" onSubmit={onSubmit} />);

    fireEvent.change(screen.getByLabelText(/Type the Irish word/i), {
      target: { value: "teach" },
    });
    fireEvent.click(screen.getByRole("button", { name: /submit/i }));

    expect(onSubmit).toHaveBeenCalledTimes(1);
    expect(onSubmit.mock.calls[0][0]).toMatchObject({ responseText: "teach", timedOut: false });
  });

  it("auto-submits as a timeout after 20 seconds with no input", () => {
    const onSubmit = vi.fn();
    render(<LexicalTrial promptWord="woman" instructionText="Type the Irish word" onSubmit={onSubmit} />);

    act(() => {
      vi.advanceTimersByTime(20100);
    });

    expect(onSubmit).toHaveBeenCalledTimes(1);
    expect(onSubmit.mock.calls[0][0]).toMatchObject({ responseText: "", timedOut: true });
  });

  it("never calls onSubmit twice (manual submit right at expiry)", () => {
    const onSubmit = vi.fn();
    render(<LexicalTrial promptWord="school" instructionText="Type the Irish word" onSubmit={onSubmit} />);

    act(() => {
      vi.advanceTimersByTime(20100);
    });
    fireEvent.click(screen.getByRole("button", { name: /submit/i }));

    expect(onSubmit).toHaveBeenCalledTimes(1);
  });

  it("resets the input when remounted with a new key (as a parent switching trials would)", () => {
    const onSubmit = vi.fn();
    const { rerender } = render(
      <LexicalTrial key="recall:1" promptWord="house" instructionText="Type the Irish word" onSubmit={onSubmit} />
    );
    fireEvent.change(screen.getByLabelText(/Type the Irish word/i), {
      target: { value: "teach" },
    });

    rerender(
      <LexicalTrial key="recall:2" promptWord="woman" instructionText="Type the Irish word" onSubmit={onSubmit} />
    );

    expect(screen.getByLabelText(/Type the Irish word/i).value).toBe("");
  });
});
