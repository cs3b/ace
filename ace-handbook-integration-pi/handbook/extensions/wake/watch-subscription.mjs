import * as nodeFs from "node:fs";
import * as nodePath from "node:path";
import { WakeError } from "./types.mjs";

/**
 * Watch subscription port owning native filesystem watcher handles.
 *
 * start() resolves the configured path to a canonical absolute path (relative
 * paths resolve against `baseDir`), validates readable metadata, and records
 * a baseline fingerprint. Only later fingerprint changes wake the agent, so
 * registering a watch never produces an initial wake.
 *
 * A watcher runtime error (path deleted, permission lost) closes the handle,
 * marks the subscription inactive with a visible error, and never retries:
 * the user removes and re-adds the watch explicitly.
 *
 * @param {object} ports
 * @param {(path: string, handlers: {onChange: () => void, onError: (error: Error) => void}) => {close: () => void}} ports.watchFactory
 * @param {(path: string) => {mtimeMs: number, size: number}} ports.statFn
 * @param {string} [ports.baseDir] Resolution base for relative watch paths.
 * @returns {{
 *   start: (definition: import("./types.mjs").WatchDefinition, onWake: (definition: import("./types.mjs").WatchDefinition) => void) => string,
 *   stop: (name: string) => void,
 *   stopAll: () => void,
 *   errorOf: (name: string) => string | undefined,
 *   activeCount: () => number,
 * }}
 */
export function createWatchPort({ watchFactory, statFn, baseDir = process.cwd() }) {
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
 * @param {string} path
 * @param {{onChange: () => void, onError: (error: Error) => void}} handlers
 * @returns {{close: () => void}}
 */
export function nodeWatchFactory(path, handlers) {
  const watcher = nodeFs.watch(path, { persistent: false }, () => handlers.onChange());
  watcher.on("error", (error) => handlers.onError(error));
  return watcher;
}

/**
 * Default statFn over node:fs.statSync.
 *
 * @param {string} path
 * @returns {{mtimeMs: number, size: number}}
 */
export function nodeStatFn(path) {
  const stats = nodeFs.statSync(path);
  return { mtimeMs: stats.mtimeMs, size: stats.size };
}
