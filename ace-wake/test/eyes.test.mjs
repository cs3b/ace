import assert from "node:assert/strict";
import { describe, it } from "node:test";
import { Eyes } from "../wake/eyes.js";

const event = (n = "a", revision = "b") => ({ key: n.repeat(64), revision: revision.repeat(64), id: `event${n}` });
function fixture(snapshot) {
  const f = { time: 0, rows: [], sends: [], saved: snapshot, fail: false };
  f.build = () => new Eyes({ snapshot: f.saved, save: (s) => { f.saved = s; }, now: () => f.time,
    observe: async () => { if (f.fail) throw new Error("private failure"); return { schema: "ace.hitl.observation/v1", events: f.rows }; },
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
    f.rows = [event(), event("c")]; await f.eyes.tick();
    assert.equal(f.sends.length, 1); assert.equal(Object.keys(f.saved.pending).length, 2);
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
    f.rows = [event("a", "c")]; await f.eyes.tick();
    f.eyes.ack(event().key,event().revision);
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
  it("errors and idle budgets fail closed without losing pending", async () => {
    const f = fixture(); f.fail = true;
    for (let i = 0; i < 10; i++) await f.eyes.tick();
    assert.equal(f.saved.breaker.reason, "observation-or-delivery-failure"); assert.equal(f.sends.length,0);
    const g = fixture(); g.eyes.start({ maxObservationsPerHour: 1 }); await g.eyes.tick(); await g.eyes.tick();
    assert.equal(g.saved.breaker.reason, "observation-budget");
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

it("semantic event storms hit a durable wake budget without resetting on restart", async () => {
  const f=fixture();f.eyes.start({maxWakesPerHour:1});f.rows=[event()];await f.eyes.tick();
  f.eyes.ack(event().key,event().revision);f.eyes=f.build();f.rows=[event("a","c")];await f.eyes.tick();
  assert.equal(f.sends.length,1);assert.equal(f.saved.breaker.reason,"wake-budget");
  assert.equal(f.saved.pending[event().key].revision,"c".repeat(64));
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
