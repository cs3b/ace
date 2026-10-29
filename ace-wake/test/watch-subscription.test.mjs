import * as assert from "node:assert/strict";
import { createHash } from "node:crypto";
import * as nodeFs from "node:fs";
import * as nodeOs from "node:os";
import * as nodePath from "node:path";
import { describe, it } from "node:test";

import {
  createWatchPort,
  nodeStatFn,
  nodeWatchFactory,
} from "../handbook/extensions/ace-wake/wake/watch-subscription.js";
import { WakeDispatcher } from "../handbook/extensions/ace-wake/wake/wake-dispatcher.js";
import { createFakeHost } from "./fake-pi-host.mjs";

const WATCHED = "/fake/project/dep.txt";

function startWatch(host, overrides = {}) {
  const port = createWatchPort({
    watchFactory: host.watchFactory,
    statFn: host.statFn,
    baseDir: "/fake/project",
  });
  const wakes = [];
  host.setFile(WATCHED, { mtimeMs: 100, size: 10 });
  const canonical = port.start(
    { kind: "watch", name: "dep", path: overrides.path ?? WATCHED, message: "changed" },
    () => wakes.push(1),
  );
  return { port, wakes, canonical };
}

describe("createWatchPort", () => {
  it("resolves relative paths against the base directory", () => {
    const host = createFakeHost();
    const { canonical } = startWatch(host, { path: "dep.txt" });

    assert.equal(canonical, WATCHED);
    assert.equal(host.watcherCount(), 1);
  });

  it("rejects unreadable paths with a visible error at add time", () => {
    const host = createFakeHost();
    const port = createWatchPort({
      watchFactory: host.watchFactory,
      statFn: host.statFn,
      baseDir: "/fake/project",
    });

    assert.throws(
      () => port.start({ kind: "watch", name: "ghost", path: "/fake/project/ghost.txt", message: "m" }, () => {}),
      /path is not readable: .*ghost\.txt/,
    );
    assert.equal(host.watcherCount(), 0);
  });

  it("establishes a baseline without emitting an initial wake", () => {
    const host = createFakeHost();
    const { wakes } = startWatch(host);

    assert.equal(wakes.length, 0);
  });

  it("emits exactly one wake for a later fingerprint change", () => {
    const host = createFakeHost();
    const { wakes } = startWatch(host);

    host.setFile(WATCHED, { mtimeMs: 200, size: 12 });
    host.triggerWatch(WATCHED);

    assert.equal(wakes.length, 1);
  });

  it("reconciles a change dropped during watcher initialization", () => {
    const host = createFakeHost();
    const reconciles = [];
    const port = createWatchPort({
      watchFactory: host.watchFactory,
      statFn: host.statFn,
      baseDir: "/fake/project",
      scheduleReconcile: (reconcile) => reconciles.push(reconcile),
    });
    const wakes = [];
    host.setFile(WATCHED, { mtimeMs: 100, size: 10 });
    port.start({ kind: "watch", name: "dep", path: WATCHED, message: "changed" }, () => wakes.push(1));

    // The change lands in the registration gap: the watcher never fires.
    host.setFile(WATCHED, { mtimeMs: 200, size: 12 });
    assert.equal(wakes.length, 0);

    // The post-registration reconcile pass re-stats and catches the change.
    assert.equal(reconciles.length, 1);
    reconciles[0]();

    assert.equal(wakes.length, 1, "the registration-gap change must wake via reconcile");
  });

  it("ignores events that do not change the fingerprint", () => {
    const host = createFakeHost();
    const { wakes } = startWatch(host);

    host.triggerWatch(WATCHED);
    host.triggerWatch(WATCHED);

    assert.equal(wakes.length, 0);
  });

  it("marks the subscription inactive with the error and closes the watcher when the path vanishes", () => {
    const host = createFakeHost();
    const { port, wakes } = startWatch(host);

    host.setFile(WATCHED, { missing: true });
    host.triggerWatch(WATCHED);

    assert.match(port.errorOf("dep"), /ENOENT/);
    assert.equal(host.watcherCount(), 0, "watcher must be closed, not left spinning");
    assert.equal(port.activeCount(), 0, "no retries after deactivation");
    assert.equal(wakes.length, 0);
  });

  it("keeps the delivered fingerprint when a wake coalesces so the change is not lost", () => {    const host = createFakeHost();
    const dispatcher = new WakeDispatcher({ deliver: () => true });
    const port = createWatchPort({
      watchFactory: host.watchFactory,
      statFn: host.statFn,
      baseDir: "/fake/project",
    });
    host.setFile(WATCHED, { mtimeMs: 100, size: 10 });
    port.start(
      { kind: "watch", name: "dep", path: WATCHED, message: "changed" },
      () => dispatcher.wake("watch:dep", "changed"),
    );

    // Delivered change advances the baseline.
    host.setFile(WATCHED, { mtimeMs: 200, size: 12 });
    host.triggerWatch(WATCHED);
    assert.equal(dispatcher.pending.has("watch:dep"), true);

    // A second change whose wake coalesces must NOT advance the fingerprint:
    // the queued wake covers it, so after settlement a duplicate directory
    // event for the same state still wakes instead of being silently lost.
    host.setFile(WATCHED, { mtimeMs: 300, size: 14 });
    host.triggerWatch(WATCHED);

    dispatcher.settle("watch:dep");
    host.triggerWatch(WATCHED);

    assert.equal(host.watcherCount(), 1);
    assert.equal(port.errorOf("dep"), undefined);
    // The second change eventually produced its own wake: the fingerprint
    // advanced past the coalesced state (visible as a fresh pending wake).
    assert.equal(dispatcher.pending.has("watch:dep"), true);
  });

  it("deactivates on watcher runtime errors without retrying", () => {
    const host = createFakeHost();
    const { port, wakes } = startWatch(host);

    host.failWatch(WATCHED, "EMFILE: too many open files");

    assert.match(port.errorOf("dep"), /EMFILE/);
    assert.equal(host.watcherCount(), 0);
    assert.equal(wakes.length, 0);
  });

  it("stop closes the watcher and prevents future wakes", () => {
    const host = createFakeHost();
    const { port, wakes } = startWatch(host);

    port.stop("dep");
    assert.equal(host.watcherCount(), 0, "native handle must be closed on removal");
    assert.equal(port.errorOf("dep"), undefined);
    assert.equal(wakes.length, 0);
  });

  it("stopAll closes every watcher and clears error state", () => {
    const host = createFakeHost();
    const port = createWatchPort({
      watchFactory: host.watchFactory,
      statFn: host.statFn,
      baseDir: "/fake/project",
    });
    host.setFile(WATCHED, { mtimeMs: 1, size: 1 });
    host.setFile("/fake/project/other.txt", { mtimeMs: 1, size: 1 });
    port.start({ kind: "watch", name: "dep", path: WATCHED, message: "m" }, () => {});
    port.start({ kind: "watch", name: "other", path: "/fake/project/other.txt", message: "m" }, () => {});
    host.failWatch(WATCHED, "boom");

    port.stopAll();

    assert.equal(host.watcherCount(), 0);
    assert.equal(port.errorOf("dep"), undefined);
    assert.equal(port.activeCount(), 0);
  });

  it("invokes the onDeactivate hook when a runtime error deactivates a watch", () => {
    const host = createFakeHost();
    let deactivations = 0;
    const port = createWatchPort({
      watchFactory: host.watchFactory,
      statFn: host.statFn,
      baseDir: "/fake/project",
      onDeactivate: () => {
        deactivations += 1;
      },
    });
    host.setFile(WATCHED, { mtimeMs: 1, size: 1 });
    port.start({ kind: "watch", name: "dep", path: WATCHED, message: "m" }, () => {});

    host.setFile(WATCHED, { missing: true });
    host.triggerWatch(WATCHED);

    assert.equal(deactivations, 1, "callers must learn about deactivation to refresh status");
  });
});

describe("createWatchPort wake delta", () => {
  const FILE = "/fake/project/dep.txt";

  const sha = (content) => `sha256:${createHash("sha256").update(content).digest("hex")}`;

  function startDeltaWatch(host, contents, overrides = {}) {
    const port = createWatchPort({
      watchFactory: host.watchFactory,
      statFn: host.statFn,
      readFn: overrides.readFn ?? ((path) => contents.get(path)),
      baseDir: "/fake/project",
      ...overrides.ports,
    });
    const wakes = [];
    host.setFile(FILE, { mtimeMs: 100, size: contents.get(FILE)?.length ?? 10 });
    port.start(
      { kind: "watch", name: "dep", path: overrides.path ?? FILE, message: "changed" },
      (_definition, delta) => wakes.push(delta),
    );
    return { port, wakes };
  }

  it("delivers path, change kind, BEFORE→AFTER signatures, and a capped sanitized excerpt", () => {
    const host = createFakeHost();
    const contents = new Map([[FILE, Buffer.from("alpha")]]);
    const { wakes } = startDeltaWatch(host, contents);
    assert.equal(wakes.length, 0, "registration never wakes");

    const next = Buffer.from(`beta line\n\n${"x".repeat(400)}`);
    contents.set(FILE, next);
    host.setFile(FILE, { mtimeMs: 200, size: next.length });
    host.triggerWatch(FILE);

    assert.equal(wakes.length, 1);
    const [delta] = wakes.flat();
    assert.equal(delta.path, FILE);
    assert.equal(delta.kind, "modified");
    assert.equal(delta.before, sha("alpha"));
    assert.equal(delta.after, sha(next));
    assert.ok(delta.excerpt.startsWith("beta line x"), `sanitized to one line, got: ${delta.excerpt}`);
    assert.ok(!delta.excerpt.includes("\n"), "excerpt must be a single sanitized line");
    assert.ok(delta.excerpt.length <= 200, `excerpt capped at ~200 bytes, got ${delta.excerpt.length}`);
  });

  it("does not wake again when a readable file is rewritten with identical content", () => {
    const host = createFakeHost();
    const contents = new Map([[FILE, Buffer.from("same bytes")]]);
    const { port, wakes } = startDeltaWatch(host, contents);

    // A real content change wakes once.
    contents.set(FILE, Buffer.from("new bytes"));
    host.setFile(FILE, { mtimeMs: 200, size: 9 });
    host.triggerWatch(FILE);
    assert.equal(wakes.length, 1);

    // The same content rewritten (fresh mtime, same bytes) is NOT a change:
    // the content-hash signature filters the touch.
    contents.set(FILE, Buffer.from("new bytes"));
    host.setFile(FILE, { mtimeMs: 300, size: 9 });
    host.triggerWatch(FILE);
    assert.equal(wakes.length, 1, "an identical-content rewrite must not wake twice");
    assert.equal(port.errorOf("dep"), undefined);
  });

  it("wakes on a content change even when stat metadata is unchanged", () => {
    const host = createFakeHost();
    const contents = new Map([[FILE, Buffer.from("one")]]);
    const { wakes } = startDeltaWatch(host, contents);

    contents.set(FILE, Buffer.from("two"));
    host.setFile(FILE, { mtimeMs: 100, size: 3 });
    host.triggerWatch(FILE);

    assert.equal(wakes.length, 1, "an mtime-undetectable content rewrite must wake via the hash");
    assert.equal(wakes.flat()[0].after, sha("two"));
  });

  it("falls back to stat-only signatures when the content is unreadable", () => {
    const host = createFakeHost();
    const { wakes } = startDeltaWatch(host, new Map(), { readFn: () => undefined });

    host.setFile(FILE, { mtimeMs: 200, size: 12 });
    host.triggerWatch(FILE);

    assert.equal(wakes.length, 1);
    const [delta] = wakes.flat();
    assert.equal(delta.kind, "modified");
    assert.equal(delta.before, "100:10", "the stat pair is the signature when content is unreadable");
    assert.equal(delta.after, "200:12");
    assert.equal(delta.excerpt, undefined, "no excerpt without readable content");
  });

  it("reports created and deleted kinds for absent→present and present→absent targets", () => {
    const host = createFakeHost();
    const contents = new Map();
    const reconciles = [];
    const targets = ["/fake/project/.ace-local/hitl", "/fake/wt/task-9/.ace-local/hitl"];
    host.setFile("/fake/project/.ace-local/hitl", { mtimeMs: 1, size: 10 });
    host.setFile("/fake/wt/task-9/.ace-local", { mtimeMs: 1, size: 1 });
    const port = createWatchPort({
      watchFactory: host.watchFactory,
      statFn: host.statFn,
      readFn: (path) => contents.get(path),
      baseDir: "/fake/project",
      resolveTargets: () => [...targets],
      scheduleReconcile: (reconcile) => reconciles.push(reconcile),
    });
    const wakes = [];
    port.start(
      { kind: "watch", name: "reports", path: "/fake/project/.ace-local/hitl", message: "m" },
      (_definition, delta) => wakes.push(delta),
    );

    // The worktree inbox did not exist at registration (watched through its
    // ancestor, baseline records the proven absent state): its appearance is
    // a creation.
    contents.set(targets[1], Buffer.from("first report"));
    host.setFile(targets[1], { mtimeMs: 5, size: 12 });
    host.triggerWatch("/fake/wt/task-9/.ace-local");
    assert.equal(wakes.length, 1);
    const created = wakes.flat().find((delta) => delta.path === targets[1]);
    assert.equal(created.kind, "created");
    assert.equal(created.before, "absent");
    assert.equal(created.after, sha(Buffer.from("first report")));
    assert.equal(created.excerpt, "first report");

    // The target's disappearance (worktree inbox removed without a watcher
    // error) is a deletion.
    wakes.length = 0;
    contents.delete(targets[1]);
    host.setFile(targets[1], { missing: true });
    host.triggerWatch(targets[1]);
    assert.equal(wakes.length, 1);
    const deleted = wakes.flat().find((delta) => delta.path === targets[1]);
    assert.equal(deleted.kind, "deleted");
    assert.equal(deleted.after, "absent");
    assert.equal(deleted.excerpt, undefined, "a deleted target has no excerpt");
  });
});

describe("createWatchPort runtime target discovery", () => {
  const MAIN_INBOX = "/fake/project/.ace-local/hitl";
  const WORKTREE_INBOX = "/fake/wt/task-9/.ace-local/hitl";
  const WORKTREE_PARENT = "/fake/wt/task-9/.ace-local";

  function startDiscoveryWatch(host, { targets, onDeactivate, statFn } = {}) {
    const reconciles = [];
    const port = createWatchPort({
      watchFactory: host.watchFactory,
      statFn: statFn ?? host.statFn,
      baseDir: "/fake/project",
      resolveTargets: () => [...targets],
      scheduleReconcile: (reconcile) => reconciles.push(reconcile),
      onDeactivate,
    });
    const wakes = [];
    const onWake = () => {
      wakes.push(1);
      return { delivered: true };
    };
    host.setFile(MAIN_INBOX, { mtimeMs: 1, size: 10 });
    port.start({ kind: "watch", name: "reports", path: MAIN_INBOX, message: "m" }, onWake);
    return { port, wakes, onWake, reconciles };
  }

  it("discovers a late-linked worktree at a settlement boundary with no watched-path event", () => {
    const host = createFakeHost();
    const targets = [MAIN_INBOX];
    const { port, wakes, onWake, reconciles } = startDiscoveryWatch(host, { targets });

    // Production ordering: the one-shot post-registration reconcile has
    // already run and settled before the worktree is linked.
    reconciles.splice(0).forEach((reconcile) => reconcile());
    assert.equal(wakes.length, 0);

    // The worktree is linked long after start and its FIRST report lands
    // in its own inbox — a path no watcher covers, so no event can fire.
    targets.push(WORKTREE_INBOX);
    host.setFile(WORKTREE_INBOX, { mtimeMs: 10, size: 100 });
    assert.equal(wakes.length, 0, "nothing is watched on the new path yet");

    // The settlement boundary (flushDirty) is the only remaining channel.
    port.flushDirty(onWake);

    assert.equal(wakes.length, 1,
      "a late-linked worktree's first report must wake at the settlement boundary");
    assert.deepEqual(host.watcherPaths().sort(), [MAIN_INBOX, WORKTREE_INBOX].sort(),
      "the discovered inbox must now be watched directly");
  });

  it("does not absorb a report created between the discovery stat and the baseline recomputation", () => {
    const host = createFakeHost();
    host.setFile(WORKTREE_PARENT, { mtimeMs: 1, size: 1 });
    // Inject the production micro-race precisely: the report is created at
    // the moment the discovery stat of the absent inbox throws — after the
    // proof of absence, before the baseline fingerprint recomputation.
    let raceInjected = false;
    const realStatFn = host.statFn;
    const racingStatFn = (path) => {
      try {
        return realStatFn(path);
      } catch (error) {
        if (path === WORKTREE_INBOX && !raceInjected) {
          raceInjected = true;
          host.setFile(WORKTREE_INBOX, { mtimeMs: 10, size: 100 });
        }
        throw error;
      }
    };
    const { port, wakes } = startDiscoveryWatch(host, {
      targets: [MAIN_INBOX, WORKTREE_INBOX],
      statFn: racingStatFn,
    });
    assert.ok(raceInjected, "the race window must have been exercised");
    assert.equal(wakes.length, 0, "registration itself never wakes");

    // The registration-time baseline must record the PROVEN absent state,
    // so the post-registration reconcile (scheduled by start()) delivers
    // the race-window report instead of silently absorbing it.
    port.flushDirty(() => {
      wakes.push(1);
      return { delivered: true };
    });

    assert.equal(wakes.length, 1, "the race-window report must not be absorbed into the baseline");
    assert.ok(host.watcherPaths().includes(WORKTREE_INBOX),
      `the now-existing inbox must be watched directly, got ${host.watcherPaths()}`);
  });

  it("drops only the failed extra target's watcher and keeps the subscription", () => {
    const host = createFakeHost();
    host.setFile(WORKTREE_INBOX, { mtimeMs: 1, size: 1 });
    let deactivations = 0;
    const { port, wakes } = startDiscoveryWatch(host, {
      targets: [MAIN_INBOX, WORKTREE_INBOX],
      onDeactivate: () => {
        deactivations += 1;
      },
    });
    assert.equal(host.watcherCount(), 2);

    // ace-overseer prune removed the watched worktree: its watcher errors
    // while the primary inbox stays healthy.
    host.setFile(WORKTREE_INBOX, { missing: true });
    host.failWatch(WORKTREE_INBOX, "EPERM: watch lost");

    assert.equal(port.activeCount(), 1, "the subscription must stay active");
    assert.equal(port.errorOf("reports"), undefined, "a dropped target is not a subscription error");
    assert.equal(deactivations, 0, "onDeactivate must not fire while the subscription lives");
    assert.equal(host.watcherCount(), 1, "only the failed target's watcher closed");
    assert.equal(wakes.length, 0, "a pruned worktree must not wake");

    // The surviving primary still wakes on its own changes.
    host.setFile(MAIN_INBOX, { mtimeMs: 20, size: 40 });
    host.triggerWatch(MAIN_INBOX);
    assert.equal(wakes.length, 1, "the primary target keeps the wake posture");
  });

  it("still delivers a pending undelivered wake when an extra target drops at settlement", () => {
    const host = createFakeHost();
    const reconciles = [];
    const port = createWatchPort({
      watchFactory: host.watchFactory,
      statFn: host.statFn,
      baseDir: "/fake/project",
      resolveTargets: () => [MAIN_INBOX, WORKTREE_INBOX],
      scheduleReconcile: (reconcile) => reconciles.push(reconcile),
    });
    host.setFile(MAIN_INBOX, { mtimeMs: 1, size: 10 });
    host.setFile(WORKTREE_INBOX, { mtimeMs: 1, size: 100 });
    const wakes = [];
    port.start({ kind: "watch", name: "reports", path: MAIN_INBOX, message: "m" }, () => ({ delivered: false }));
    reconciles.splice(0).forEach((reconcile) => reconcile());

    // A report lands on the primary while its wake is deferred
    // (delivered: false): the fingerprint stays at the pre-report state
    // and the subscription is marked dirty.
    host.setFile(MAIN_INBOX, { mtimeMs: 20, size: 40 });
    host.triggerWatch(MAIN_INBOX);
    assert.equal(wakes.length, 0);

    // At the settlement boundary the extra target's worktree is pruned:
    // dropTarget runs while the primary's change is still undelivered.
    host.setFile(WORKTREE_INBOX, { missing: true });
    host.failWatch(WORKTREE_INBOX, "EPERM: watch lost");
    assert.equal(port.activeCount(), 1, "the subscription must stay active");

    // Dropping the extra target must NOT absorb the pending primary
    // change into the baseline: the deferred report wake still delivers.
    port.flushDirty(() => {
      wakes.push(1);
      return { delivered: true };
    });

    assert.equal(wakes.length, 1, "the pending undelivered wake must survive the extra target drop");
    assert.equal(port.errorOf("reports"), undefined);
  });

  it("does not throw from dropTarget when the primary was deleted just before the extra target's watcher error", () => {
    const host = createFakeHost();
    const port = createWatchPort({
      watchFactory: host.watchFactory,
      statFn: host.statFn,
      baseDir: "/fake/project",
      resolveTargets: () => [MAIN_INBOX, WORKTREE_INBOX],
      scheduleReconcile: () => {},
    });
    host.setFile(MAIN_INBOX, { mtimeMs: 1, size: 10 });
    host.setFile(WORKTREE_INBOX, { mtimeMs: 1, size: 100 });
    port.start({ kind: "watch", name: "reports", path: MAIN_INBOX, message: "m" }, () => ({ delivered: true }));

    // The primary is deleted right before the extra target's watcher
    // errors: dropTarget (inside a native onError callback) must not
    // throw uncaught into the extension host.
    host.setFile(MAIN_INBOX, { missing: true });
    host.setFile(WORKTREE_INBOX, { missing: true });
    host.failWatch(WORKTREE_INBOX, "EPERM: watch lost");
    assert.equal(port.activeCount(), 1, "the drop itself must not deactivate the subscription");

    // The primary's own watcher error still deactivates with a visible
    // error through the documented path.
    host.failWatch(MAIN_INBOX, "ENOENT: primary gone");
    assert.match(port.errorOf("reports"), /ENOENT/);
    assert.equal(port.activeCount(), 0);
  });
});

describe("nodeWatchFactory on the real filesystem", { timeout: 20_000 }, () => {
  it("resolves symlinked watch paths to their filesystem target", async () => {
    const tmp = nodeFs.mkdtempSync(nodePath.join(nodeOs.tmpdir(), "wake-symlink-"));
    const realFile = nodePath.join(tmp, "real.txt");
    const link = nodePath.join(tmp, "link.txt");
    nodeFs.writeFileSync(realFile, "version-1");
    nodeFs.symlinkSync(realFile, link);

    const port = createWatchPort({
      watchFactory: nodeWatchFactory,
      statFn: nodeStatFn,
      baseDir: tmp,
    });
    const wakes = [];
    const canonical = port.start(
      { kind: "watch", name: "via-link", path: link, message: "m" },
      () => wakes.push(1),
    );

    assert.equal(canonical, nodeFs.realpathSync(realFile), "the canonical path must be the symlink target");

    nodeFs.writeFileSync(realFile, "version-2 with more content");
    await waitFor(() => wakes.length === 1, { timeoutMs: 10_000 });
    assert.equal(wakes.length, 1, "writes to the symlink target must wake");

    port.stopAll();
    nodeFs.rmSync(tmp, { recursive: true, force: true });
  });

  it("wakes exactly once when a file is created inside a watched directory", async () => {
    const tmp = nodeFs.mkdtempSync(nodePath.join(nodeOs.tmpdir(), "wake-dir-"));

    const port = createWatchPort({
      watchFactory: nodeWatchFactory,
      statFn: nodeStatFn,
      baseDir: tmp,
    });
    const wakes = [];
    port.start({ kind: "watch", name: "inbox", path: tmp, message: "m" }, () => wakes.push(1));

    // A child file appearing inside the watched directory (the ace-hitl
    // inbox wiring) must wake exactly once on every platform: Linux inotify
    // delivers child-create events only to a watch on the directory itself.
    nodeFs.writeFileSync(nodePath.join(tmp, "event-1.md"), "report body");
    await waitFor(() => wakes.length === 1, { timeoutMs: 10_000 });
    assert.equal(wakes.length, 1, "a file created inside the watched directory must wake");

    // Duplicate platform events for the same state stay filtered.
    await new Promise((resolve) => setTimeout(resolve, 700));
    assert.equal(wakes.length, 1, "no extra wakes for the same directory state");

    port.stopAll();
    nodeFs.rmSync(tmp, { recursive: true, force: true });
  });

  it("rejects existing files whose contents are not readable", () => {
    if (process.platform === "win32") {
      return; // POSIX permission bits do not apply.
    }
    const tmp = nodeFs.mkdtempSync(nodePath.join(nodeOs.tmpdir(), "wake-mode-"));
    const target = nodePath.join(tmp, "secret.txt");
    nodeFs.writeFileSync(target, "contents");
    nodeFs.chmodSync(target, 0o000);

    const port = createWatchPort({
      watchFactory: nodeWatchFactory,
      statFn: nodeStatFn,
      baseDir: tmp,
    });

    assert.throws(
      () => port.start({ kind: "watch", name: "secret", path: target, message: "m" }, () => {}),
      /path is not readable/,
      "stat metadata alone must not pass validation when the file cannot be read",
    );

    nodeFs.chmodSync(target, 0o644);
    nodeFs.rmSync(tmp, { recursive: true, force: true });
  });

  it("keeps waking across atomic replacement of the watched file", async () => {
    const tmp = nodeFs.mkdtempSync(nodePath.join(nodeOs.tmpdir(), "wake-atomic-"));
    const target = nodePath.join(tmp, "state.json");
    nodeFs.writeFileSync(target, "version-1");

    const port = createWatchPort({
      watchFactory: nodeWatchFactory,
      statFn: nodeStatFn,
      baseDir: tmp,
    });
    const wakes = [];
    port.start({ kind: "watch", name: "state", path: target, message: "m" }, () => wakes.push(1));

    const replace = (content) => {
      const temp = nodePath.join(tmp, `state.json.tmp-${Date.now()}`);
      nodeFs.writeFileSync(temp, content);
      nodeFs.renameSync(temp, target);
    };

    // Direct in-place write.
    replace("version-2");
    await waitFor(() => wakes.length === 1);
    assert.equal(wakes.length, 1, "in-place change must wake");

    // Atomic replacement: a second rename after the first must still wake,
    // proving the subscription did not stay attached to the original inode.
    await new Promise((resolve) => setTimeout(resolve, 300));
    replace("version-3 with different content length");
    await waitFor(() => wakes.length === 2, { timeoutMs: 10_000 });
    assert.equal(wakes.length, 2, "atomic replacement must not detach the watch");

    // An unrelated sibling event must not wake.
    await new Promise((resolve) => setTimeout(resolve, 300));
    nodeFs.writeFileSync(nodePath.join(tmp, "unrelated.txt"), "noise");
    await new Promise((resolve) => setTimeout(resolve, 700));
    assert.equal(wakes.length, 2, "sibling events in the directory must be filtered out");

    port.stopAll();
    nodeFs.rmSync(tmp, { recursive: true, force: true });
  });
});

function waitFor(predicate, { timeoutMs = 10_000, stepMs = 100 } = {}) {
  return new Promise((resolve) => {
    const deadline = Date.now() + timeoutMs;
    const check = () => {
      if (predicate() || Date.now() > deadline) {
        resolve(predicate());
        return;
      }
      setTimeout(check, stepMs);
    };
    check();
  });
}
