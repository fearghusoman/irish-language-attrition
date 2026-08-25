import { useEffect, useRef, useState } from "react";

/**
 * A visible countdown timer that calls onExpire once when it reaches zero.
 * Starts fresh on mount — the caller is responsible for remounting (via a
 * `key` prop, not a resetKey argument here) when a new trial should get its
 * own fresh countdown rather than continuing one already in progress.
 *
 * onExpire is read from a ref that's updated on every render (not just once
 * on mount), so it always sees the latest closure — e.g. the participant's
 * current in-progress response text — even though the countdown effect
 * itself only runs once.
 */
export function useCountdownTimer(durationMs, onExpire) {
  const [remainingMs, setRemainingMs] = useState(durationMs);
  const startedAtRef = useRef(null);
  const expiredRef = useRef(false);
  const onExpireRef = useRef(onExpire);
  onExpireRef.current = onExpire;

  useEffect(() => {
    startedAtRef.current = performance.now();
    expiredRef.current = false;
    setRemainingMs(durationMs);

    let frameId;

    function tick() {
      const elapsed = performance.now() - startedAtRef.current;
      const remaining = Math.max(0, durationMs - elapsed);
      setRemainingMs(remaining);

      if (remaining <= 0) {
        if (!expiredRef.current) {
          expiredRef.current = true;
          onExpireRef.current();
        }
        return;
      }
      frameId = requestAnimationFrame(tick);
    }

    frameId = requestAnimationFrame(tick);
    return () => cancelAnimationFrame(frameId);
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [durationMs]);

  function getElapsedMs() {
    if (startedAtRef.current === null) return 0;
    return Math.min(durationMs, Math.round(performance.now() - startedAtRef.current));
  }

  return { remainingMs, getElapsedMs };
}
