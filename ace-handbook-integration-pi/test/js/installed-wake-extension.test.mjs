import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { createFakeHost } from "./fake-pi-host.mjs";
import aceWakeFactory from "../../handbook/extensions/ace-wake.mjs";

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
    /** Simulate an extension reload: factory reruns, session_start(reason reload). */
    reload: async () => {
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

  it("list states are explicit about empty configuration", async () => {
    const host = createFakeHost();
    await startSession(host);

    await host.runCommand("watch", "list");
    assert.match(host.notifications.at(-1).message, /no watches configured/);
  });
});

describe("ace-wake delivery", () => {
  it("wakes an idle agent directly through a queued user message", async () => {
    const host = createFakeHost();
    await startSession(host);
    await host.runCommand("loop", "add heartbeat --interval 10 --message check in");

    host.setIdle(true);
    host.clock.advance(10_000);

    assert.equal(host.sends.length, 1);
    const send = host.assertIdleDelivery("text:0");
    assert.equal(send.text, "[ace-wake loop:heartbeat] check in");
  });

  it("wakes a busy agent with a queued follow-up that never interrupts", async () => {
    const host = createFakeHost();
    await startSession(host);
    await host.runCommand("loop", "add heartbeat --interval 10 --message check in");

    host.setIdle(false);
    host.clock.advance(10_000);

    assert.equal(host.sends.length, 1);
    host.assertFollowUpDelivery("text:0");
  });

  it("coalesces same-source wakes while one is queued and keeps distinct sources", async () => {
    const host = createFakeHost();
    const session = await startSession(host);
    host.setFile("/fake/project/dep.txt", { mtimeMs: 1, size: 1 });
    await host.runCommand("loop", "add heartbeat --interval 10 --message loop wake");
    await host.runCommand("watch", "add dep --path dep.txt --message watch wake");

    host.setIdle(false);
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
