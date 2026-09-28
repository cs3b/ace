import { boundMessage } from "./types.mjs";

/**
 * Delivers wake messages with per-source coalescing.
 *
 * A wake is delivered through the injected queue port only; the dispatcher
 * never interprets the message or triggers work itself. While a source has a
 * wake queued (delivered but not yet settled), repeated triggers for the same
 * source coalesce into the pending one. Distinct sources never coalesce.
 *
 * The adapter settles sources when Pi reports the agent fully settled, so a
 * busy agent receives at most one queued follow-up per source per run cycle.
 */
export class WakeDispatcher {
  /** @private @type {(sourceKey: string, text: string) => boolean} */
  #deliver;

  /** @private @type {Set<string>} */
  pending = new Set();

  /**
   * @param {object} ports
   * @param {(sourceKey: string, text: string) => boolean} ports.deliver
   *   Queue the wake for the source. Returns true when Pi accepted it.
   */
  constructor({ deliver }) {
    this.#deliver = deliver;
  }

  /**
   * Queue a wake for the source, coalescing while one is already pending.
   *
   * @param {string} sourceKey Stable source identity, e.g. "loop:heartbeat".
   * @param {string} text Wake text; bounded before delivery.
   * @returns {{delivered: boolean, reason?: string}}
   */
  wake(sourceKey, text) {
    if (this.pending.has(sourceKey)) {
      return { delivered: false, reason: "coalesced" };
    }

    const accepted = this.#deliver(sourceKey, boundMessage(text));
    if (!accepted) {
      return { delivered: false, reason: "rejected" };
    }

    this.pending.add(sourceKey);
    return { delivered: true };
  }

  /**
   * Mark one source's queued wake as consumed.
   *
   * @param {string} sourceKey
   */
  settle(sourceKey) {
    this.pending.delete(sourceKey);
  }

  /** Mark every source's queued wake as consumed (agent fully settled). */
  settleAll() {
    this.pending.clear();
  }

  /**
   * @param {string} sourceKey
   * @returns {boolean}
   */
  isPending(sourceKey) {
    return this.pending.has(sourceKey);
  }
}
