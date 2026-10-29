import { boundMessage } from "./types.js";

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
 * Pending entries keep their message text so a delivery boundary that never
 * sees a settlement (e.g. manual compaction rejecting prompts without an
 * extension-visible signal) can reconcile unacknowledged attempts.
 */
export class WakeDispatcher {
  /** @private @type {(sourceKey: string, text: string) => boolean} */
  #deliver;

  /** @private @type {Map<string, string>} */
  pending = new Map();

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

    const bounded = boundMessage(text);
    const accepted = this.#deliver(sourceKey, bounded);
    if (!accepted) {
      return { delivered: false, reason: "rejected" };
    }

    this.pending.set(sourceKey, bounded);
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
   * Pending wake attempts as [sourceKey, text] pairs, for reconciliation at
   * delivery boundaries that bypass the normal settlement signal.
   *
   * @returns {Array<[string, string]>}
   */
  pendingEntries() {
    return [...this.pending.entries()];
  }

  /**
   * @param {string} sourceKey
   * @returns {boolean}
   */
  isPending(sourceKey) {
    return this.pending.has(sourceKey);
  }
}
