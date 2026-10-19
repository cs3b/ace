import assert from "node:assert/strict";
import { describe, it } from "node:test";

import { createFakeHost } from "./fake-pi-host.mjs";
import aceWakeFactory from "../../handbook/extensions/ace-wake/index.js";

// L7.3 acceptance scenarios (8xg.t.sbz.6.2): a report notification reaches a
// pi overseer session through the ace-wake watch on the ace-hitl inbox
// directory. The scenarios assert the composed behavior the spec requires:
// wake-on-report for a waiting session, queued follow-up (never a second
// execution) during an active turn, exactly-once re-registration after
// restart, and idempotence of repeated notifications.

const HOST_PORTS = ["setIntervalFn", "clearIntervalFn", "watchFactory", "statFn"];
const HITL_DIR = "/fake/project/.ace-local/hitl";
const WAKE_TEXT = /watch:reports/;

/** Start the real extension against the fake host, as Pi would. */
async function startSession(host) {
  const events = [];
  host.pi.on = (event, handler) => {
    events.push([event, handler]);
    return () => {};
  };
  aceWakeFactory(host.pi, Object.fromEntries(HOST_PORTS.map((name) => [name, host[name]])));

  const handlerFor = (event) => {
    const found = events.find(([name]) => name === event);
    if (!found) {
      throw new Error(`extension did not register ${event}`);
    }
    return found[1];
  };

  await handlerFor("session_start")({ type: "session_start", reason: "startup" }, host.commandContext);

  return {
    reload: async () => {
      await handlerFor("session_shutdown")({ type: "session_shutdown", reason: "reload" }, host.commandContext);
      const reloadEvents = [];
      host.pi.on = (event, handler) => {
        reloadEvents.push([event, handler]);
        return () => {};
      };
      aceWakeFactory(host.pi, Object.fromEntries(HOST_PORTS.map((name) => [name, host[name]])));
      const found = reloadEvents.find(([name]) => name === "session_start");
      await found[1]({ type: "session_start", reason: "reload" }, host.commandContext);
    },
    settle: () => handlerFor("agent_settled")({ type: "agent_settled" }, host.commandContext),
  };
}

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
    host.setAgentActive(true);
    reportArrives(host, 2);

    const sends = reportSends(host);
    assert.equal(sends.length, 1);
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
});
