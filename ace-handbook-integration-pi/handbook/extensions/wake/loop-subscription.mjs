/**
 * Loop subscription port owning native interval handles.
 *
 * Each start schedules an in-process interval from "now". After disposal and
 * re-registration (reload, restart, reconcile) the next tick is a full
 * interval away: no missed or catch-up ticks are ever replayed.
 *
 * @param {object} ports
 * @param {(callback: () => void, ms: number) => unknown} ports.setIntervalFn
 * @param {(handle: unknown) => void} ports.clearIntervalFn
 * @returns {{
 *   start: (definition: import("./types.mjs").LoopDefinition, onTick: (definition: import("./types.mjs").LoopDefinition) => void) => void,
 *   stop: (name: string) => void,
 *   stopAll: () => void,
 *   errorOf: (name: string) => string | undefined,
 *   activeCount: () => number,
 * }}
 */
export function createLoopPort({ setIntervalFn, clearIntervalFn }) {
  /** @type {Map<string, unknown>} */
  const handles = new Map();

  return {
    start(definition, onTick) {
      stopExisting(definition.name);
      const milliseconds = definition.intervalSeconds * 1000;
      handles.set(definition.name, setIntervalFn(() => onTick(definition), milliseconds));
    },

    stop(name) {
      stopExisting(name);
    },

    stopAll() {
      for (const handle of handles.values()) {
        clearIntervalFn(handle);
      }
      handles.clear();
    },

    errorOf() {
      // Intervals do not produce runtime errors; the clock either runs or the
      // process is gone.
      return undefined;
    },

    activeCount() {
      return handles.size;
    },
  };

  function stopExisting(name) {
    const handle = handles.get(name);
    if (handle !== undefined) {
      clearIntervalFn(handle);
      handles.delete(name);
    }
  }
}
