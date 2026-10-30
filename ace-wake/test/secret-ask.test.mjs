import assert from "node:assert/strict";
import { describe, it } from "node:test";
import * as nodeFs from "node:fs";
import * as nodeOs from "node:os";
import * as nodePath from "node:path";

import { armPendingAskWatches, requestsDirFor } from "../handbook/extensions/ace-wake/wake/ask-bridge.js";
import { WakeDispatcher } from "../handbook/extensions/ace-wake/wake/wake-dispatcher.js";
import { WakeRegistry } from "../handbook/extensions/ace-wake/wake/wake-registry.js";
import { createWatchPort, nodeReadFn, nodeStatFn, nodeStatfsFn, nodeWatchFactory } from "../handbook/extensions/ace-wake/wake/watch-subscription.js";
import { createFakeHost } from "./fake-pi-host.mjs";

const flush = () => new Promise((resolve) => setImmediate(resolve));

/** Stub registry recording armed watch inputs (ask-bridge contract level). */
function stubRegistry() {
  const watches = [];
  return {
    watches,
    list: () => watches.map(({ kind, name }) => ({ kind, name })),
    addWatch(input) {
      watches.push({ kind: "watch", ...input });
      return { kind: "watch", ...input };
    },
  };
}

/** A REAL registry wired to the fake host, with real watch ports. */
function realRegistry(host) {
  const stateStore = { snapshot: { loops: [], watches: [] } };
  const state = {
    load: () => structuredClone(stateStore.snapshot),
    save: (snapshot) => {
      stateStore.snapshot = structuredClone(snapshot);
    },
  };
  const dispatcher = new WakeDispatcher({
    deliver: (sourceKey, text) => {
      host.pi.sendUserMessage(`[ace-wake ${sourceKey}] ${text}`);
      return true;
    },
  });
  return {
    registry: new WakeRegistry({
      loops: { start: () => {}, stop: () => {}, stopAll: () => {}, errorOf: () => undefined },
      watches: createWatchPort({
        watchFactory: host.watchFactory,
        statFn: nodeStatFn,
        readFn: nodeReadFn,
        statfsFn: () => ({ type: nodeStatfsFn(nodeOs.tmpdir()).type }),
        pollIntervalMs: 60_000,
        baseDir: nodeOs.tmpdir(),
      }),
      state,
      status: { render: () => {} },
      dispatcher,
      isHostQueued: () => false,
      isHostIdle: () => host.idle,
    }),
    stateStore,
  };
}

/**
 * Task 8xs.t.pu0.9: a SECRET ask (explicit at creation — e.g. an OTP) arms a
 * watch whose wake carries the CASE REFERENCE ONLY; the delivered value
 * never passes through the model. A normal ask still carries the answer.
 */
describe("secret ask wake carries the reference, never the value", () => {
  it("the bridge arms a redacted watch for a secret request and a plain one otherwise", () => {
    const dir = nodeFs.mkdtempSync(nodePath.join(nodeOs.tmpdir(), "ace-secret-arm-"));
    try {
      const requestsDir = requestsDirFor(dir);
      nodeFs.mkdirSync(requestsDir, { recursive: true });
      const secretCase = nodePath.join(dir, "secret.hitl.s.md");
      const openCase = nodePath.join(dir, "open.hitl.s.md");
      nodeFs.writeFileSync(secretCase, "---\nid: c1\nsecret: true\n---\n# Q\n");
      nodeFs.writeFileSync(openCase, "---\nid: c2\n---\n# Q\n");
      nodeFs.writeFileSync(nodePath.join(requestsDir, "c1.json"), JSON.stringify({
        schema: "ace.wake.ask/v1", kind: "ask", case_id: "c1", case_path: secretCase, secret: true,
      }));
      nodeFs.writeFileSync(nodePath.join(requestsDir, "c2.json"), JSON.stringify({
        schema: "ace.wake.ask/v1", kind: "ask", case_id: "c2", case_path: openCase,
      }));

      const registry = stubRegistry();
      armPendingAskWatches({ requestsDir, registry });

      const secret = registry.watches.find((entry) => entry.name === "ask-c1");
      assert.equal(secret.redact, true, "the secret ask arms a redacted watch");
      assert.match(secret.message, /secure channel/);
      assert.ok(!secret.message.includes("918273"));

      const open = registry.watches.find((entry) => entry.name === "ask-c2");
      assert.notEqual(open.redact, true, "a normal ask is not redacted");
      assert.match(open.message, /names the answer/);
    } finally {
      nodeFs.rmSync(dir, { recursive: true, force: true });
    }
  });

  it("a secret case wake fires without the answer content; a normal wake names it", async () => {
    const base = nodeFs.mkdtempSync(nodePath.join(nodeOs.tmpdir(), "ace-secret-wake-"));
    try {
      const host = createFakeHost();
      host.commandContext.cwd = base;
      const { registry } = realRegistry(host);

      const secretCase = nodePath.join(base, "secret.hitl.s.md");
      const openCase = nodePath.join(base, "open.hitl.s.md");
      nodeFs.writeFileSync(secretCase, "---\nid: c1\nsecret: true\nanswered: false\n---\n# Q\n");
      nodeFs.writeFileSync(openCase, "---\nid: c2\nanswered: false\n---\n# Q\n");
      registry.addWatch({
        name: "ask-c1", path: secretCase,
        message: "HITL answer for case c1: read the value through the secure channel (never this wake)",
        redact: true,
      });
      registry.addWatch({
        name: "ask-c2", path: openCase,
        message: "HITL answer for case c2: the wake names the answer",
      });

      nodeFs.writeFileSync(secretCase,
        "---\nid: c1\nsecret: true\nanswered: true\n---\n# Q\n\n## Answer\n\n918273\n");
      nodeFs.writeFileSync(openCase,
        "---\nid: c2\nanswered: true\n---\n# Q\n\n## Answer\n\nProceed\n");
      host.triggerWatch(nodeFs.realpathSync(secretCase));
      host.triggerWatch(nodeFs.realpathSync(openCase));
      await flush();
      registry.settleAll?.();
      await flush();

      const secretWake = host.sends.find((send) => send.text.includes("case c1"));
      const openWake = host.sends.find((send) => send.text.includes("case c2"));
      assert.ok(secretWake, "the secret answer still wakes the asker");
      assert.ok(secretWake.text.includes("918273") === false,
        "the OTP value NEVER appears in the secret wake");
      assert.ok(openWake, "the normal answer wakes the asker");
      assert.ok(openWake.text.includes("Proceed"), "a non-secret answer names the answer");
    } finally {
      nodeFs.rmSync(base, { recursive: true, force: true });
    }
  });
});
