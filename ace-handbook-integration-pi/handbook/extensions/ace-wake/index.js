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

import { WakeDispatcher } from "./wake/wake-dispatcher.js";
import { parseWakeCommand } from "./wake/wake-command-parser.js";
import { createLoopPort } from "./wake/loop-subscription.js";
import { createWatchPort, nodeStatFn, nodeWatchFactory } from "./wake/watch-subscription.js";
import {
  SESSION_ENTRY_TYPE,
  WakeError,
  boundMessage,
} from "./wake/types.js";
import { WakeRegistry } from "./wake/wake-registry.js";

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
  /** @type {{registry: WakeRegistry} | undefined} */
  let runtime;

  const getRuntime = () => runtime;
  const bindRuntime = (ctx) => {
    runtime?.registry.dispose();
    runtime = { registry: createRegistry(pi, ctx, ports) };
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

  // A run has begun: wakes dispatched concurrently during the idle-to-running
  // transition can now enter the follow-up queue safely, so the registry
  // drains anything it serialized.
  pi.on("agent_start", async () => {
    runtime?.registry.noteRunStarted();
  });

  // The agent consumed every queued continuation; same-source wakes may
  // deliver again. Watches whose change was absorbed by a pending wake are
  // re-checked so no change is lost without a new filesystem event.
  pi.on("agent_settled", async () => {
    runtime?.registry.settleAll();
  });

  // Manual compaction rejects sendUserMessage asynchronously (before, during,
  // and briefly after the compaction events) and never emits agent_settled:
  // wakes are retained while it runs and flushed once the context is actually
  // idle again. Automatic compaction happens inside a run whose pending wakes
  // stay legitimately queued, so it is left untouched.
  pi.on("session_before_compact", async (event) => {
    if (event.reason === "manual") {
      runtime?.registry.pauseDelivery();
    }
  });
  pi.on("session_compact", async (event, ctx) => {
    if (event.reason === "manual") {
      runtime?.registry.resumeDelivery();
      scheduleManualCompactionFlush(ctx);
    }
  });
  pi.on("session_compact_failed", async (event, ctx) => {
    if (event.reason === "manual") {
      runtime?.registry.resumeDelivery();
      scheduleManualCompactionFlush(ctx);
    }
  });

  pi.on("session_shutdown", async () => {
    runtime?.registry.dispose();
    runtime = undefined;
  });

  /**
   * Poll until the host context is genuinely idle (no run, no compaction) and
   * then flush retained wakes. A single deferred callback is not enough: other
   * session_compact handlers may await asynchronous work while Pi still rejects
   * prompts. Bounded polling covers the idle-after-compaction case; a run that
   * continues after compaction flushes via agent_settled instead.
   */
  function scheduleManualCompactionFlush(ctx) {
    const pollMs = 100;
    // Bound the poll to the session that scheduled it: a rebind or shutdown
    // replaces the registry, and the old poll must not flush the new one.
    const registry = runtime.registry;
    const attempt = () => {
      if (runtime?.registry !== registry) {
        return;
      }
      let idle;
      try {
        idle = ctx.isIdle();
      } catch {
        return; // Stale context: session_start rebinds.
      }
      if (idle) {
        registry.completeResume();
        return;
      }
      const timer = setTimeout(attempt, pollMs);
      timer.unref?.();
    };
    attempt();
  }
}

function createRegistry(pi, ctx, ports) {
  const dispatcher = new WakeDispatcher({
    deliver: (sourceKey, text) => deliverWake(pi, ctx, sourceKey, text),
  });
  /** The registry is created after its watch port, so deactivation hooks go
   * through this holder once it exists. */
  let registry;
  const built = new WakeRegistry({
    loops: createLoopPort({
      setIntervalFn: ports.setIntervalFn ?? ((callback, ms) => setInterval(callback, ms)),
      clearIntervalFn: ports.clearIntervalFn ?? ((handle) => clearInterval(handle)),
    }),
    watches: createWatchPort({
      watchFactory: ports.watchFactory ?? nodeWatchFactory,
      statFn: ports.statFn ?? nodeStatFn,
      baseDir: ctx.cwd,
      scheduleReconcile: ports.scheduleReconcile,
      onDeactivate: () => registry?.refreshStatus(),
    }),
    state: sessionStatePort(pi, ctx),
    status: statusPort(ctx),
    dispatcher,
    isHostIdle: () => {
      try {
        return ctx.isIdle();
      } catch {
        return false;
      }
    },
  });
  registry = built;
  return built;
}

/**
 * Queue-only delivery, always as a queued follow-up. Pi runs a follow-up
 * immediately when nothing is in flight and queues it behind any active run
 * otherwise, so no window — between runs, during a tool, or while earlier
 * wakes are queued — can drop a wake or interrupt an in-flight operation.
 * The complete rendered message (source prefix included) is bounded.
 */
function deliverWake(pi, ctx, sourceKey, text) {
  const message = boundMessage(`[ace-wake ${sourceKey}] ${text}`);
  try {
    pi.sendUserMessage(message, { deliverAs: "followUp" });
    return true;
  } catch {
    // A stale context (session replaced/reloaded) or a rejecting host must
    // not crash the timer callback; the next session_start rebinds.
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
      // getBranch() returns the stored entries themselves; cloning keeps
      // registry mutations from rewriting historical session entries, which
      // would leak later edits back into branched-away history.
      return snapshot ? structuredClone(snapshot) : { loops: [], watches: [] };
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
