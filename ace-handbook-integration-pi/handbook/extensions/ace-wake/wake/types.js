// Shared contracts for the ace-wake Pi extension.
//
// The extension wakes a Pi agent through queue/sendUserMessage only. It never
// executes tasks, never spawns external timers or services, and never injects
// text into an in-flight tool operation. Host capabilities (clock, interval
// scheduling, filesystem watching, message queueing, session state, status
// reporting) are injected as plain function ports so the registry can be
// tested deterministically without Pi.

/** Prefix for wake source keys originating from a named loop. */
export const LOOP_SOURCE_PREFIX = "loop:";

/** Prefix for wake source keys originating from a named watch. */
export const WATCH_SOURCE_PREFIX = "watch:";

/** Hard upper bound for a delivered wake message, in characters. */
export const MAX_WAKE_MESSAGE_CHARS = 4000;

/** Upper bound for a subscription name, in characters. */
export const MAX_NAME_CHARS = 64;

/** customType used for pi.appendEntry persistence of wake definitions. */
export const SESSION_ENTRY_TYPE = "ace-wake";

/**
 * A configured recurring timer.
 *
 * @typedef {object} LoopDefinition
 * @property {string} name Unique within loop subscriptions for the session.
 * @property {number} intervalSeconds Finite number greater than zero.
 * @property {string} message Wake text delivered on each fire.
 */

/**
 * A configured filesystem watch.
 *
 * @typedef {object} WatchDefinition
 * @property {string} name Unique within watch subscriptions for the session.
 * @property {string} path Canonical absolute path of the watched file.
 * @property {string} message Wake text delivered on change.
 */

/**
 * One changed target of a watch wake: the watched path, the change kind, the
 * BEFORE→AFTER change signatures, and — when the file content was readable —
 * a short capped sanitized excerpt of the new content.
 *
 * @typedef {object} WatchDelta
 * @property {string} path Absolute path of the changed target.
 * @property {"created" | "modified" | "deleted"} kind Change kind.
 * @property {string} before Signature of the last delivered state.
 * @property {string} after Signature of the current state.
 * @property {string} [excerpt] Sanitized single-line head of the new content.
 */

/**
 * Persisted session snapshot handed to the state port.
 *
 * @typedef {object} WakeSnapshot
 * @property {LoopDefinition[]} loops
 * @property {WatchDefinition[]} watches
 */

/**
 * Raised for user-facing validation and lookup failures.
 */
export class WakeError extends Error {
  /**
   * @param {string} message
   */
  constructor(message) {
    super(message);
    this.name = "WakeError";
  }
}

/**
 * Truncate a message to the bounded length, reserving space for the
 * truncation marker so the delivered message never exceeds the bound.
 *
 * @param {string} text
 * @returns {string}
 */
export function boundMessage(text) {
  const trimmed = text.trim();
  const marker = "… [ace-wake: message truncated]";
  if (trimmed.length <= MAX_WAKE_MESSAGE_CHARS) {
    return trimmed;
  }
  return `${trimmed.slice(0, MAX_WAKE_MESSAGE_CHARS - marker.length)}${marker}`;
}

/**
 * Append the watch change delta to a watch wake message: one line per changed
 * target with path, change kind, and BEFORE→AFTER signatures, plus an
 * `excerpt:` line when the file content was readable. Loop wakes and watch
 * wakes without a delta keep the bare message.
 *
 * @param {string} message
 * @param {Array<WatchDelta>} deltas
 * @returns {string}
 */
export function formatWatchDelta(message, deltas) {
  if (!Array.isArray(deltas) || deltas.length === 0) {
    return message;
  }
  const lines = deltas.map((delta) => {
    const head = `changed: ${delta.path} (${delta.kind}) ${delta.before} → ${delta.after}`;
    return delta.excerpt === undefined ? head : `${head}\nexcerpt: ${delta.excerpt}`;
  });
  return `${message}\n${lines.join("\n")}`;
}
