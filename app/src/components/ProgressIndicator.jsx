export function ProgressIndicator({ current, total, label }) {
  const percent = Math.max(0, Math.min(100, Math.round((current / total) * 100)));

  return (
    <div className="progress-indicator">
      <div className="progress-indicator-track">
        <div className="progress-indicator-fill" style={{ width: `${percent}%` }} />
      </div>
      <p className="progress-indicator-label" role="status">
        {label ?? `Item ${current} of ${total}`}
      </p>
    </div>
  );
}
