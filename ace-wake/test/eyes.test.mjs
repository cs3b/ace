import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { Eyes, validateConfig } from "../handbook/extensions/ace-wake/wake/eyes.js";

const event = (n = "a", revision = "b") => ({ key: n.repeat(64), revision: revision.repeat(64), id: `event${n}` });
function fixture(snapshot) {
  const f = { time: 0, rows: [], sends: [], saved: snapshot, fail: false, observations: 0 };
  f.build = () => new Eyes({ snapshot: f.saved, save: (s) => { f.saved = s; }, now: () => f.time,
    observe: async () => { f.observations++; if (f.fail) throw new Error("private failure"); return { schema: "ace.hitl.observation/v1", events: f.rows }; },
    deliver: async (batch) => { f.sends.push(batch); return true; } });
  f.eyes = f.build(); f.eyes.start({}); return f;
}
describe("event-driven eyes", () => {
  it("24 hours unchanged has zero model deliveries with bounded observation", async () => {
    const f = fixture();
    for (let i = 0; i < 2880; i++) { f.time = i * 30000; await f.eyes.tick(); }
    assert.equal(f.sends.length, 0); assert.equal(f.eyes.s.breaker, null); assert.equal(f.eyes.s.window.count, 120);
  });
  it("coalesces revisions while active without accepting on settlement", async () => {
    const f = fixture(); f.rows = [event()]; await f.eyes.tick();
    f.eyes.canDeliver = () => false;
    f.rows = [event(), event("c")]; await f.eyes.tick();
    assert.equal(f.sends.length, 1); assert.equal(Object.keys(f.saved.pending).length, 2);
    f.eyes.canDeliver = () => true;
    f.eyes.ack(event().key, event().revision); await f.eyes.tick();
    assert.equal(f.sends.length, 2); assert.equal(f.sends[1][0][0], event("c").key);
    f.eyes.ack(event("c").key, event("c").revision); await f.eyes.tick();
    assert.equal(f.sends.length, 2);
  });
  it("restart retains pending until explicit exact acknowledgement", async () => {
    const f = fixture(); f.rows = [event()]; await f.eyes.tick();
    f.eyes.dispose(); f.eyes = f.build(); await f.eyes.tick();
    assert.deepEqual(f.sends[0], f.sends[1]);
    f.eyes.ack(event().key, event().revision); f.eyes = f.build(); await f.eyes.tick();
    assert.equal(f.sends.length, 2);
  });
  it("new revision racing old acknowledgement is retained", async () => {
    const f = fixture(); f.rows = [event()]; await f.eyes.tick();
    f.eyes.canDeliver = () => false;
    f.rows = [event("a", "c")]; await f.eyes.tick();
    f.eyes.ack(event().key,event().revision);
    f.eyes.canDeliver = () => true;
    await f.eyes.tick();
    assert.equal(f.sends.length,2);
    assert.equal(f.saved.pending[event().key].revision, "c".repeat(64));
  });
  it("quota breaker survives restart and100 observations without model calls", async () => {
    const f = fixture(); f.rows = [event()]; f.eyes.quota("quota exceeded"); f.eyes = f.build();
    for (let i = 0; i < 100; i++) await f.eyes.tick();
    assert.equal(f.sends.length, 0); assert.equal(f.saved.breaker.reason, "quota-or-budget");
    await f.eyes.resume(); assert.equal(f.sends.length, 1);
  });
  it("observation failures retain pending and recover without a new model turn", async () => {
    const f = fixture();
    f.eyes.start({maxObservationsPerHour: 11});
    f.rows = [event()];
    f.eyes.canDeliver = () => false;
    await f.eyes.tick();
    f.fail = true;
    f.eyes = f.build();
    for (let i = 0; i < 10; i++) await f.eyes.tick();
    assert.equal(f.saved.breaker, null);
    assert.equal(f.saved.observationUnavailable, true);
    assert.equal(f.saved.pending[event().key].revision, event().revision);
    assert.equal(f.sends.length, 0);
    f.eyes = f.build();
    f.fail = false;
    await f.eyes.tick({scheduled: true});
    assert.equal(f.sends.length, 0, "a tick without acquisition cannot deliver stale pending work");
    assert.equal(f.observations, 11, "failed acquisitions consume the same persisted allowance");
    f.time = 3600000;
    await f.eyes.tick({scheduled: true});
    assert.equal(f.saved.observationUnavailable, false);
    assert.equal(f.sends.length, 1);
    f.eyes.ack(event().key, event().revision);
    await f.eyes.tick();
    assert.equal(f.sends.length, 1);
  });
  it("explicit deadline fires once and cancel/change invalidates old pending", async () => {
    const f = fixture(); f.eyes.deadline("review", 100, "head-a"); await f.eyes.tick(); assert.equal(f.sends.length,0);
    f.time=100; await f.eyes.tick(); const old=f.saved.pending["deadline:review"].revision;
    f.eyes.ack("deadline:review",old); f.eyes=f.build(); await f.eyes.tick(); assert.equal(f.sends.length,1);
    f.eyes.deadline("review",200,"head-b"); f.eyes.cancelDeadline("review"); f.time=300; await f.eyes.tick(); assert.equal(f.sends.length,1);
  });
  it("retirement prevents late observation delivery and preserves handoff evidence", async () => {
    const f=fixture(); f.rows=[event()]; await f.eyes.tick(); f.eyes.retire(); f.eyes=f.build();
    await f.eyes.tick(); assert.equal(f.sends.length,1); assert.equal(Object.keys(f.saved.pending).length,1);
    assert.throws(()=>f.eyes.start({}));
  });
});

it("rejected notification delivery opens a bounded breaker and retains exact pending", async () => {
  const f=fixture();f.rows=[event()];let attempts=0;
  f.eyes.deliver=async()=>{attempts++;return false;};
  for(let i=0;i<10;i++) await f.eyes.tick();
  assert.equal(attempts,3);assert.equal(f.saved.breaker.reason,"observation-or-delivery-failure");
  assert.equal(f.saved.pending[event().key].revision,event().revision);
});
it("retirement during in-flight observation prevents a late wake", async () => {
  const f=fixture();let finish;f.eyes.observe=()=>new Promise(resolve=>{finish=resolve;});
  const tick=f.eyes.tick();f.eyes.retire();finish({schema:"ace.hitl.observation/v1",events:[event()]});
  await tick;assert.equal(f.sends.length,0);
});

it("hourly wake allowance survives restart, keeps observing, and delivers in the next window", async () => {
  const f = fixture();
  f.eyes.start({maxWakesPerHour: 1});
  f.rows = [event()];
  await f.eyes.tick();
  f.eyes.ack(event().key, event().revision);
  f.eyes = f.build();
  f.rows = [event("a", "c")];
  await f.eyes.tick();
  assert.equal(f.sends.length, 1);
  assert.equal(f.saved.breaker, null);
  assert.equal(f.eyes.summary().wakeLimitedUntil, 3600000);

  f.time = 30000;
  f.rows = [event("a", "d")];
  await f.eyes.tick();
  assert.equal(f.observations, 3);
  assert.equal(f.sends.length, 1);
  assert.equal(f.saved.pending[event().key].revision, event("a", "d").revision);

  f.time = 3600000;
  await f.eyes.tick();
  assert.equal(f.sends.length, 2);
  assert.equal(f.sends[1][0][1].revision, event("a", "d").revision);
  f.eyes.ack(event().key, event("a", "d").revision);
  await f.eyes.tick();
  assert.equal(f.sends.length, 2);
});

it("canonical terminal settlement suppresses pending after crash without model notification", async()=>{
  const f=fixture();f.rows=[event()];await f.eyes.tick();f.eyes=f.build();
  f.eyes.observe=async()=>({schema:"ace.hitl.observation/v1",events:[],settled:[event()]});
  await f.eyes.tick();assert.equal(f.sends.length,1);assert.equal(Object.keys(f.saved.pending).length,0);
  assert.equal(f.saved.acknowledged[event().key],event().revision);
});

it("partial batch acknowledgement never requeues the other already delivered members", async()=>{
  const f=fixture();f.rows=[event(),event("c")];await f.eyes.tick();
  f.eyes.ack(event().key,event().revision);await f.eyes.tick();assert.equal(f.sends.length,1);
  f.eyes.ack(event("c").key,event("c").revision);await f.eyes.tick();assert.equal(f.sends.length,1);
});
it("a recovered source wakes an idle owner even with accepted work awaiting acknowledgement", async () => {
  const f = fixture();
  const held = event("a"), degraded = event("c"), recovered = event("c", "d");
  f.rows = [held, degraded];
  await f.eyes.tick();
  f.eyes.ack(degraded.key, degraded.revision);
  f.rows = [held, recovered];
  await f.eyes.tick();
  assert.deepEqual(f.sends[1], [[recovered.key, {id: recovered.id, revision: recovered.revision}]]);
  assert.equal(f.saved.pending[held.key].revision, held.revision);
  await f.eyes.tick();
  assert.equal(f.sends.length, 2, "unchanged delivered revisions do not wake again");
  f.eyes.ack(held.key, held.revision);
  f.eyes.ack(recovered.key, recovered.revision);
  assert.deepEqual(f.saved.pending, {});
});

it("cancelling an in-flight deadline releases coalesced actual events", async()=>{
  const f=fixture();f.eyes.deadline("review",0,"head-a");await f.eyes.tick();
  f.rows=[event()];await f.eyes.tick();f.eyes.cancelDeadline("review");await f.eyes.tick();
  assert.equal(f.sends.length,2);assert.equal(f.sends[1][0][0],event().key);
});

it("unconfirmed host delivery persists a breaker across restart without automatic retry",async()=>{
  const f=fixture();f.rows=[event()];f.eyes.deliveryStatus=()=>"uncertain";
  await f.eyes.tick();await f.eyes.tick();assert.equal(f.saved.breaker.reason,"notification-unconfirmed");
  f.eyes=f.build();for(let i=0;i<10;i++)await f.eyes.tick();
  assert.equal(f.sends.length,1);assert.equal(Object.keys(f.saved.pending).length,1);
  await f.eyes.resume();assert.equal(f.sends.length,2,"only explicit owner resume can retry after reconciliation");
});

it("explicit reconciliation retries uncertain delivery in the same process",async()=>{
  const f=fixture();f.rows=[event()];f.eyes.deliveryStatus=()=>"uncertain";
  await f.eyes.tick();await f.eyes.tick();
  assert.equal(f.saved.breaker.reason,"notification-unconfirmed");
  for(let i=0;i<10;i++)await f.eyes.tick();
  assert.equal(f.sends.length,1,"never retry without explicit reconciliation");
  f.eyes.deliveryStatus=()=>"accepted";
  await f.eyes.resume();await f.eyes.tick();
  assert.equal(f.sends.length,2);
  assert.equal(Object.keys(f.saved.pending).length,1);
  await f.eyes.resume();await f.eyes.tick();
  assert.equal(f.sends.length,2,"confirmed delivery remains suppressed without an ack");
});

it("reconciliation retries only the uncertain batch, retaining earlier confirmed suppression",async()=>{
  const f=fixture();f.rows=[event()];await f.eyes.tick();
  f.rows=[event(),event("c")];await f.eyes.tick();
  assert.equal(f.sends.length,2);
  f.eyes.deliveryStatus=()=>"uncertain";await f.eyes.tick();
  assert.equal(f.saved.breaker.reason,"notification-unconfirmed");
  f.eyes.deliveryStatus=()=>"accepted";
  await f.eyes.resume();await f.eyes.tick();
  assert.equal(f.sends.length,3);
  assert.deepEqual(f.sends[2].map(([key])=>key),[event("c").key]);
  assert.equal(Object.keys(f.saved.pending).length,2,"delivery does not acknowledge either revision");
});

// The real installed ARM64 lab needed 17 seconds to read two worktrees.
it("uses a bounded observation timeout by default and validates overrides", async () => {
  const f = fixture();
  let timeout;
  f.eyes.observe = async config => { timeout = config.timeoutMs; return { schema: "ace.hitl.observation/v1", events: [] }; };
  await f.eyes.tick();
  assert.equal(timeout, 60000);
  assert.equal(validateConfig({ timeoutMs: 120000 }).timeoutMs, 120000);
  assert.throws(() => validateConfig({ timeoutMs: 120001 }), /timeoutMs/);
});

it("delivers a deadline that expires during a slow observation", async () => {
  const f = fixture();
  f.eyes.deadline("review", 100, "head-a");
  f.eyes.observe = async () => { f.time = 101; return { schema: "ace.hitl.observation/v1", events: [] }; };
  await f.eyes.tick();
  assert.equal(f.sends.length, 1);
  assert.equal(f.sends[0][0][0], "deadline:review");
});

it("observation allowance renews autonomously after exhaustion and restart", async () => {
  const f = fixture(); f.eyes.start({ maxObservationsPerHour: 1 });
  await f.eyes.tick();
  f.rows = [event()]; f.time = 10000;
  await f.eyes.tick();
  assert.equal(f.observations, 1);
  assert.equal(f.saved.breaker, null);
  f.eyes.dispose(); f.eyes = f.build();
  f.time = 3599999; await f.eyes.tick();
  assert.equal(f.observations, 1);
  assert.equal(f.sends.length, 0);
  f.time = 3600000; await f.eyes.tick();
  assert.equal(f.observations, 2);
  assert.equal(f.sends.length, 1);
  assert.equal(f.saved.pending[event().key].revision, event().revision);
  f.eyes.ack(event().key, event().revision);
  f.time = 7200000; await f.eyes.tick();
  assert.equal(f.sends.length, 1);
});

it("local deadlines remain live when the source allowance is exhausted", async () => {
  const f = fixture(); f.eyes.start({maxObservationsPerHour:1});
  await f.eyes.tick(); f.eyes.deadline("startup",60000,"session-1");
  f.time=60000; await f.eyes.tick({scheduled:true});
  assert.equal(f.observations,1);
  assert.equal(f.sends.length,1);
  assert.equal(f.sends[0][0][0],"deadline:startup");
  f.eyes.cancelDeadline("startup"); f.time=90000;
  await f.eyes.tick({scheduled:true});
  assert.equal(f.sends.length,1);
  assert.equal(f.saved.breaker,null);
});

it("scheduled acquisition rounds allowance cadence to timer boundaries", async()=>{
  const f=fixture();f.eyes.start({intervalSeconds:20,maxObservationsPerHour:120});
  await f.eyes.tick({scheduled:true});
  f.time=20000;await f.eyes.tick({scheduled:true});assert.equal(f.observations,1);
  f.time=40000;await f.eyes.tick({scheduled:true});assert.equal(f.observations,2);
});
