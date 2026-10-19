import assert from "node:assert/strict";
import { spawnSync } from "node:child_process";
import { describe, it } from "node:test";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";

import { createWatchPort, nodeStatFn, nodeWatchFactory } from "../../handbook/extensions/ace-wake/wake/watch-subscription.js";
import { expandInboxWatchTargets } from "../../handbook/extensions/ace-wake/wake/inbox-discovery.js";

// PR393 P2 reproduction with REAL pieces: a real git linked worktree, a
// real `bin/ace-hitl create` executed inside the coworker worktree (the
// way a coworker files its report), and the REAL watch port plus the real
// multi-worktree inbox discovery. The documented main-checkout inbox is
// never touched by that write, so only the cross-worktree expansion wakes
// the waiting overseer session.

const PACKAGE_ROOT = path.resolve(import.meta.dirname, "../..");
const REPO_ROOT = path.resolve(PACKAGE_ROOT, "..");

const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Await a condition instead of sleeping a fixed gap: poll on a short
 * interval until the predicate holds or the deadline passes. Removes the
 * flake profile of fixed sleeps (too short on slow disks, needlessly slow
 * otherwise).
 *
 * @param {() => boolean} predicate
 * @param {string} description
 * @param {number} timeoutMs
 */
async function waitFor(predicate, description, timeoutMs = 5000) {
  const deadline = Date.now() + timeoutMs;
  for (;;) {
    if (predicate()) {
      return;
    }
    if (Date.now() >= deadline) {
      assert.fail(`timed out waiting for ${description}`);
    }
    await pause(25);
  }
}

function run(command, args, options = {}) {
  const result = spawnSync(command, args, { encoding: "utf8", ...options });
  assert.equal(result.status, 0, `${command} ${args.join(" ")} failed:\n${result.stdout}\n${result.stderr}`);
  return result.stdout;
}

describe("report wake across a real linked worktree (PR393)", () => {
  it("wakes the main-checkout watch when ace-hitl create files the report in the coworker worktree", async () => {
    const dir = fs.mkdtempSync(path.join(os.tmpdir(), "pr393-wake-"));
    const main = path.join(dir, "main");
    const worker = path.join(dir, "worker");
    try {
      run("git", ["init", "-q", main]);
      run("git", ["-C", main, "-c", "user.name=Review", "-c", "user.email=review@example.invalid",
        "commit", "--allow-empty", "-qm", "fixture"]);
      run("git", ["-C", main, "worktree", "add", "-qb", "worker", worker]);
      fs.mkdirSync(path.join(main, ".ace-local", "hitl"), { recursive: true });

      // The same discovery the expansion port uses in production.
      const targets = expandInboxWatchTargets(main, ".ace-local/hitl");
      const real = (p) => fs.realpathSync(p);
      assert.ok(targets.includes(real(path.join(main, ".ace-local", "hitl"))), `main inbox missing: ${targets}`);
      assert.ok(targets.includes(path.join(real(worker), ".ace-local", "hitl")), `worker inbox missing: ${targets}`);

      let wakes = 0;
      const port = createWatchPort({
        watchFactory: nodeWatchFactory,
        statFn: nodeStatFn,
        baseDir: main,
        resolveTargets: (baseDir, configuredPath) => expandInboxWatchTargets(baseDir, configuredPath),
      });
      const stopWatch = () => port.stopAll();
      process.on("exit", stopWatch);
      try {
        port.start(
          { kind: "watch", name: "reports", path: ".ace-local/hitl", message: "new ace-hitl report; run /continue-work" },
          () => {
            wakes += 1;
            return { delivered: true };
          },
        );
        // The coworker files its report from INSIDE its own worktree. No
        // fixed pre-sleep: the reconcile pass covers the registration gap.
        const report = spawnSync(path.join(REPO_ROOT, "bin", "ace-hitl"),
          ["create", "Worker complete", "--type", "report", "--result", "success", "--body", "Done"],
          { cwd: worker, encoding: "utf8" });
        assert.equal(report.status, 0,
          `ace-hitl create failed: ${report.error ? report.error.message : ""}\n${report.stdout}\n${report.stderr}`);
        const workerInbox = path.join(worker, ".ace-local", "hitl");
        assert.ok(fs.readdirSync(workerInbox).length > 0, "the report must land in the worktree inbox");
        assert.equal(fs.readdirSync(path.join(main, ".ace-local", "hitl")).length, 0,
          "the main inbox is untouched: only cross-worktree expansion can wake");

        await waitFor(() => wakes >= 1, "the first cross-worktree report to wake");
        const wakesAfterFirst = wakes;

        // A SECOND report into the now-existing worktree inbox: Linux
        // inotify is non-recursive, so the ancestor watch the absent inbox
        // started with can never see it — the refresh pass must have
        // re-attached the inbox directory directly.
        const secondReport = spawnSync(path.join(REPO_ROOT, "bin", "ace-hitl"),
          ["create", "Worker follow-up", "--type", "report", "--result", "success", "--body", "More"],
          { cwd: worker, encoding: "utf8" });
        assert.equal(secondReport.status, 0,
          `second ace-hitl create failed: ${secondReport.error ? secondReport.error.message : ""}\n${secondReport.stdout}\n${secondReport.stderr}`);
        assert.ok(fs.readdirSync(workerInbox).length > 1, "the second report must land in the worktree inbox");

        await waitFor(() => wakes > wakesAfterFirst, "the second report into the formerly-absent inbox to wake");
        assert.ok(wakes > wakesAfterFirst, "the ancestor watch alone stayed deaf to the second report");
      } finally {
        stopWatch();
        process.off("exit", stopWatch);
      }
    } finally {
      fs.rmSync(dir, { recursive: true, force: true });
    }
  });
});
