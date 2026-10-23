// Installed-extension acceptance for ace-wake on the real Pi runtime.
//
// Requires PI_PKG_ROOT (pi-coding-agent package dir) and EXT_PATH (a
// projected ace-wake.js). The Ruby suite projects the package via
// ProviderSyncer and invokes this suite against the projected
// .pi/extensions/ace-wake/index.js, proving the installed artifact — not the
// source tree — wakes idle and busy agents through queued user messages
// with no external timer or service.
import * as assert from "node:assert/strict";
import * as fs from "node:fs";
import * as os from "node:os";
import * as path from "node:path";
import { createRequire } from "node:module";
import { pathToFileURL } from "node:url";
import { describe, it } from "node:test";

const PI_PKG_ROOT = process.env.PI_PKG_ROOT;
const EXT_PATH = process.env.EXT_PATH;

if (!PI_PKG_ROOT || !EXT_PATH) {
  throw new Error(
    "pi-sdk-acceptance requires PI_PKG_ROOT (pi-coding-agent package dir) and EXT_PATH (projected ace-wake.js)",
  );
}

const { createAgentSession, DefaultResourceLoader, ModelRuntime, SessionManager, SettingsManager } =
  await import(pathToFileURL(path.join(PI_PKG_ROOT, "dist", "index.js")).href);
const sdkRequire = createRequire(path.join(PI_PKG_ROOT, "package.json"));
const dependencyEntry = (name, entry) => {
  const found = sdkRequire.resolve.paths(name).map(root => path.join(root, name, entry)).find(file => fs.existsSync(file));
  if (!found) throw new Error(`SDK dependency missing: ${name}/${entry}`);
  return pathToFileURL(found).href;
};
const { createAssistantMessageEventStream } = await import(dependencyEntry("@earendil-works/pi-ai", "dist/index.js"));
const { Type } = await import(dependencyEntry("typebox", "build/index.mjs"));

/**
 * Scripted fake model stream handler: each stream request consumes the next
 * scripted response. Responses: {kind: "text", text} or {kind: "tool",
 * toolName}. Unscripted requests answer with plain text "ack".
 */
function streamHandler(script) {
  return (_model, _context, _options) => {
    const response = script.length > 0 ? script.shift() : { kind: "text", text: "ack" };
        const stream = createAssistantMessageEventStream();
        const base = {
          role: "assistant",
          api: "wake-test-api",
          provider: "wake-test",
          model: "wake-model",
          usage: { input: 1, output: 1, cacheRead: 0, cacheWrite: 0, totalTokens: 2, cost: { input: 0, output: 0, cacheRead: 0, cacheWrite: 0, total: 0 } },
          stopReason: "stop",
          timestamp: Date.now(),
        };
        if (response.kind === "tool") {
          const toolCall = { type: "toolCall", id: `call-${Date.now()}-${Math.random()}`, name: response.toolName, arguments: response.arguments || {} };
          const withCall = { ...base, content: [toolCall], stopReason: "toolUse" };
          stream.push({ type: "start", partial: { ...base, content: [] } });
          stream.push({ type: "toolcall_start", contentIndex: 0, partial: withCall });
          stream.push({ type: "toolcall_end", contentIndex: 0, toolCall, partial: withCall });
          stream.push({ type: "done", reason: "toolUse", message: withCall });
          return stream;
        }
        const empty = { ...base, content: [] };
        const withText = { ...base, content: [{ type: "text", text: response.text }] };
        stream.push({ type: "start", partial: empty });
        stream.push({ type: "text_start", contentIndex: 0, partial: empty });
        stream.push({ type: "text_delta", contentIndex: 0, delta: response.text, partial: withText });
        stream.push({ type: "text_end", contentIndex: 0, content: response.text, partial: withText });
        stream.push({ type: "done", reason: "stop", message: withText });
        return stream;
  };
}

/**
 * Start a hermetic SDK session with the projected ace-wake extension loaded
 * the way pi loads project extensions.
 */
/**
 * Start a hermetic SDK session with the projected ace-wake extension loaded
 * the way pi loads project extensions.
 *
 * `autoDiscover` omits additionalExtensionPaths so discovery must find the
 * extension from the project `.pi/extensions/` directory on its own — the
 * installed behavior a real `pi` session relies on.
 */
async function startWakeSession({ script = [], extraFactories = [], extraTools = [], autoDiscover = false, loadProjected = true } = {}) {
  const tmp = fs.mkdtempSync(path.join(os.tmpdir(), "wake-accept-"));
  const cwd = path.join(tmp, "project");
  const agentDir = path.join(tmp, "agent");
  fs.mkdirSync(cwd, { recursive: true });
  fs.mkdirSync(agentDir, { recursive: true });
  fs.writeFileSync(
    path.join(agentDir, "models.json"),
    JSON.stringify({
      providers: {
        "wake-test": {
          baseUrl: "http://127.0.0.1:9",
          api: "wake-test-api",
          apiKey: "acceptance-key",
          models: [{ id: "wake-model", name: "Wake Model", input: ["text"], contextWindow: 32000, maxTokens: 1024 }],
        },
      },
    }),
  );

  if (autoDiscover) {
    // Project the extension the way `ace-handbook sync` would so discovery
    // must find it from the project directory on its own.
    fs.cpSync(path.dirname(EXT_PATH), path.join(cwd, ".pi", "extensions", "ace-wake"), { recursive: true });
    if (!fs.existsSync(path.join(cwd, ".pi", "extensions", "ace-wake", "index.js"))) {
      throw new Error("projection for auto-discovery is missing ace-wake/index.js");
    }
  }

  const resourceLoader = new DefaultResourceLoader({
    cwd,
    agentDir,
    additionalExtensionPaths: autoDiscover || !loadProjected ? [] : [EXT_PATH],
    extensionFactories: [...extraFactories],
  });
  await resourceLoader.reload();

  const modelRuntime = await ModelRuntime.create({
    authPath: path.join(agentDir, "auth.json"),
    modelsPath: path.join(agentDir, "models.json"),
  });
  // Register the scripted stream handler directly on the runtime: registering
  // it from an extension factory is queued until the runner binds its
  // context, which races an immediate first model call.
  modelRuntime.registerProvider("wake-test", {
    name: "Wake Test",
    api: "wake-test-api",
    streamSimple: streamHandler(script),
  });
  const model = modelRuntime.getModel("wake-test", "wake-model");
  if (!model) {
    throw new Error("wake-test/wake-model was not registered");
  }

  const { session } = await createAgentSession({
    cwd,
    agentDir,
    model,
    modelRuntime,
    resourceLoader,
    sessionManager: SessionManager.inMemory(cwd),
    settingsManager: SettingsManager.inMemory({ compaction: { enabled: false } }),
    customTools: extraTools,
  });

  return {
    session,
    cwd,
    cleanup: () => {
      session.dispose();
      fs.rmSync(tmp, { recursive: true, force: true });
    },
  };
}

async function waitFor(predicate, { timeoutMs = 10_000, stepMs = 100 } = {}) {
  const deadline = Date.now() + timeoutMs;
  while (Date.now() < deadline) {
    const value = predicate();
    if (value) {
      return value;
    }
    await new Promise((resolve) => setTimeout(resolve, stepMs));
  }
  return undefined;
}

function userTextsOf(session) {
  return session.messages
    .filter((message) => message.role === "user")
    .map((message) => (message.content ?? []).map((part) => part.text ?? "").join(""));
}

function wakeTexts(session) {
  return userTextsOf(session).filter((text) => text.includes("[ace-wake "));
}

function lastWakeMessage(session) {
  return session.messages.findLast(
    (message) => message.role === "user" && (message.content ?? []).some((part) => (part.text ?? "").includes("[ace-wake ")),
  );
}

describe("ace-wake installed acceptance", { timeout: 90_000 }, () => {
  it("recovers the exact async compaction rejection without stranding or duplicate delivery", async () => {
    const { registerEyes } = await import(pathToFileURL(path.join(path.dirname(EXT_PATH), "wake/eyes-runtime.js")).href);
    let tick, rows=[];
    const {session,cwd,cleanup}=await startWakeSession({loadProjected:false,extraFactories:[pi=>registerEyes(pi,{
      observe:async()=>({schema:"ace.hitl.observation/v1",events:rows}),schedule:fn=>{tick=fn;return 1;},cancel:()=>{}
    })]});
    const flush=()=>new Promise(resolve=>setImmediate(resolve));
    try {
      fs.writeFileSync(path.join(cwd,"eyes.json"),"{}");await session.prompt("/eyes start eyes.json");
      session._compactionAbortController=new AbortController();
      rows=[{key:"a".repeat(64),revision:"b".repeat(64),id:"event1"}];tick();await flush();
      assert.equal(userTextsOf(session).filter(text=>text.includes("[ace-eyes]")).length,0);
      session._compactionAbortController=undefined;
      for(let i=0;i<6;i++){tick();await flush();}
      await waitFor(()=>session.isIdle);
      const state=session.sessionManager.getBranch().filter(e=>e.customType==="ace-wake-eyes").at(-1).data;
      assert.equal(userTextsOf(session).filter(text=>text.includes("[ace-eyes]")).length,1);
      assert.equal(state.window.wakes,1,"defer during compaction, then one actually accepted notification");
      assert.equal(Object.keys(state.pending).length,1,"notification acceptance is not business acknowledgement");
      assert.equal(state.breaker,null);
    } finally {session._compactionAbortController=undefined;cleanup();}
  });

  it("preserves uncertain async interception behind a breaker until explicit owner reconciliation", async () => {
    const { registerEyes } = await import(pathToFileURL(path.join(path.dirname(EXT_PATH), "wake/eyes-runtime.js")).href);
    let tick, rows=[],reject=true;
    const {session,cwd,cleanup}=await startWakeSession({loadProjected:false,extraFactories:[pi=>{
      registerEyes(pi,{observe:async()=>({schema:"ace.hitl.observation/v1",events:rows}),schedule:fn=>{tick=fn;return 1;},cancel:()=>{}});
      pi.on("input",async event=>{if(reject&&event.text.includes("[ace-eyes]")){await Promise.resolve();return {action:"handled"};}});
      pi.registerCommand("eyes-test-reload",{handler:async(_args,ctx)=>ctx.reload()});
    }]});
    const flush=()=>new Promise(resolve=>setImmediate(resolve));
    try {
      fs.writeFileSync(path.join(cwd,"eyes.json"),"{}");await session.prompt("/eyes start eyes.json");
      rows=[{key:"a".repeat(64),revision:"b".repeat(64),id:"event1"}];
      for(let i=0;i<10;i++){tick();await flush();}
      let state=session.sessionManager.getBranch().filter(e=>e.customType==="ace-wake-eyes").at(-1).data;
      assert.equal(userTextsOf(session).filter(text=>text.includes("[ace-eyes]")).length,0);
      assert.equal(state.window.wakes,1);assert.equal(state.breaker.reason,"notification-unconfirmed");
      await session.prompt("/eyes-test-reload");await flush();
      state=session.sessionManager.getBranch().filter(e=>e.customType==="ace-wake-eyes").at(-1).data;
      assert.equal(state.breaker.reason,"notification-unconfirmed","reload must preserve the uncertain-delivery breaker");
      assert.equal(Object.keys(state.pending).length,1);
      reject=false;await session.prompt("/eyes resume quota-verified");await flush();
      for(let i=0;i<3;i++){tick();await flush();}
      assert.equal(userTextsOf(session).filter(text=>text.includes("[ace-eyes]")).length,1);
      state=session.sessionManager.getBranch().filter(e=>e.customType==="ace-wake-eyes").at(-1).data;
      assert.equal(Object.keys(state.pending).length,1);assert.equal(state.breaker,null);
    }finally{cleanup();}
  });

  it("never retries a delayed asynchronous input preflight even while the SDK reports idle", async () => {
    const { registerEyes } = await import(pathToFileURL(path.join(path.dirname(EXT_PATH), "wake/eyes-runtime.js")).href);
    let tick,rows=[],release;
    const gate=new Promise(resolve=>{release=resolve;});
    const {session,cwd,cleanup}=await startWakeSession({loadProjected:false,extraFactories:[pi=>{
      pi.on("input",async event=>{if(event.text.includes("[ace-eyes]")) await gate;});
      registerEyes(pi,{observe:async()=>({schema:"ace.hitl.observation/v1",events:rows}),schedule:fn=>{tick=fn;return 1;},cancel:()=>{}});
    }]});
    const flush=()=>new Promise(resolve=>setImmediate(resolve));
    try {
      fs.writeFileSync(path.join(cwd,"eyes.json"),"{}");await session.prompt("/eyes start eyes.json");
      rows=[{key:"a".repeat(64),revision:"b".repeat(64),id:"event1"}];
      for(let i=0;i<8;i++){tick();await flush();}
      const state=session.sessionManager.getBranch().filter(e=>e.customType==="ace-wake-eyes").at(-1).data;
      assert.equal(state.window.wakes,1);assert.equal(state.breaker.reason,"notification-unconfirmed");
      release();await flush();await waitFor(()=>session.isIdle);
      assert.equal(userTextsOf(session).filter(text=>text.includes("[ace-eyes]")).length,1,"the delayed accepted original must not acquire duplicates");
    }finally{release();cleanup();}
  });

  it("retains one uncertain busy follow-up until the actual host consumes it", async () => {
    const { registerEyes } = await import(pathToFileURL(path.join(path.dirname(EXT_PATH), "wake/eyes-runtime.js")).href);
    let tick,rows=[],release,entered=false;
    const gate=new Promise(resolve=>{release=resolve;});
    const block={name:"block",label:"Block",description:"Scripted blocking tool",parameters:Type.Object({}),execute:async()=>{
      entered=true;await gate;return {content:[{type:"text",text:"released"}],details:{}};
    }};
    const {session,cwd,cleanup}=await startWakeSession({loadProjected:false,script:[{kind:"tool",toolName:"block"}],extraTools:[block],extraFactories:[pi=>registerEyes(pi,{
      observe:async()=>({schema:"ace.hitl.observation/v1",events:rows}),schedule:fn=>{tick=fn;return 1;},cancel:()=>{}
    })]});
    const flush=()=>new Promise(resolve=>setImmediate(resolve));
    try {
      fs.writeFileSync(path.join(cwd,"eyes.json"),"{}");await session.prompt("/eyes start eyes.json");
      const running=session.prompt("Run the scripted blocking tool");await waitFor(()=>entered);
      rows=[{key:"a".repeat(64),revision:"b".repeat(64),id:"event1"}];
      for(let i=0;i<4;i++){tick();await flush();}
      let state=session.sessionManager.getBranch().filter(e=>e.customType==="ace-wake-eyes").at(-1).data;
      assert.equal(state.window.wakes,1,"queued follow-up must never be retried while host busy");
      release();await running;await waitFor(()=>session.isIdle);
      for(let i=0;i<3;i++){tick();await flush();}
      assert.equal(userTextsOf(session).filter(text=>text.includes("[ace-eyes]")).length,1);
    }finally{release();cleanup();}
  });

  it("registers the eyes acknowledgement tool with the real SDK schema validator", async () => {
    const { session, cleanup } = await startWakeSession({script:[
      {kind:"tool",toolName:"ace_eyes",arguments:{action:"status"}},
      {kind:"text",text:"read status"}
    ]});
    try {
      await session.prompt("Read the eyes status with its tool.");
      const result = session.messages.find(message => message.role === "toolResult" && message.toolName === "ace_eyes");
      assert.ok(result, "SDK must discover and execute the projected eyes tool");
      assert.ok(!result.isError, JSON.stringify(result.content));
      assert.equal(JSON.parse(result.content[0].text).enabled, false);
      assert.equal(JSON.parse(result.content[0].text).pending && Object.keys(JSON.parse(result.content[0].text).pending).length, 0);
    } finally {cleanup();}
  });

  it("is discovered automatically from the projected project directory", async () => {
    const { session, cleanup } = await startWakeSession({ autoDiscover: true });
    try {
      // No additionalExtensionPaths: if pi's discovery did not load the
      // projected .pi/extensions entrypoint, "/loop add" would become an
      // ordinary user message and no wake would ever fire.
      await session.prompt("/loop add auto --interval 1 --message auto tick");

      const wake = await waitFor(() => wakeTexts(session).find((text) => text.includes("loop:auto")));
      assert.ok(wake, "the projected extension must be auto-discovered without an explicit path");
      assert.equal(wake, "[ace-wake loop:auto] auto tick");
    } finally {
      cleanup();
    }
  });

  it("wakes an idle agent when the timer fires and the agent answers", async () => {
    const { session, cleanup } = await startWakeSession();
    try {
      await session.prompt("/loop add probe --interval 1 --message probe tick");

      const wake = await waitFor(() => wakeTexts(session).find((text) => text.includes("loop:probe")));
      assert.ok(wake, "idle agent must receive the timer wake as a user message");
      assert.equal(wake, "[ace-wake loop:probe] probe tick");

      const answered = await waitFor(() => session.messages.some((message) => message.role === "assistant"));
      assert.ok(answered, "agent must answer the wake");
    } finally {
      cleanup();
    }
  });

  it("wakes a busy agent with a queued follow-up that never interrupts an in-flight tool", async () => {
    let releaseTool;
    const release = new Promise((resolve) => {
      releaseTool = resolve;
    });
    let toolEntered = false;
    const blockTool = {
      name: "block",
      label: "Block",
      description: "Blocks until released",
      parameters: Type.Object({}),
      execute: async () => {
        toolEntered = true;
        await release;
        return { content: [{ type: "text", text: "tool finished" }], details: undefined };
      },
    };

    const script = [
      { kind: "tool", toolName: "block" },
      { kind: "text", text: "tool done" },
    ];
    const { session, cleanup } = await startWakeSession({ script, extraTools: [blockTool] });
    try {
      await session.prompt("/loop add busy --interval 1 --message busy tick");

      const run = session.prompt("use the block tool");
      await waitFor(() => toolEntered);
      assert.equal(wakeTexts(session).length, 0, "no wake may arrive before the tool finishes");

      // Two intervals elapse while the tool is in flight: the first wake
      // queues as a follow-up, the second coalesces into it.
      await new Promise((resolve) => setTimeout(resolve, 2300));
      assert.equal(wakeTexts(session).length, 0, "wakes must queue as follow-ups, not interrupt the tool");

      releaseTool();
      await run;

      const wake = await waitFor(() => wakeTexts(session).find((text) => text.includes("loop:busy")));
      assert.ok(wake, "the queued follow-up wake must run after the busy work finished");
      assert.equal(wakeTexts(session).length, 1, "same-source wakes must coalesce into one follow-up");

      const toolResult = session.messages.find((message) => message.role === "toolResult" && message.toolName === "block");
      assert.ok(toolResult, "the in-flight tool must complete normally");
      assert.ok(
        session.messages.indexOf(lastWakeMessage(session)) > session.messages.indexOf(toolResult),
        "the wake turn must follow the tool completion",
      );
    } finally {
      cleanup();
    }
  });

  it("keeps normal user conversation responsive while subscriptions are active", async () => {
    const { session, cleanup } = await startWakeSession();
    try {
      await session.prompt("/loop add chatter --interval 5 --message slow tick");
      await session.prompt("plain conversation message");

      assert.ok(
        session.messages.some((message) => message.role === "assistant"),
        "normal conversation must complete while a loop subscription exists",
      );
      assert.ok(
        userTextsOf(session).some((text) => text.includes("plain conversation message")),
        "the user message must enter the transcript normally",
      );
    } finally {
      cleanup();
    }
  });

  it("does not duplicate timers after an extension reload", async () => {
    const reloadFactory = (pi) => {
      pi.registerCommand("test-reload", {
        description: "Reload extensions (acceptance hook)",
        handler: async (_args, ctx) => {
          await ctx.reload();
        },
      });
    };

    const { session, cleanup } = await startWakeSession({ extraFactories: [reloadFactory] });
    try {
      await session.prompt("/loop add ticky --interval 1 --message reload tick");
      await session.prompt("/test-reload");

      // Let the reload settle (the reloaded runtime re-registers one timer),
      // then count wakes over a window. A 1s interval observed for 2.3s
      // yields 2 or 3 ticks depending on phase; a duplicated timer would
      // yield 4 or more.
      await new Promise((resolve) => setTimeout(resolve, 1500));
      const before = wakeTexts(session).length;
      await new Promise((resolve) => setTimeout(resolve, 2300));
      const fired = wakeTexts(session).length - before;

      assert.ok(fired >= 2, `the reloaded subscription must keep ticking (saw ${fired})`);
      assert.ok(fired <= 3, `exactly one timer survives reload; saw ${fired}, a duplicate would fire 4+`);
    } finally {
      cleanup();
    }
  });

  it("wakes the idle agent when a watched file changes and ignores unreadable watch adds", async () => {
    const { session, cwd, cleanup } = await startWakeSession();
    try {
      const watched = path.join(cwd, "dep.txt");
      fs.writeFileSync(watched, "version-1");
      await session.prompt("/watch add dep --path dep.txt --message file changed");

      // The platform watcher backend subscribes asynchronously; give it a
      // beat before the change so the baseline-vs-change proof stays honest.
      await new Promise((resolve) => setTimeout(resolve, 500));
      fs.writeFileSync(watched, "version-2 with more content");
      const wake = await waitFor(() => wakeTexts(session).find((text) => text.includes("watch:dep")), { timeoutMs: 15_000 });
      assert.ok(wake, "file change must wake the idle agent");
      assert.equal(wake, "[ace-wake watch:dep] file changed");

      const before = wakeTexts(session).length;
      await session.prompt("/watch add ghost --path missing.txt --message never");
      assert.equal(wakeTexts(session).length, before, "a failed watch add must not wake the agent");
    } finally {
      cleanup();
    }
  });
});

describe("acceptance harness sanity", () => {
  it("loads the projected entrypoint and imports no runtime dependencies beyond node builtins", () => {
    const entry = fs.readFileSync(EXT_PATH, "utf8");
    const imports = [...entry.matchAll(/import\s+[^'"]*['"]([^'"]+)['"]/g)].map((match) => match[1]);
    assert.ok(imports.length > 0, "entrypoint must declare imports");
    const offenders = imports.filter((name) => !name.startsWith(".") && !name.startsWith("node:"));
    assert.deepEqual(offenders, [], "entrypoint must rely only on relative modules and node builtins");
    assert.ok(fs.existsSync(EXT_PATH), "projected extension entrypoint must exist");
  });
});
