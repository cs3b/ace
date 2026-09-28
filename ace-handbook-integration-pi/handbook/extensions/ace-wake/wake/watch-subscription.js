import * as nodeFs from "node:fs";
import * as nodePath from "node:path";
import { WakeError } from "./types.js";

/**
 * Resolve a configured watch path to the filesystem target: relative paths
 * resolve against `baseDir`, and an existing symlinked path resolves to its
 * target so directory events match the watched file's real name.
 *
 * @param {string} baseDir
 * @param {string} path
 * @returns {string}
 */
export function canonicalizeWatchPath(baseDir, path) {
  const resolved = nodePath.resolve(baseDir, path);
  try {
    return nodeFs.realpathSync(resolved);
  } catch {
    // A nonexistent path cannot be canonicalized; stat validation in start()
    // reports the visible error instead.
    return resolved;
  }
}

/**
 * Watch subscription port owning native filesystem watcher handles.
 *
 * start() resolves the configured path to a canonical absolute target (relative
 * paths resolve against `baseDir`; symlinks resolve to their target), validates
 * readable metadata, and records a baseline fingerprint. Only later fingerprint
 * changes wake the agent, so registering a watch never produces an initial
 * wake. When a wake coalesces into one already queued, the fingerprint stays
 * at the previously delivered state: the queued wake covers the change, and a
 * further change queues a fresh follow-up after settlement.
 *
 * A watcher runtime error (path deleted, permission lost) closes the handle,
 * marks the subscription inactive with a visible error via the injected
 * `onDeactivate` hook, and never retries: the user removes and re-adds the
 * watch explicitly. `fail()` records the same inactive-error state without a
 * native handle, which reconciliation uses for subscriptions that could not
 * be restarted.
 *
 * @param {object} ports
 * @param {(path: string, handlers: {onChange: () => void, onError: (error: Error) => void}) => {close: () => void}} ports.watchFactory
 * @param {(path: string) => {mtimeMs: number, size: number}} ports.statFn
 * @param {string} [ports.baseDir] Resolution base for relative watch paths.
 * @param {(baseDir: string, path: string) => string} [ports.canonicalizeFn] Path canonicalization; defaults to resolve + realpath.
 * @param {(reconcile: () => void) => unknown} [ports.scheduleReconcile] Schedules
 *   the post-registration reconcile pass. Native watcher initialization is
 *   asynchronous on some platforms, so a change landing in the registration
 *   gap may produce no callback; the reconcile re-stats once and wakes on a
   * missed change. Defaults to a delayed macrotask.
 * @param {() => void} [ports.onDeactivate] Invoked when a subscription leaves
 *   the active state so callers can refresh visible status.
 * @returns {{
 *   start: (definition: import("./types.js").WatchDefinition, onWake: (definition: import("./types.js").WatchDefinition) => {delivered: boolean, reason?: string} | undefined) => string,
 *   stop: (name: string) => void,
 *   stopAll: () => void,
 *   fail: (name: string, message: string) => void,
 *   errorOf: (name: string) => string | undefined,
 *   activeCount: () => number,
 * }}
 */
const RECONCILE_DELAY_MS = 500;

export function createWatchPort({ watchFactory, statFn, baseDir = process.cwd(), canonicalizeFn = canonicalizeWatchPath, scheduleReconcile = defaultScheduleReconcile, onDeactivate }) {
  /** @type {Map<string, {watcher: {close: () => void}, canonicalPath: string, definition: import("./types.js").WatchDefinition, fingerprint: string, previousFingerprint: string, dirty: boolean}>} */
  const active = new Map();
  /** @type {Map<string, string>} */
  const errors = new Map();

  return {
    /**
     * @returns {string} The canonical absolute path being watched.
     */
    start(definition, onWake) {
      stopExisting(definition.name);
      errors.delete(definition.name);

      const canonicalPath = canonicalizeFn(baseDir, definition.path);
      const baseline = readBaseline(canonicalPath);
      const fingerprint = fingerprintOf(baseline);
      const watcher = watchFactory(canonicalPath, {
        onChange: () => handleChange(definition, onWake),
        onError: (error) => {
          // A callback from a removed registration must never touch its
          // replacement.
          if (active.get(definition.name)?.definition !== definition) {
            return;
          }
          deactivate(definition.name, describeError(error));
        },
      });

      active.set(definition.name, { watcher, canonicalPath, definition, fingerprint, previousFingerprint: fingerprint, dirty: false });
      // Close the registration gap: a change between baseline capture and
      // watcher effectiveness produces no callback, so re-stat once.
      scheduleReconcile(() => handleChange(definition, onWake));
      return canonicalPath;
    },

    stop(name) {
      stopExisting(name);
      errors.delete(name);
    },

    stopAll() {
      for (const name of [...active.keys()]) {
        stopExisting(name);
      }
      errors.clear();
    },

    /**
     * Re-check subscriptions whose change was absorbed by a pending wake.
     * Called after the agent settles (pending markers cleared): a subscription
     * whose current state still differs from its last delivered fingerprint
     * fires a fresh wake — no new filesystem event required.
     *
     * @param {(definition: import("./types.js").WatchDefinition) => {delivered: boolean, reason?: string} | undefined} onWake
     */
    flushDirty(onWake) {
      for (const entry of active.values()) {
        if (!entry.dirty) {
          continue;
        }
        const current = readBaselineOrError(entry.canonicalPath, entry.definition.name);
        if (current === undefined) {
          continue;
        }
        const next = fingerprintOf(current);
        if (next === entry.fingerprint) {
          entry.dirty = false;
          continue;
        }
        const outcome = onWake(entry.definition);
        // The fingerprint advances only when the wake actually crossed —
        // a deferred outcome stays dirty for the next settlement boundary.
        if (outcome && outcome.delivered === false) {
          entry.dirty = true;
          continue;
        }
        entry.previousFingerprint = entry.fingerprint;
        entry.fingerprint = next;
        entry.dirty = false;
      }
    },

    /**
     * Mark a subscription's latest change as undelivered so flushDirty()
     * re-checks it at the next settlement boundary. Used when a wake is
     * deferred by retention or the dispatch serialization window.
     *
     * @param {string} name
     */
    markDirty(name) {
      const entry = active.get(name);
      if (entry) {
        entry.dirty = true;
      }
    },

    /**
     * Record a visible inactive-error state for a subscription without a
     * native handle (used by reconciliation for watches that cannot restart).
     *
     * @param {string} name
     * @param {string} message
     */
    fail(name, message) {
      stopExisting(name);
      errors.set(name, message);
    },

    errorOf(name) {
      return errors.get(name);
    },

    activeCount() {
      return active.size;
    },
  };

  function stopExisting(name) {
    const entry = active.get(name);
    if (entry !== undefined) {
      try {
        entry.watcher.close();
      } catch {
        // Closing an already-broken watcher must not mask the original error.
      }
      active.delete(name);
    }
  }

  /** Shared change path for watcher callbacks and the reconcile pass. */
  function handleChange(definition, onWake) {
    const entry = active.get(definition.name);
    // A callback from a removed registration must never touch its
    // replacement: ignore obsolete subscriptions entirely.
    if (entry === undefined || entry.definition !== definition) {
      return;
    }
    const current = readBaselineOrError(entry.canonicalPath, definition.name);
    if (current === undefined) {
      return;
    }
    const next = fingerprintOf(current);
    if (next === entry.fingerprint) {
      return;
    }
    const outcome = onWake(definition);
    if (outcome && outcome.delivered === false) {
      // Coalesced (a queued wake covers this change) or serialized (held back
      // by the dispatch transition window): the change itself is undelivered,
      // so mark the subscription dirty — flushDirty() re-checks it once the
      // agent settles, without needing another filesystem event.
      entry.dirty = true;
      return;
    }
    entry.previousFingerprint = entry.fingerprint;
    entry.fingerprint = next;
    entry.dirty = false;
  }

  function deactivate(name, message) {
    stopExisting(name);
    errors.set(name, message);
    try {
      onDeactivate?.();
    } catch {
      // Status rendering must never break the watcher callback.
    }
  }

  function readBaseline(path) {
    let stats;
    try {
      stats = statFn(path);
    } catch (error) {
      throw new WakeError(`path is not readable: ${path} (${describeError(error)})`);
    }
    return stats;
  }

  function readBaselineOrError(path, name) {
    try {
      return statFn(path);
    } catch (error) {
      deactivate(name, describeError(error));
      return undefined;
    }
  }
}

/**
 * Default reconcile scheduler: a delayed macrotask after registration, timed
 * to land once the native watcher is effective. Never holds the process open.
 *
 * @param {() => void} reconcile
 */
export function defaultScheduleReconcile(reconcile) {
  const timer = setTimeout(reconcile, RECONCILE_DELAY_MS);
  timer.unref?.();
  return timer;
}

/**
 * @param {{mtimeMs: number, size: number}} stats
 * @returns {string}
 */
function fingerprintOf(stats) {
  return `${stats.mtimeMs}:${stats.size}`;
}

/**
 * @param {unknown} error
 * @returns {string}
 */
function describeError(error) {
  return error instanceof Error ? error.message : String(error);
}

/**
 * Default watchFactory over node:fs.watch.
 *
 * Watches the target's parent directory and filters events to the target's
 * basename: watching the file itself keeps following the original inode, so
 * atomic replacement (write-to-temporary + rename) would silently detach the
 * subscription after one change.
 *
 * @param {string} path Canonical path of the watched file.
 * @param {{onChange: () => void, onError: (error: Error) => void}} handlers
 * @returns {{close: () => void}}
 */
export function nodeWatchFactory(path, handlers) {
  const directory = nodePath.dirname(path);
  const target = nodePath.basename(path);
  const watcher = nodeFs.watch(
    directory,
    { persistent: false },
    (_eventType, filename) => {
      // filename is null on some platforms; the fingerprint comparison
      // filters non-changes, so a null event is checked rather than trusted.
      if (filename !== null && filename !== target) {
        return;
      }
      handlers.onChange();
    },
  );
  watcher.on("error", (error) => handlers.onError(error));
  // Never hold the host process open on the extension's behalf.
  watcher.unref?.();
  return watcher;
}

/**
 * Default statFn over node:fs. Checks read access explicitly: stat metadata
 * alone is readable for files whose contents are not (mode 000), and a watch
 * on an unreadable file could never deliver meaningful wakes.
 *
 * @param {string} path
 * @returns {{mtimeMs: number, size: number}}
 */
export function nodeStatFn(path) {
  nodeFs.accessSync(path, nodeFs.constants.R_OK);
  const stats = nodeFs.statSync(path);
  return { mtimeMs: stats.mtimeMs, size: stats.size };
}
