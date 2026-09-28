import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { createFakeHost } from "./fake-pi-host.mjs";
import { MAX_WAKE_MESSAGE_CHARS } from "../../handbook/extensions/ace-wake/wake/types.js";
import aceWakeFactory from "../../handbook/extensions/ace-wake/index.js";

const HOST_PORTS = ["setIntervalFn", "clearIntervalFn", "watchFactory", "statFn"];

function portsOf(host) {
  return Object.fromEntries(HOST_PORTS.map((name) => [name, host[name]]));
}

/**
 * Load the adapter the way Pi would: run the default-exported factory with a
 * fake extension API, capture the lifecycle handlers it registered, then fire
 * session_start. The fake host's deterministic ports are injected through the
 * factory's optional second argument.
 */
async function startSession(host) {
  const events = [];
  host.pi.on = (event, handler) => {
    events.push([event, handler]);
    return () => {};
  };
  aceWakeFactory(host.pi, portsOf(host));

  const handlerFor = (event) => {
    const found = events.find(([name]) => name === event);
    if (!found) {
      throw new Error(`extension did not register ${event}`);
    }
    return found[1];
  };

  await handlerFor("session_start")({ type: "session_start", reason: "startup" }, host.commandContext);

  return {
    /**
     * Simulate an extension reload with real pi semantics: the old runtime
     * receives session_shutdown(reason reload), then the factory reruns and
     * session_start fires with reason "reload".
     */
    reload: async () => {
      const shutdown = events.find(([name]) => name === "session_shutdown");
      if (shutdown) {
        await shutdown[1]({ type: "session_shutdown", reason: "reload" }, host.commandContext);
      }
      const reloadEvents = [];
      host.pi.on = (event, handler) => {
        reloadEvents.push([event, handler]);
        return () => {};
      };
      aceWakeFactory(host.pi, portsOf(host));
      const found = reloadEvents.find(([name]) => name === "session_start");
      await found[1]({ type: "session_start", reason: "reload" }, host.commandContext);
    },
    settle: () => handlerFor("agent_settled")({ type: "agent_settled" }, host.commandContext),
    beforeCompact: () => handlerFor("session_before_compact")({ type: "session_before_compact" }, host.commandContext),
    compacted: () => handlerFor("session_compact")({ type: "session_compact", trigger: "manual" }, host.commandContext),
    compactFailed: () => handlerFor("session_compact_failed")({ type: "session_compact_failed", trigger: "manual" }, host.commandContext),
    shutdown: () => handlerFor("session_shutdown")({ type: "session_shutdown" }, host.commandContext),
  };
}

describe("ace-wake commands", () => {
  it("registers /loop and /watch", async () => {
    const host = createFakeHost();
    await startSession(host);

    assert.ok(host.commands.has("loop"));
    assert.ok(host.commands.has("watch"));
    assert.match(host.commands.get("loop").description, /timer loops/);
    assert.match(host.commands.get("watch").description, /file watches/);
  });

  it("/loop add validates, persists a session entry, and /loop list reports it", async () => {
    const host = createFakeHost();
    await startSession(host);

    await host.runCommand("loop", "add heartbeat --interval 30 --message check the build");

    const added = host.sessionEntries.at(-1);
    assert.equal(added.customType, "ace-wake");
    assert.deepEqual(added.data.loops, [
      { kind: "loop", name: "heartbeat", intervalSeconds: 30, message: "check the build" },
    ]);

    await host.runCommand("loop", "list");
    const listed = host.notifications.at(-1);
    assert.equal(listed.type, "info");
    assert.match(listed.message, /heartbeat — 30s/);
  });

  it("rejects invalid intervals, duplicate names, and unknown names with clear errors", async () => {
    const host = createFakeHost();
    await startSession(host);

    await host.runCommand("loop", "add bad --interval 0 --message x");
    assert.equal(host.notifications.at(-1).type, "error");
    assert.match(host.notifications.at(-1).message, /greater than 0/);

    await host.runCommand("loop", "add ok --interval 5 --message x");
    await host.runCommand("loop", "add ok --interval 9 --message y");
    assert.match(host.notifications.at(-1).message, /loop "ok" already exists/);

    await host.runCommand("loop", "remove ghost");
    assert.match(host.notifications.at(-1).message, /unknown loop: ghost/);
  });

  it("/watch add requires a readable path and stores the canonical path", async () => {
    const host = createFakeHost();
    await startSession(host);

    await host.runCommand("watch", "add dep --path missing.txt --message changed");
    assert.match(host.notifications.at(-1).message, /path is not readable/);
    assert.equal(host.sessionEntries.length, 0, "failed adds must not persist");

    host.setFile("/fake/project/dep.txt", { mtimeMs: 1, size: 1 });
    await host.runCommand("watch", "add dep --path dep.txt --message changed");
    const added = host.sessionEntries.at(-1);
    assert.deepEqual(added.data.watches, [
      { kind: "watch", name: "dep", path: "/fake/project/dep.txt", message: "changed" },
    ]);
  });

  it("quoted messages and --flag=value forms parse", async () => {
    const host = createFakeHost();
    await startSession(host);

    await host.runCommand("loop", 'add quoted --interval=15 --message "two words here"');

    const added = host.sessionEntries.at(-1);
    assert.equal(added.data.loops[0].message, "two words here");
    assert.equal(added.data.loops[0].intervalSeconds, 15);
  });

  it("quoted watch paths containing spaces are stored canonically", async () => {
    const host = createFakeHost();
    await startSession(host);
    host.setFile("/fake/project/my file.txt", { mtimeMs: 1, size: 1 });

    await host.runCommand("watch", 'add spaces --path "my file.txt" --message changed');

    const added = host.sessionEntries.at(-1);
    assert.equal(added.data.watches[0].path, "/fake/project/my file.txt");
  });

  it("loaded snapshots are cloned so registry edits never mutate session history", async () => {
    const host = createFakeHost();
    await startSession(host);
    await host.runCommand("loop", "add first --interval 10 --message m");

    const persisted = host.sessionEntries.at(-1);
    const before = JSON.stringify(persisted.data);

    // A later restart loads this entry; adding another subscription must not
    // rewrite the historical entry (branch isolation).
    const freshHost = createFakeHost();
    freshHost.sessionEntries.push(...structuredClone(host.sessionEntries));
    const freshSession = await startSession(freshHost);
    await freshHost.runCommand("loop", "add second --interval 20 --message m");

    assert.equal(JSON.stringify(persisted.data), before, "historical session entry must stay untouched");
    void freshSession;
  });

  it("list states are explicit about empty configuration", async () => {
    const host = createFakeHost();
    await startSession(host);

    await host.runCommand("watch", "list");
    assert.match(host.notifications.at(-1).message, /no watches configured/);
  });
});

describe("ace-wake delivery", () => {
  it("always delivers wakes as queued follow-ups", async () => {
    const host = createFakeHost();
    const session = await startSession(host);
    await host.runCommand("loop", "add heartbeat --interval 10 --message check in");

    // Follow-up delivery runs immediately when idle and queues behind any
    // active run otherwise; the constant shape leaves no window that could
    // send a direct message Pi would reject.
    host.clock.advance(10_000);

    assert.equal(host.sends.length, 1);
    const send = host.assertFollowUpDelivery("text:0");
    assert.equal(send.text, "[ace-wake loop:heartbeat] check in");

    host.clock.advance(10_000);
    assert.equal(host.sends.length, 1, "same-source wakes coalesce while one is pending");

    await session.settle();
    host.clock.advance(10_000);
    assert.equal(host.sends.length, 2, "after settlement the source wakes again");
  });

  it("bounds the complete rendered wake message including the source prefix", async () => {
    const host = createFakeHost();
    await startSession(host);
    const longMessage = "y".repeat(MAX_WAKE_MESSAGE_CHARS + 500);

    await host.runCommand("loop", `add big --interval 10 --message ${longMessage}`);
    host.clock.advance(10_000);

    assert.equal(host.sends.length, 1);
    assert.equal(
      host.sends[0].text.length,
      MAX_WAKE_MESSAGE_CHARS,
      "the composed message, prefix and truncation marker included, must not exceed the bound",
    );
    await host.runCommand("loop", "remove big");
  });

  it("re-delivers a watch change absorbed by a pending wake after settlement", async () => {
    const host = createFakeHost();
    const session = await startSession(host);
    host.setFile("/fake/project/dep.txt", { mtimeMs: 1, size: 1 });
    await host.runCommand("watch", "add dep --path dep.txt --message watch wake");

    // First change wakes; second change during the wake's run coalesces.
    host.setFile("/fake/project/dep.txt", { mtimeMs: 2, size: 2 });
    host.triggerWatch("/fake/project/dep.txt");
    assert.equal(host.sends.length, 1);
    host.setFile("/fake/project/dep.txt", { mtimeMs: 3, size: 3 });
    host.triggerWatch("/fake/project/dep.txt");
    assert.equal(host.sends.length, 1, "the second change coalesces into the pending wake");

    // Settlement re-checks dirty watches: the absorbed change wakes again
    // without any further filesystem event.
    await session.settle();
    assert.equal(host.sends.length, 2, "the absorbed change must wake after settlement");
    assert.match(host.sends[1].text, /watch:dep/);
  });

  it("retains wakes during compaction and flushes them after compaction state clears", async () => {
    const host = createFakeHost();
    const session = await startSession(host);
    await host.runCommand("loop", "add heartbeat --interval 10 --message check in");

    await session.beforeCompact();
    host.clock.advance(10_000);
    host.clock.advance(10_000);
    assert.equal(host.sends.length, 0, "wakes during compaction are retained, not dispatched");

    await session.compacted();
    // Pi clears its compaction state after the session_compact emission; the
    // flush is deferred to a macrotask so it lands once sends are accepted.
    await new Promise((resolve) => setTimeout(resolve, 20));
    assert.equal(host.sends.length, 1, "the retained wake flushes after compaction");
    host.assertFollowUpDelivery("text:0");

    // The flushed wake runs and settles like any other; the next tick wakes
    // normally: nothing is stranded pending.
    await session.settle();
    host.clock.advance(10_000);
    assert.equal(host.sends.length, 2);
  });

  it("flushes retained wakes when compaction fails", async () => {
    const host = createFakeHost();
    const session = await startSession(host);
    await host.runCommand("loop", "add heartbeat --interval 10 --message check in");

    await session.beforeCompact();
    host.clock.advance(10_000);
    assert.equal(host.sends.length, 0);

    await session.compactFailed();
    await new Promise((resolve) => setTimeout(resolve, 20));
    assert.equal(host.sends.length, 1, "retained wakes flush after failed compaction too");
  });

  it("reconciles a timer wake stranded by the pre-compaction rejection window", async () => {
    const host = createFakeHost();
    const session = await startSession(host);
    await host.runCommand("loop", "add heartbeat --interval 10 --message check in");

    // The wake dispatches before any compaction event fires (Pi rejects
    // prompts while resolving compaction authentication, before
    // session_before_compact), so it is pending but never consumed.
    host.clock.advance(10_000);
    assert.equal(host.sends.length, 1);

    // The compaction outcome reconciles unacknowledged attempts even though
    // nothing was retained.
    await session.compacted();
    await new Promise((resolve) => setTimeout(resolve, 20));
    assert.equal(host.sends.length, 2, "the stranded attempt must re-dispatch after compaction");
    await session.settle();
  });

  it("reconciles a stranded watch wake after compaction without a new filesystem event", async () => {
    const host = createFakeHost();
    const session = await startSession(host);
    host.setFile("/fake/project/dep.txt", { mtimeMs: 1, size: 1 });
    await host.runCommand("watch", "add dep --path dep.txt --message watch wake");

    // The watch wake dispatches into the pre-compaction rejection window:
    // pending, never consumed, and not dirty (the change was fingerprinted).
    host.setFile("/fake/project/dep.txt", { mtimeMs: 2, size: 2 });
    host.triggerWatch("/fake/project/dep.txt");
    assert.equal(host.sends.length, 1);

    await session.compactFailed();
    await new Promise((resolve) => setTimeout(resolve, 20));
    assert.equal(host.sends.length, 2, "the stranded watch wake must re-dispatch after compaction");
    await session.settle();
  });

  it("does not deliver a removed subscription's message through its replacement", async () => {
    const host = createFakeHost();
    const reconciles = [];
    const hostPorts = {
      setIntervalFn: host.setIntervalFn,
      clearIntervalFn: host.clearIntervalFn,
      watchFactory: host.watchFactory,
      statFn: host.statFn,
      scheduleReconcile: (reconcile) => reconciles.push(reconcile),
    };
    const events = [];
    host.pi.on = (event, handler) => {
      events.push([event, handler]);
      return () => {};
    };
    aceWakeFactory(host.pi, hostPorts);
    const start = events.find(([name]) => name === "session_start");
    await start[1]({ type: "session_start", reason: "startup" }, host.commandContext);

    host.setFile("/fake/project/dep.txt", { mtimeMs: 1, size: 1 });
    await host.runCommand("watch", "add dep --path dep.txt --message old message");
    const staleReconcile = reconciles.at(-1);

    // Remove and re-add with a new message before the old reconcile runs.
    await host.runCommand("watch", "remove dep");
    host.setFile("/fake/project/dep.txt", { mtimeMs: 2, size: 2 });
    await host.runCommand("watch", "add dep --path dep.txt --message new message");
    host.setFile("/fake/project/dep.txt", { mtimeMs: 3, size: 3 });

    staleReconcile();
    assert.equal(host.sends.length, 0, "the stale reconcile must not deliver or suppress anything");

    // The replacement's own reconcile delivers the new message.
    reconciles.at(-1)();
    assert.equal(host.sends.length, 1);
    assert.match(host.sends[0].text, /new message/);
  });

  it("does not flush a retained wake for a subscription removed while delivery is paused", async () => {
    const host = createFakeHost();
    const session = await startSession(host);
    await host.runCommand("loop", "add heartbeat --interval 10 --message check in");

    await session.beforeCompact();
    host.clock.advance(10_000);
    await host.runCommand("loop", "remove heartbeat");

    await session.compactFailed();
    await new Promise((resolve) => setTimeout(resolve, 20));
    assert.equal(host.sends.length, 0, "removal must cancel the retained wake");
  });

  it("coalesces same-source wakes while one is queued and keeps distinct sources", async () => {
    const host = createFakeHost();
    const session = await startSession(host);
    host.setFile("/fake/project/dep.txt", { mtimeMs: 1, size: 1 });
    await host.runCommand("loop", "add heartbeat --interval 10 --message loop wake");
    await host.runCommand("watch", "add dep --path dep.txt --message watch wake");

    host.clock.advance(10_000);
    host.setFile("/fake/project/dep.txt", { mtimeMs: 2, size: 2 });
    host.triggerWatch("/fake/project/dep.txt");
    host.setFile("/fake/project/dep.txt", { mtimeMs: 3, size: 3 });
    host.triggerWatch("/fake/project/dep.txt");

    assert.equal(host.sends.length, 2, "one loop wake + one coalesced watch wake");
    assert.match(host.sends[0].text, /loop:heartbeat/);
    assert.match(host.sends[1].text, /watch:dep/);

    await session.settle();
    host.setFile("/fake/project/dep.txt", { mtimeMs: 4, size: 4 });
    host.triggerWatch("/fake/project/dep.txt");
    assert.equal(host.sends.length, 3, "the source may wake again after the agent settled");
  });

  it("/loop remove stops future wakes", async () => {
    const host = createFakeHost();
    await startSession(host);
    await host.runCommand("loop", "add heartbeat --interval 10 --message m");

    host.clock.advance(10_000);
    assert.equal(host.sends.length, 1);
    await host.runCommand("loop", "remove heartbeat");
    host.resetSends();

    host.setIdle(true);
    host.clock.advance(60_000);

    assert.equal(host.sends.length, 0);
  });
});

describe("ace-wake session lifecycle", () => {
  it("restart reconciles persisted definitions without flooding missed ticks", async () => {
    const host = createFakeHost();
    await startSession(host);
    await host.runCommand("loop", "add heartbeat --interval 10 --message m");

    const freshHost = createFakeHost();
    freshHost.sessionEntries.push(...structuredClone(host.sessionEntries));
    await startSession(freshHost);

    assert.equal(freshHost.sends.length, 0, "reconciliation itself wakes nobody");
    freshHost.clock.advance(9999);
    assert.equal(freshHost.sends.length, 0, "elapsed wall-clock time is not replayed");
    freshHost.clock.advance(1);
    assert.equal(freshHost.sends.length, 1, "the next full interval wakes exactly once");
  });

  it("reload re-registers each subscription exactly once", async () => {
    const host = createFakeHost();
    const session = await startSession(host);
    await host.runCommand("loop", "add heartbeat --interval 10 --message m");

    await session.reload();
    host.clock.advance(10_000);

    const loopWakes = host.sends.filter((send) => send.text.includes("loop:heartbeat"));
    assert.equal(loopWakes.length, 1, "reload must not duplicate timers");
  });

  it("session shutdown disposes all handles", async () => {
    const host = createFakeHost();
    const session = await startSession(host);
    await host.runCommand("loop", "add heartbeat --interval 10 --message m");

    await session.shutdown();
    host.setIdle(true);
    host.clock.advance(60_000);

    assert.equal(host.sends.length, 0);
  });

  it("shows active subscriptions in the status surface and clears it when empty", async () => {
    const host = createFakeHost();
    await startSession(host);

    await host.runCommand("loop", "add heartbeat --interval 30 --message m");
    const rendered = host.statusRenders.find((render) => render.key === "ace-wake");
    assert.ok(rendered, "status surface must show active subscriptions");
    assert.match(rendered.text, /loop heartbeat 30s/);

    await host.runCommand("loop", "remove heartbeat");
    assert.equal(
      host.statusRenders.find((render) => render.key === "ace-wake"),
      undefined,
      "status cleared when no subscriptions remain",
    );
  });
});
