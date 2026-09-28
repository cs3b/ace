import {
  LOOP_SOURCE_PREFIX,
  WATCH_SOURCE_PREFIX,
  WakeError,
} from "./types.mjs";

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
  /** @private @type {import("./wake-dispatcher.mjs").WakeDispatcher} */
  #dispatcher;
  /** @private @type {import("./types.mjs").WakeSnapshot | undefined} */
  #loaded;

  /**
   * @param {object} ports
   * @param {object} ports.loops
   * @param {object} ports.watches
   * @param {object} ports.state
   * @param {object} ports.status
   * @param {import("./wake-dispatcher.mjs").WakeDispatcher} ports.dispatcher
   */
  constructor({ loops, watches, state, status, dispatcher }) {
    this.#loops = loops;
    this.#watches = watches;
    this.#state = state;
    this.#status = status;
    this.#dispatcher = dispatcher;
  }

  /**
   * Register a named recurring timer.
   *
   * @param {{name: string, intervalSeconds: number, message: string}} input
   * @returns {import("./types.mjs").LoopDefinition}
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
   * @returns {import("./types.mjs").WatchDefinition}
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
   * and never replays missed ticks.
   */
  reconcile() {
    this.#loops.stopAll();
    this.#watches.stopAll();

    for (const loop of this.#snapshot.loops) {
      this.#loops.start(loop, () => this.#fire(LOOP_SOURCE_PREFIX, loop.name, loop.message));
    }
    for (const watch of this.#snapshot.watches) {
      this.#watches.start(
        watch,
        () => this.#fire(WATCH_SOURCE_PREFIX, watch.name, watch.message),
      );
    }
    this.#refreshStatus();
  }

  /** Dispose all runtime handles; persisted definitions remain for reload. */
  dispose() {
    this.#loops.stopAll();
    this.#watches.stopAll();
    this.#status.render([]);
  }

  /** Clear pending wake markers after the agent fully settled. */
  settleAll() {
    this.#dispatcher.settleAll();
    this.#refreshStatus();
  }

  /** Load persisted definitions from the session state port. */
  load() {
    this.#snapshot = this.#state.load();
  }

  #fire(sourcePrefix, name, message) {
    this.#dispatcher.wake(`${sourcePrefix}${name}`, message);
    this.#refreshStatus();
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
  return name;
}

/**
 * @param {unknown} value
 * @returns {number}
 */
export function requireInterval(value) {
  const interval = typeof value === "string" ? Number(value) : value;
  if (typeof interval !== "number" || !Number.isFinite(interval) || interval <= 0) {
    throw new WakeError(`interval must be a finite number of seconds greater than 0, got ${JSON.stringify(value ?? null)}`);
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
