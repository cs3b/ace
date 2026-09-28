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

/** @type {{ports: object, registry: WakeRegistry} | undefined} */
let runtime;

/**
 * Extension factory. Pi calls it as `factory(pi)`; the optional second
 * argument exists so tests can inject deterministic clock, watcher, and
 * stat ports. Production defaults are real Node timers and fs.
 *
 * @param {object} pi ExtensionAPI surface provided by Pi.
 * @param {object} [ports] Injectable host ports for deterministic tests.
 */
export default function (pi, ports = {}) {
  pi.registerCommand("loop", {
    description: "Manage named timer loops that wake this agent (add | list | remove)",
    handler: async (args, ctx) => {
      await handleCommand(pi, ctx, "loop", args, ports);
    },
  });

  pi.registerCommand("watch", {
    description: "Manage named file watches that wake this agent (add | list | remove)",
    handler: async (args, ctx) => {
      await handleCommand(pi, ctx, "watch", args, ports);
    },
  });

  // session_start covers startup, reload, resume, fork, and new sessions;
  // session_tree covers branch switches. Reconciliation is idempotent, so a
  // reload re-registers each configured subscription exactly once.
  pi.on("session_start", async (_event, ctx) => {
    resetRuntime(pi, ctx, ports);
  });
  pi.on("session_tree", async (_event, ctx) => {
    resetRuntime(pi, ctx, ports);
  });

  // The agent consumed every queued continuation; same-source wakes may
  // deliver again.
  pi.on("agent_settled", async () => {
    runtime?.registry.settleAll();
  });

  pi.on("session_shutdown", async () => {
    runtime?.registry.dispose();
    runtime = undefined;
  });
}

function resetRuntime(pi, ctx, ports) {
  runtime?.registry.dispose();
  runtime = { ports, registry: createRegistry(pi, ctx, ports) };
  runtime.registry.reconcile();
}

function createRegistry(pi, ctx, ports) {
  const dispatcher = new WakeDispatcher({
    deliver: (sourceKey, text) => deliverWake(pi, ctx, sourceKey, text),
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
 * Queue-only delivery. Idle agents receive the wake directly (it triggers a
 * turn); busy agents receive a queued follow-up that never interrupts an
 * in-flight tool operation.
 */
function deliverWake(pi, ctx, sourceKey, text) {
  const message = `[ace-wake ${sourceKey}] ${text}`;
  try {
    if (ctx.isIdle()) {
      pi.sendUserMessage(message);
    } else {
      pi.sendUserMessage(message, { deliverAs: "followUp" });
    }
    return true;
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
    },
  };
}

async function handleCommand(pi, ctx, kind, args, ports) {
  const wakeRuntime = runtime ?? bindRuntime(pi, ctx, ports);
  try {
    const parsed = parseWakeCommand(kind, args);
    switch (parsed.subcommand) {
      case "add":
        addSubscription(wakeRuntime.registry, kind, parsed);
        notify(ctx, `${kind} "${parsed.name}" added`, "info");
        break;
      case "list":
        notify(ctx, formatList(kind, wakeRuntime.registry.list()), "info");
        break;
      case "remove":
        removeSubscription(wakeRuntime.registry, kind, parsed.name);
        notify(ctx, `${kind} "${parsed.name}" removed; no further wakes will fire`, "info");
        break;
      default:
        throw new WakeError(`unknown ${kind} subcommand: ${parsed.subcommand}`);
    }
  } catch (error) {
    notify(ctx, error instanceof WakeError ? error.message : `${kind} failed: ${error.message}`, "error");
  }
}

function bindRuntime(pi, ctx, ports) {
  resetRuntime(pi, ctx, ports);
  return runtime;
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
