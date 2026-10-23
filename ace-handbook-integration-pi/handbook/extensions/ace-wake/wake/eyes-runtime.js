import fs from "node:fs";
import path from "node:path";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { Eyes, EYES_ENTRY } from "./eyes.js";

const execute = promisify(execFile);

/** Existing native sync owns canonical import; HITL owns event projection.
 * No Ruby parsing, private text, shell command strings or model work here. */
export async function observeHitl(cwd, config) {
  const options = { cwd, timeout: config.timeoutMs, maxBuffer: 1024 * 1024, encoding: "utf8" };
  for (const route of config.syncRoutes) {
    const { stdout } = await execute("ace-hitl-hermes", ["sync", "--config", route], options);
    const result = JSON.parse(stdout);
    if (!Array.isArray(result.errors) || result.errors.length) throw new Error("Native synchronization incomplete");
  }
  const { stdout } = await execute("ace-overseer", ["observe", "--owner", config.recipient, "--scope", config.scope, "--limit", String(config.maxEvents)], options);
  return JSON.parse(stdout);
}

export function registerEyes(pi, { retireLegacy, observe = observeHitl, now = Date.now,
  schedule = (fn, ms) => setInterval(fn, ms), cancel = clearInterval } = {}) {
  let eyes, timer, attempt, compacting = false, running = false;
  const stopTimer = () => { if (timer !== undefined) cancel(timer); timer = undefined; };
  function arm() {
    stopTimer();
    if (eyes?.s.enabled && !eyes.s.retired && !eyes.s.breaker) {
      timer = schedule(() => { void eyes.tick(); }, eyes.s.config.intervalSeconds * 1000);
      timer?.unref?.();
    }
  }
  const bind = (ctx) => {
    stopTimer(); eyes?.dispose(); attempt = undefined; compacting = false; running = false;
    const entries = ctx.sessionManager.getBranch();
    const snapshot = [...entries].reverse().find((e) => e.type === "custom" && e.customType === EYES_ENTRY)?.data;
    if (snapshot?.enabled || snapshot?.retired) retireLegacy?.();
    const ownerCwd = path.resolve(ctx.cwd);
    if (snapshot?.ownerCwd && snapshot.ownerCwd !== ownerCwd) {
      eyes = undefined;
      ctx.ui?.setStatus?.("ace-eyes", "eyes blocked: session belongs to another project cwd");
      throw new Error("Eyes project owner mismatch; preserve this actor and use its original project session");
    }
    eyes = new Eyes({ snapshot, now,
      save: (data) => pi.appendEntry(EYES_ENTRY, { ...data, ownerCwd }),
      status: (state) => {
        ctx.ui?.setStatus?.("ace-eyes", `eyes ${state.retired ? "retired" : state.breaker?.reason || (state.enabled ? "observing" : "off")} pending:${state.pending}`);
        if (state.breaker || state.retired) stopTimer();
      },
      observe: (config) => observe(ctx.cwd, config),
      canDeliver: () => !compacting && (ctx.isIdle() || running),
      deliveryStatus: () => {
        if (attempt?.accepted) return "accepted";
        // sendUserMessage is a void wrapper. Busy/queued is uncertain, not
        // acceptance or rejection. Idle without confirmation is uncertain:
        // async input/auth preflight may still be running, so never blind-retry.
        return compacting || !ctx.isIdle() || ctx.hasPendingMessages() ? "waiting" : "uncertain";
      },
      deliver: async (batch) => {
        if (!ctx.model) return false;
        const text = `[ace-eyes] Pending canonical HITL/deadline revisions: ${JSON.stringify(batch)}. ` +
          "Read original events; adopt reports through ace-overseer process-reports and existing task/assignment gates. " +
          "Reconcile uncertain effects; never repeat external actions on wake alone. After handling each exact revision, " +
          "acknowledge with the ace_eyes tool (action ack, key, revision). Settlement alone is not acknowledgement.";
        attempt = { text, accepted: false };
        const result = pi.sendUserMessage(text, { deliverAs: "followUp" });
        // Some hosts expose a promise, the standard ExtensionAPI exposes void.
        // Neither completion nor void is proof of message consumption.
        if (result?.then) await result;
        return result !== false;
      } });
    if (eyes.s.enabled || eyes.s.retired) retireLegacy?.();
    arm();
    if (eyes.s.enabled) void eyes.tick();
  };
  pi.on("session_start", async (_event, ctx) => bind(ctx));
  pi.on("session_tree", async (_event, ctx) => bind(ctx));
  pi.on("agent_start", async () => { running = true; });
  pi.on("agent_settled", async () => { running = false; });
  pi.on("message_start", async (event) => {
    if (event.message?.role !== "user" || !attempt) return;
    const text = typeof event.message.content === "string" ? event.message.content :
      (event.message.content || []).filter(part => part.type === "text").map(part => part.text).join("");
    if (text === attempt.text) attempt.accepted = true;
  });
  pi.on("session_before_compact", async (event) => { if (event.reason === "manual") compacting = true; });
  pi.on("session_compact", async () => { compacting = false; eyes?.persist(); });
  pi.on("session_compact_failed", async () => { compacting = false; });
  pi.on("session_shutdown", async () => { stopTimer(); eyes?.dispose(); });
  pi.on("message_end", async (event) => {
    const message = event.message;
    if (message?.role === "assistant" && message.stopReason === "error") eyes?.quota(message.errorMessage);
  });
  pi.registerTool?.({
    name: "ace_eyes", label: "Eyes acknowledgement", description: "Read pending semantic events or acknowledge an exact handled revision. Does not accept reports, authorize effects, start actors or reset quota. Use existing report/assignment owners first. Deadlines require an operation identity and revision; cancel when no longer active.",
    parameters: { type: "object", properties: {
      action: { type: "string", enum: ["status", "ack", "deadline", "cancel"] },
      key: { type: "string" }, revision: { type: "string" }, at: { type: "integer" }
    }, required: ["action"], additionalProperties: false },
    execute: async (_id, args, _signal, _onUpdate, ctx) => {
      if (!eyes) {
        if (!ctx) throw new Error("Eyes session not initialized");
        bind(ctx);
      }
      if (args.action === "ack") eyes.ack(args.key, args.revision);
      else if (args.action === "deadline") eyes.deadline(args.key, args.at, args.revision);
      else if (args.action === "cancel") eyes.cancelDeadline(args.key);
      else if (args.action !== "status") throw new Error("Unknown eyes action");
      // Do not send a second wake from inside the running model turn. The next
      // observation delivers remaining coalesced revisions through the same owner.
      const details = { ...eyes.summary(), pending: eyes.s.pending, deadlines: eyes.s.deadlines };
      return { content: [{ type: "text", text: JSON.stringify(details) }], details };
    }
  });
  pi.registerCommand("eyes", { description: "Event-driven HITL observation: start CONFIG | status | ack KEY REV | deadline NAME REVISION EPOCH_MS | cancel NAME | resume quota-verified | retire",
    handler: async (args, ctx) => {
      try {
        if (!eyes) bind(ctx);
        const [command, a, b, ...rest] = args.trim().split(/\s+/);
        if (rest.length && command !== "deadline") throw new Error("Too many arguments");
        switch (command) {
          case "start": {
            if (!a || b) throw new Error("Use eyes start CONFIG_JSON");
            const config = JSON.parse(fs.readFileSync(path.resolve(ctx.cwd, a), "utf8"));
            eyes.start(config); retireLegacy?.(); arm(); await eyes.tick(); break;
          }
          case "status": ctx.ui?.notify?.(JSON.stringify({ ...eyes.summary(), pending: eyes.s.pending, deadlines: eyes.s.deadlines }), "info"); break;
          case "ack": eyes.ack(a, b); await eyes.tick(); break;
          case "deadline":
            if (rest.length !== 1) throw new Error("Deadline requires operation identity, revision and epoch milliseconds");
            eyes.deadline(a, Number(rest[0]), b); await eyes.tick(); break;
          case "cancel": eyes.cancelDeadline(a); break;
          case "resume":
            if (a !== "quota-verified" || b) throw new Error("Explicit owner verification required: eyes resume quota-verified");
            await eyes.resume(); arm(); break;
          case "retire": eyes.retire(); retireLegacy?.(); stopTimer(); break;
          default: throw new Error("Unknown eyes command; use start, status, ack, deadline, cancel, resume or retire");
        }
      } catch (error) {
        // Never echo process stdout/stderr: a failed native sync may carry private data.
        ctx.ui?.notify?.(`Eyes operation refused (${error.name}); check configuration or /eyes status`, "error");
      }
    } });
  return { active: () => Boolean(eyes?.s.enabled || eyes?.s.retired) };
}
