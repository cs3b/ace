import {
  LOOP_SOURCE_PREFIX,
  MAX_NAME_CHARS,
  WATCH_SOURCE_PREFIX,
  WakeError,
} from "./types.js";

/**
 * Session-owned store of named loop and watch subscriptions.
 *
 * The registry owns definitions and their runtime handles. Host capabilities
 * arrive as injected ports:
 *
 * - `loops` / `watches`: subscription ports owning native interval and
 *   filesystem-watcher handles (`start(def, handlers)`, `stop(name)`,
 *   `stopAll()`, `errorOf(name)`).
 * - `state`: persistence port (`load()` / `save(snapshot)`).
 * - `status`: reporting port (`render(snapshot)`).
 * - `dispatcher`: wake dispatcher (queue-only delivery with coalescing).
 *
 * Reconciliation is idempotent: prior runtime handles are disposed first,
 * then exactly one native handle is registered per persisted definition.
 * Loops schedule their next interval from "now"; no missed ticks are replayed
 * after reload or restart.
 */
export class WakeRegistry {
  /** @private @type {object} */
  #loops;
  /** @private @type {object} */
  #watches;
  /** @private @type {object} */
  #state;
  /** @private @type {object} */
  #status;
  /** @private @type {import("./wake-dispatcher.js").WakeDispatcher} */
  #dispatcher;
  /** @private @type {boolean} */
  #retaining;
  /** @private @type {boolean} */
  #resuming;
  /** @private @type {Map<string, {prefix: string, name: string, message: string}>} */
  #retained;
  /** @private @type {boolean} */
  #dispatchPending;
  /** @private @type {Timeout | undefined} */
  #dispatchRecoveryTimer;
  /** @private @type {number} */
  #dispatchRecoveryMs;
  /** @private @type {Timeout | undefined} */
  #recoveryTimer;
  /** @private @type {Timeout | undefined} */
  #dirtyRetryTimer;
  /** @private @type {boolean} */
  #deliveryUnresolved;
  /** @private @type {Set<string>} */
  #inFlightWatchNames;
  /** @private @type {(() => boolean) | undefined} */
  #isHostQueued;
  /** @private @type {(() => boolean) | undefined} */
  #isHostIdle;
  /** @private @type {boolean} */
  #disposed;

  /** @private @type {{retained: Array<{prefix: string, name: string, message: string}>, stranded: Array<[string, string]>} | undefined} */
  #reconcileBatch;
  /** @private @type {import("./types.js").WakeSnapshot | undefined} */
  #loaded;

  /**
   * @param {object} ports
   * @param {object} ports.loops
   * @param {object} ports.watches
   * @param {object} ports.state
   * @param {object} ports.status
   * @param {import("./wake-dispatcher.js").WakeDispatcher} ports.dispatcher
   */
  constructor({ loops, watches, state, status, dispatcher, dispatchRecoveryMs = 5000, isHostQueued, isHostIdle }) {
    this.#loops = loops;
    this.#watches = watches;
    this.#state = state;
    this.#status = status;
    this.#dispatcher = dispatcher;
    /** @private @type {boolean} */
    this.#retaining = false;
    /** @private @type {boolean} */
    this.#resuming = false;
    /** @private @type {Map<string, {prefix: string, name: string, message: string}>} */
    this.#retained = new Map();
    /** @private @type {boolean} */
    this.#dispatchPending = false;
    /** @private @type {Timeout | undefined} */
    this.#dispatchRecoveryTimer;
    /** @private @type {number} */
    this.#dispatchRecoveryMs = dispatchRecoveryMs;
    /** @private @type {boolean} */
    this.#deliveryUnresolved = false;
    /** @private @type {Timeout | undefined} */
    this.#dirtyRetryTimer = undefined;
    /** @private @type {Set<string>} */
    this.#inFlightWatchNames = new Set();
    /** @private @type {(() => boolean) | undefined} */
    this.#isHostQueued = isHostQueued;
    /** @private @type {(() => boolean) | undefined} */
    this.#isHostIdle = isHostIdle;
    /** @private @type {boolean} */
    this.#disposed = false;
  }

  /**
   * Register a named recurring timer.
   *
   * @param {{name: string, intervalSeconds: number, message: string}} input
   * @returns {import("./types.js").LoopDefinition}
   */
  addLoop(input) {
    const name = requireName(input.name, "loop");
    const intervalSeconds = requireInterval(input.intervalSeconds);
    const message = requireMessage(input.message);

    if (this.#snapshot.loops.some((loop) => loop.name === name)) {
      throw new WakeError(`loop "${name}" already exists; remove it before re-adding`);
    }

    const definition = { kind: "loop", name, intervalSeconds, message };
    this.#snapshot.loops.push(definition);
    this.#loops.start(definition, () => this.#fire(LOOP_SOURCE_PREFIX, name, definition.message));
    this.#persist();
    return definition;
  }

  /**
   * Register a named filesystem watch.
   *
   * @param {{name: string, path: string, message: string}} input
   * @returns {import("./types.js").WatchDefinition}
   */
  addWatch(input) {
    const name = requireName(input.name, "watch");
    const path = requireWatchPath(input.path);
    const message = requireMessage(input.message);

    if (this.#snapshot.watches.some((watch) => watch.name === name)) {
      throw new WakeError(`watch "${name}" already exists; remove it before re-adding`);
    }

    const definition = { kind: "watch", name, path, message };
    // The watch port validates readability, takes its baseline, and resolves
    // the configured path to a canonical absolute path — an unreadable or
    // invalid path fails the command loudly before anything is persisted.
    definition.path = this.#watches.start(
      definition,
      () => this.#fire(WATCH_SOURCE_PREFIX, name, definition.message),
    );

    this.#snapshot.watches.push(definition);
    this.#persist();
    return definition;
  }

  /**
   * Remove a loop and stop its future wakes.
   *
   * @param {string} name
   */
  removeLoop(name) {
    const removed = removeByName(this.#snapshot.loops, name, "loop");
    this.#loops.stop(name);
    this.#dispatcher.settle(loopSourceKey(name));
    this.#retained.delete(loopSourceKey(name));
    this.#dropFromReconcileBatch(loopSourceKey(name));
    this.#persist();
    return removed;
  }

  /**
   * Remove a watch and stop its future wakes.
   *
   * @param {string} name
   */
  removeWatch(name) {
    const removed = removeByName(this.#snapshot.watches, name, "watch");
    this.#watches.stop(name);
    this.#dispatcher.settle(watchSourceKey(name));
    this.#retained.delete(watchSourceKey(name));
    this.#dropFromReconcileBatch(watchSourceKey(name));
    this.#persist();
    return removed;
  }

  /**
   * Immutable view of definitions plus runtime state for commands and UI.
   *
   * @returns {Array<object>}
   */
  list() {
    const entries = [];
    for (const loop of this.#snapshot.loops) {
      entries.push({
        kind: "loop",
        name: loop.name,
        detail: `${loop.intervalSeconds}s`,
        message: loop.message,
        pending: this.#dispatcher.isPending(loopSourceKey(loop.name)),
        error: this.#loops.errorOf(loop.name),
      });
    }
    for (const watch of this.#snapshot.watches) {
      entries.push({
        kind: "watch",
        name: watch.name,
        detail: watch.path,
        message: watch.message,
        pending: this.#dispatcher.isPending(watchSourceKey(watch.name)),
        error: this.#watches.errorOf(watch.name),
      });
    }
    return entries;
  }

  /**
   * Re-register exactly one native handle per persisted definition. Prior
   * handles are disposed first, so reload or restart never duplicates timers
   * and never replays missed ticks. A subscription that fails to restart
   * (e.g. its watched path vanished) records a visible inactive-error state
   * and never blocks the remaining subscriptions.
   */
  reconcile() {
    this.#loops.stopAll();
    this.#watches.stopAll();

    for (const loop of this.#snapshot.loops) {
      this.#loops.start(loop, () => this.#fire(LOOP_SOURCE_PREFIX, loop.name, loop.message));
    }
    for (const watch of this.#snapshot.watches) {
      try {
        this.#watches.start(
          watch,
          () => this.#fire(WATCH_SOURCE_PREFIX, watch.name, watch.message),
        );
      } catch (error) {
        const message = error instanceof Error ? error.message : String(error);
        this.#watches.fail(watch.name, `could not restart watch: ${message}`);
      }
    }
    this.#refreshStatus();
  }

  /**
   * Re-render the visible subscription status; ports invoke this when runtime
   * state changes outside a registry call (e.g. a watch deactivates itself).
   */
  refreshStatus() {
    this.#refreshStatus();
  }

  /** Dispose all runtime handles; persisted definitions remain for reload. */
  dispose() {
    this.#retaining = false;
    this.#resuming = false;
    this.#disposed = true;
    this.#deliveryUnresolved = false;
    this.#dispatchPending = false;
    clearTimeout(this.#recoveryTimer);
    clearTimeout(this.#dirtyRetryTimer);
    this.#retained.clear();
    this.#reconcileBatch = undefined;
    this.#loops.stopAll();
    this.#watches.stopAll();
    this.#status.render([]);
  }

  /**
   * Clear pending wake markers after the agent fully settled, then re-check
   * watches whose change was absorbed by a pending wake: their state still
   * differs from the last delivered fingerprint, so they wake again without
   * needing another filesystem event.
   */
  settleAll() {
    // A settlement is proof the host accepts prompts again; a manual
    // compaction that is still resuming completes its boundary here so the
    // stranded attempts reconcile instead of being silently cleared.
    this.#deliveryUnresolved = false;
    if (this.#resuming) {
      this.completeResume();
    } else {
      this.#dispatcher.settleAll();
      this.#closeDispatchWindow();
    }
    this.#drainRetained();
    this.#watches.flushDirty((watch) => this.#fire(WATCH_SOURCE_PREFIX, watch.name, watch.message));
    this.#refreshStatus();
  }

  /**
   * Retain wakes instead of dispatching while the host cannot accept them
   * (manual compaction rejects sendUserMessage asynchronously — before, during,
   * and after the compaction events — which would otherwise strand the source
   * pending forever, since manual compaction never emits agent_settled).
   */
  pauseDelivery() {
    this.#retaining = true;
  }

  /**
   * Mark the compaction events as finished. Pi may still reject prompts while
   * later session_compact handlers complete, so retention stays on and the
   * boundary is taken by completeResume() — either when the readiness poll
   * observes an idle context or at the next settlement.
   */
  resumeDelivery() {
    this.#resuming = true;
  }

  /**
   * Take the resume boundary atomically: every pending marker and retained
   * wake at this moment is reconciled in one batch, and delivery returns to
   * normal. Idempotent — without a pending boundary it is a no-op.
   */
  completeResume() {
    if (!this.#resuming) {
      return;
    }
    this.#resuming = false;
    this.#retaining = false;
    clearTimeout(this.#dispatchRecoveryTimer);
    this.#dispatchPending = false;
    this.#reconcileBatch = {
      retained: [...this.#retained.values()],
      stranded: this.#dispatcher.pendingEntries(),
    };
    this.#retained.clear();
    this.#dispatcher.settleAll();
    this.flushRetained();
    this.#watches.flushDirty((watch) => this.#fire(WATCH_SOURCE_PREFIX, watch.name, watch.message));
    this.#refreshStatus();
  }

  /**
   * Dispatch the reconciliation batch captured at the last resume boundary:
   * retained wakes plus stranded pre-boundary attempts. Consumed exactly
   * once — later calls are no-ops, so a flush can never replay wakes that
   * were legitimately re-queued after the boundary.
   */
  flushRetained() {
    const batch = this.#reconcileBatch;
    if (!batch || (batch.retained.length === 0 && batch.stranded.length === 0)) {
      return;
    }
    this.#reconcileBatch = undefined;
    for (const wake of batch.retained) {
      this.#fire(wake.prefix, wake.name, wake.message);
    }
    for (const [sourceKey, text] of batch.stranded) {
      // Replay through #dispatch so concurrent stranded sources serialize
      // across the idle-to-running transition instead of racing it.
      const separator = sourceKey.indexOf(":");
      this.#dispatch(sourceKey.slice(0, separator + 1), sourceKey.slice(separator + 1), text);
    }
    this.#refreshStatus();
  }

  /**
   * A removed subscription's wake must never fire from a pending resume
   * batch, so removal strips it from the reconciliation boundary.
   *
   * @param {string} sourceKey
   */
  #dropFromReconcileBatch(sourceKey) {
    const batch = this.#reconcileBatch;
    if (!batch) {
      return;
    }
    batch.retained = batch.retained.filter((wake) => `${wake.prefix}${wake.name}` !== sourceKey);
    batch.stranded = batch.stranded.filter(([key]) => key !== sourceKey);
  }

  /** Load persisted definitions from the session state port. */
  load() {
    this.#snapshot = this.#state.load();
  }

  #fire(sourcePrefix, name, message) {
    try {
      const outcome = this.#dispatch(sourcePrefix, name, message);
      this.#refreshStatus();
      return outcome;
    } catch {
      // Timer and watcher callbacks can outlive their host context (session
      // replacement, reload, or disposal invalidates the captured context
      // without running session_shutdown). A stale context must never crash
      // the callback, and a runtime that can no longer deliver should not
      // keep ticking: defuse all handles until the next session_start
      // re-registers them.
      this.#loops.stopAll();
      this.#watches.stopAll();
      return { delivered: false, reason: "stale" };
    }
  }

  #dispatch(sourcePrefix, name, message) {
    const sourceKey = `${sourcePrefix}${name}`;
    if (this.#dispatcher.isPending(sourceKey)) {
      // Same-source repeats coalesce regardless of the transition window.
      return { delivered: false, reason: "coalesced" };
    }
    const blocked = this.#retaining || this.#dispatchPending;
    if (blocked && sourcePrefix === WATCH_SOURCE_PREFIX) {
      // Watch changes must never queue as bare messages: marking the
      // subscription dirty defers delivery to flushDirty(), which re-stats
      // and wakes with the latest state at the next settlement boundary —
      // no lost changes, no duplicate replays.
      this.#watches.markDirty(name);
      return { delivered: false, reason: "deferred" };
    }
    if (this.#retaining) {
      this.#retained.set(sourceKey, { prefix: sourcePrefix, name, message });
      return { delivered: false, reason: "retained" };
    }
    if (this.#dispatchPending) {
      // A previous wake is still crossing the idle-to-running transition;
      // Pi rejects concurrent prompts asynchronously, so this source waits
      // to enter the follow-up queue safely (agent_start) or until the
      // transition window expires.
      this.#retained.set(sourceKey, { prefix: sourcePrefix, name, message });
      return { delivered: false, reason: "serialized" };
    }
    const outcome = this.#dispatcher.wake(sourceKey, message);
    if (!outcome.delivered) {
      // A refused watch wake (no model selected, broken authentication) has
      // no next tick, settlement, or lifecycle event to retry it: without a
      // timer the change would wait for an unrelated filesystem event.
      // Still-refused retries re-arm the timer when they fire.
      if (sourcePrefix === WATCH_SOURCE_PREFIX && outcome.reason === "rejected") {
        this.#scheduleDirtyWatchRetry();
      }
      return outcome;
    }
    if (this.#hostIsActive()) {
      // A run is already active: deliverAs: "followUp" is queue-safe by Pi's
      // contract, so no serialization window arms. The window exists only
      // for the idle-to-running transition, where concurrent sends race
      // Pi's asynchronous prompt preparation — and no agent_start ever
      // fires for follow-ups queued behind an active run to close one.
      // Unrelated sources deliver immediately instead of waiting for that
      // run's settlement.
      return outcome;
    }
    if (sourcePrefix === WATCH_SOURCE_PREFIX) {
      this.#inFlightWatchNames.add(name);
    }
    this.#markDispatchInFlight();
    return outcome;
  }

  /**
   * Whether the host reports a run already in progress. The serialization
   * window guards only the idle-to-running transition; delivery into an
   * active run is queue-safe and needs no window and no recovery tracking.
   */
  #hostIsActive() {
    if (!this.#isHostIdle) {
      return false;
    }
    try {
      return !this.#isHostIdle();
    } catch {
      return false;
    }
  }

  /**
   * Bounded retry for watch changes whose dispatch was refused: loops retry
   * on their next tick, but a watch has no future trigger of its own, so
   * this timer is the only thing standing between a refused change and its
   * delivery once the refusal cause clears (e.g. a model gets selected).
   * One attempt per recovery window, deduplicated; disposal cancels it. No
   * duplicate risk: a refused wake was never accepted, so its fingerprint
   * never advanced and the retry is a first delivery, not a replay.
   */
  #scheduleDirtyWatchRetry() {
    if (this.#disposed || this.#dirtyRetryTimer) {
      return;
    }
    this.#dirtyRetryTimer = setTimeout(() => {
      this.#dirtyRetryTimer = undefined;
      if (this.#disposed) {
        return;
      }
      this.#watches.flushDirty((watch) => this.#fire(WATCH_SOURCE_PREFIX, watch.name, watch.message));
      this.#refreshStatus();
    }, this.#dispatchRecoveryMs);
    this.#dirtyRetryTimer.unref?.();
  }

  /**
   * An unacknowledged watch attempt must not read as delivered: revert its
   * fingerprint to the last delivered state and mark it dirty so the next
   * settlement re-fires the change.
   */
  #revertInFlightWatchAttempts() {
    if (this.#inFlightWatchNames.size === 0) {
      return;
    }
    this.#watches.revertToDelivered([...this.#inFlightWatchNames]);
    this.#inFlightWatchNames.clear();
  }

  #closeDispatchWindow() {
    clearTimeout(this.#dispatchRecoveryTimer);
    this.#dispatchPending = false;
    this.#drainRetained();
  }


  /**
   * The host started a run: concurrent sends now queue safely as follow-ups,
   * so the serialization window closes and retained wakes drain immediately.
   */
  noteRunStarted() {
    this.#deliveryUnresolved = false;
    this.#inFlightWatchNames.clear();
    this.#dispatchPending = false;
    this.#drainRetained();
  }

  #markDispatchInFlight() {
    // The dispatch stays in flight until a lifecycle transition confirms
    // delivery: agent_start proves the prompt entered a run (concurrent
    // sends queue safely as follow-ups from then on), and any settlement
    // proves the host accepts prompts again.
    this.#dispatchPending = true;
    clearTimeout(this.#recoveryTimer);
    this.#recoveryTimer = setTimeout(() => this.recoverUnacknowledgedDispatch(), this.#dispatchRecoveryMs);
    this.#recoveryTimer.unref?.();
  }

  /**
   * Recovery for attempts no lifecycle transition ever acknowledged: Pi's
   * void sendUserMessage API reports preflight failures (no model, broken
   * authentication) only asynchronously, and no signal distinguishes a
   * rejected attempt from one whose startup hooks are slow. Wake semantics
   * prefer redelivery over loss — a duplicate is a repeated bounded message
   * the agent can ignore, a lost duty wake is a silent miss — so recovery
   * releases the in-flight state: serialization opens, pending markers
   * clear, and watch changes re-fire from their latest state at the next
   * settlement. Retry cadence stays bounded by the recovery window.
   */
  recoverUnacknowledgedDispatch() {
    if (this.#disposed || !this.#dispatchPending) {
      return;
    }
    let queued = true;
    let idle = false;
    try {
      // The discriminators the void API still provides: an accepted wake
      // sits in Pi's queue (pendingMessages true) until processing consumes
      // it, and while anything runs the context is not idle. Both signals
      // must agree that nothing is queued and nothing is running before an
      // attempt is treated as rejected — an empty queue during active
      // processing is a consumed follow-up, and an idle context during
      // asynchronous startup hooks is an unresolved submission.
      queued = this.#isHostQueued?.() ?? true;
      idle = this.#isHostIdle?.() ?? false;
    } catch {
      queued = true;
      idle = false;
    }
    if (queued || !idle) {
      // Legitimate: queued for later or actively processing. Re-check after
      // another window; the run's own settlement settles the marker.
      this.#scheduleRecovery();
      return;
    }
    this.#dispatchPending = false;
    this.#dispatcher.settleAll();
    this.#revertInFlightWatchAttempts();
    this.#watches.flushDirty((watch) => this.#fire(WATCH_SOURCE_PREFIX, watch.name, watch.message));
    this.#refreshStatus();
  }

  #scheduleRecovery() {
    clearTimeout(this.#dispatchRecoveryTimer);
    this.#dispatchRecoveryTimer = setTimeout(() => this.recoverUnacknowledgedDispatch(), this.#dispatchRecoveryMs);
    this.#dispatchRecoveryTimer.unref?.();
  }

  #drainRetained() {
    const entries = [...this.#retained.values()];
    this.#retained.clear();
    for (const wake of entries) {
      try {
        this.#dispatcher.wake(`${wake.prefix}${wake.name}`, wake.message);
      } catch {
        // Draining must never crash the releasing callback.
      }
    }
  }

  #persist() {
    this.#state.save({
      loops: this.#snapshot.loops.map((loop) => ({ ...loop })),
      watches: this.#snapshot.watches.map((watch) => ({ ...watch })),
    });
    this.#refreshStatus();
  }

  #refreshStatus() {
    this.#status.render(this.list());
  }

  get #snapshot() {
    if (this.#loaded === undefined) {
      this.#loaded = this.#state.load();
    }
    return this.#loaded;
  }

  set #snapshot(value) {
    this.#loaded = value;
  }
}

/**
 * @param {string} value
 * @param {string} kind
 * @returns {string}
 */
export function requireName(value, kind) {
  const name = typeof value === "string" ? value.trim() : "";
  if (!name) {
    throw new WakeError(`${kind} name must not be empty`);
  }
  if (/\s/.test(name)) {
    throw new WakeError(`${kind} name must not contain whitespace`);
  }
  if (name.length > MAX_NAME_CHARS) {
    throw new WakeError(`${kind} name must be at most ${MAX_NAME_CHARS} characters, got ${name.length}`);
  }
  return name;
}

/**
 * Largest interval the host timer layer supports: node:timers clamps delays
 * above 2^31 - 1 milliseconds down to 1 millisecond, which would turn an
 * over-large interval into a wake storm, so it is rejected instead.
 *
 * @constant {number}
 */
export const MAX_INTERVAL_SECONDS = (2 ** 31 - 1) / 1000;

/**
 * @param {unknown} value
 * @returns {number}
 */
export function requireInterval(value) {
  const interval = typeof value === "string" ? Number(value) : value;
  if (typeof interval !== "number" || !Number.isFinite(interval) || interval <= 0) {
    throw new WakeError(`interval must be a finite number of seconds greater than 0, got ${JSON.stringify(value ?? null)}`);
  }
  if (interval > MAX_INTERVAL_SECONDS) {
    throw new WakeError(`interval must be at most ${MAX_INTERVAL_SECONDS} seconds (~24.9 days), got ${JSON.stringify(value)}`);
  }
  return interval;
}

/**
 * @param {unknown} value
 * @returns {string}
 */
export function requireMessage(value) {
  const message = typeof value === "string" ? value.trim() : "";
  if (!message) {
    throw new WakeError("message must not be empty");
  }
  return message;
}

/**
 * @param {unknown} value
 * @returns {string}
 */
export function requireWatchPath(value) {
  const path = typeof value === "string" ? value.trim() : "";
  if (!path) {
    throw new WakeError("path must not be empty");
  }
  return path;
}

/**
 * @param {Array<{name: string}>} definitions
 * @param {string} name
 * @param {string} kind
 */
function removeByName(definitions, name, kind) {
  const index = definitions.findIndex((definition) => definition.name === name);
  if (index === -1) {
    throw new WakeError(`unknown ${kind}: ${name}`);
  }
  return definitions.splice(index, 1)[0];
}

/** @param {string} name */
export function loopSourceKey(name) {
  return `${LOOP_SOURCE_PREFIX}${name}`;
}

/** @param {string} name */
export function watchSourceKey(name) {
  return `${WATCH_SOURCE_PREFIX}${name}`;
}
