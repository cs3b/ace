import { execFileSync } from "node:child_process";
import * as nodePath from "node:path";

/**
 * Cross-worktree discovery for the ace-hitl report inbox.
 *
 * `ace-hitl create` writes a coworker's report inside THAT coworker's
 * worktree (its own `.ace-local/hitl`), while the overseer session usually
 * waits in the main checkout — a watch on the main checkout's inbox alone
 * never fires. The HITL list already solves this with multi-worktree
 * discovery over `git worktree list --porcelain`; this module reuses the
 * SAME discovery (no second inbox, queue, or cache) to expand a configured
 * `.ace-local/hitl` watch to every linked worktree's inbox directory.
 *
 * Expansion happens at watch registration and at every re-registration
 * (session start/reload/branch switch); worktrees created later are picked
 * up at the next re-registration.
 */

/** The inbox path suffix that marks a watch as the ace-hitl report inbox. */
export const HITL_INBOX_SEGMENTS = [".ace-local", "hitl"];

/**
 * List the roots of every linked worktree (including the main checkout)
 * using the same porcelain output ace-hitl's WorktreeScopeResolver reads.
 *
 * @param {string} baseDir session working directory (git runs there)
 * @param {(args: string[], options: object) => string} [execGit] injectable
 *   git runner for tests; defaults to execFileSync with output decoding
 * @returns {string[]} unique worktree roots, main first; [] when git fails
 */
export function discoverWorktreeRoots(baseDir, execGit = defaultExecGit) {
  let output;
  try {
    output = execGit(["worktree", "list", "--porcelain"], { cwd: baseDir });
  } catch {
    // Not a repository (or git missing): the caller keeps whatever targets
    // it can resolve on its own.
    return [];
  }
  return output
    .split(/\r?\n/)
    .filter((line) => line.startsWith("worktree "))
    .map((line) => line.slice("worktree ".length).trim())
    .filter((path) => path.length > 0);
}

/**
 * Resolve the watch targets for a configured path. A path that names an
 * ace-hitl inbox (any `.ace-local/hitl` directory) expands to that same
 * inbox in EVERY discovered worktree, so a report written inside a
 * coworker's worktree wakes the waiting session. Any other path stays a
 * single target — the watch never invents unrelated directories.
 *
 * @param {string} baseDir session working directory
 * @param {string} configuredPath the path the user configured
 * @param {(args: string[], options: object) => string} [execGit]
 * @returns {string[]} canonical target directories, sorted and unique
 */
export function expandInboxWatchTargets(baseDir, configuredPath, execGit = defaultExecGit) {
  const primary = nodePath.resolve(baseDir, configuredPath);
  if (!namesInbox(primary)) {
    return [primary];
  }
  const roots = discoverWorktreeRoots(baseDir, execGit);
  if (roots.length === 0) {
    return [primary];
  }
  const targets = new Set(roots.map((root) => nodePath.join(root, ...HITL_INBOX_SEGMENTS)));
  targets.add(primary);
  return [...targets].sort();
}

/** @param {string} path @returns {boolean} */
function namesInbox(path) {
  const segments = nodePath.normalize(path).split(nodePath.sep);
  const last = HITL_INBOX_SEGMENTS.length;
  for (let index = segments.length - last; index >= 0; index -= 1) {
    const window = segments.slice(index, index + last);
    if (window.join(nodePath.sep) === HITL_INBOX_SEGMENTS.join(nodePath.sep)) {
      return true;
    }
  }
  return false;
}

/**
 * @param {string[]} args
 * @param {{cwd: string}} options
 * @returns {string}
 */
function defaultExecGit(args, options) {
  return execFileSync("git", args, { ...options, encoding: "utf8" });
}
