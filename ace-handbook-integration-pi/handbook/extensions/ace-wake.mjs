// ace-wake — in-process loop and file-watch wakes for Pi agents.
//
// Named /loop timers and /watch file subscriptions queue a bounded wake
// message to the agent through sendUserMessage only. The agent decides what
// to do after waking; the extension never executes tasks and never depends on
// cron, systemd, or any external heartbeat service. While the agent is busy a
// wake is queued as a follow-up instead of interrupting an in-flight tool
// operation. Definitions persist as session entries, survive compaction, and
// reconcile exactly once per session start, reload, or branch switch.
//
// Commands:
//   /loop add NAME --interval SECONDS --message TEXT
//   /loop list
//   /loop remove NAME
//   /watch add NAME --path PATH --message TEXT
//   /watch list
//   /watch remove NAME

import { clearInterval, setInterval } from "node:timers";

import { WakeDispatcher } from "./wake/wake-dispatcher.mjs";
import { parseWakeCommand } from "./wake/wake-command-parser.mjs";
import { createLoopPort } from "./wake/loop-subscription.mjs";
import { createWatchPort, nodeStatFn, nodeWatchFactory } from "./wake/watch-subscription.mjs";
import {
  SESSION_ENTRY_TYPE,
  WakeError,
} from "./wake/types.mjs";
import { WakeRegistry } from "./wake/wake-registry.mjs";

const STATUS_KEY = "ace-wake";

/**
 * Extension factory. Pi calls it as `factory(pi)`; the optional second
 * argument exists so tests can inject deterministic clock, watcher, and
 * stat ports. Production defaults are real Node timers and fs.
 *
 * All mutable state lives inside this factory closure: one extension runtime
 * (one pi process, or one SDK session) owns exactly one state slot, and
 * multiple runtimes in one process never share state.
 *
 * @param {object} pi ExtensionAPI surface provided by Pi.
 * @param {object} [ports] Injectable host ports for deterministic tests.
 */
export default function (pi, ports = {}) {
  /** @type {{registry: WakeRegistry, agentActive: boolean} | undefined} */
  let runtime;

  const getRuntime = () => runtime;
  const bindRuntime = (ctx) => {
    runtime?.registry.dispose();
    runtime = { registry: createRegistry(pi, ctx, ports, getRuntime), agentActive: false };
    runtime.registry.reconcile();
  };

  pi.registerCommand("loop", {
    description: "Manage named timer loops that wake this agent (add | list | remove)",
    handler: async (args, ctx) => {
      await handleCommand(ctx, "loop", args, getRuntime, bindRuntime);
    },
  });

  pi.registerCommand("watch", {
    description: "Manage named file watches that wake this agent (add | list | remove)",
    handler: async (args, ctx) => {
      await handleCommand(ctx, "watch", args, getRuntime, bindRuntime);
    },
  });

  // session_start covers startup, reload, resume, fork, and new sessions;
  // session_tree covers branch switches. Reconciliation is idempotent, so a
  // reload re-registers each configured subscription exactly once.
  pi.on("session_start", async (_event, ctx) => {
    bindRuntime(ctx);
  });
  pi.on("session_tree", async (_event, ctx) => {
    bindRuntime(ctx);
  });

  // The agent consumed every queued continuation; same-source wakes may
  // deliver again.
  pi.on("agent_settled", async () => {
    runtime?.registry.settleAll();
  });

  // ctx.isIdle() only tracks model streaming — it reports idle while a tool
  // executes mid-run. Track actual run activity so wakes during tool
  // execution queue as follow-ups instead of starting a parallel turn.
  pi.on("agent_start", async () => {
    if (runtime) {
      runtime.agentActive = true;
    }
  });
  pi.on("agent_end", async () => {
    if (runtime) {
      runtime.agentActive = false;
    }
  });

  pi.on("session_shutdown", async () => {
    runtime?.registry.dispose();
    runtime = undefined;
  });
}

function createRegistry(pi, ctx, ports, getRuntime) {
  const dispatcher = new WakeDispatcher({
    deliver: (sourceKey, text) => deliverWake(getRuntime(), pi, ctx, sourceKey, text),
  });
  return new WakeRegistry({
    loops: createLoopPort({
      setIntervalFn: ports.setIntervalFn ?? ((callback, ms) => setInterval(callback, ms)),
      clearIntervalFn: ports.clearIntervalFn ?? ((handle) => clearInterval(handle)),
    }),
    watches: createWatchPort({
      watchFactory: ports.watchFactory ?? nodeWatchFactory,
      statFn: ports.statFn ?? nodeStatFn,
      baseDir: ctx.cwd,
    }),
    state: sessionStatePort(pi, ctx),
    status: statusPort(ctx),
    dispatcher,
  });
}

/**
 * Queue-only delivery. An agent with no run in flight receives the wake
 * directly (it triggers a turn); a busy agent — streaming or executing a
 * tool, or holding queued messages — receives a queued follow-up that never
 * interrupts the in-flight operation.
 */
function deliverWake(runtime, pi, ctx, sourceKey, text) {
  const message = `[ace-wake ${sourceKey}] ${text}`;
  try {
    if (isBusy(runtime, ctx)) {
      pi.sendUserMessage(message, { deliverAs: "followUp" });
    } else {
      pi.sendUserMessage(message);
    }
    return true;
  } catch {
    // A stale context (session replaced/reloaded) or a rejecting host must
    // not crash the timer callback; the next session_start rebinds.
    return false;
  }
}

function isBusy(runtime, ctx) {
  if (runtime?.agentActive) {
    return true;
  }
  try {
    return ctx.hasPendingMessages();
  } catch {
    return false;
  }
}

function sessionStatePort(pi, ctx) {
  return {
    load() {
      let snapshot;
      for (const entry of ctx.sessionManager.getBranch()) {
        if (entry.type === "custom" && entry.customType === SESSION_ENTRY_TYPE && entry.data) {
          snapshot = entry.data;
        }
      }
      return snapshot ?? { loops: [], watches: [] };
    },
    save(snapshot) {
      pi.appendEntry(SESSION_ENTRY_TYPE, snapshot);
    },
  };
}

function statusPort(ctx) {
  return {
    render(entries) {
      try {
        // Every context access — including hasUI — throws once the context
        // is stale after session replacement, reload, or disposal.
        if (!ctx.hasUI) {
          return;
        }
        if (entries.length === 0) {
          ctx.ui.setStatus(STATUS_KEY, undefined);
          return;
        }
        const parts = entries.map((entry) => {
          const state = entry.error ? " error" : entry.pending ? " pending" : "";
          return `${entry.kind} ${entry.name}${state} ${entry.detail}`;
        });
        ctx.ui.setStatus(STATUS_KEY, parts.join(" | "));
      } catch {
        // Stale context: skip the render; the next session_start rebinds.
      }
    },
  };
}

async function handleCommand(ctx, kind, args, getRuntime, bindRuntime) {
  try {
    if (!getRuntime()) {
      bindRuntime(ctx);
    }
    const registry = getRuntime().registry;
    const parsed = parseWakeCommand(kind, args);
    switch (parsed.subcommand) {
      case "add":
        addSubscription(registry, kind, parsed);
        notify(ctx, `${kind} "${parsed.name}" added`, "info");
        break;
      case "list":
        notify(ctx, formatList(kind, registry.list()), "info");
        break;
      case "remove":
        removeSubscription(registry, kind, parsed.name);
        notify(ctx, `${kind} "${parsed.name}" removed; no further wakes will fire`, "info");
        break;
      default:
        throw new WakeError(`unknown ${kind} subcommand: ${parsed.subcommand}`);
    }
  } catch (error) {
    notify(ctx, error instanceof WakeError ? error.message : `${kind} failed: ${error.message}`, "error");
  }
}

function addSubscription(registry, kind, parsed) {
  if (kind === "loop") {
    registry.addLoop({
      name: parsed.name,
      intervalSeconds: parsed.flags.interval,
      message: parsed.message,
    });
    return;
  }
  registry.addWatch({
    name: parsed.name,
    path: parsed.flags.path,
    message: parsed.message,
  });
}

function removeSubscription(registry, kind, name) {
  if (kind === "loop") {
    registry.removeLoop(name);
    return;
  }
  registry.removeWatch(name);
}

/**
 * @returns {string}
 */
function formatList(kind, entries) {
  const plural = kind === "watch" ? "watches" : `${kind}s`;
  const scoped = entries.filter((entry) => entry.kind === kind);
  if (scoped.length === 0) {
    return `no ${plural} configured`;
  }
  return scoped
    .map((entry) => {
      const state = entry.error ? ` ERROR: ${entry.error}` : entry.pending ? " (wake pending)" : "";
      return `${entry.name} — ${entry.detail}${state}`;
    })
    .join("\n");
}

function notify(ctx, message, type) {
  if (ctx.hasUI) {
    ctx.ui.notify(message, type);
  }
}
