/**
 * Deterministic fake Pi host for ace-wake tests.
 *
 * Provides the ports the extension consumes: a manual clock with schedulable
 * intervals, a manual filesystem-watcher factory, a queue recording every
 * sendUserMessage with idle/busy simulation, an in-memory session-entry
 * store mirroring pi.appendEntry/getBranch semantics, and a status recorder.
 */

export function createFakeHost() {
  let currentTime = 0;
  let nextIntervalId = 1;
  const intervals = new Map();
  /** Watchers per registered path: path -> Map(id -> watcher). */
  const watchers = new Map();
  let nextWatcherId = 1;

  /** Queue record: {sourceKey, text, deliverAs} */
  const sends = [];
  let idle = true;

  /** Session entries: [{type: "custom", customType, data}] */
  const sessionEntries = [];

  /** Status renders recorded by the extension UI. */
  const statusRenders = [];

  const notifications = [];

  /**
   * Commands captured from pi.registerCommand: {name, description, handler}.
   */
  const commands = new Map();

  const clock = {
    now: () => currentTime,
    advance(ms) {
      currentTime += ms;
      // Fire due intervals in registration order until none is due.
      let fired = true;
      while (fired) {
        fired = false;
        for (const [id, interval] of [...intervals.entries()]) {
          if (interval.nextFireAt <= currentTime && !interval.cleared) {
            interval.nextFireAt += interval.ms;
            interval.callback();
            fired = true;
            void id;
          }
        }
      }
    },
  };

  const host = {
    clock,

    intervals,

    /** @returns {ReadonlyArray<{sourceKey: string, text: string, deliverAs?: string}>} */
    get sends() {
      return sends;
    },

    sendCount(sourceKey) {
      return sends.filter((send) => send.sourceKey === sourceKey).length;
    },

    setIdle(value) {
      idle = value;
    },

    get idle() {
      return idle;
    },

    /** Models the adapter's run-activity tracking (agent_start/agent_end). */
    setAgentActive(value) {
      host.agentActive = value;
    },

    /** Models Pi's queue state: an accepted wake sits in pendingMessages. */
    setPendingMessages(value) {
      host.pendingMessages = value;
    },

    agentActive: false,

    pendingMessages: false,

    /** Simulate the agent consuming everything queued: clears busy runs. */
    settle: () => {},

    sessionEntries,

    statusRenders,

    notifications,

    commands,

    /** Fire the filesystem change callback of EVERY watcher covering path.
     * The production watchFactory watches the target itself for directory
     * targets and the target's parent directory for file targets; several
     * subscriptions may watch the same directory (e.g. the registry's inbox
     * watch and the ask bridge's anchor), and a real event reaches them all. */
    triggerWatch(path) {
      const covering = watchersCovering(path);
      if (covering.length === 0) {
        throw new Error(`no watcher registered covering ${path}`);
      }
      for (const watcher of covering) {
        watcher.onChange();
      }
    },

    /** Fail EVERY watcher covering path the way node:fs.watch reports runtime errors. */
    failWatch(path, message) {
      const covering = watchersCovering(path);
      if (covering.length === 0) {
        throw new Error(`no watcher registered covering ${path}`);
      }
      for (const watcher of covering) {
        watcher.onError(new Error(message));
      }
    },

    /** The directory watchFactory callbacks receive for a watched file. */
    watchedDir(path) {
      return path.slice(0, path.lastIndexOf("/"));
    },

    watcherCount() {
      let total = 0;
      for (const bucket of watchers.values()) {
        total += bucket.size;
      }
      return total;
    },

    /** Live watchers registered on exactly this path (not ancestors). */
    watcherCountFor(path) {
      return watchers.get(path)?.size ?? 0;
    },

    /** The exact paths native watchers are registered on (not targets); one
     * entry per live watcher, duplicates included. */
    watcherPaths() {
      const paths = [];
      for (const [path, bucket] of watchers) {
        for (let index = 0; index < bucket.size; index += 1) {
          paths.push(path);
        }
      }
      return paths;
    },

    /** Invoke a registered slash command. */
    async runCommand(name, args) {
      const command = commands.get(name);
      if (!command) {
        throw new Error(`command not registered: ${name}`);
      }
      await command.handler(args, host.commandContext);
    },

    assertIdleDelivery(sourceKey) {
      const send = sends.filter((entry) => entry.sourceKey === sourceKey).at(-1);
      if (!send) {
        throw new Error(`no send recorded for ${sourceKey}`);
      }
      if (send.deliverAs !== undefined) {
        throw new Error(`expected direct delivery for ${sourceKey}, got ${send.deliverAs}`);
      }
      return send;
    },

    assertFollowUpDelivery(sourceKey) {
      const send = sends.filter((entry) => entry.sourceKey === sourceKey).at(-1);
      if (!send) {
        throw new Error(`no send recorded for ${sourceKey}`);
      }
      if (send.deliverAs !== "followUp") {
        throw new Error(`expected followUp delivery for ${sourceKey}, got ${send.deliverAs}`);
      }
      return send;
    },

    resetSends() {
      sends.length = 0;
    },
  };

  // Port: node:timers surface used by the loop subscription.
  const setIntervalFn = (callback, ms) => {
    const id = nextIntervalId++;
    intervals.set(id, { callback, ms, nextFireAt: currentTime + ms, cleared: false });
    return id;
  };
  const clearIntervalFn = (id) => {
    const interval = intervals.get(id);
    if (interval) {
      interval.cleared = true;
      intervals.delete(id);
    }
  };

  // Port: filesystem watcher factory used by the watch subscription.
  // Watchers are keyed per path but several may coexist on one path (the
  // registry's inbox watch and the ask bridge's anchor, for instance),
  // mirroring the independent native handles of node:fs.watch.
  function watchersCovering(path) {
    const direct = watchers.get(path);
    if (direct && direct.size > 0) {
      return [...direct.values()];
    }
    const parent = path.slice(0, path.lastIndexOf("/"));
    const parentBucket = watchers.get(parent);
    return parentBucket ? [...parentBucket.values()] : [];
  }

  const watchFactory = (path, handlers) => {
    const failure = watchFailures.get(path);
    if (failure) {
      watchFailures.delete(path);
      throw failure;
    }
    const id = nextWatcherId++;
    if (!watchers.has(path)) {
      watchers.set(path, new Map());
    }
    watchers.get(path).set(id, {
      onChange: handlers.onChange,
      onError: handlers.onError,
      path,
      id,
    });
    return {
      close: () => {
        for (const bucket of watchers.values()) {
          bucket.delete(id);
        }
      },
    };
  };

  // Port: statFn backed by caller-managed fake file states.
  // Synchronous watchFactory failures for the NEXT attach on a path
  // (EMFILE/EPERM/stat-race shape: throw at attach time, once).
  const watchFailures = new Map();
  host.failNextWatchAttach = (path, message = "EMFILE: too many open files") => {
    watchFailures.set(path, new Error(message));
  };
  const fakeFiles = new Map();
  host.setFile = (path, { mtimeMs, size, missing = false }) => {
    if (missing) {
      fakeFiles.delete(path);
    } else {
      fakeFiles.set(path, { mtimeMs, size });
    }
  };
  const statFn = (path) => {
    const stats = fakeFiles.get(path);
    if (!stats) {
      const error = new Error(`ENOENT: no such file or directory, stat '${path}'`);
      error.code = "ENOENT";
      throw error;
    }
    return stats;
  };

  // Pi extension API surface consumed by the adapter.
  const pi = {
    registerCommand(name, options) {
      commands.set(name, options);
    },
    sendUserMessage(text, options) {
      const deliverAs = options?.deliverAs;
      sends.push({ sourceKey: `text:${sends.length}`, text, deliverAs });
      return deliverAs === undefined || deliverAs === "followUp";
    },
    appendEntry(customType, data) {
      sessionEntries.push({ type: "custom", customType, data });
    },
    on() {
      return () => {};
    },
  };

  // Command context surface consumed by the adapter.
  host.commandContext = {
    ui: {
      notify(message, type) {
        notifications.push({ message, type });
      },
      setStatus(key, text) {
        if (text === undefined) {
          const index = statusRenders.findIndex((render) => render.key === key);
          if (index !== -1) {
            statusRenders.splice(index, 1);
          }
          return;
        }
        const existing = statusRenders.find((render) => render.key === key);
        if (existing) {
          existing.text = text;
        } else {
          statusRenders.push({ key, text });
        }
      },
    },
    cwd: "/fake/project",
    model: { provider: "fake", id: "fake-model" },
    isIdle: () => idle,
    hasUI: true,
    hasPendingMessages: () => host.pendingMessages,
    sessionManager: {
      getBranch: () => sessionEntries.map((entry) => ({ ...entry })),
    },
  };

  host.pi = pi;
  host.setIntervalFn = setIntervalFn;
  host.clearIntervalFn = clearIntervalFn;
  host.watchFactory = watchFactory;
  host.statFn = statFn;

  return host;
}
