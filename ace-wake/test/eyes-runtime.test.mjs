import assert from "node:assert/strict";
import { it } from "node:test";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createFakeHost } from "./fake-pi-host.mjs";
import { startSession } from "./session-harness.mjs";
import { observeHitl, eyesProcessIdentity, readEyesProcessIdentity } from "../handbook/extensions/ace-wake/wake/eyes-runtime.js";
const key="a".repeat(64), revision="b".repeat(64);
const flush=()=>new Promise(resolve=>setImmediate(resolve));
it("clears stale readiness during acquisition failure and recovers on the scheduled read", async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ace-eyes-retry-"));
  const host = createFakeHost(), tools = new Map();
  host.pi.registerTool = (tool) => tools.set(tool.name, tool);
  let unavailable = false;
  const session = await startSession(host, {eyes: {
    now: host.clock.now, schedule: host.setIntervalFn, cancel: host.clearIntervalFn,
    observe: async () => {
      if (unavailable) throw new Error("observe timed out");
      return {schema: "ace.hitl.observation/v1", events: [], sources: {tasks: {status: "ok"}}};
    }
  }});
  try {
    const file = path.join(dir, "eyes.json");
    fs.writeFileSync(file, "{}");
    const tool = tools.get("ace_eyes");
    const status = async () => (await tool.execute("status", {action: "status"})).details;
    await tool.execute("start", {action: "start", configPath: file}, null, null, host.commandContext);
    assert.deepEqual((await status()).sources, {tasks: {status: "ok"}});
    unavailable = true;
    for (let i = 0; i < 4; i++) { host.clock.advance(30000); await flush(); }
    assert.equal((await status()).observationUnavailable, true);
    assert.equal((await status()).breaker, null);
    assert.equal((await status()).sources, undefined);
    const evidence = host.sessionEntries.filter(e => e.customType === "ace-wake-eyes").at(-1).data.observerEvidence;
    assert.equal(evidence.observedAt, null);
    unavailable = false;
    host.clock.advance(30000);
    await flush();
    assert.deepEqual((await status()).sources, {tasks: {status: "ok"}});
    assert.equal((await status()).errors, 0);
    assert.equal(host.sends.length, 0);
  } finally {
    await session.shutdown();
    fs.rmSync(dir, {recursive: true, force: true});
  }
});

it("does not record source health from an invalid observation", async()=>{
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ace-eyes-invalid-"));
  const host=createFakeHost(), tools=new Map();
  host.pi.registerTool=(tool)=>tools.set(tool.name,tool);
  const session=await startSession(host,{eyes:{
    now:host.clock.now,schedule:host.setIntervalFn,cancel:host.clearIntervalFn,
    processIdentity:()=>({pid:42,startedAt:"linux:01234567-89ab-cdef-0123-456789abcdef:10"}),
    observe:async()=>({schema:"invalid",events:[],sources:{tasks:{status:"ok"}}})
  }});
  try {
    const file=path.join(dir,"eyes.json");fs.writeFileSync(file,"{}");
    await tools.get("ace_eyes").execute("start",{action:"start",configPath:file},null,null,host.commandContext);
    await session.settle();
    const data=host.sessionEntries.filter(e=>e.customType==="ace-wake-eyes").at(-1).data;
    assert.equal(data.errors,1);
    assert.deepEqual(data.observerEvidence.sources,{});
    assert.equal(data.observerEvidence.observedAt,null);
  } finally {await session.shutdown();fs.rmSync(dir,{recursive:true,force:true});}
});
it("real config enables eyes coexisting with loops, survives reload, exposes exact ack tool and retires", async()=>{
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ace-eyes-"));
  try {
    const file=path.join(dir,"eyes.json"); fs.writeFileSync(file,"{}");
    const host=createFakeHost(), tools=new Map();
    host.pi.registerTool=(tool)=>tools.set(tool.name,tool);
    let observations=0;
    const session=await startSession(host,{eyes:{
      now:host.clock.now,schedule:host.setIntervalFn,cancel:host.clearIntervalFn,
      observe:async()=>{observations++;return {schema:"ace.hitl.observation/v1",events:[{key,revision,id:"report1"}]};}
    }});
    await host.runCommand("loop","add old --interval 10 --message noop");
    await host.runCommand("eyes",`start ${file}`);
    assert.equal(host.sends.filter((send)=>/ace_eyes/.test(send.text)).length,1);assert.match(host.sends[0].text,/ace_eyes/);
    // Coexistence contract (8xs.t.pu0.2): the observer timer AND the loop
    // timer run side by side — eyes never retires user subscriptions.
    assert.equal(host.intervals.size,2,"observer and loop timers coexist");
    await host.runCommand("loop","add second --interval 10 --message noop");
    assert.equal(host.notifications.at(-1).type,"info","loop add under eyes is accepted");
    assert.equal(host.intervals.size,3,"the new loop arms its own timer");
    await session.reload();await flush();
    assert.equal(host.intervals.size,3,"observer and loops re-register after reload");
    assert.equal(host.sends.filter((send)=>/ace_eyes/.test(send.text)).length,2,"unacknowledged revision reconciles on reload");
    const tool=tools.get("ace_eyes");
    await assert.rejects(tool.execute("id",{action:"ack",key,revision:"c".repeat(64)}));
    await tool.execute("id",{action:"ack",key,revision});
    await session.settle();host.clock.advance(30000);await flush();
    // The loops coexist and may tick during the advance; the eyes stream
    // itself must stay at its two semantic deliveries.
    assert.equal(host.sends.filter((send)=>/ace_eyes/.test(send.text)).length,2,"settlement/ack does not create new semantic work");
    await session.emit("message_end",{message:{role:"assistant",stopReason:"error",errorMessage:"429 quota exceeded"}});
    assert.equal(host.intervals.size,2,"quota hook stops the live observer; loops stay");
    await session.reload();await flush();assert.equal(host.intervals.size,2,"breaker survives actual lifecycle reload");
    assert.equal(host.sends.filter((send)=>/ace_eyes/.test(send.text)).length,2);
    await host.runCommand("eyes","resume quota-verified");assert.equal(host.intervals.size,3);
    assert.equal(host.sends.filter((send)=>/ace_eyes/.test(send.text)).length,2,"explicit healthy-source resume does not repeat acknowledged events");
    await host.runCommand("eyes","retire");assert.equal(host.intervals.size,2,"retiring eyes leaves the loops running");
    const count=observations;await session.reload();await flush();
    host.clock.advance(60000);await flush();assert.equal(observations,count);
    await session.shutdown();assert.equal(host.intervals.size,0);
  } finally {fs.rmSync(dir,{recursive:true,force:true});}
});

it("agent arms eyes through its tool, acknowledges baseline and stays silent until change", async()=>{
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ace-eyes-tool-"));
  const host=createFakeHost(), tools=new Map();
  host.pi.registerTool=(tool)=>tools.set(tool.name,tool);
  let current=revision;
  const session=await startSession(host,{eyes:{
    now:host.clock.now,schedule:host.setIntervalFn,cancel:host.clearIntervalFn,
    observe:async()=>({schema:"ace.hitl.observation/v1",events:[{key,revision:current,id:"report1"}]})
  }});
  try {
    const file=path.join(dir,"eyes.json");fs.writeFileSync(file,"{}");
    const tool=tools.get("ace_eyes");
    await assert.rejects(tool.execute("start",{action:"start"},null,null,host.commandContext));
    const result=await tool.execute("start",{action:"start",configPath:file},null,null,host.commandContext);
    assert.equal(result.details.enabled,true);
    assert.equal(result.details.errors,0);
    assert.equal(host.intervals.size,1);
    assert.equal(host.sends.length,0,"arming returns baseline without a redundant wake");
    await tool.execute("ack",{action:"ack",key,revision});
    await session.settle();
    for(let i=0;i<10;i++){host.clock.advance(30000);await flush();}
    assert.equal(host.sends.length,0,"five idle minutes invoke no model");
    current="c".repeat(64);host.clock.advance(30000);await flush();
    assert.equal(host.sends.length,1,"new revision wakes the overseer");
    await tool.execute("ack",{action:"ack",key,revision:current});
    await session.reload();await flush();
    assert.equal(host.sends.length,1,"acknowledged revision is not replayed after reload");
  } finally {await session.shutdown();fs.rmSync(dir,{recursive:true,force:true});}
});

it("does not queue a stale wake for work handled during an active turn", async()=>{
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ace-eyes-busy-"));
  const host=createFakeHost(), tools=new Map();
  host.pi.registerTool=(tool)=>tools.set(tool.name,tool);
  let rows=[];
  const session=await startSession(host,{eyes:{
    now:host.clock.now,schedule:host.setIntervalFn,cancel:host.clearIntervalFn,
    observe:async()=>({schema:"ace.hitl.observation/v1",events:rows})
  }});
  try {
    const file=path.join(dir,"eyes.json");fs.writeFileSync(file,"{}");
    const tool=tools.get("ace_eyes");
    await tool.execute("start",{action:"start",configPath:file},null,null,host.commandContext);
    host.setIdle(false);await session.agentStart();
    rows=[{key,revision,id:"task1"}];host.clock.advance(30000);await flush();
    assert.equal(host.sends.length,0,"active turns must not accumulate stale follow-ups");
    await tool.execute("ack",{action:"ack",key,revision});
    host.setIdle(true);await session.settle();host.clock.advance(30000);await flush();
    assert.equal(host.sends.length,0,"handled changes do not start another turn");
    rows=[{key,revision:"c".repeat(64),id:"task1"}];host.clock.advance(30000);await flush();
    assert.equal(host.sends.length,1,"a later unhandled change still wakes the idle agent");
  } finally {await session.shutdown();fs.rmSync(dir,{recursive:true,force:true});}
});

it("delivers recovery after the accepted turn settles without repeating held work", async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ace-eyes-partial-"));
  const host = createFakeHost(), tools = new Map();
  host.pi.registerTool = (tool) => tools.set(tool.name, tool);
  const held = {key, revision, id: "held"};
  const health = {key: "c".repeat(64), revision: "d".repeat(64), id: "health"};
  const recovered = {...health, revision: "e".repeat(64)};
  let rows = [];
  const session = await startSession(host, {eyes: {
    now: host.clock.now, schedule: host.setIntervalFn, cancel: host.clearIntervalFn,
    observe: async () => ({schema: "ace.hitl.observation/v1", events: rows})
  }});
  try {
    const file = path.join(dir, "eyes.json");
    fs.writeFileSync(file, "{}");
    const tool = tools.get("ace_eyes");
    await tool.execute("start", {action: "start", configPath: file}, null, null, host.commandContext);
    rows = [held, health];
    host.clock.advance(30000);
    await flush();
    assert.equal(host.sends.length, 1);
    await session.emit("message_start", {message: {role: "user", content: host.sends[0].text}});
    host.setIdle(false);
    await session.agentStart();
    await tool.execute("ack", {action: "ack", key: health.key, revision: health.revision});
    rows = [held, recovered];
    host.clock.advance(30000);
    await flush();
    assert.equal(host.sends.length, 1);
    host.setIdle(true);
    await session.settle();
    host.clock.advance(30000);
    await flush();
    assert.equal(host.sends.length, 2);
    assert.ok(host.sends[1].text.includes(recovered.revision));
    assert.ok(!host.sends[1].text.includes(held.revision));
  } finally {
    await session.shutdown();
    fs.rmSync(dir, {recursive: true, force: true});
  }
});

it("waits for other pending host messages before delivering an eyes wake", async()=>{
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ace-eyes-queue-"));
  const host=createFakeHost(), tools=new Map();
  host.pi.registerTool=(tool)=>tools.set(tool.name,tool);
  let rows=[];
  const session=await startSession(host,{eyes:{
    now:host.clock.now,schedule:host.setIntervalFn,cancel:host.clearIntervalFn,
    observe:async()=>({schema:"ace.hitl.observation/v1",events:rows})
  }});
  try {
    const file=path.join(dir,"eyes.json");fs.writeFileSync(file,"{}");
    await tools.get("ace_eyes").execute("start",{action:"start",configPath:file},null,null,host.commandContext);
    host.setPendingMessages(true);rows=[{key,revision,id:"task1"}];
    host.clock.advance(30000);await flush();
    assert.equal(host.sends.length,0,"another queued message must run first");
    host.setPendingMessages(false);host.clock.advance(30000);await flush();
    assert.equal(host.sends.length,1,"the still-unhandled revision is delivered after queue drain");
  } finally {await session.shutdown();fs.rmSync(dir,{recursive:true,force:true});}
});

it("rebinding clears source health until the new observation completes", async()=>{
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ace-eyes-rebind-"));
  const host=createFakeHost(), tools=new Map();
  host.pi.registerTool=(tool)=>tools.set(tool.name,tool);
  let calls=0, finishObservation;
  const session=await startSession(host,{eyes:{
    now:host.clock.now,schedule:host.setIntervalFn,cancel:host.clearIntervalFn,
    observe:async()=>{
      calls++;
      if(calls===1)return {schema:"ace.hitl.observation/v1",events:[],sources:{tasks:{status:"ok"}}};
      return new Promise(resolve=>{finishObservation=resolve;});
    }
  }});
  try {
    const file=path.join(dir,"eyes.json");fs.writeFileSync(file,"{}");
    const tool=tools.get("ace_eyes");
    const initial=await tool.execute("start",{action:"start",configPath:file},null,null,host.commandContext);
    assert.deepEqual(initial.details.sources,{tasks:{status:"ok"}});
    await session.emit("session_tree",{});
    const rebinding=await tool.execute("status",{action:"status"});
    assert.equal(rebinding.details.sources,undefined,"previous session health is not evidence for a new binding");
    assert.equal(calls,2);
    finishObservation({schema:"ace.hitl.observation/v1",events:[],sources:{tasks:{status:"degraded"}}});
    await flush();
    const observed=await tool.execute("status",{action:"status"});
    assert.deepEqual(observed.details.sources,{tasks:{status:"degraded"}});
  } finally {await session.shutdown();fs.rmSync(dir,{recursive:true,force:true});}
});

it("binds persisted observer health to this process and clears it on rebinding", async()=>{
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ace-eyes-evidence-"));
  const host=createFakeHost(), tools=new Map();
  host.pi.registerTool=(tool)=>tools.set(tool.name,tool);
  const identity={pid:123,startedAt:"linux:01234567-89ab-cdef-0123-456789abcdef:12345"};
  let calls=0, finish;
  const session=await startSession(host,{eyes:{
    now:host.clock.now,schedule:host.setIntervalFn,cancel:host.clearIntervalFn,
    processIdentity:()=>identity,
    observe:async()=>{
      calls++;
      if(calls===1)return {schema:"ace.hitl.observation/v1",events:[],sources:{tasks:{status:"ok"}}};
      return new Promise(resolve=>{finish=resolve;});
    }
  }});
  try {
    const file=path.join(dir,"eyes.json");fs.writeFileSync(file,"{}");
    await tools.get("ace_eyes").execute("start",{action:"start",configPath:file},null,null,host.commandContext);
    let evidence=host.sessionEntries.filter(e=>e.customType==="ace-wake-eyes").at(-1).data.observerEvidence;
    assert.deepEqual(evidence,{process:identity,observedAt:0,sources:{tasks:"ok"}});
    await session.emit("session_tree",{});
    evidence=host.sessionEntries.filter(e=>e.customType==="ace-wake-eyes").at(-1).data.observerEvidence;
    assert.deepEqual(evidence,{process:identity,observedAt:null,sources:{}});
    finish({schema:"ace.hitl.observation/v1",events:[],sources:{tasks:{status:"degraded"}}});
    await flush();
    evidence=host.sessionEntries.filter(e=>e.customType==="ace-wake-eyes").at(-1).data.observerEvidence;
    assert.deepEqual(evidence.sources,{tasks:"degraded"});
    assert.equal(host.sends.length,0,"health evidence does not wake the model");
    await session.shutdown();
    evidence=host.sessionEntries.filter(e=>e.customType==="ace-wake-eyes").at(-1).data.observerEvidence;
    assert.equal(evidence.observedAt,null,"a stopped observer cannot leave fresh evidence");
  } finally {await session.shutdown();fs.rmSync(dir,{recursive:true,force:true});}
});

it("does not reuse an in-flight observation after changing the eyes configuration", async()=>{
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ace-eyes-reconfigure-"));
  const host=createFakeHost(), tools=new Map();host.pi.registerTool=(tool)=>tools.set(tool.name,tool);
  let calls=0, finish;
  const session=await startSession(host,{eyes:{now:host.clock.now,schedule:host.setIntervalFn,cancel:host.clearIntervalFn,
    processIdentity:()=>({pid:123,startedAt:"linux:01234567-89ab-cdef-0123-456789abcdef:12345"}),
    observe:async()=>{
      calls++;
      if(calls===2)return new Promise(resolve=>{finish=resolve;});
      return {schema:"ace.hitl.observation/v1",events:[],sources:{tasks:{status:"ok"}}};
    }
  }});
  try {
    const first=path.join(dir,"first.json"), second=path.join(dir,"second.json");
    fs.writeFileSync(first,"{}");fs.writeFileSync(second,JSON.stringify({scope:"all"}));
    const tool=tools.get("ace_eyes");
    await tool.execute("start",{action:"start",configPath:first},null,null,host.commandContext);
    host.clock.advance(30000);await flush();
    await tool.execute("start",{action:"start",configPath:second},null,null,host.commandContext);
    let evidence=host.sessionEntries.filter(e=>e.customType==="ace-wake-eyes").at(-1).data.observerEvidence;
    assert.deepEqual(evidence.sources,{tasks:"ok"},"start observes the replacement config immediately");
    finish({schema:"ace.hitl.observation/v1",events:[],sources:{tasks:{status:"degraded"}}});await flush();
    evidence=host.sessionEntries.filter(e=>e.customType==="ace-wake-eyes").at(-1).data.observerEvidence;
    assert.deepEqual(evidence.sources,{tasks:"ok"},"old-config results cannot replace new evidence");
  } finally {await session.shutdown();fs.rmSync(dir,{recursive:true,force:true});}
});

for(const transition of ["session_tree","session_shutdown"]) {
  it(`a pending resume cannot persist or rearm after ${transition}`, async()=>{
    const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ace-eyes-resume-race-"));
    const host=createFakeHost(), tools=new Map();host.pi.registerTool=(tool)=>tools.set(tool.name,tool);
    let calls=0, finish;
    const session=await startSession(host,{eyes:{now:host.clock.now,schedule:host.setIntervalFn,cancel:host.clearIntervalFn,
      observe:async()=>{
        calls++;
        if(calls===2)return new Promise(resolve=>{finish=resolve;});
        return {schema:"ace.hitl.observation/v1",events:[],sources:{tasks:{status:"ok"}}};
      }
    }});
    try {
      const file=path.join(dir,"eyes.json");fs.writeFileSync(file,"{}");
      await tools.get("ace_eyes").execute("start",{action:"start",configPath:file},null,null,host.commandContext);
      await session.emit("message_end",{message:{role:"assistant",stopReason:"error",errorMessage:"quota exceeded"}});
      const resume=host.runCommand("eyes","resume quota-verified");await flush();
      await session.emit(transition,{});
      const entries=host.sessionEntries.length;
      finish({schema:"ace.hitl.observation/v1",events:[],sources:{tasks:{status:"ok"}}});
      await resume;await flush();
      assert.equal(host.sessionEntries.length,entries,"disposed observer must not persist after its binding changes");
      assert.equal(host.intervals.size,0,"disposed observer must not rearm");
    } finally {await session.shutdown();fs.rmSync(dir,{recursive:true,force:true});}
  });
}

it("a rejected old observation cannot persist after rebinding", async()=>{
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ace-eyes-reject-race-"));
  const host=createFakeHost(), tools=new Map();host.pi.registerTool=(tool)=>tools.set(tool.name,tool);
  let calls=0, rejectOld;
  const session=await startSession(host,{eyes:{now:host.clock.now,schedule:host.setIntervalFn,cancel:host.clearIntervalFn,
    observe:async()=>{
      calls++;
      if(calls===2)return new Promise((_resolve,reject)=>{rejectOld=reject;});
      return {schema:"ace.hitl.observation/v1",events:[],sources:{tasks:{status:"ok"}}};
    }
  }});
  try {
    const file=path.join(dir,"eyes.json");fs.writeFileSync(file,"{}");
    await tools.get("ace_eyes").execute("start",{action:"start",configPath:file},null,null,host.commandContext);
    host.clock.advance(30000);await flush();
    await session.emit("session_tree",{});await flush();
    const entries=host.sessionEntries.length;
    rejectOld(new Error("old observation failed"));await flush();
    assert.equal(host.sessionEntries.length,entries,"disposed observer must not append a stale error");
    assert.equal((await tools.get("ace_eyes").execute("status",{action:"status"})).details.errors,0);
  } finally {await session.shutdown();fs.rmSync(dir,{recursive:true,force:true});}
});

it("an old in-flight observation cannot overwrite source health after rebind", async()=>{
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ace-eyes-rebind-race-"));
  const host=createFakeHost(), tools=new Map();
  host.pi.registerTool=(tool)=>tools.set(tool.name,tool);
  let calls=0, finishOldObservation;
  const freshSources={tasks:{status:"ok"},assignments:{status:"ok"}};
  const session=await startSession(host,{eyes:{
    now:host.clock.now,schedule:host.setIntervalFn,cancel:host.clearIntervalFn,
    observe:async()=>{
      calls++;
      if(calls===2)return new Promise(resolve=>{finishOldObservation=resolve;});
      return {schema:"ace.hitl.observation/v1",events:[],sources:calls===1?{tasks:{status:"ok"}}:freshSources};
    }
  }});
  try {
    const file=path.join(dir,"eyes.json");fs.writeFileSync(file,"{}");
    const tool=tools.get("ace_eyes");
    await tool.execute("start",{action:"start",configPath:file},null,null,host.commandContext);
    host.clock.advance(30000);await flush();
    assert.equal(calls,2,"old binding has an observation in flight");
    await session.emit("session_tree",{});await flush();
    assert.equal(calls,3,"new binding completes its own observation");
    assert.deepEqual((await tool.execute("status",{action:"status"})).details.sources,freshSources);
    finishOldObservation({schema:"ace.hitl.observation/v1",events:[],sources:{tasks:{status:"degraded"}}});
    await flush();
    assert.deepEqual((await tool.execute("status",{action:"status"})).details.sources,freshSources,
      "late disposed-binding results cannot replace fresh source health");
  } finally {await session.shutdown();fs.rmSync(dir,{recursive:true,force:true});}
});

it("terminates an observation command exceeding its configured timeout", async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ace-eyes-timeout-"));
  const previousPath = process.env.PATH;
  try {
    const executable = path.join(dir, "ace-overseer");
    fs.writeFileSync(executable, "#!/bin/sh\nexec /bin/sleep 3\n", { mode: 0o700 });
    process.env.PATH = `${dir}:${previousPath || ""}`;
    await assert.rejects(
      observeHitl(dir, { syncRoutes: [], timeoutMs: 100, recipient: "overseer", scope: "current", maxEvents: 500 }),
      error => error.killed === true
    );
  } finally {
    if (previousPath === undefined) delete process.env.PATH; else process.env.PATH = previousPath;
    fs.rmSync(dir, { recursive: true, force: true });
  }
});

it("rejects native observations without source health", async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ace-eyes-no-sources-"));
  const previousPath = process.env.PATH;
  try {
    fs.writeFileSync(path.join(dir, "ace-overseer"), "#!/bin/sh\nprintf '%s\\n' '{\"schema\":\"ace.hitl.observation/v1\",\"events\":[]}'\n", {mode: 0o700});
    process.env.PATH = `${dir}:${previousPath || ""}`;
    await assert.rejects(observeHitl(dir, {syncRoutes: [], timeoutMs: 1000, recipient: "overseer", scope: "current", maxEvents: 500}),
      /source health is missing/);
  } finally {
    if (previousPath === undefined) delete process.env.PATH; else process.env.PATH = previousPath;
    fs.rmSync(dir, {recursive: true, force: true});
  }
});

it("short configured intervals keep observing across hourly allowances and deliver a late report", async()=>{
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ace-eyes-budget-"));
  const host=createFakeHost();
  let observations=0, rows=[];
  const session=await startSession(host,{eyes:{
    now:host.clock.now,schedule:host.setIntervalFn,cancel:host.clearIntervalFn,
    observe:async()=>{observations++;return {schema:"ace.hitl.observation/v1",events:rows,sources:{tasks:{status:"ok"}}};}
  }});
  try {
    const file=path.join(dir,"eyes.json");
    fs.writeFileSync(file,JSON.stringify({intervalSeconds:10,maxObservationsPerHour:120}));
    await host.runCommand("eyes",`start ${file}`);
    for(let i=0;i<720;i++){host.clock.advance(10000);await flush();}
    assert.equal(host.sends.length,0,"unchanged state causes no model turns");
    assert.ok(observations>=240 && observations<=241,"observations are spread over both hours");
    assert.equal(host.intervals.size,1,"renewable allowance never removes observation timer");
    rows=[{key,revision,id:"late-worker-report"}];
    for(let i=0;i<3;i++){host.clock.advance(10000);await flush();}
    assert.equal(host.sends.length,1);
    const state=host.sessionEntries.filter(e=>e.customType==="ace-wake-eyes").at(-1).data;
    assert.equal(state.breaker,null);
    assert.equal(state.pending[key].revision,revision);
  } finally {await session.shutdown();fs.rmSync(dir,{recursive:true,force:true});}
});

it("runtime delivers a local deadline without spending an exhausted observation allowance", async()=>{
  const dir=fs.mkdtempSync(path.join(os.tmpdir(),"ace-eyes-deadline-budget-"));
  const host=createFakeHost(), tools=new Map();
  host.pi.registerTool=tool=>tools.set(tool.name,tool);
  let observations=0;
  const session=await startSession(host,{eyes:{
    now:host.clock.now,schedule:host.setIntervalFn,cancel:host.clearIntervalFn,
    observe:async()=>{observations++;return {schema:"ace.hitl.observation/v1",events:[],sources:{tasks:{status:"ok"}}};}
  }});
  try {
    const file=path.join(dir,"eyes.json");
    fs.writeFileSync(file,JSON.stringify({intervalSeconds:10,maxObservationsPerHour:1}));
    await host.runCommand("eyes",`start ${file}`);
    await tools.get("ace_eyes").execute("deadline",{action:"deadline",key:"startup",revision:"session-1",at:60000});
    for(let i=0;i<6;i++){host.clock.advance(10000);await flush();}
    assert.equal(observations,1);
    assert.equal(host.sends.length,1);
    assert.match(host.sends[0].text,/deadline:startup/);
    assert.equal(host.intervals.size,1);
  } finally {await session.shutdown();fs.rmSync(dir,{recursive:true,force:true});}
});


it("reads Linux exact boot/ticks without invoking Ruby", () => {
  const boot = "01234567-89ab-cdef-0123-456789abcdef";
  const fields = ["S", ...Array(18).fill("0"), "12345"];
  const identity = readEyesProcessIdentity({platform: "linux", pid: 42,
    readFile: file => file.endsWith("stat") ? `42 (name with ) parenthesis) ${fields.join(" ")}\n` : boot,
    run: () => { throw new Error("Linux must not spawn"); }});
  assert.deepEqual(identity, {pid: 42, startedAt: `linux:${boot}:12345`});
});

it("reads Darwin microsecond birth through the bounded installed Ruby owner", () => {
  let observed;
  const identity = readEyesProcessIdentity({platform: "darwin", pid: 42,
    run: (...args) => { observed = args; return "darwin:1794000000:123456"; }});
  assert.deepEqual(identity, {pid: 42, startedAt: "darwin:1794000000:123456"});
  assert.equal(observed[0], "ruby");
  assert.equal(observed[1][1], "ace/runtime/molecules/process_identity");
  assert.equal(observed[1].at(-1), "42");
  assert.equal(observed[2].timeout, 2000);
  assert.equal(observed[2].killSignal, "SIGKILL");
});

it("leaves Darwin evidence unverified if Ruby/runtime is unavailable or birth invalid", () => {
  for (const run of [() => { throw new Error("runtime missing"); }, () => "", () => "darwin:1:1000000", () => "linux:wrong:42"]) {
    assert.equal(readEyesProcessIdentity({platform: "darwin", pid: 42, run}), null);
  }
  assert.equal(readEyesProcessIdentity({platform: "unknown", pid: 42}), null);
});

it("binds the real local process once with exact native birth", () => {
  if (!["linux", "darwin"].includes(process.platform)) return;
  const identity = eyesProcessIdentity();
  assert.equal(identity?.pid, process.pid);
  assert.match(identity.startedAt, /^(linux:[0-9a-f-]{36}:[1-9][0-9]*|darwin:[1-9][0-9]*:[0-9]{1,6})$/);
  assert.strictEqual(eyesProcessIdentity(), identity);
});

it("process-reports acknowledges only completed exact report revisions", async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ace-report-ack-"));
  const host = createFakeHost(), tools = new Map();
  host.pi.registerTool = tool => tools.set(tool.name, tool);
  const other = "c".repeat(64), newer = "d".repeat(64);
  let receiptRevision = revision;
  const session = await startSession(host, {eyes: {
    now: host.clock.now, schedule: host.setIntervalFn, cancel: host.clearIntervalFn,
    observe: async () => ({schema: "ace.hitl.observation/v1", events: [
      {key, revision: newer, id: "report1", type: "report"},
      {key: other, revision, id: "question1", type: "question"}], sources: {hitl: {status: "ok"}}}),
    processReports: async () => ({dry_run: false, outcomes: [
      {key, revision: receiptRevision, accepted: true, cleanup: "complete", acknowledge: true},
      {key: other, revision, accepted: false, cleanup: "pending", acknowledge: false}]})
  }});
  try {
    const file = path.join(dir, "eyes.json"); fs.writeFileSync(file, "{}");
    const tool = tools.get("ace_eyes");
    await tool.execute("start", {action: "start", configPath: file}, null, null, host.commandContext);
    const result = await tool.execute("process", {action: "process-reports"}, null, null, host.commandContext);
    assert.equal(result.details.pending[key].revision, newer, "older receipt must retain the newer observation");
    assert.equal(result.details.pending[other].revision, revision, "question must remain pending");
    receiptRevision = newer;
    const completed = await tool.execute("process-again", {action: "process-reports"}, null, null, host.commandContext);
    assert.equal(completed.details.pending[key], undefined);
    assert.equal(completed.details.pending[other].revision, revision);
  } finally { await session.shutdown(); fs.rmSync(dir, {recursive: true, force: true}); }
});

it("session initialization arms the configured observer without a model tool call", async () => {
  const host = createFakeHost();
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ace-auto-eyes-"));
  host.commandContext.cwd = dir;
  const folder = path.join(dir, ".ace-local/overseer");
  fs.mkdirSync(folder, {recursive: true});
  const file = path.join(folder, "eyes.json");
  const original = fs.existsSync(file) ? fs.readFileSync(file) : null;
  fs.writeFileSync(file, JSON.stringify({scope: "all", recipient: "overseer", maxWakesPerHour: 7}));
  let reads = 0;
  let session;
  try {
    session = await startSession(host, {eyes: {
      env: {ACE_OVERSEER_EYES_CONFIG: file}, now: host.clock.now,
      schedule: host.setIntervalFn, cancel: host.clearIntervalFn,
      observe: async config => { reads++; assert.equal(config.scope, "all");
        return {schema: "ace.hitl.observation/v1", events: [], sources: {hitl: {status: "ok"}}}; }
    }});
    assert.equal(reads, 1);
    const snapshot = host.sessionEntries.filter(e => e.customType === "ace-wake-eyes").at(-1).data;
    assert.equal(snapshot.enabled, true);
    assert.equal(snapshot.config.maxWakesPerHour, 7);
    assert.equal(host.sends.length, 0);
  } finally {
    await session?.shutdown();
    if (original) fs.writeFileSync(file, original); else fs.rmSync(file, {force: true});
    fs.rmSync(dir, {recursive: true, force: true});
  }
});

it("refuses report processing while an observation source is degraded", async () => {
  const dir = fs.mkdtempSync(path.join(os.tmpdir(), "ace-report-degraded-"));
  const host = createFakeHost(), tools = new Map();
  host.pi.registerTool = tool => tools.set(tool.name, tool);
  let calls = 0;
  const session = await startSession(host, {eyes: {
    now: host.clock.now, schedule: host.setIntervalFn, cancel: host.clearIntervalFn,
    observe: async () => ({schema: "ace.hitl.observation/v1", events: [],
      sources: {hitl: {status: "error", error: "unavailable"}}}),
    processReports: async () => { calls++; return {dry_run: false, outcomes: []}; }
  }});
  try {
    const file = path.join(dir, "eyes.json"); fs.writeFileSync(file, "{}");
    const tool = tools.get("ace_eyes");
    await tool.execute("start", {action: "start", configPath: file}, null, null, host.commandContext);
    await assert.rejects(tool.execute("process", {action: "process-reports"}, null, null, host.commandContext), /observation.*degraded/);
    assert.equal(calls, 0);
  } finally { await session.shutdown(); fs.rmSync(dir, {recursive: true, force: true}); }
});
