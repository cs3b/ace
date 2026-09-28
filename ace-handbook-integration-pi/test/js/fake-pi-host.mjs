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

    /** Simulate the agent consuming everything queued: clears busy runs. */
    settle: () => {},

    sessionEntries,

    statusRenders,

    notifications,

    commands,

    /** Fire the filesystem change callback of a registered watcher. */
    triggerWatch(name) {
      watchers.get(name).onChange();
    },

    /** Fail a registered watcher the way node:fs.watch reports runtime errors. */
    failWatch(name, message) {
      watchers.get(name).onError(new Error(message));
    },

    watcherCount() {
      return watchers.size;
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
  const watchFactory = (path, handlers) => {
    const id = nextWatcherId++;
    watchers.set(path, {
      onChange: handlers.onChange,
      onError: handlers.onError,
      path,
      id,
    });
    return {
      close: () => {
        for (const [key, watcher] of watchers) {
          if (watcher.id === id) {
            watchers.delete(key);
          }
        }
      },
    };
  };

  // Port: statFn backed by caller-managed fake file states.
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
    isIdle: () => idle,
    hasUI: true,
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
