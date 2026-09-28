import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { createWatchPort } from "../../handbook/extensions/wake/watch-subscription.mjs";
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
});
