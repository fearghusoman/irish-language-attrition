import { describe, it, expect, vi } from "vitest";
import { render, screen, fireEvent } from "@testing-library/react";
import { SchemaForm } from "./SchemaForm";

describe("SchemaForm", () => {
  it("blocks submission and shows an error when a required field is empty", () => {
    const onSubmit = vi.fn();
    render(
      <SchemaForm
        fields={[{ key: "age", type: "number", label: "Age", min: 18, max: 120 }]}
        onSubmit={onSubmit}
      />
    );

    fireEvent.click(screen.getByRole("button", { name: /continue/i }));

    expect(onSubmit).not.toHaveBeenCalled();
    expect(screen.getByRole("alert")).toHaveTextContent("Age");
  });

  it("submits values keyed by field key, coerced to the right type", () => {
    const onSubmit = vi.fn();
    render(
      <SchemaForm
        fields={[{ key: "age", type: "number", label: "Age", min: 18, max: 120 }]}
        onSubmit={onSubmit}
      />
    );

    fireEvent.change(screen.getByRole("spinbutton"), { target: { value: "34" } });
    fireEvent.click(screen.getByRole("button", { name: /continue/i }));

    expect(onSubmit).toHaveBeenCalledWith({ age: 34 });
  });

  it("hides a dependent field until its condition is met, and does not require it while hidden", () => {
    const onSubmit = vi.fn();
    render(
      <SchemaForm
        fields={[
          {
            key: "gaeltacht_contact",
            type: "boolean",
            label: "Gaeltacht contact?",
          },
          {
            key: "gaeltacht_contact_context",
            type: "text",
            label: "Context",
            required: false,
            dependsOn: (values) => values.gaeltacht_contact === true,
          },
        ]}
        onSubmit={onSubmit}
      />
    );

    expect(screen.queryByLabelText(/context/i)).not.toBeInTheDocument();

    fireEvent.click(screen.getAllByRole("radio", { name: "Yes" })[0]);
    expect(screen.getByText("Context")).toBeInTheDocument();

    fireEvent.click(screen.getByRole("button", { name: /continue/i }));
    expect(onSubmit).toHaveBeenCalledWith({ gaeltacht_contact: true, gaeltacht_contact_context: undefined });
  });

  it("toggles multiselect values on and off", () => {
    const onSubmit = vi.fn();
    render(
      <SchemaForm
        fields={[
          {
            key: "current_use_contexts",
            type: "multiselect",
            label: "Contexts",
            options: [
              { value: "work", label: "Work" },
              { value: "family", label: "Family" },
            ],
          },
        ]}
        onSubmit={onSubmit}
      />
    );

    fireEvent.click(screen.getByRole("checkbox", { name: "Work" }));
    fireEvent.click(screen.getByRole("checkbox", { name: "Family" }));
    fireEvent.click(screen.getByRole("checkbox", { name: "Work" })); // toggle off

    fireEvent.click(screen.getByRole("button", { name: /continue/i }));
    expect(onSubmit).toHaveBeenCalledWith({ current_use_contexts: ["family"] });
  });

  it("records a likert score 1-5", () => {
    const onSubmit = vi.fn();
    render(
      <SchemaForm
        fields={[{ key: "integrative_q21", type: "likert", prompt: "I felt connected." }]}
        onSubmit={onSubmit}
      />
    );

    fireEvent.click(screen.getByRole("radio", { name: /4 — Agree/ }));
    fireEvent.click(screen.getByRole("button", { name: /continue/i }));

    expect(onSubmit).toHaveBeenCalledWith({ integrative_q21: 4 });
  });
});
