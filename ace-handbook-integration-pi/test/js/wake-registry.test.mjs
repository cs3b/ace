import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { WakeDispatcher } from "../../handbook/extensions/wake/wake-dispatcher.js";
import {
  MAX_WAKE_MESSAGE_CHARS,
} from "../../handbook/extensions/wake/types.js";
import {
  MAX_INTERVAL_SECONDS,
  WakeRegistry,
  loopSourceKey,
  requireInterval,
  requireMessage,
  requireName,
  watchSourceKey,
} from "../../handbook/extensions/wake/wake-registry.js";
import { createFakeHost } from "./fake-pi-host.mjs";

function buildRegistry(host, overrides = {}) {
  const stateStore = { snapshot: { loops: [], watches: [] } };
  const state = {
    load: () => structuredClone(stateStore.snapshot),
    save: (snapshot) => {
      stateStore.snapshot = structuredClone(snapshot);
    },
  };
  const status = { render: (entries) => host.statusRenders.push({ key: "ace-wake", text: entries }) };
  const dispatcher = new WakeDispatcher({
    deliver: (sourceKey, text) => {
      if (host.idle) {
        host.pi.sendUserMessage(`[ace-wake ${sourceKey}] ${text}`);
        return true;
      }
      host.pi.sendUserMessage(`[ace-wake ${sourceKey}] ${text}`, { deliverAs: "followUp" });
      return true;
    },
  });
  const registry = new WakeRegistry({
    loops: overrides.loops ?? {
      start: () => {},
      stop: () => {},
      stopAll: () => {},
      errorOf: () => undefined,
    },
    watches: overrides.watches ?? {
      start: () => {},
      stop: () => {},
      stopAll: () => {},
      errorOf: () => undefined,
    },
    state: overrides.state ?? state,
    status: overrides.status ?? status,
    dispatcher: overrides.dispatcher ?? dispatcher,
  });
  return { registry, stateStore, dispatcher };
}

describe("WakeDispatcher", () => {
  it("delivers one wake per source and coalesces repeats while pending", () => {
    const delivered = [];
    const dispatcher = new WakeDispatcher({ deliver: (key, text) => (delivered.push({ key, text }), true) });

    const first = dispatcher.wake("loop:tick", "hello");
    const second = dispatcher.wake("loop:tick", "hello");

    assert.deepEqual(first, { delivered: true });
    assert.deepEqual(second, { delivered: false, reason: "coalesced" });
    assert.equal(delivered.length, 1);
    assert.equal(dispatcher.isPending("loop:tick"), true);
  });

  it("preserves distinct sources without coalescing", () => {
    const delivered = [];
    const dispatcher = new WakeDispatcher({ deliver: (key) => (delivered.push(key), true) });

    dispatcher.wake("loop:tick", "a");
    dispatcher.wake("watch:dep", "b");

    assert.deepEqual(delivered, ["loop:tick", "watch:dep"]);
  });

  it("allows a later wake after settle", () => {
    const delivered = [];
    const dispatcher = new WakeDispatcher({ deliver: (key) => (delivered.push(key), true) });

    dispatcher.wake("loop:tick", "a");
    dispatcher.settle("loop:tick");
    const next = dispatcher.wake("loop:tick", "a");

    assert.deepEqual(next, { delivered: true });
    assert.equal(delivered.length, 2);
  });

  it("reports rejection when the queue port refuses delivery", () => {
    const dispatcher = new WakeDispatcher({ deliver: () => false });

    const outcome = dispatcher.wake("loop:tick", "a");

    assert.deepEqual(outcome, { delivered: false, reason: "rejected" });
    assert.equal(dispatcher.isPending("loop:tick"), false);
  });

  it("bounds and trims wake messages", () => {
    const delivered = [];
    const dispatcher = new WakeDispatcher({ deliver: (key, text) => (delivered.push(text), true) });

    dispatcher.wake("loop:tick", "  spaced  ");
    dispatcher.wake("loop:big", "x".repeat(MAX_WAKE_MESSAGE_CHARS + 100));

    assert.equal(delivered[0], "spaced");
    assert.equal(delivered[1].length, MAX_WAKE_MESSAGE_CHARS + "… [ace-wake: message truncated]".length);
  });

  it("settleAll clears every source", () => {
    const dispatcher = new WakeDispatcher({ deliver: () => true });
    dispatcher.wake("loop:a", "a");
    dispatcher.wake("watch:b", "b");

    dispatcher.settleAll();

    assert.equal(dispatcher.isPending("loop:a"), false);
    assert.equal(dispatcher.isPending("watch:b"), false);
  });
});

describe("wake validation", () => {
  it("rejects invalid names", () => {
    assert.throws(() => requireName("", "loop"), /name must not be empty/);
    assert.throws(() => requireName("  ", "watch"), /name must not be empty/);
    assert.throws(() => requireName("has space", "loop"), /must not contain whitespace/);
  });

  it("rejects invalid intervals with a clear message", () => {
    assert.throws(() => requireInterval(0), /greater than 0/);
    assert.throws(() => requireInterval(-5), /greater than 0/);
    assert.throws(() => requireInterval("abc"), /finite number/);
    assert.throws(() => requireInterval(Number.POSITIVE_INFINITY), /finite number/);
    assert.throws(() => requireInterval(undefined), /finite number/);
    assert.throws(
      () => requireInterval(Number.MAX_SAFE_INTEGER),
      /at most .* seconds/,
      "intervals beyond the host timer clamp must fail instead of becoming 1ms wake storms",
    );
    assert.equal(MAX_INTERVAL_SECONDS, (2 ** 31 - 1) / 1000);
    assert.equal(requireInterval("30"), 30);
    assert.equal(requireInterval(1.5), 1.5);
  });

  it("rejects empty messages", () => {
    assert.throws(() => requireMessage("   "), /message must not be empty/);
    assert.throws(() => requireMessage(undefined), /message must not be empty/);
  });
});

describe("WakeRegistry loops", () => {
  it("adds a loop, persists it, and fires wakes through the dispatcher", () => {
    const host = createFakeHost();
    const loops = { started: [], stopped: [] };
    const { registry, stateStore } = buildRegistry(host, {
      loops: {
        start: (definition) => loops.started.push(definition.name),
        stop: (name) => loops.stopped.push(name),
        stopAll: () => loops.stopped.push("*"),
        errorOf: () => undefined,
      },
    });

    const definition = registry.addLoop({ name: "heartbeat", intervalSeconds: 30, message: "check in" });

    assert.equal(definition.name, "heartbeat");
    assert.deepEqual(loops.started, ["heartbeat"]);
    assert.deepEqual(stateStore.snapshot.loops, [{ kind: "loop", name: "heartbeat", intervalSeconds: 30, message: "check in" }]);
  });

  it("rejects duplicate loop names", () => {
    const host = createFakeHost();
    const { registry } = buildRegistry(host);
    registry.addLoop({ name: "heartbeat", intervalSeconds: 30, message: "a" });

    assert.throws(
      () => registry.addLoop({ name: "heartbeat", intervalSeconds: 60, message: "b" }),
      /loop "heartbeat" already exists/,
    );
  });

  it("removeLoop disposes the handle and stops future wakes", () => {
    const host = createFakeHost();
    const stopped = [];
    let tick = () => {};
    const { registry } = buildRegistry(host, {
      loops: {
        start: (definition, onTick) => {
          tick = onTick;
        },
        stop: (name) => stopped.push(name),
        stopAll: () => {},
        errorOf: () => undefined,
      },
    });

    registry.addLoop({ name: "heartbeat", intervalSeconds: 30, message: "check in" });
    tick();
    registry.removeLoop("heartbeat");

    assert.deepEqual(stopped, ["heartbeat"]);
    assert.throws(() => registry.removeLoop("heartbeat"), /unknown loop: heartbeat/);
  });

  it("list reports loops with pending state", () => {
    const host = createFakeHost();
    const { registry, dispatcher } = buildRegistry(host);
    registry.addLoop({ name: "heartbeat", intervalSeconds: 30, message: "check in" });
    dispatcher.pending.add(loopSourceKey("heartbeat"));

    const entries = registry.list();

    assert.equal(entries.length, 1);
    assert.equal(entries[0].kind, "loop");
    assert.equal(entries[0].detail, "30s");
    assert.equal(entries[0].pending, true);
  });

  it("reconciliation registers exactly one handle per definition without replaying elapsed ticks", () => {
    const host = createFakeHost();
    const { registry, dispatcher, stateStore } = buildRegistry(host, {
      loops: {
        start: () => {},
        stop: () => {},
        stopAll: () => {},
        errorOf: () => undefined,
      },
    });
    registry.addLoop({ name: "heartbeat", intervalSeconds: 1, message: "check in" });

    // Simulate a restart: a fresh registry over the persisted snapshot.
    const restarted = new WakeRegistry({
      loops: { start: () => {}, stop: () => {}, stopAll: () => {}, errorOf: () => undefined },
      watches: { start: () => {}, stop: () => {}, stopAll: () => {}, errorOf: () => undefined },
      state: { load: () => structuredClone(stateStore.snapshot), save: () => {} },
      status: { render: () => {} },
      dispatcher,
    });
    host.clock.advance(10 * 60 * 1000);

    restarted.reconcile();

    assert.equal(host.sends.length, 0, "reconciliation must not flood missed ticks");
  });
});

describe("WakeRegistry watches", () => {
  function watchOverrides(host, { statError } = {}) {
    const state = {
      started: [],
      stopped: [],
      errors: new Map(),
    };
    return {
      watches: {
        start: (definition) => {
          if (statError) {
            const error = new Error("EACCES: permission denied");
            throw error;
          }
          state.started.push(definition.name);
        },
        stop: (name) => state.stopped.push(name),
        stopAll: () => {},
        errorOf: (name) => state.errors.get(name),
      },
      state,
    };
  }

  it("rejects an unreadable watch path before persisting", () => {
    const host = createFakeHost();
    const overrides = watchOverrides(host, { statError: true });
    const { registry, stateStore } = buildRegistry(host, overrides);

    assert.throws(
      () => registry.addWatch({ name: "dep", path: "/tmp/missing", message: "changed" }),
    );
    assert.deepEqual(stateStore.snapshot.watches, []);
  });

  it("rejects duplicate watch names", () => {
    const host = createFakeHost();
    const { registry } = buildRegistry(host);
    registry.addWatch({ name: "dep", path: "/tmp/file", message: "changed" });

    assert.throws(
      () => registry.addWatch({ name: "dep", path: "/tmp/other", message: "other" }),
      /watch "dep" already exists/,
    );
  });

  it("removeWatch disposes the watcher and fails clearly for unknown names", () => {
    const host = createFakeHost();
    const stopped = [];
    const { registry } = buildRegistry(host, {
      watches: {
        start: () => {},
        stop: (name) => stopped.push(name),
        stopAll: () => {},
        errorOf: () => undefined,
      },
    });

    registry.addWatch({ name: "dep", path: "/tmp/file", message: "changed" });
    registry.removeWatch("dep");

    assert.deepEqual(stopped, ["dep"]);
    assert.throws(() => registry.removeWatch("dep"), /unknown watch: dep/);
  });

  it("surfaces runtime errors as inactive-error subscriptions without retry", () => {
    const host = createFakeHost();
    const errors = new Map();
    let stopCalls = 0;
    const { registry } = buildRegistry(host, {
      watches: {
        start: () => {},
        stop: () => {
          stopCalls += 1;
        },
        stopAll: () => {},
        errorOf: (name) => errors.get(name),
      },
    });
    registry.addWatch({ name: "dep", path: "/tmp/file", message: "changed" });
    errors.set("dep", "ENOENT: path vanished");

    const entries = registry.list();

    assert.equal(stopCalls, 0);
    assert.equal(entries[0].error, "ENOENT: path vanished");
    assert.equal(entries[0].pending, false);
  });

  it("reconcile isolates a failing watch so other watches still restart", () => {
    const host = createFakeHost();
    const failures = new Map();
    const startedNames = [];
    const statusRenders = [];
    const registry = new WakeRegistry({
      loops: { start: () => {}, stop: () => {}, stopAll: () => {}, errorOf: () => undefined },
      watches: {
        start: (definition) => {
          if (definition.name === "ghost") {
            throw new Error("ENOENT: stat ghost.txt");
          }
          startedNames.push(definition.name);
        },
        stop: () => {},
        stopAll: () => {},
        fail: (name, message) => failures.set(name, message),
        errorOf: (name) => failures.get(name),
      },
      state: { load: () => ({ loops: [], watches: [
        { kind: "watch", name: "ghost", path: "/tmp/ghost.txt", message: "m" },
        { kind: "watch", name: "alive", path: "/tmp/alive.txt", message: "m" },
      ] }), save: () => {} },
      status: { render: (entries) => statusRenders.push(entries) },
      dispatcher: new WakeDispatcher({ deliver: () => true }),
    });

    registry.reconcile();

    assert.deepEqual(startedNames, ["alive"], "a failed watch must not block later subscriptions");
    assert.match(failures.get("ghost") ?? "", /could not restart watch.*ENOENT/);
    const listed = registry.list();
    assert.match(listed.find((entry) => entry.name === "ghost").error, /could not restart watch/);
    assert.equal(listed.find((entry) => entry.name === "alive").error, undefined);
    assert.equal(statusRenders.length, 1, "status must render even when a watch failed to restart");
  });
});

describe("wake source keys", () => {
  it("keep loop and watch namespaces distinct", () => {
    assert.equal(loopSourceKey("x"), "loop:x");
    assert.equal(watchSourceKey("x"), "watch:x");
    assert.notEqual(loopSourceKey("x"), watchSourceKey("x"));
  });
});
