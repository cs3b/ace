import * as nodeFs from "node:fs";
import * as nodePath from "node:path";
import { WakeError } from "./types.js";

/**
 * Watch subscription port owning native filesystem watcher handles.
 *
 * start() resolves the configured path to a canonical absolute path (relative
 * paths resolve against `baseDir`), validates readable metadata, and records
 * a baseline fingerprint. Only later fingerprint changes wake the agent, so
 * registering a watch never produces an initial wake.
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
 * @param {() => void} [ports.onDeactivate] Invoked when a subscription leaves
 *   the active state so callers can refresh visible status.
 * @returns {{
 *   start: (definition: import("./types.js").WatchDefinition, onWake: (definition: import("./types.js").WatchDefinition) => void) => string,
 *   stop: (name: string) => void,
 *   stopAll: () => void,
 *   fail: (name: string, message: string) => void,
 *   errorOf: (name: string) => string | undefined,
 *   activeCount: () => number,
 * }}
 */
export function createWatchPort({ watchFactory, statFn, baseDir = process.cwd(), onDeactivate }) {
  /** @type {Map<string, {watcher: {close: () => void}, canonicalPath: string, fingerprint: string}>} */
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

      const canonicalPath = nodePath.resolve(baseDir, definition.path);
      const baseline = readBaseline(canonicalPath);
      const fingerprint = fingerprintOf(baseline);
      const watcher = watchFactory(canonicalPath, {
        onChange: () => {
          const current = readBaselineOrError(canonicalPath, definition.name);
          if (current === undefined) {
            return;
          }
          const next = fingerprintOf(current);
          if (next === active.get(definition.name)?.fingerprint) {
            return;
          }
          active.get(definition.name).fingerprint = next;
          onWake(definition);
        },
        onError: (error) => {
          deactivate(definition.name, describeError(error));
        },
      });

      active.set(definition.name, { watcher, canonicalPath, fingerprint });
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
