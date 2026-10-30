import assert from "node:assert/strict";
import { describe, it } from "node:test";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createFakeHost } from "./fake-pi-host.mjs";
import { startSession } from "./session-harness.mjs";

const flush = () => new Promise((resolve) => setImmediate(resolve));

/**
 * Task 8xs.t.pu0.f: the zero-idle window — a full 30 minutes of healthy
 * silence produces ZERO model turns, while technical polling (the eyes
 * observation timer and a loop's own ticks) keeps running and is counted
 * SEPARATELY. A source failure during the window is a separate scenario,
 * never silence.
 */
describe("zero-idle window (8xs.t.pu0.f)", () => {
  it("30 minutes of unchanged state: zero model calls, polling counted separately", async () => {
    const host = createFakeHost();
    let observations = 0;
    const session = await startSession(host, { eyes: {
      now: host.clock.now, schedule: host.setIntervalFn, cancel: host.clearIntervalFn,
      observe: async () => {
        observations += 1;
        return { schema: "ace.hitl.observation/v1", events: [] };
      },
    } });

    const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ace-zero-idle-"));
    const eyesConfig = path.join(dir, "eyes.json");
    fs.writeFileSync(eyesConfig, "{}");
    host.setFile("/fake/project/source.txt", { mtimeMs: 1, size: 3 });
    await host.runCommand("eyes", `start ${eyesConfig}`);
    await host.runCommand("watch", "add quiet --path source.txt --message quiet-change");
    await flush();

    const modelCallsBefore = host.sends.length;
    const pollsBefore = { observations, intervals: host.intervals.size };

    // 30 minutes of healthy silence on the manual clock: technical timers
    // fire, nothing in the watched state changes.
    host.clock.advance(30 * 60 * 1000);
    await flush();
    await session.settle();
    await flush();

    const modelCallsAfter = host.sends.length;
    assert.equal(modelCallsAfter - modelCallsBefore, 0,
      "30 minutes of healthy silence consume ZERO model turns");
    assert.ok(observations > pollsBefore.observations,
      `technical polling continued (${observations} observations vs ${pollsBefore.observations} before)`);
    assert.ok(host.intervals.size >= 1,
      "the technical observer timer stays armed through the silent window");

    // A REAL change still wakes after the silent window.
    host.setFile("/fake/project/source.txt", { mtimeMs: 2, size: 3 });
    host.triggerWatch("/fake/project/source.txt");
    await flush();
    await session.settle();
    await flush();
    assert.ok(host.sends.some((send) => send.text.includes("quiet-change")),
      "a real change after the window still wakes the receiver");
    await session.shutdown();
    fs.rmSync(dir, { recursive: true, force: true });
  });
});
