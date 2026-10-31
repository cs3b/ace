import assert from "node:assert/strict";
import { it } from "node:test";
import fs from "node:fs";
import os from "node:os";
import path from "node:path";
import { createFakeHost } from "./fake-pi-host.mjs";
import { startSession } from "./session-harness.mjs";
const key="a".repeat(64), revision="b".repeat(64);
const flush=()=>new Promise(resolve=>setImmediate(resolve));
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
