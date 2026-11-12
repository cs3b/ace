import fs from "node:fs";
import path from "node:path";
import { execFile, execFileSync } from "node:child_process";
import { promisify } from "node:util";
import { Eyes, EYES_ENTRY } from "./eyes.js";

const execute = promisify(execFile);
export const EYES_BINDING = "ace-wake-eyes-binding";

// Birth identity is immutable for this process. Probe once at session binding,
// never during observation polling. Darwin uses the same native libproc owner
// as the Ruby readiness reader; second-resolution ps timestamps are insufficient.
let ownIdentity;
export function eyesProcessIdentity() {
  if (ownIdentity === undefined) ownIdentity = readEyesProcessIdentity();
  return ownIdentity;
}

export function readEyesProcessIdentity({ platform = process.platform, pid = process.pid,
  readFile = fs.readFileSync, run = execFileSync } = {}) {
  try {
    if (platform === "darwin") {
      const birth = run("ruby", ["-r", "ace/runtime/molecules/process_identity", "-e",
        "print Ace::Runtime::Molecules::ProcessIdentity.new.native_birth(Integer(ARGV.fetch(0)))", String(pid)],
        { encoding: "utf8", timeout: 2000, killSignal: "SIGKILL", maxBuffer: 1024, stdio: ["ignore", "pipe", "pipe"] }).trim();
      return /^darwin:[1-9][0-9]*:[0-9]{1,6}$/.test(birth) ? { pid, startedAt: birth } : null;
    }
    if (platform !== "linux") return null;
    const stat = readFile(`/proc/${pid}/stat`, "utf8");
    const end = stat.lastIndexOf(") ");
    if (end < 0) return null;
    const ticks = stat.slice(end + 2).trim().split(/\s+/)[19];
    const boot = readFile("/proc/sys/kernel/random/boot_id", "utf8").trim();
    if (!/^[1-9][0-9]*$/.test(ticks) || !/^[0-9a-f-]{36}$/.test(boot)) return null;
    return { pid, startedAt: `linux:${boot}:${ticks}` };
  } catch { return null; }
}

/** Existing native sync owns canonical import; HITL owns event projection.
 * No Ruby parsing, private text, shell command strings or model work here. */
export async function observeHitl(cwd, config) {
  const options = { cwd, timeout: config.timeoutMs, maxBuffer: 1024 * 1024, encoding: "utf8" };
  for (const source of config.syncRoutes) {
    // One source per project: each entry names the project hitl config and,
    // when several hermes_native routes exist there, the route to reconcile.
    const argv = ["sync", "--config", source.config];
    if (source.route !== undefined) argv.push("--route", source.route);
    const { stdout } = await execute("ace-hitl-hermes", argv, options);
    const result = JSON.parse(stdout);
    if (!Array.isArray(result.errors) || result.errors.length) throw new Error("Native synchronization incomplete");
  }
  const { stdout } = await execute("ace-overseer", ["observe", "--owner", config.recipient, "--scope", config.scope, "--limit", String(config.maxEvents)], options);
  const result = JSON.parse(stdout);
  if (!result?.sources || typeof result.sources !== "object" || Array.isArray(result.sources) ||
      Object.keys(result.sources).length === 0) throw new Error("Observation source health is missing");
  return result;
}

export async function processReports(cwd, config, signal) {
  const { stdout } = await execute("ace-overseer", ["process-reports", "--json",
    "--owner", config.recipient, "--scope", config.scope],
    { cwd, signal, maxBuffer: 8 * 1024 * 1024, encoding: "utf8" });
  const result = JSON.parse(stdout);
  if (!Array.isArray(result?.outcomes) || result.dry_run !== false)
    throw new Error("Invalid report-processing receipt");
  return result;
}

export function registerEyes(pi, { observe = observeHitl, processReports: processReportOwner = processReports, env = process.env, now = Date.now,
  schedule = (fn, ms) => setInterval(fn, ms), cancel = clearInterval, processIdentity = eyesProcessIdentity } = {}) {
  let eyes, timer, attempt, observedSources, observedAt, bindingGeneration = 0, compacting = false, running = false, arming = false;
  const clearEvidence = () => { observedSources = undefined; observedAt = undefined; };
  const stopTimer = () => { if (timer !== undefined) cancel(timer); timer = undefined; };
  function arm() {
    stopTimer();
    if (eyes?.s.enabled && !eyes.s.retired && !eyes.s.breaker) {
      timer = schedule(() => { void eyes.tick({ scheduled: true }); },
        eyes.s.config.intervalSeconds * 1000);
      timer?.unref?.();
    }
  }
  const bind = async (ctx) => {
    const generation = ++bindingGeneration;
    stopTimer(); eyes?.dispose(); attempt = undefined; clearEvidence(); compacting = false; running = false;
    const entries = ctx.sessionManager.getBranch();
    const snapshot = [...entries].reverse().find((e) => e.type === "custom" && e.customType === EYES_ENTRY)?.data;
    const ownerCwd = path.resolve(ctx.cwd);
    if (snapshot?.ownerCwd && snapshot.ownerCwd !== ownerCwd) {
      eyes = undefined;
      ctx.ui?.setStatus?.("ace-eyes", "eyes blocked: session belongs to another project cwd");
      throw new Error("Eyes project owner mismatch; preserve this actor and use its original project session");
    }
    const identity = processIdentity();
    pi.appendEntry(EYES_BINDING, { ownerCwd, process: identity });
    eyes = new Eyes({ snapshot, now,
      save: (data) => {
        const entries = observedSources && typeof observedSources === "object" && !Array.isArray(observedSources) ? Object.entries(observedSources) : [];
        const valid = entries.length > 0 && entries.length <= 64 && entries.every(([name, source]) =>
          /^[a-zA-Z0-9_.:-]{1,128}$/.test(name) && source && ["ok", "degraded"].includes(source.status));
        const sources = valid ? Object.fromEntries(entries.map(([name, source]) => [name, source.status]).sort()) : {};
        pi.appendEntry(EYES_ENTRY, { ...data, ownerCwd, observerEvidence: {
          process: identity, observedAt: observedAt ?? null, sources
        } });
      },
      status: (state) => {
        ctx.ui?.setStatus?.("ace-eyes", `eyes ${state.retired ? "retired" : state.breaker?.reason || (state.observationUnavailable ? "observation-unavailable" : state.wakeLimitedUntil && state.pending ? `wake-limited until ${new Date(state.wakeLimitedUntil).toISOString()}` : state.enabled ? "observing" : "off")} pending:${state.pending}`);
        if (state.breaker || state.retired) stopTimer();
      },
      observe: (config) => observe(ctx.cwd, config),
      // A result is evidence only after Eyes validated it and confirmed that
      // the observer generation is still current.
      onObserved: (result) => {
        if (generation === bindingGeneration) { observedSources = result.sources; observedAt = now(); }
      },
      onObservationUnavailable: () => {
        if (generation === bindingGeneration) clearEvidence();
      },
      // Do not queue a follow-up while the current turn can still handle and
      // acknowledge the same revision. Polling retains it until the agent is
      // idle; already handled changes then require no extra model turn. Unlike
      // eyes revisions, loop/watch messages cannot be acknowledged this way.
      canDeliver: () => !arming && !compacting && !running && ctx.isIdle() && !ctx.hasPendingMessages(),
      deliveryStatus: () => {
        if (attempt?.accepted) return "accepted";
        // sendUserMessage is a void wrapper. Busy/queued is uncertain, not
        // acceptance or rejection. Idle without confirmation is uncertain:
        // async input/auth preflight may still be running, so never blind-retry.
        return compacting || !ctx.isIdle() || ctx.hasPendingMessages() ? "waiting" : "uncertain";
      },
      deliver: async (batch) => {
        if (!ctx.model) return false;
        const text = `[ace-eyes] Pending task/assignment/HITL/deadline revisions: ${JSON.stringify(batch)}. ` +
          "Read the original state owners. For reports use ace_eyes action process-reports; it accepts, continues and acknowledges exact completed revisions. " +
          "Reconcile uncertain effects; never repeat external actions on wake alone. For other event types, after handling each exact revision, " +
          "acknowledge with the ace_eyes tool (action ack, key, revision). Settlement alone is not acknowledgement.";
        const previous = attempt;
        attempt = { text, accepted: false };
        const result = pi.sendUserMessage(text, { deliverAs: "followUp" });
        // Some hosts expose a promise, the standard ExtensionAPI exposes void.
        // Neither completion nor void is proof of message consumption.
        const submitted = await result;
        if (submitted === false) attempt = previous;
        return submitted !== false;
      } });
    const configPath = env.ACE_OVERSEER_EYES_CONFIG;
    if (configPath) {
      const expected = path.join(ownerCwd, ".ace-local/overseer/eyes.json");
      if (path.resolve(configPath) !== expected) throw new Error("Eyes config does not belong to this coordinator root");
      eyes.start(JSON.parse(fs.readFileSync(configPath, "utf8")));
    }
    arm();
    if (eyes.s.enabled && configPath) {
      arming = true;
      try { await eyes.tick(); } finally { arming = false; }
    } else if (eyes.s.enabled) void eyes.tick();
  };
  pi.on("session_start", async (_event, ctx) => bind(ctx));
  pi.on("session_tree", async (_event, ctx) => bind(ctx));
  pi.on("agent_start", async () => { running = true; });
  pi.on("agent_settled", async () => { running = false; eyes?.persist(); });
  pi.on("message_start", async (event) => {
    if (event.message?.role !== "user" || !attempt) return;
    const text = typeof event.message.content === "string" ? event.message.content :
      (event.message.content || []).filter(part => part.type === "text").map(part => part.text).join("");
    if (text === attempt.text) attempt.accepted = true;
  });
  pi.on("session_before_compact", async (event) => { if (event.reason === "manual") compacting = true; });
  pi.on("session_compact", async () => { compacting = false; eyes?.persist(); });
  pi.on("session_compact_failed", async () => { compacting = false; });
  pi.on("session_shutdown", async () => {
    bindingGeneration++; stopTimer(); clearEvidence();
    eyes?.persist(); eyes?.dispose(); eyes = undefined;
  });
  pi.on("message_end", async (event) => {
    const message = event.message;
    if (message?.role === "assistant" && message.stopReason === "error") eyes?.quota(message.errorMessage);
  });
  pi.registerTool?.({
    name: "ace_eyes", label: "Eyes observation", description: "Start standing observation with an existing config file, read pending semantic events or acknowledge an exact handled revision. Action process-reports invokes the existing report owner and acknowledges only its completed exact revisions. Other events require explicit ack. Does not reset quota. Deadlines require an operation identity and revision; cancel when no longer active.",
    parameters: { type: "object", properties: {
      action: { type: "string", enum: ["start", "status", "process-reports", "ack", "deadline", "cancel"] },
      configPath: { type: "string" },
      key: { type: "string" }, revision: { type: "string" },
      at: { type: "integer", description: "Absolute Unix epoch timestamp in milliseconds, NOT a duration. For five minutes from now use the current epoch milliseconds plus 300000; a past timestamp is immediately due." }
    }, required: ["action"], additionalProperties: false },
    execute: async (_id, args, _signal, _onUpdate, ctx) => {
      if (!eyes) {
        if (!ctx) throw new Error("Eyes session not initialized");
        await bind(ctx);
      }
      let processing;
      if (args.action === "start") {
        if (!ctx || typeof args.configPath !== "string" || !args.configPath.trim()) {
          throw new Error("Eyes start requires configPath and the current session context");
        }
        const config = JSON.parse(fs.readFileSync(path.resolve(ctx.cwd, args.configPath), "utf8"));
        const current = eyes, generation = bindingGeneration;
        clearEvidence(); current.start(config); arm();
        // Observe now, but do not enqueue a redundant model turn inside the
        // caller's turn. Pending revisions are returned to the caller below.
        arming = true;
        try { await current.tick(); } finally { if (current === eyes && generation === bindingGeneration) arming = false; }
        if (current !== eyes || generation !== bindingGeneration) throw new Error("Eyes session changed during start");
      }
      else if (args.action === "process-reports") {
        if (!ctx || !eyes.s.enabled) throw new Error("Report processing requires active eyes in this session");
        const sources = observedSources && Object.values(observedSources);
        const config = eyes.s.config;
        const interval = config.intervalSeconds * 1000;
        const cadence = Math.ceil(3600000 / (config.maxObservationsPerHour * interval)) * interval;
        if (eyes.s.breaker || eyes.s.observationUnavailable || !sources?.length ||
            sources.some(source => source.status !== "ok") || observedAt === undefined ||
            now() - observedAt > cadence + config.timeoutMs)
          throw new Error("Report processing blocked: required observation is unavailable, degraded or stale");
        const current = eyes, generation = bindingGeneration;
        processing = await processReportOwner(ctx.cwd, current.s.config, _signal);
        if (current !== eyes || generation !== bindingGeneration)
          throw new Error("Eyes session changed during report processing; retained receipts require reconciliation");
        if (!Array.isArray(processing?.outcomes) || processing.dry_run !== false)
          throw new Error("Invalid report-processing receipt");
        for (const receipt of processing.outcomes) {
          if (receipt.acknowledge !== true || receipt.accepted !== true || receipt.cleanup !== "complete") continue;
          if (current.s.pending[receipt.key]?.revision === receipt.revision || current.sent.get(receipt.key) === receipt.revision)
            current.ack(receipt.key, receipt.revision);
        }
      }
      else if (args.action === "ack") eyes.ack(args.key, args.revision);
      else if (args.action === "deadline") eyes.deadline(args.key, args.at, args.revision);
      else if (args.action === "cancel") eyes.cancelDeadline(args.key);
      else if (args.action !== "status") throw new Error("Unknown eyes action");
      // Do not send a second wake from inside the running model turn. The next
      // observation delivers remaining coalesced revisions through the same owner.
      const details = { ...eyes.summary(), ...(processing ? { processing } : {}), sources: observedSources, pending: eyes.s.pending, deadlines: eyes.s.deadlines };
      return { content: [{ type: "text", text: JSON.stringify(details) }], details };
    }
  });
  pi.registerCommand("eyes", { description: "Event-driven HITL observation: start CONFIG | status | ack KEY REV | deadline NAME REVISION EPOCH_MS | cancel NAME | resume quota-verified | retire",
    handler: async (args, ctx) => {
      try {
        if (!eyes) await bind(ctx);
        const [command, a, b, ...rest] = args.trim().split(/\s+/);
        if (rest.length && command !== "deadline") throw new Error("Too many arguments");
        switch (command) {
          case "start": {
            if (!a || b) throw new Error("Use eyes start CONFIG_JSON");
            const config = JSON.parse(fs.readFileSync(path.resolve(ctx.cwd, a), "utf8"));
            const current = eyes, generation = bindingGeneration;
            clearEvidence(); current.start(config); arm(); await current.tick();
            if (current !== eyes || generation !== bindingGeneration) throw new Error("Eyes session changed during start");
            break;
          }
          case "status": ctx.ui?.notify?.(JSON.stringify({ ...eyes.summary(), pending: eyes.s.pending, deadlines: eyes.s.deadlines }), "info"); break;
          case "ack": eyes.ack(a, b); await eyes.tick(); break;
          case "deadline":
            if (rest.length !== 1) throw new Error("Deadline requires operation identity, revision and epoch milliseconds");
            eyes.deadline(a, Number(rest[0]), b); await eyes.tick(); break;
          case "cancel": eyes.cancelDeadline(a); break;
          case "resume":
            if (a !== "quota-verified" || b) throw new Error("Explicit owner verification required: eyes resume quota-verified");
            {
              const current = eyes, generation = bindingGeneration;
              clearEvidence(); await current.resume();
              if (current !== eyes || generation !== bindingGeneration) throw new Error("Eyes session changed during resume");
              arm();
            }
            break;
          case "retire": eyes.retire(); stopTimer(); break;
          default: throw new Error("Unknown eyes command; use start, status, ack, deadline, cancel, resume or retire");
        }
      } catch (error) {
        // Never echo process stdout/stderr: a failed native sync may carry private data.
        ctx.ui?.notify?.(`Eyes operation refused (${error.name}); check configuration or /eyes status`, "error");
      }
    } });
  return { active: () => Boolean(eyes?.s.enabled || eyes?.s.retired) };
}
