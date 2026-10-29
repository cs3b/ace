import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { createWatchPort } from "../handbook/extensions/ace-wake/wake/watch-subscription.js";
import { createFakeHost } from "./fake-pi-host.mjs";

// The HITL transport folder (/lab/state/hitl-address/ace) is a FUSE/virtiofs
// mount whose inotify event delivery is deaf: a registered /watch never
// fires there. These tests pin the mount-aware poll fallback through the
// same injected-ports pattern as watch-subscription.test.mjs — a statfsFn
// port classifies the mount, and a reconcile timer re-stats the fingerprint
// so a watcher whose fs.watch never fires still wakes.

const TRANSPORT_INBOX = "/fake/state/hitl-address/ace";
const LOCAL_INBOX = "/fake/project/.ace-local/hitl";
const POLL_INTERVAL_MS = 20;

const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

/**
 * Await a condition on the real clock: the poll timer runs on real timers,
 * so the suite polls a short predicate instead of sleeping a fixed gap.
 *
 * @param {() => boolean} predicate
 * @param {string} description
 * @param {number} timeoutMs
 */
async function waitFor(predicate, description, timeoutMs = 2000) {
  const deadline = Date.now() + timeoutMs;
  for (;;) {
    if (predicate()) {
      return;
    }
    if (Date.now() >= deadline) {
      assert.fail(`timed out waiting for ${description}`);
    }
    await pause(10);
  }
}

function startSilentWatch(host, { path, statfsFn, pollIntervalMs = POLL_INTERVAL_MS } = {}) {
  const port = createWatchPort({
    watchFactory: host.watchFactory,
    statFn: host.statFn,
    statfsFn,
    pollIntervalMs,
    baseDir: "/fake",
  });
  const wakes = [];
  port.start(
    { kind: "watch", name: "transport", path: path ?? TRANSPORT_INBOX, message: "new answer" },
    (definition, delta) => {
      wakes.push({ definition, delta });
      return { delivered: true };
    },
  );
  return { port, wakes };
}

describe("poll fallback on mounts with unreliable inotify events", () => {
  it("wakes via the reconcile timer when fs.watch never fires on a virtiofs mount", async () => {
    const host = createFakeHost();
    host.setFile(TRANSPORT_INBOX, { mtimeMs: 100, size: 10 });
    const { port, wakes } = startSilentWatch(host, { statfsFn: () => ({ type: "virtiofs" }) });

    // fs.watch stays attached (primary everywhere), even though it will
    // never fire on this mount.
    assert.equal(host.watcherCount(), 1);

    // The counterpart answers while the session waits; the deaf mount
    // delivers no event, so only the poll fallback can wake.
    host.setFile(TRANSPORT_INBOX, { mtimeMs: 200, size: 12 });
    await waitFor(() => wakes.length >= 1, "the poll fallback to wake on the deaf mount");

    assert.equal(wakes.length, 1, "one change wakes exactly once");
    assert.equal(wakes[0].definition.name, "transport");
    assert.equal(wakes[0].delta.length, 1);
    assert.equal(wakes[0].delta[0].path, TRANSPORT_INBOX);
    assert.equal(wakes[0].delta[0].kind, "modified");

    // The fingerprint advanced with the wake: the next tick re-stats the
    // same state and must not re-wake.
    await pause(POLL_INTERVAL_MS * 3);
    assert.equal(wakes.length, 1);

    port.stopAll();
  });

  it("classifies the Linux f_type magic number for virtiofs the same as the string form", async () => {
    const host = createFakeHost();
    host.setFile(TRANSPORT_INBOX, { mtimeMs: 100, size: 10 });
    const { port, wakes } = startSilentWatch(host, {
      statfsFn: () => ({ type: 0x49475649 }),
    });

    host.setFile(TRANSPORT_INBOX, { mtimeMs: 300, size: 14 });
    await waitFor(() => wakes.length >= 1, "the numeric virtiofs magic to join the poll fallback");
    port.stopAll();
  });

  it("keeps fs.watch primary on reliable mounts: a silent watcher never polls", async () => {
    const host = createFakeHost();
    host.setFile(LOCAL_INBOX, { mtimeMs: 100, size: 10 });
    const { port, wakes } = startSilentWatch(host, {
      path: LOCAL_INBOX,
      statfsFn: () => ({ type: "ext4" }),
    });

    assert.equal(host.watcherCount(), 1);
    host.setFile(LOCAL_INBOX, { mtimeMs: 200, size: 12 });
    await pause(POLL_INTERVAL_MS * 5);
    assert.equal(wakes.length, 0, "a reliable mount relies on fs.watch events only");

    // The same port still wakes through the watcher callback path.
    host.triggerWatch(LOCAL_INBOX);
    await waitFor(() => wakes.length >= 1, "the fs.watch callback to wake on the reliable mount");
    port.stopAll();
  });

  it("keeps fs.watch primary when the mount type is unavailable", async () => {
    const host = createFakeHost();
    host.setFile(TRANSPORT_INBOX, { mtimeMs: 100, size: 10 });
    const { port, wakes } = startSilentWatch(host, {
      statfsFn: () => {
        throw new Error("statfs is not available on this platform");
      },
    });

    host.setFile(TRANSPORT_INBOX, { mtimeMs: 200, size: 12 });
    await pause(POLL_INTERVAL_MS * 5);
    assert.equal(wakes.length, 0, "a failed statfs must not silently start polling");

    host.triggerWatch(TRANSPORT_INBOX);
    await waitFor(() => wakes.length >= 1, "the fs.watch callback to still wake");
    port.stopAll();
  });

  it("disarms the reconcile timer when the unreliable subscription is removed", async () => {
    const host = createFakeHost();
    host.setFile(TRANSPORT_INBOX, { mtimeMs: 100, size: 10 });
    const { port, wakes } = startSilentWatch(host, { statfsFn: () => ({ type: "fuse" }) });

    port.stop("transport");
    host.setFile(TRANSPORT_INBOX, { mtimeMs: 200, size: 12 });
    await pause(POLL_INTERVAL_MS * 5);
    assert.equal(wakes.length, 0, "a removed subscription must not be polled");
  });

  it("covers a discovered extra target that joins an unreliable mount after registration", async () => {
    const host = createFakeHost();
    host.setFile(LOCAL_INBOX, { mtimeMs: 100, size: 10 });
    let discovered = [LOCAL_INBOX];
    const port = createWatchPort({
      watchFactory: host.watchFactory,
      statFn: host.statFn,
      statfsFn: (path) => ({ type: path === LOCAL_INBOX ? "ext4" : "virtiofs" }),
      pollIntervalMs: POLL_INTERVAL_MS,
      baseDir: "/fake",
      resolveTargets: () => discovered,
    });
    const wakes = [];
    port.start(
      { kind: "watch", name: "reports", path: LOCAL_INBOX, message: "new report" },
      (_definition, delta) => {
        wakes.push(delta);
        return { delivered: true };
      },
    );
    host.triggerWatch(LOCAL_INBOX);

    // A linked worktree's inbox on the transport mount appears after
    // registration; a discovery pass (forced by one unrelated primary event)
    // attaches it, and a report landing there afterwards produces no
    // fs.watch event at all — only the poll fallback can wake.
    discovered = [LOCAL_INBOX, TRANSPORT_INBOX];
    host.setFile(TRANSPORT_INBOX, { mtimeMs: 100, size: 10 });
    host.triggerWatch(LOCAL_INBOX);
    host.setFile(TRANSPORT_INBOX, { mtimeMs: 200, size: 12 });

    await waitFor(
      () => wakes.some((delta) => delta.some((entry) => entry.path === TRANSPORT_INBOX)),
      "the newly discovered unreliable target to join the poll fallback",
    );
    port.stopAll();
  });
});
