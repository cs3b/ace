import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { createLoopPort } from "../../handbook/extensions/ace-wake/wake/loop-subscription.js";
import { createFakeHost } from "./fake-pi-host.mjs";

describe("createLoopPort", () => {
  it("fires one tick per interval from registration time", () => {
    const host = createFakeHost();
    const port = createLoopPort({ setIntervalFn: host.setIntervalFn, clearIntervalFn: host.clearIntervalFn });
    const ticks = [];

    port.start({ kind: "loop", name: "heartbeat", intervalSeconds: 10, message: "m" }, () => ticks.push(1));
    host.clock.advance(9999);
    assert.equal(ticks.length, 0);
    host.clock.advance(1);
    assert.equal(ticks.length, 1);
    host.clock.advance(10_000);
    assert.equal(ticks.length, 2);
  });

  it("stop disposes the handle and prevents future wakes", () => {
    const host = createFakeHost();
    const port = createLoopPort({ setIntervalFn: host.setIntervalFn, clearIntervalFn: host.clearIntervalFn });
    const ticks = [];

    port.start({ kind: "loop", name: "heartbeat", intervalSeconds: 5, message: "m" }, () => ticks.push(1));
    assert.equal(port.activeCount(), 1);
    port.stop("heartbeat");
    assert.equal(port.activeCount(), 0);
    host.clock.advance(60_000);

    assert.equal(ticks.length, 0);
  });

  it("stopAll disposes every handle", () => {
    const host = createFakeHost();
    const port = createLoopPort({ setIntervalFn: host.setIntervalFn, clearIntervalFn: host.clearIntervalFn });
    const ticks = [];

    port.start({ kind: "loop", name: "a", intervalSeconds: 1, message: "m" }, () => ticks.push("a"));
    port.start({ kind: "loop", name: "b", intervalSeconds: 1, message: "m" }, () => ticks.push("b"));
    port.stopAll();
    host.clock.advance(60_000);

    assert.equal(ticks.length, 0);
    assert.equal(port.activeCount(), 0);
  });

  it("restarting a name disposes the prior handle exactly once", () => {
    const host = createFakeHost();
    const port = createLoopPort({ setIntervalFn: host.setIntervalFn, clearIntervalFn: host.clearIntervalFn });
    const ticks = [];

    port.start({ kind: "loop", name: "heartbeat", intervalSeconds: 10, message: "old" }, () => ticks.push("old"));
    port.start({ kind: "loop", name: "heartbeat", intervalSeconds: 10, message: "new" }, () => ticks.push("new"));
    assert.equal(port.activeCount(), 1);

    host.clock.advance(10_000);

    assert.deepEqual(ticks, ["new"], "exactly one live timer survives a re-registration");
  });

  it("errorOf is always undefined because intervals cannot fail at runtime", () => {
    const host = createFakeHost();
    const port = createLoopPort({ setIntervalFn: host.setIntervalFn, clearIntervalFn: host.clearIntervalFn });

    assert.equal(port.errorOf("anything"), undefined);
  });
});
