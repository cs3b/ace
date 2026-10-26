import * as nodeFs from "node:fs";
import * as nodePath from "node:path";

// Contract with the ace-hitl CLI (`ace-hitl ask`): the asker's Ruby process
// drops one request file per asked case into
// `<cwd>/.ace-local/hitl/wake-requests/<case id>.json`; this bridge consumes
// the folder through the extension's own reconcile pass and arms one scoped
// watch on the case file. When the answer lands, the case file's fingerprint
// changes and the wake carries the answer content (the excerpt prefers the
// `## Answer` section). The request file is consumed once the watch is armed;
// the armed watch itself persists through the registry (reload/restart safe),
// and nothing expires on the asker side.
export const ASK_REQUEST_SCHEMA = "ace.wake.ask/v1";

/**
 * The wake-request folder for one agent session.
 *
 * @param {string} cwd Session working directory (the asking agent's worktree).
 * @returns {string}
 */
export function requestsDirFor(cwd) {
  return nodePath.join(cwd, ".ace-local", "hitl", "wake-requests");
}

/**
 * Arm one scoped `ask-<case id>` watch per pending wake request. Idempotent:
 * a request whose watch is already armed (a previous pass, a reload, or a
 * restart re-registration) is consumed without re-arming, because a restart
 * of a watch would reset its baseline fingerprint and could swallow an
 * answer that already landed. A request whose case file is unreadable stays
 * pending for the next pass. Torn or partial request files (never produced
 * by the atomic ask writer, but never trusted either) stay untouched.
 *
 * @param {{requestsDir: string, registry: import("./wake-registry.js").WakeRegistry}} inputs
 * @returns {number} Number of watches newly armed.
 */
export function armPendingAskWatches({ requestsDir, registry }) {
  let entries;
  try {
    entries = nodeFs.readdirSync(requestsDir);
  } catch {
    // No requests folder (or unreadable): nothing to arm.
    return 0;
  }
  let armed = 0;
  for (const name of entries.filter((entry) => entry.endsWith(".json")).sort()) {
    const requestPath = nodePath.join(requestsDir, name);
    let request;
    try {
      request = JSON.parse(nodeFs.readFileSync(requestPath, "utf8"));
    } catch {
      continue;
    }
    if (!isAskRequest(request)) {
      continue;
    }
    const watchName = `ask-${request.case_id}`;
    if (registry.list().some((entry) => entry.kind === "watch" && entry.name === watchName)) {
      consumeRequest(requestPath);
      continue;
    }
    try {
      registry.addWatch({
        name: watchName,
        path: request.case_path,
        message: `HITL answer for case ${request.case_id}: run /continue-work only when this wake names the answer`,
      });
    } catch {
      // The case file is unreadable or the watch is invalid: keep the
      // request pending for the next reconcile pass.
      continue;
    }
    consumeRequest(requestPath);
    armed += 1;
  }
  return armed;
}

/**
 * @param {string} path
 */
function consumeRequest(path) {
  try {
    nodeFs.unlinkSync(path);
  } catch {
    // Already consumed by a concurrent pass.
  }
}

/**
 * @param {unknown} request
 * @returns {request is {schema: string, kind: string, case_id: string, case_path: string}}
 */
function isAskRequest(request) {
  return typeof request === "object" && request !== null &&
    request.schema === ASK_REQUEST_SCHEMA && request.kind === "ask" &&
    typeof request.case_id === "string" && request.case_id.length > 0 &&
    typeof request.case_path === "string" && request.case_path.length > 0;
}
