import { useState } from "react";

function isVisible(field, values) {
  if (!field.dependsOn) return true;
  return field.dependsOn(values);
}

function isEmpty(value) {
  return value === undefined || value === null || value === "" || (Array.isArray(value) && value.length === 0);
}

function isRequired(field, values) {
  if (typeof field.required === "function") return field.required(values);
  if (field.required === false) return false;
  return true;
}

function toggleInArray(array, value) {
  const current = array ?? [];
  return current.includes(value) ? current.filter((v) => v !== value) : [...current, value];
}

const AGREEMENT_LABELS = ["Strongly disagree", "Disagree", "Neutral", "Agree", "Strongly agree"];

function FieldRenderer({ field, value, onChange }) {
  switch (field.type) {
    case "number":
      return (
        <input
          type="number"
          min={field.min}
          max={field.max}
          value={value ?? ""}
          onChange={(e) => onChange(e.target.value === "" ? "" : Number(e.target.value))}
        />
      );

    case "text":
      return (
        <input
          type="text"
          value={value ?? ""}
          onChange={(e) => onChange(e.target.value)}
        />
      );

    case "boolean":
      return (
        <div className="choice-group choice-group--segmented" role="radiogroup" aria-label={field.label}>
          {[
            { label: "Yes", val: true },
            { label: "No", val: false },
          ].map(({ label, val }) => (
            <label key={label} className="choice-option">
              <input
                type="radio"
                name={field.key}
                checked={value === val}
                onChange={() => onChange(val)}
              />
              <span className="choice-option-body">{label}</span>
            </label>
          ))}
        </div>
      );

    case "select":
      return (
        <select value={value ?? ""} onChange={(e) => onChange(e.target.value)}>
          <option value="" disabled>
            Select…
          </option>
          {field.options.map((opt) => (
            <option key={opt.value} value={opt.value}>
              {opt.label}
            </option>
          ))}
        </select>
      );

    case "multiselect":
      return (
        <div className="choice-group">
          {field.options.map((opt) => (
            <label key={opt.value} className="choice-option">
              <input
                type="checkbox"
                checked={(value ?? []).includes(opt.value)}
                onChange={() => onChange(toggleInArray(value, opt.value))}
              />
              <span className="choice-option-body">{opt.label}</span>
            </label>
          ))}
        </div>
      );

    case "likert":
      return (
        <div className="choice-group choice-group--segmented" role="radiogroup" aria-label={field.prompt ?? field.label}>
          {AGREEMENT_LABELS.map((label, i) => {
            const score = i + 1;
            return (
              <label key={score} className="choice-option">
                <input
                  type="radio"
                  name={field.key}
                  checked={value === score}
                  onChange={() => onChange(score)}
                />
                <span className="choice-option-body">
                  {score} — {label}
                </span>
              </label>
            );
          })}
        </div>
      );

    case "scale5":
      return (
        <div className="choice-group choice-group--segmented" role="radiogroup" aria-label={field.prompt ?? field.label}>
          {field.scaleLabels.map((label, i) => {
            const score = i + 1;
            return (
              <label key={score} className="choice-option">
                <input
                  type="radio"
                  name={field.key}
                  checked={value === score}
                  onChange={() => onChange(score)}
                />
                <span className="choice-option-body">
                  {score} — {label}
                </span>
              </label>
            );
          })}
        </div>
      );

    default:
      throw new Error(`Unknown field type: ${field.type}`);
  }
}

/**
 * Renders a questionnaire Part from a declarative field schema and collects
 * values keyed exactly by the target Postgres column name, so the caller can
 * pass the submitted object straight into a row insert.
 */
export function SchemaForm({ title, fields, onSubmit, submitLabel = "Continue" }) {
  const [values, setValues] = useState({});
  const [error, setError] = useState(null);

  function setValue(key, value) {
    setValues((prev) => ({ ...prev, [key]: value }));
  }

  function handleSubmit(event) {
    event.preventDefault();

    for (const field of fields) {
      if (!isVisible(field, values)) continue;
      if (isRequired(field, values) && isEmpty(values[field.key])) {
        setError(`Please answer: "${field.label ?? field.prompt}"`);
        return;
      }
    }

    setError(null);
    onSubmit(values);
  }

  return (
    <form className="schema-form" onSubmit={handleSubmit}>
      {title && <h2>{title}</h2>}
      {fields.map((field) =>
        isVisible(field, values) ? (
          <div className="schema-form-field" key={field.key}>
            {(field.label || field.prompt) && <p className="field-prompt">{field.label ?? field.prompt}</p>}
            <FieldRenderer field={field} value={values[field.key]} onChange={(v) => setValue(field.key, v)} />
          </div>
        ) : null
      )}
      {error && (
        <p role="alert" className="form-error">
          {error}
        </p>
      )}
      <button type="submit">{submitLabel}</button>
    </form>
  );
}
