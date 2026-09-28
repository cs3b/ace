import * as assert from "node:assert/strict";
import * as nodeFs from "node:fs";
import * as nodeOs from "node:os";
import * as nodePath from "node:path";
import { describe, it } from "node:test";

import {
  createWatchPort,
  nodeStatFn,
  nodeWatchFactory,
} from "../../handbook/extensions/ace-wake/wake/watch-subscription.js";
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

describe("nodeWatchFactory on the real filesystem", { timeout: 20_000 }, () => {
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
