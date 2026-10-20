import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { createFakeHost } from "./fake-pi-host.mjs";
import { startSession } from "./session-harness.mjs";

// L7.3 acceptance scenarios (8xg.t.sbz.6.2): a report notification reaches a
// pi overseer session through the ace-wake watch on the ace-hitl inbox
// directory. The scenarios assert the composed behavior the spec requires:
// wake-on-report for a waiting session, queued follow-up (never a second
// execution) during an active turn, exactly-once re-registration after
// restart, and idempotence of repeated notifications.

const HITL_DIR = "/fake/project/.ace-local/hitl";
const WAKE_TEXT = /watch:reports/;

/** A session with the report watch configured on the hitl inbox directory. */
async function overseerSession() {
  const host = createFakeHost();
  host.setFile(HITL_DIR, { mtimeMs: 1, size: 10 });
  const session = await startSession(host);
  await host.runCommand("watch", "add reports --path .ace-local/hitl --message new ace-hitl report; run /continue-work");
  return { host, session };
}

/** Simulate ace-hitl writing a report event into the inbox directory. */
function reportArrives(host, sequence) {
  host.setFile(HITL_DIR, { mtimeMs: sequence, size: 10 + sequence });
  host.triggerWatch(HITL_DIR);
}

function reportSends(host) {
  return host.sends.filter((send) => WAKE_TEXT.test(send.text));
}

describe("report wake (L7.3 continuation transport)", () => {
  it("wakes a waiting overseer exactly once with a bounded source-prefixed message", async () => {
    const { host } = await overseerSession();

    reportArrives(host, 2);

    const sends = reportSends(host);
    assert.equal(sends.length, 1, "exactly one wake for one report");
    assert.match(sends[0].text, /\[ace-wake watch:reports\] new ace-hitl report; run \/continue-work/);
  });

  it("delivers a report during an active turn as a queued follow-up, never a second execution", async () => {
    const { host } = await overseerSession();

    // The overseer session is mid-run: Pi accepts the message into its
    // follow-up queue for THIS session instead of starting another run.
    host.setIdle(false);
    reportArrives(host, 2);

    const sends = reportSends(host);
    assert.equal(sends.length, 1);
    // This pins the queue-only delivery contract (every wake is a queued
    // follow-up, never an interrupting send); the single-execution semantics
    // themselves live in pi's host, which this fake cannot falsify.
    assert.equal(sends[0].deliverAs, "followUp", "active turns receive queued follow-ups");

    // Repeated notifications while the wake is still pending coalesce into
    // the one queued message — no storm, no second delivery channel.
    reportArrives(host, 3);
    reportArrives(host, 4);
    assert.equal(reportSends(host).length, 1, "pending report wakes coalesce repeats");
  });

  it("re-arms the report watch exactly once after restart and continues waking", async () => {
    const { host, session } = await overseerSession();
    reportArrives(host, 2);
    assert.equal(reportSends(host).length, 1);

    host.resetSends();
    await session.reload();

    assert.equal(host.watcherCount(), 1, "restart re-registers the report watch exactly once");
    assert.equal(reportSends(host).length, 0, "restart never replays past reports");

    // The same commissioned process continues: the next report wakes the
    // restarted session exactly once.
    reportArrives(host, 5);
    assert.equal(reportSends(host).length, 1);
    assert.match(reportSends(host)[0].text, WAKE_TEXT);
  });

  it("treats a repeated identical notification as no change", async () => {
    const { host } = await overseerSession();

    reportArrives(host, 2);
    assert.equal(reportSends(host).length, 1);

    // Same fingerprint (identical mtime/size): the transport re-fired, but
    // the inbox state did not change — delivery repetition is not work
    // repetition, so no new wake is queued.
    host.triggerWatch(HITL_DIR);
    assert.equal(reportSends(host).length, 1);
  });

  it("delivers a fresh report after settlement as one more follow-up to the same session", async () => {
    const { host, session } = await overseerSession();

    reportArrives(host, 2);
    session.settle();

    // A genuinely new report after the run settled wakes the SAME session
    // once more; there is still only one overseer execution channel.
    reportArrives(host, 6);
    const sends = reportSends(host);
    assert.equal(sends.length, 2);
    for (const send of sends) {
      assert.match(send.text, WAKE_TEXT);
    }
  });

  // --- Cross-worktree reports (PR393 P2: ace-hitl create writes inside
  // --- the coworker's worktree, not the main checkout's inbox) ---

  const WORKTREE_INBOX = "/fake/wt/task-9/.ace-local/hitl";

  /**
   * A session whose report watch expands across the linked worktrees — the
   * same multi-worktree discovery ace-hitl's list uses (simulated here with
   * a deterministic resolveTargets port; a real-git scenario lives in
   * report-wake-worktree.test.mjs).
   */
  async function overseerSessionAcrossWorktrees({ worktreeInboxExists = true } = {}) {
    const host = createFakeHost();
    host.setFile(HITL_DIR, { mtimeMs: 1, size: 10 });
    if (worktreeInboxExists) {
      host.setFile(WORKTREE_INBOX, { mtimeMs: 1, size: 10 });
    } else {
      // The worktree inbox does not exist yet; its parent directory does,
      // so the watch attaches through the parent and the first report
      // still fires.
      host.setFile("/fake/wt/task-9/.ace-local", { mtimeMs: 1, size: 10 });
    }
    const session = await startSession(host, {
      resolveTargets: (baseDir, path) => [
        `${baseDir}/.ace-local/hitl`,
        WORKTREE_INBOX,
      ],
    });
    await host.runCommand("watch", "add reports --path .ace-local/hitl --message new ace-hitl report; run /continue-work");
    return { host, session };
  }

  it("wakes for a report written inside a coworker worktree's inbox", async () => {
    const { host } = await overseerSessionAcrossWorktrees();

    // ace-hitl create wrote the report into the WORKTREE's inbox; the main
    // checkout's inbox directory never changed.
    host.setFile(WORKTREE_INBOX, { mtimeMs: 20, size: 44 });
    host.triggerWatch(WORKTREE_INBOX);

    const sends = reportSends(host);
    assert.equal(sends.length, 1, "a worktree report must wake the waiting overseer");
    assert.match(sends[0].text, /\[ace-wake watch:reports\] new ace-hitl report/);
  });

  it("wakes for the first report into a worktree inbox that did not exist at registration", async () => {
    const { host } = await overseerSessionAcrossWorktrees({ worktreeInboxExists: false });

    // The inbox directory appears only now, together with its first report.
    host.setFile(WORKTREE_INBOX, { mtimeMs: 5, size: 30 });
    host.triggerWatch(WORKTREE_INBOX);

    assert.equal(reportSends(host).length, 1,
      "the first report into a freshly created worktree inbox must still wake");
  });

  it("re-attaches the formerly-absent inbox directly and wakes for the SECOND report", async () => {
    const { host, session } = await overseerSessionAcrossWorktrees({ worktreeInboxExists: false });

    // First report: the inbox appears; the ancestor watch delivers it and
    // the refresh pass must swap the ancestor watch for a direct one.
    host.setFile(WORKTREE_INBOX, { mtimeMs: 5, size: 30 });
    host.triggerWatch(WORKTREE_INBOX);
    assert.equal(reportSends(host).length, 1);
    assert.ok(host.watcherPaths().includes(WORKTREE_INBOX),
      `the now-existing inbox must be watched directly, got ${host.watcherPaths()}`);
    assert.ok(!host.watcherPaths().includes("/fake/wt/task-9/.ace-local"),
      "the ancestor watch must be closed once the real target exists");
    session.settle();

    // Second report INTO the now-existing inbox: Linux inotify is
    // non-recursive, so only a direct watch on the inbox directory can
    // observe this — the ancestor climb alone would stay deaf.
    host.setFile(WORKTREE_INBOX, { mtimeMs: 7, size: 52 });
    host.triggerWatch(WORKTREE_INBOX);

    assert.equal(reportSends(host).length, 2,
      "the second report into a formerly-absent inbox must wake");
  });

  it("deactivates the watch when re-attachment throws synchronously, without crashing the host", async () => {
    const { host } = await overseerSessionAcrossWorktrees({ worktreeInboxExists: false });

    // The inbox appears (first report would wake), but the direct
    // re-attachment inside the watcher callback hits a synchronous
    // watchFactory failure — EMFILE/EPERM/stat race. The old code closed
    // the ancestor watcher FIRST and let the throw escape into the native
    // callback (host crash, dead watcher); now the failure deactivates
    // the definition with a visible error.
    host.setFile(WORKTREE_INBOX, { mtimeMs: 5, size: 30 });
    host.failNextWatchAttach(WORKTREE_INBOX, "EMFILE: too many open files, watch");
    host.triggerWatch(WORKTREE_INBOX);

    assert.equal(reportSends(host).length, 0, "no wake is delivered from the failing pass");
    // The status line shows the error state; the full message is visible via
    // errorOf (checked through the fake's recorded status renders).
    const render = host.statusRenders.at(-1);
    assert.ok(render, "the deactivation must refresh the visible status");
    assert.match(render.text, /watch reports error/, `got: ${render?.text}`);
    assert.equal(host.watcherCount(), 0, "the subscription is fully torn down, never retried");
  });

  it("re-expands the worktree targets exactly once per restart", async () => {
    const { host, session } = await overseerSessionAcrossWorktrees();

    host.resetSends();
    await session.reload();

    // One subscription, two targets: main inbox + worktree inbox.
    assert.equal(host.watcherCount(), 2, "restart re-registers one watcher per discovered inbox");
    assert.equal(reportSends(host).length, 0, "restart never replays past reports");

    host.setFile(WORKTREE_INBOX, { mtimeMs: 30, size: 60 });
    host.triggerWatch(WORKTREE_INBOX);
    assert.equal(reportSends(host).length, 1);
  });
});
