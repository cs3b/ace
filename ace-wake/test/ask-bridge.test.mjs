import assert from "node:assert/strict";
import * as nodeFs from "node:fs";
import * as nodeOs from "node:os";
import * as nodePath from "node:path";
import { describe, it } from "node:test";

import { ASK_REQUEST_SCHEMA, armPendingAskWatches, requestsDirFor } from "../handbook/extensions/ace-wake/wake/ask-bridge.js";
import { createWatchPort, nodeReadFn, nodeStatFn, nodeStatfsFn, nodeWatchFactory } from "../handbook/extensions/ace-wake/wake/watch-subscription.js";

const pause = (ms) => new Promise((resolve) => setTimeout(resolve, ms));

async function waitFor(predicate, description, timeoutMs = 2000) {
  const deadline = Date.now() + timeoutMs;
  for (;;) {
    if (predicate()) {
      return;
    }
    if (Date.now() >= deadline) {
      assert.fail(`timed out waiting for ${description}`);
    }
    await pause(10);
  }
}

/** Stub registry: records armed watches, answers list() for idempotence, and
 * refuses to arm watches whose path is unreadable (the real registry's watch
 * port fails the add loudly before anything is persisted). */
function stubRegistry() {
  const watches = [];
  return {
    watches,
    list: () => watches.map(({ kind, name }) => ({ kind, name })),
    addWatch(input) {
      if (!nodeFs.existsSync(input.path)) {
        throw new Error(`path is not readable: ${input.path}`);
      }
      watches.push({ kind: "watch", ...input });
      return { kind: "watch", ...input };
    },
  };
}

function writeRequest(requestsDir, caseId, casePath, extra = {}) {
  nodeFs.mkdirSync(requestsDir, { recursive: true });
  const request = {
    schema: ASK_REQUEST_SCHEMA,
    kind: "ask",
    case_id: caseId,
    case_path: casePath,
    ...extra,
  };
  nodeFs.writeFileSync(nodePath.join(requestsDir, `${caseId}.json`), JSON.stringify(request));
  return request;
}

/** A real case file in the shipped HITL shape (pending). */
const PENDING_CASE = (title) => `---
id: 8xhkep
title: ${title}
kind: approval
status: pending
answered: false
questions:
- Proceed?
---

# ${title}

## Questions

- Proceed?
`;

const ANSWERED_CASE = (title, answer) => `---
id: 8xhkep
title: ${title}
kind: approval
status: answered
answered: true
questions:
- Proceed?
---

# ${title}

## Questions

- Proceed?

## Answer

${answer}
`;

describe("ask bridge (ace-hitl ask wake requests)", () => {
  it("arms one scoped watch per pending request and consumes the request file", () => {
    const tmp = nodeFs.mkdtempSync(nodePath.join(nodeOs.tmpdir(), "ask-bridge-"));
    const requestsDir = requestsDirFor(tmp);
    try {
      const casePath = nodePath.join(tmp, ".ace-local", "hitl", "8xhkep-continue", "8xhkep-continue.hitl.s.md");
      nodeFs.mkdirSync(nodePath.dirname(casePath), { recursive: true });
      nodeFs.writeFileSync(casePath, PENDING_CASE("Continue"));
      writeRequest(requestsDir, "8xhkep", casePath);

      const registry = stubRegistry();
      const armed = armPendingAskWatches({ requestsDir, registry });

      assert.equal(armed, 1);
      assert.deepEqual(registry.watches.map(({ name, path }) => ({ name, path })), [
        { name: "ask-8xhkep", path: casePath },
      ]);
      assert.match(registry.watches[0].message, /HITL answer for case 8xhkep/);
      assert.equal(nodeFs.readdirSync(requestsDir).length, 0, "the request is consumed after arming");
    } finally {
      nodeFs.rmSync(tmp, { recursive: true, force: true });
    }
  });

  it("is idempotent and tolerates torn, foreign, and unarmable requests", () => {
    const tmp = nodeFs.mkdtempSync(nodePath.join(nodeOs.tmpdir(), "ask-bridge-"));
    const requestsDir = requestsDirFor(tmp);
    try {
      const casePath = nodePath.join(tmp, "case.hitl.s.md");
      nodeFs.writeFileSync(casePath, PENDING_CASE("Continue"));
      writeRequest(requestsDir, "8xhkep", casePath);
      nodeFs.writeFileSync(nodePath.join(requestsDir, "torn.json"), '{"schema": "ace.wake');
      nodeFs.writeFileSync(nodePath.join(requestsDir, "foreign.json"),
        JSON.stringify({ schema: "other/v9", kind: "ask", case_id: "zzz111", case_path: casePath }));

      const registry = stubRegistry();
      registry.watches.push({ kind: "watch", name: "ask-8xhkep", path: casePath });
      // 8xhkep is already armed: the stale request is consumed, nothing re-arms
      // (a re-arm would reset the baseline and could swallow a landed answer).
      assert.equal(armPendingAskWatches({ requestsDir, registry }), 0);
      assert.equal(registry.watches.length, 1);
      assert.deepEqual(nodeFs.readdirSync(requestsDir).sort(), ["foreign.json", "torn.json"]);

      // A request whose case file is unreadable stays pending.
      writeRequest(requestsDir, "bbb222", nodePath.join(tmp, "gone.hitl.s.md"));
      assert.equal(armPendingAskWatches({ requestsDir, registry }), 0);
      assert.deepEqual(nodeFs.readdirSync(requestsDir).sort(), ["bbb222.json", "foreign.json", "torn.json"]);
    } finally {
      nodeFs.rmSync(tmp, { recursive: true, force: true });
    }
  });

  it("returns zero when the requests folder does not exist", () => {
    const tmp = nodeFs.mkdtempSync(nodePath.join(nodeOs.tmpdir(), "ask-bridge-"));
    try {
      assert.equal(armPendingAskWatches({ requestsDir: nodePath.join(tmp, "absent"), registry: stubRegistry() }), 0);
    } finally {
      nodeFs.rmSync(tmp, { recursive: true, force: true });
    }
  });

  // The point-1 acceptance, end to end on real files: the armed watch sits
  // on a deaf virtiofs mount (fs.watch never fires), the fixture answer
  // lands in the case file, and the wake carries the answer content — the
  // extension-internal reconcile fallback is what makes ask work.
  it("wakes with the answer content through the poll fallback when fs.watch never fires", async () => {
    const tmp = nodeFs.mkdtempSync(nodePath.join(nodeOs.tmpdir(), "ask-accept-"));
    const casePath = nodePath.join(tmp, "8xhkep-continue.hitl.s.md");
    try {
      nodeFs.writeFileSync(casePath, PENDING_CASE("Continue"));
      const caseRealPath = nodeFs.realpathSync(casePath);
      const port = createWatchPort({
        // Silent watcher: the deaf mount never delivers an event.
        watchFactory: () => ({ close: () => {} }),
        statFn: nodeStatFn,
        readFn: nodeReadFn,
        statfsFn: () => ({ type: "virtiofs" }),
        pollIntervalMs: 20,
        baseDir: tmp,
      });
      const wakes = [];
      port.start(
        { kind: "watch", name: "ask-8xhkep", path: casePath, message: "HITL answer for case 8xhkep" },
        (definition, delta) => {
          wakes.push({ definition, delta });
          return { delivered: true };
        },
      );

      nodeFs.writeFileSync(casePath, ANSWERED_CASE("Continue", "Proceed with JWT"));
      await waitFor(() => wakes.length >= 1, "the poll fallback to wake with the answer");

      assert.equal(wakes.length, 1);
      assert.equal(wakes[0].definition.name, "ask-8xhkep");
      assert.equal(wakes[0].delta[0].path, caseRealPath);
      assert.equal(wakes[0].delta[0].kind, "modified");
      assert.equal(wakes[0].delta[0].excerpt, "answer: Proceed with JWT");
      port.stopAll();
    } finally {
      nodeFs.rmSync(tmp, { recursive: true, force: true });
    }
  });

  it("wakes with the answer content through fs.watch on reliable mounts", async () => {
    const tmp = nodeFs.mkdtempSync(nodePath.join(nodeOs.tmpdir(), "ask-accept-"));
    const casePath = nodePath.join(tmp, "8xhkep-continue.hitl.s.md");
    try {
      nodeFs.writeFileSync(casePath, PENDING_CASE("Continue"));
      const port = createWatchPort({
        watchFactory: nodeWatchFactory,
        statFn: nodeStatFn,
        readFn: nodeReadFn,
        statfsFn: () => ({ type: nodeStatfsFn(casePath).type }),
        pollIntervalMs: 60_000,
        baseDir: tmp,
      });
      const wakes = [];
      port.start(
        { kind: "watch", name: "ask-8xhkep", path: casePath, message: "HITL answer for case 8xhkep" },
        (definition, delta) => {
          wakes.push({ definition, delta });
          return { delivered: true };
        },
      );

      nodeFs.writeFileSync(casePath, ANSWERED_CASE("Continue", "Use sessions"));
      await waitFor(() => wakes.length >= 1, "the fs.watch event to wake with the answer");
      assert.equal(wakes[0].delta[0].excerpt, "answer: Use sessions");
      port.stopAll();
    } finally {
      nodeFs.rmSync(tmp, { recursive: true, force: true });
    }
  });
});
