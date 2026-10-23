import { createHash } from "node:crypto";
import * as nodeFs from "node:fs";
import * as nodePath from "node:path";
import { WakeError } from "./types.js";
import { expandInboxWatchTargets } from "./inbox-discovery.js";

/**
 * Resolve a configured watch path to the filesystem target: relative paths
 * resolve against `baseDir`, and an existing symlinked path resolves to its
 * target so directory events match the watched file's real name.
 *
 * @param {string} baseDir
 * @param {string} path
 * @returns {string}
 */
export function canonicalizeWatchPath(baseDir, path) {
  const resolved = nodePath.resolve(baseDir, path);
  try {
    return nodeFs.realpathSync(resolved);
  } catch {
    // A nonexistent path cannot be canonicalized; stat validation in start()
    // reports the visible error instead.
    return resolved;
  }
}

/**
 * Watch subscription port owning native filesystem watcher handles.
 *
 * start() resolves the configured path to a canonical absolute target (relative
 * paths resolve against `baseDir`; symlinks resolve to their target), validates
 * readable metadata, and records a baseline fingerprint. An injected
 * `resolveTargets` port may expand the configured path to several targets —
 * the ace-hitl inbox watch expands `.ace-local/hitl` to every linked
 * worktree's inbox, because `ace-hitl create` writes reports inside the
 * coworker's worktree, not the main checkout. Discovery re-runs on every
 * change/reconcile pass, so worktrees linked AFTER registration are
 * picked up without a re-registration or session reload. The fingerprint
 * aggregates all
 * targets; a target that does not exist yet is a stable "absent" state, so
 * the first report into a freshly created inbox still wakes. Only later fingerprint
 * changes wake the agent, so registering a watch never produces an initial
 * wake. When a wake coalesces into one already queued, the fingerprint stays
 * at the previously delivered state: the queued wake covers the change, and a
 * further change queues a fresh follow-up after settlement.
 *
 * A readable target's signature is its content hash, so a rewrite with
 * identical bytes (fresh mtime, same size) is not a change and never wakes;
 * targets whose content is not readable (directories, denied files) keep the
 * `mtimeMs:size` stat-only signature. Every wake callback receives a delta of
 * the changed targets — watched path, change kind (created/modified/deleted),
 * BEFORE→AFTER signatures, and a short capped content excerpt when the file is
 * readable — so the woken agent can identify the case without a full reload.
 *
 * A watcher runtime error on the configured (primary) path closes the
 * handle, marks the subscription inactive with a visible error via the
 * injected `onDeactivate` hook, and never retries: the user removes and
 * re-adds the watch explicitly. A runtime error on a DISCOVERED extra
 * target (e.g. `ace-overseer prune` removed a watched worktree) drops only
 * that target's watcher and keeps the subscription alive for every other
 * worktree; discovery re-attaches the target if it reappears. `fail()`
 * records the same inactive-error state without a native handle, which
 * reconciliation uses for subscriptions that could not be restarted.
 *
 * @param {object} ports
 * @param {(path: string, handlers: {onChange: () => void, onError: (error: Error) => void}) => {close: () => void}} ports.watchFactory
 * @param {(path: string) => {mtimeMs: number, size: number}} ports.statFn
 * @param {(path: string) => Buffer | undefined} [ports.readFn] Content reader for
 *   signatures and excerpts; returns undefined when the content is not readable
 *   (missing target, directory, denied content) and never throws. Defaults to
 *   a node:fs read of the whole file.
 * @param {string} [ports.baseDir] Resolution base for relative watch paths.
 * @param {(baseDir: string, path: string) => string} [ports.canonicalizeFn] Path canonicalization; defaults to resolve + realpath.
 * @param {(reconcile: () => void) => unknown} [ports.scheduleReconcile] Schedules
 *   the post-registration reconcile pass. Native watcher initialization is
 *   asynchronous on some platforms, so a change landing in the registration
 *   gap may produce no callback; the reconcile re-stats once and wakes on a
   * missed change. Defaults to a delayed macrotask.
 * @param {() => void} [ports.onDeactivate] Invoked when a subscription leaves
 *   the active state so callers can refresh visible status.
 * @returns {{
 *   start: (definition: import("./types.js").WatchDefinition, onWake: (definition: import("./types.js").WatchDefinition, delta: Array<import("./types.js").WatchDelta>) => {delivered: boolean, reason?: string} | undefined) => string,
 *   stop: (name: string) => void,
 *   stopAll: () => void,
 *   fail: (name: string, message: string) => void,
 *   errorOf: (name: string) => string | undefined,
 *   activeCount: () => number,
 * }}
 */
const RECONCILE_DELAY_MS = 500;
// How far above a not-yet-existing target an ancestor watch may climb
// (enough for <worktree>/.ace-local/hitl inside any sane worktree layout).
const MAX_ANCESTOR_CLIMB = 6;
// Content excerpt capped into a wake delta, in bytes.
const EXCERPT_BYTES = 200;
// Fingerprint segment of a target that does not (yet) exist.
const ABSENT_SEGMENT = "absent";

export function createWatchPort({ watchFactory, statFn, readFn = nodeReadFn, baseDir = process.cwd(), canonicalizeFn = canonicalizeWatchPath, resolveTargets = expandInboxWatchTargets, scheduleReconcile = defaultScheduleReconcile, onDeactivate }) {
  /** @type {Map<string, {watchers: Array<{path: string, watchPath: string, watcher: {close: () => void}}>, paths: string[], definition: import("./types.js").WatchDefinition, fingerprint: string, previousFingerprint: string, dirty: boolean}>} */
  const active = new Map();
  /** @type {Map<string, string>} */
  const errors = new Map();

  return {
    /**
     * @returns {string} The canonical absolute path being watched.
     */
    start(definition, onWake) {
      stopExisting(definition.name);
      errors.delete(definition.name);

      const canonicalPath = canonicalizeFn(baseDir, definition.path);
      // The configured path itself must be readable; expansion targets may
      // legitimately not exist yet (an inbox in a worktree that never
      // received a report), so only the primary is validated strictly.
      readBaseline(canonicalPath);
      const targetPaths = resolveTargetsFor(resolveTargets, baseDir, definition.path, canonicalPath);
      const watchers = targetPaths.flatMap((target) => attachWatcher(target, definition, onWake));
      const paths = watchers.map((entry) => entry.path);
      // A target watched through an ancestor was PROVEN absent just now;
      // its baseline records that fact rather than a re-stat, so a report
      // created between the proof and this recomputation stays a change
      // (the scheduled reconcile below delivers it).
      const provenAbsent = new Set(watchers.filter((each) => each.watchPath !== each.path).map((each) => each.path));
      const fingerprint = aggregateFingerprint(paths, canonicalPath, provenAbsent);

      active.set(definition.name, { watchers, paths, primaryPath: canonicalPath, definition, fingerprint, previousFingerprint: fingerprint, dirty: false });
      // Close the registration gap: a change between baseline capture and
      // watcher effectiveness produces no callback, so re-stat once.
      scheduleReconcile(() => handleChange(definition, onWake));
      return canonicalPath;
    },

    stop(name) {
      stopExisting(name);
      errors.delete(name);
    },

    stopAll() {
      for (const name of [...active.keys()]) {
        stopExisting(name);
      }
      errors.clear();
    },

    /**
     * Re-check subscriptions after the agent settles (pending markers
     * cleared). Target discovery refreshes for EVERY active subscription:
     * a worktree linked while the session was watching whose first report
     * landed in its own (then-unwatched) inbox produced no watched-path
     * event, so this settlement boundary is the channel that notices it.
     * A subscription whose current state still differs from its last
     * delivered fingerprint fires a fresh wake — no new filesystem event
     * required.
     *
     * @param {(definition: import("./types.js").WatchDefinition) => {delivered: boolean, reason?: string} | undefined} onWake
     */
    flushDirty(onWake) {
      for (const entry of active.values()) {
        // Settlement boundaries refresh target discovery for EVERY active
        // subscription, not only dirty ones: a worktree linked long after
        // start whose first report lands in its own (not yet watched)
        // inbox produces no watched-path event, so this pass is the only
        // channel that can notice the new target and wake.
        refreshAttachments(entry, entry.definition, onWake);
        if (active.get(entry.definition.name)?.definition !== entry.definition) {
          continue;
        }
        const next = currentFingerprint(entry, entry.definition.name);
        if (next === undefined) {
          continue;
        }
        if (next === entry.fingerprint) {
          entry.dirty = false;
          continue;
        }
        const outcome = onWake(entry.definition, deltaOf(entry.fingerprint, next));
        // The fingerprint advances only when the wake actually crossed —
        // a deferred outcome stays dirty for the next settlement boundary.
        if (outcome && outcome.delivered === false) {
          entry.dirty = true;
          continue;
        }
        entry.previousFingerprint = entry.fingerprint;
        entry.fingerprint = next;
        entry.dirty = false;
      }
    },

    /**
     * Mark a subscription's latest change as undelivered so flushDirty()
     * re-checks it at the next settlement boundary. Used when a wake is
     * deferred by retention or the dispatch serialization window.
     *
     * @param {string} name
     */
    markDirty(name) {
      const entry = active.get(name);
      if (entry) {
        entry.dirty = true;
      }
    },

    /**
     * A dispatch attempt was never acknowledged (Pi rejected it in async
     * preflight without any lifecycle event): revert each subscription to
     * its last delivered state and mark it dirty, so flushDirty() re-fires
     * the change at the next settlement — no loss, and no duplicate for
     * wakes that were genuinely consumed.
     */
    revertToDelivered(names) {
      for (const name of names) {
        const entry = active.get(name);
        if (!entry) {
          continue;
        }
        entry.fingerprint = entry.previousFingerprint;
        entry.dirty = true;
      }
    },

    /**
     * Record a visible inactive-error state for a subscription without a
     * native handle (used by reconciliation for watches that cannot restart).
     *
     * @param {string} name
     * @param {string} message
     */
    fail(name, message) {
      stopExisting(name);
      errors.set(name, message);
    },

    errorOf(name) {
      return errors.get(name);
    },

    activeCount() {
      return active.size;
    },
  };

  function stopExisting(name) {
    const entry = active.get(name);
    if (entry !== undefined) {
      for (const { watcher } of entry.watchers) {
        try {
          watcher.close();
        } catch {
          // Closing an already-broken watcher must not mask the original error.
        }
      }
      active.delete(name);
    }
  }

  /** Shared change path for watcher callbacks and the reconcile pass. */
  function handleChange(definition, onWake) {
    const entry = active.get(definition.name);
    // A callback from a removed registration must never touch its
    // replacement: ignore obsolete subscriptions entirely.
    if (entry === undefined || entry.definition !== definition) {
      return;
    }
    refreshAttachments(entry, definition, onWake);
    // Re-attachment failure deactivates the subscription; a deactivated
    // definition must not deliver a wake from the same pass.
    if (active.get(definition.name)?.definition !== definition) {
      return;
    }
    const next = currentFingerprint(entry, definition.name);
    if (next === undefined) {
      return;
    }
    if (next === entry.fingerprint) {
      return;
    }
    const outcome = onWake(definition, deltaOf(entry.fingerprint, next));
    if (outcome && outcome.delivered === false) {
      // Coalesced (a queued wake covers this change) or serialized (held back
      // by the dispatch transition window): the change itself is undelivered,
      // so mark the subscription dirty — flushDirty() re-checks it once the
      // agent settles, without needing another filesystem event.
      entry.dirty = true;
      return;
    }
    entry.previousFingerprint = entry.fingerprint;
    entry.fingerprint = next;
    entry.dirty = false;
  }

  function deactivate(name, message) {
    stopExisting(name);
    errors.set(name, message);
    try {
      onDeactivate?.();
    } catch {
      // Status rendering must never break the watcher callback.
    }
  }

  function readBaseline(path) {
    let stats;
    try {
      stats = statFn(path);
    } catch (error) {
      throw new WakeError(`path is not readable: ${path} (${describeError(error)})`);
    }
    return stats;
  }

  function readBaselineOrError(path, name) {
    try {
      return statFn(path);
    } catch (error) {
      deactivate(name, describeError(error));
      return undefined;
    }
  }

  /**
   * Resolve the watch targets for one configured path. An injected
   * `resolveTargets` port (the ace-hitl inbox expansion) may return several
   * directories; the validated primary canonical path is always watched,
   * whatever the port returns.
   *
   * @param {((baseDir: string, path: string) => string[]) | undefined} resolveTargets
   * @param {string} baseDir
   * @param {string} configuredPath
   * @param {string} canonicalPath
   * @returns {string[]}
   */
  function resolveTargetsFor(resolveTargets, baseDir, configuredPath, canonicalPath) {
    if (!resolveTargets) {
      return [canonicalPath];
    }
    const expanded = resolveTargets(baseDir, configuredPath)
      .filter((path) => typeof path === "string" && path.length > 0)
      .map((path) => nodePath.resolve(path));
    return [...new Set([canonicalPath, ...expanded])];
  }

  /**
   * Attach one native watcher for a target. A target that does not exist
   * yet (a worktree inbox with no report so far) is watched through its
   * nearest EXISTING ancestor directory: the ancestor's events re-stat the
   * target, so the first report — which creates the inbox — still wakes.
   * When no ancestor is readable the target is skipped until the next
   * re-registration.
   *
   * @param {string} target
   * @param {import("./types.js").WatchDefinition} definition
   * @param {(definition: import("./types.js").WatchDefinition) => unknown} onWake
   * @returns {Array<{path: string, watchPath: string, watcher: {close: () => void}}>}
   */
  function attachWatcher(target, definition, onWake) {
    const handlers = {
      onChange: () => handleChange(definition, onWake),
      onError: (error) => {
        // A callback from a removed registration must never touch its
        // replacement.
        const entry = active.get(definition.name);
        if (entry === undefined || entry.definition !== definition) {
          return;
        }
        if (target !== entry.primaryPath) {
          // A discovered extra target died (the worktree was pruned):
          // drop only this target's watcher, keep the subscription.
          dropTarget(entry, target);
          return;
        }
        deactivate(definition.name, describeError(error));
      },
    };
    let watchPath = target;
    let attempts = 0;
    for (;;) {
      try {
        statFn(watchPath);
        break;
      } catch {
        if (attempts >= MAX_ANCESTOR_CLIMB || watchPath === nodePath.dirname(watchPath)) {
          return [];
        }
        attempts += 1;
        watchPath = nodePath.dirname(watchPath);
      }
    }
    return [{ path: target, watchPath, watcher: watchFactory(watchPath, handlers) }];
  }

  /**
   * Re-run target discovery and re-attach targets that were watched
   * through an ancestor because they did not exist yet. Runs on every
   * change/reconcile pass — exactly when a formerly-absent target may
   * have appeared, and when a worktree linked AFTER registration may have
   * become discoverable: discovery (the ace-hitl inbox expansion over
   * `git worktree list`) no longer runs only at registration, so a task
   * worktree created while the session is already watching gets its
   * inbox watched without any re-registration or reload.
   *
   * Linux inotify is non-recursive, so an ancestor's watch never sees a
   * SECOND report created inside the now-existing target; once the target
   * exists, close the ancestor watch and watch the real target directly.
   *
   * A newly discovered target that does not exist yet joins the baseline
   * fingerprint as its PROVEN "absent" state (never a re-stat, so a report
   * created between the discovery stat and the baseline recomputation stays
   * a pending change) and a follow-up reconcile pass — mirroring start() —
   * delivers any change that landed in the attach gap; its later appearance
   * (the first report) is the change that wakes, not its discovery.
   *
   * @param {{watchers: Array<{path: string, watchPath: string, watcher: {close: () => void}}>, paths: string[], primaryPath: string, fingerprint: string, previousFingerprint: string}} entry
   * @param {import("./types.js").WatchDefinition} definition
   * @param {(definition: import("./types.js").WatchDefinition) => unknown} onWake
   */
  function refreshAttachments(entry, definition, onWake) {
    refreshDiscoveredTargets(entry, definition, onWake);
    if (active.get(definition.name)?.definition !== definition) {
      return;
    }
    for (let index = 0; index < entry.watchers.length; index += 1) {
      const attached = entry.watchers[index];
      if (attached.watchPath === attached.path) {
        continue;
      }
      try {
        statFn(attached.path);
      } catch {
        // Still absent: the ancestor watch remains the only channel.
        continue;
      }
      try {
        // Attach the replacement BEFORE closing the old watcher:
        // watchFactory can throw synchronously (EMFILE, EPERM, stat race),
        // and handleChange runs inside native watcher callbacks — an
        // uncaught throw here would crash the extension host. On failure
        // the documented runtime-error posture applies: deactivate and
        // never retry.
        const replacement = attachWatcher(attached.path, definition, onWake);
        if (replacement.length > 0) {
          try {
            attached.watcher.close();
          } catch {
            // Closing an already-broken watcher must not block re-attachment.
          }
          entry.watchers[index] = replacement[0];
        }
      } catch (error) {
        deactivate(definition.name, `re-attachment failed: ${describeError(error)}`);
        return;
      }
    }
  }

  /**
   * Re-run target discovery for one subscription and attach watchers for
   * targets that appeared since the last pass (a worktree linked after
   * registration, whose inbox the registration-time expansion could not
   * have seen). A new target that already exists keeps the OLD baseline
   * fingerprint, so the pass's fingerprint comparison delivers the wake
   * the missed event never could; a new target that is still absent joins
   * the baseline as its stable "absent" state, so only its later
   * appearance (the first report) wakes.
   *
   * @param {{watchers: Array<{path: string, watchPath: string, watcher: {close: () => void}}>, paths: string[], primaryPath: string, fingerprint: string, previousFingerprint: string}} entry
   * @param {import("./types.js").WatchDefinition} definition
   * @param {(definition: import("./types.js").WatchDefinition) => unknown} onWake
   */
  function refreshDiscoveredTargets(entry, definition, onWake) {
    if (!resolveTargets) {
      return;
    }
    const targetPaths = resolveTargetsFor(resolveTargets, baseDir, definition.path, entry.primaryPath);
    let attachedAny = false;
    for (const target of targetPaths) {
      if (entry.watchers.some((attached) => attached.path === target)) {
        continue;
      }
      let attachedWatcher;
      try {
        attachedWatcher = attachWatcher(target, definition, onWake);
      } catch (error) {
        deactivate(definition.name, `re-attachment failed: ${describeError(error)}`);
        return;
      }
      if (attachedWatcher.length === 0) {
        // No readable ancestor yet: retried on the next pass.
        continue;
      }
      entry.watchers.push(attachedWatcher[0]);
      entry.paths = entry.watchers.map((each) => each.path);
      attachedAny = true;
      if (attachedWatcher[0].watchPath !== target) {
        // The baseline records the "absent" state PROVEN by the ancestor
        // climb, never a re-stat: a report created between the two must
        // remain a pending change. The follow-up reconcile scheduled
        // below delivers it without waiting for another event.
        const baseline = aggregateFingerprint(entry.paths, entry.primaryPath, new Set([target]));
        entry.previousFingerprint = baseline;
        entry.fingerprint = baseline;
      }
    }
    if (attachedAny) {
      // Mirror start(): a change landing in the attach gap (the race
      // above, or watcher initialization latency on the new target)
      // produces no callback, so re-stat once.
      scheduleReconcile(() => handleChange(definition, onWake));
    }
  }

  /**
   * Drop the watcher of one discovered extra target after a runtime error
   * (typically `ace-overseer prune` removing the worktree): only that
   * target's handle closes; the subscription stays active for the primary
   * and every other worktree. The target's disappearance is absorbed into
   * the baseline — a pruned worktree is not a report and must not wake.
   *
   * The baselines are adjusted by removing ONLY the dropped target's
   * segment from the recorded fingerprint strings. Re-statting every
   * remaining target would fold an undelivered change (a deferred wake
   * left the fingerprint at its pre-change state) into the baseline,
   * silently losing the pending report; the segment removal keeps every
   * remaining target at its recorded state, so the settlement boundary
   * still delivers it. It also never touches the filesystem at all, so a
   * primary deleted moments earlier cannot throw from inside the native
   * onError callback (the primary's own watcher error deactivates the
   * subscription through the documented path).
   *
   * @param {{watchers: Array<{path: string, watchPath: string, watcher: {close: () => void}}>, paths: string[], primaryPath: string, fingerprint: string, previousFingerprint: string}} entry
   * @param {string} target
   */
  function dropTarget(entry, target) {
    const remaining = [];
    for (const attached of entry.watchers) {
      if (attached.path === target) {
        try {
          attached.watcher.close();
        } catch {
          // Closing an already-broken watcher must not mask the original error.
        }
      } else {
        remaining.push(attached);
      }
    }
    if (remaining.length === entry.watchers.length) {
      return;
    }
    entry.watchers = remaining;
    entry.paths = remaining.map((each) => each.path);
    // The `=` terminator makes the prefix match the segment of exactly this
    // target, never a target whose path merely extends it.
    const droppedPrefix = `${target}=`;
    entry.fingerprint = withoutSegment(entry.fingerprint, droppedPrefix);
    entry.previousFingerprint = withoutSegment(entry.previousFingerprint, droppedPrefix);
  }

  /**
   * Remove one target's `path=fingerprint` segment from an aggregate
   * fingerprint string, keeping every other segment verbatim.
   *
   * @param {string} fingerprint
   * @param {string} segmentPrefix The exact `path=` prefix of the removed target.
   * @returns {string}
   */
  function withoutSegment(fingerprint, segmentPrefix) {
    return fingerprint
      .split("|")
      .filter((segment) => !segment.startsWith(segmentPrefix))
      .join("|");
  }

  /**
   * Current aggregate fingerprint of a subscription. An unreadable
   * PRIMARY deactivates the subscription (the configured path itself is
   * the contract); an unreadable extra target is a stable "absent" state
   * that changes to a real fingerprint once the target appears.
   *
   * @param {{paths: string[], primaryPath: string}} entry
   * @param {string} name
   * @returns {string | undefined}
   */
  function currentFingerprint(entry, name) {
    try {
      return aggregateFingerprint(entry.paths, entry.primaryPath);
    } catch (error) {
      deactivate(name, describeError(error));
      return undefined;
    }
  }

  /**
   * @param {string[]} paths sorted target paths
   * @param {string} primaryPath
   * @param {Set<string>} [forcedAbsent] Targets recorded as "absent" without
   *   re-statting — the proven-at-discovery baseline of a newly attached
   *   target, so a report created in the stat/recompute gap stays a change.
   * @returns {string}
   */
  function aggregateFingerprint(paths, primaryPath, forcedAbsent) {
    return [...paths]
      .sort()
      .map((path) => {
        if (forcedAbsent?.has(path)) {
          return `${path}=${ABSENT_SEGMENT}`;
        }
        if (path === primaryPath) {
          return `${path}=${fingerprintOf(statFn(path), readFn(path))}`;
        }
        try {
          return `${path}=${fingerprintOf(statFn(path), readFn(path))}`;
        } catch {
          return `${path}=${ABSENT_SEGMENT}`;
        }
      })
      .join("|");
  }

  /**
   * Build the wake delta for one delivered-fingerprint transition: every
   * target whose signature changed, described by path, change kind, and
   * BEFORE→AFTER signatures, plus a capped sanitized content excerpt when the
   * target's content is readable.
   *
   * @param {string} before aggregate fingerprint of the last delivered state
   * @param {string} after current aggregate fingerprint
   * @returns {Array<import("./types.js").WatchDelta>}
   */
  function deltaOf(before, after) {
    const previous = segmentMap(before);
    const deltas = [];
    for (const [path, next] of segmentMap(after)) {
      const prior = previous.get(path);
      if (prior === next) {
        continue;
      }
      const delta = {
        path,
        kind: changeKind(prior, next),
        before: prior ?? ABSENT_SEGMENT,
        after: next,
      };
      if (next !== ABSENT_SEGMENT) {
        const content = readFn(path);
        if (content !== undefined) {
          delta.excerpt = excerptOf(content);
        }
      }
      deltas.push(delta);
    }
    return deltas;
  }
}

/**
 * Default reconcile scheduler: a delayed macrotask after registration, timed
 * to land once the native watcher is effective. Never holds the process open.
 *
 * @param {() => void} reconcile
 */
export function defaultScheduleReconcile(reconcile) {
  const timer = setTimeout(reconcile, RECONCILE_DELAY_MS);
  timer.unref?.();
  return timer;
}

/**
 * Split an aggregate fingerprint into its per-target `path=signature` map.
 *
 * @param {string} fingerprint
 * @returns {Map<string, string>}
 */
function segmentMap(fingerprint) {
  return new Map(fingerprint.split("|").map((segment) => {
    const at = segment.indexOf("=");
    return [segment.slice(0, at), segment.slice(at + 1)];
  }));
}

/**
 * @param {string | undefined} before previous signature (undefined = never seen)
 * @param {string} after current signature
 * @returns {"created" | "modified" | "deleted"}
 */
function changeKind(before, after) {
  if (after === ABSENT_SEGMENT) {
    return "deleted";
  }
  return before === undefined || before === ABSENT_SEGMENT ? "created" : "modified";
}

/**
 * First bytes of the content as one sanitized single line: control characters
 * are dropped and whitespace runs (newlines, tabs) collapse to single spaces.
 *
 * @param {Buffer} content
 * @returns {string}
 */
function excerptOf(content) {
  const head = content.subarray(0, EXCERPT_BYTES).toString("utf8");
  return head
    .replace(/[\u0000-\u0008\u000B\u000C\u000E-\u001F\u007F]/g, "")
    .replace(/\s+/g, " ")
    .trim();
}

/**
 * Change signature of one target. Readable content signs a hash of the bytes,
 * so a content-only rewrite (identical bytes, fresh mtime) is not a change;
 * when the content is not readable (directory, denied file) the stat pair
 * remains the signature.
 *
 * @param {{mtimeMs: number, size: number}} stats
 * @param {Buffer | undefined} content
 * @returns {string}
 */
function fingerprintOf(stats, content) {
  if (content !== undefined) {
    return `sha256:${createHash("sha256").update(content).digest("hex")}`;
  }
  return `${stats.mtimeMs}:${stats.size}`;
}

/**
 * @param {unknown} error
 * @returns {string}
 */
function describeError(error) {
  return error instanceof Error ? error.message : String(error);
}

/**
 * Default watchFactory over node:fs.watch.
 *
 * Directory targets are watched directly and accept any child event: on
 * Linux (inotify) a child file's creation is delivered only to a watch on
 * the directory itself, never to a watch on its parent. The mtime/size
 * fingerprint comparison filters noise, so accepting every event is safe.
 *
 * File targets keep watching the parent directory and filter events to the
 * target's basename: watching the file itself keeps following the original
 * inode, so atomic replacement (write-to-temporary + rename) would silently
 * detach the subscription after one change.
 *
 * @param {string} path Canonical path of the watched file or directory.
 * @param {{onChange: () => void, onError: (error: Error) => void}} handlers
 * @returns {{close: () => void}}
 */
export function nodeWatchFactory(path, handlers) {
  if (nodeFs.statSync(path).isDirectory()) {
    const watcher = nodeFs.watch(path, { persistent: false }, () => {
      // Any child event is checked: the fingerprint comparison filters
      // non-changes, including nested relative paths some platforms report.
      handlers.onChange();
    });
    watcher.on("error", (error) => handlers.onError(error));
    watcher.unref?.();
    return watcher;
  }
  const directory = nodePath.dirname(path);
  const target = nodePath.basename(path);
  const watcher = nodeFs.watch(
    directory,
    { persistent: false },
    (_eventType, filename) => {
      // filename is null on some platforms; the fingerprint comparison
      // filters non-changes, so a null event is checked rather than trusted.
      if (filename !== null && filename !== target) {
        return;
      }
      handlers.onChange();
    },
  );
  watcher.on("error", (error) => handlers.onError(error));
  // Never hold the host process open on the extension's behalf.
  watcher.unref?.();
  return watcher;
}

/**
 * Default statFn over node:fs. Checks read access explicitly: stat metadata
 * alone is readable for files whose contents are not (mode 000), and a watch
 * on an unreadable file could never deliver meaningful wakes.
 *
 * @param {string} path
 * @returns {{mtimeMs: number, size: number}}
 */
export function nodeStatFn(path) {
  nodeFs.accessSync(path, nodeFs.constants.R_OK);
  const stats = nodeFs.statSync(path);
  return { mtimeMs: stats.mtimeMs, size: stats.size };
}

/**
 * Default readFn over node:fs. Returns the file's bytes, or undefined when
 * the content is not readable (missing target, directory, denied content):
 * signature and excerpt reads must never fail a watch that stat validates.
 *
 * @param {string} path
 * @returns {Buffer | undefined}
 */
export function nodeReadFn(path) {
  try {
    return nodeFs.readFileSync(path);
  } catch {
    return undefined;
  }
}
