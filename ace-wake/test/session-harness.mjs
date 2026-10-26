import aceWakeFactory from "../index.js";

const HOST_PORTS = ["setIntervalFn", "clearIntervalFn", "watchFactory", "statFn", "resolveTargets"];

function portsOf(host, extraPorts = {}) {
  return { ...Object.fromEntries(HOST_PORTS.map((name) => [name, host[name]])), ...extraPorts };
}

/**
 * Load the adapter the way Pi would: run the default-exported factory with a
 * fake extension API, capture the lifecycle handlers it registered, then fire
 * session_start. The fake host's deterministic ports are injected through the
 * factory's optional second argument.
 */
export async function startSession(host, extraPorts = {}) {
  let events = [];
  host.pi.on = (event, handler) => {
    events.push([event, handler]);
    return () => {};
  };
  aceWakeFactory(host.pi, portsOf(host, extraPorts));

  const handlerFor = (event) => {
    const found = events.filter(([name]) => name === event);
    if (!found.length) throw new Error(`extension did not register ${event}`);
    return async (...args) => { for (const [, handler] of found) await handler(...args); };
  };

  await handlerFor("session_start")({ type: "session_start", reason: "startup" }, host.commandContext);

  return {
    emit: (event, payload) => handlerFor(event)(payload, host.commandContext),
    /**
     * Simulate an extension reload with real pi semantics: the old runtime
     * receives session_shutdown(reason reload), then the factory reruns and
     * session_start fires with reason "reload".
     */
    reload: async () => {
      await handlerFor("session_shutdown")({ type: "session_shutdown", reason: "reload" }, host.commandContext);
      const reloadEvents = [];
      host.pi.on = (event, handler) => {
        reloadEvents.push([event, handler]);
        return () => {};
      };
      aceWakeFactory(host.pi, portsOf(host, extraPorts));
      events = reloadEvents;
      await handlerFor("session_start")({ type: "session_start", reason: "reload" }, host.commandContext);
    },
    settle: () => handlerFor("agent_settled")({ type: "agent_settled" }, host.commandContext),
    agentStart: () => handlerFor("agent_start")({ type: "agent_start" }, host.commandContext),
    beforeCompact: (reason = "manual") => handlerFor("session_before_compact")({ type: "session_before_compact", reason }, host.commandContext),
    compacted: (reason = "manual") => handlerFor("session_compact")({ type: "session_compact", reason, trigger: "manual" }, host.commandContext),
    compactFailed: (reason = "manual") => handlerFor("session_compact_failed")({ type: "session_compact_failed", reason, trigger: "manual" }, host.commandContext),
    shutdown: () => handlerFor("session_shutdown")({ type: "session_shutdown" }, host.commandContext),
  };
}
