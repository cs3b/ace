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
 * Truncate a wake message to the bounded length, marking the cut.
 *
 * @param {string} text
 * @returns {string}
 */
export function boundMessage(text) {
  const trimmed = text.trim();
  if (trimmed.length <= MAX_WAKE_MESSAGE_CHARS) {
    return trimmed;
  }
  return `${trimmed.slice(0, MAX_WAKE_MESSAGE_CHARS)}… [ace-wake: message truncated]`;
}
