import assert from "node:assert/strict";
import { describe, it } from "node:test";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createFakeHost } from "./fake-pi-host.mjs";
import { startSession } from "./session-harness.mjs";

const flush = () => new Promise((resolve) => setImmediate(resolve));

/** Wake deliveries carrying the probe message (public /watch source). */
const probeWakes = (host, needle) => host.sends.filter((send) => send.text.includes(needle));

/**
 * Task 8xs.t.pu0.2 contract: /eyes owns standing observation but NEVER
 * competes with user watches — a public `/watch add` under active eyes
 * must register, observe, and deliver exactly one wake on change; the
 * same delivery infrastructure (registry + sendUserMessage) serves both.
 */
describe("/watch and /eyes coexistence (8xs.t.pu0.2)", () => {
  it("a public /watch add under active eyes registers and delivers exactly one wake", async () => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ace-watch-eyes-"));
    try {
      const eyesConfig = path.join(dir, "eyes.json");
      fs.writeFileSync(eyesConfig, "{}");
      const target = "/fake/project/probe.txt";
      const host = createFakeHost();

      const session = await startSession(host, { eyes: {
        now: host.clock.now, schedule: host.setIntervalFn, cancel: host.clearIntervalFn,
        observe: async () => ({ schema: "ace.hitl.observation/v1", events: [] }),
      } });
      await host.runCommand("eyes", `start ${eyesConfig}`);
      await flush();

      // The public registration must NOT be rejected while eyes observes.
      host.setFile(target, { mtimeMs: 1, size: 10 });
      await host.runCommand("watch", "add probe --path probe.txt --message probe-changed");
      const rejections = host.notifications.filter((note) => note.type === "error");
      assert.deepEqual(rejections, [], "watch add must not be rejected while eyes owns observation");

      // No change yet: zero wake deliveries.
      assert.equal(probeWakes(host, "probe-changed").length, 0);

      // A real change reaches the registered native watcher.
      host.setFile(target, { mtimeMs: 2, size: 11 });
      host.triggerWatch(target);
      await flush();
      await session.settle();
      await flush();

      assert.equal(probeWakes(host, "probe-changed").length, 1,
        "exactly one wake must be consumed for one change under active eyes");

      // Healthy silence: no further events, no further model turns.
      await host.clock.advance(30_000);
      await flush();
      assert.equal(probeWakes(host, "probe-changed").length, 1,
        "no further model turns while the watched state is unchanged");
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  });

  it("enabling eyes does not remove an active watch", async () => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ace-watch-eyes2-"));
    try {
      const target = "/fake/project/source.txt";
      const host = createFakeHost();
      const session = await startSession(host, { eyes: {
        now: host.clock.now, schedule: host.setIntervalFn, cancel: host.clearIntervalFn,
        observe: async () => ({ schema: "ace.hitl.observation/v1", events: [] }),
      } });

      host.setFile(target, { mtimeMs: 1, size: 4 });
      await host.runCommand("watch", "add keep --path source.txt --message keep-changed");
      const eyesConfig = path.join(dir, "eyes.json");
      fs.writeFileSync(eyesConfig, "{}");
      await host.runCommand("eyes", `start ${eyesConfig}`);
      await flush();

      await host.runCommand("watch", "list");
      const listed = host.notifications.at(-1);
      assert.match(String(listed?.message ?? ""), /keep/, "the watch must survive eyes activation");

      host.setFile(target, { mtimeMs: 2, size: 5 });
      host.triggerWatch(target);
      await flush();
      await session.settle();
      await flush();
      assert.equal(probeWakes(host, "keep-changed").length, 1, "the surviving watch still delivers");
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  });
});
