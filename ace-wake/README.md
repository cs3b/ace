# ace-wake

Pi agent extension: `/loop` timers and `/watch` file subscriptions that wake
idle agents with bounded, coalesced wake messages through `sendUserMessage`
only. Definitions survive reload/restart with exactly-once re-registration;
there is no cron, daemon, heartbeat, or delivery-queue engine.

## Provenance

This directory is the canonical source of the ace-wake extension. It was
developed and tested inside `ace-handbook-integration-pi/handbook/extensions/ace-wake/`
and moved here (verbatim, with its JavaScript test suite) as its top-level
home. The deployed copy at `~/.pi/agent/extensions/ace-wake` is root-owned,
dated 2026-10-16, and is a STALE generation of this source (no eyes, no
worktree inbox discovery, no watch deltas); it was intentionally left
untouched. Deployment of this directory is a host lane action after merge —
copy this directory to `~/.pi/agent/extensions/ace-wake`.

## Mount-aware poll fallback

`/lab/state/hitl-address/ace` (the HITL transport folder) is a FUSE/virtiofs
mount where inotify event delivery is unreliable: a registered `/watch` never
fires there. The watch port (`wake/watch-subscription.js`) classifies every
watched target through a `statfsFn` port (`node:fs.statfsSync` by default;
string fstype or Linux `f_type` magic number) and, for targets on unreliable
mounts (virtiofs, fuse, fuseblk, fusectl), runs a 2.5 s reconcile timer that
re-stats the aggregate fingerprint and wakes on change. `fs.watch` stays
primary everywhere else; a failing or unsupported statfs keeps `fs.watch`
primary rather than failing the watch.

## Ask bridge (the `ace-hitl ask` contract)

`ace-hitl ask` is create + send + arm + END TURN: it never blocks and never
polls. The asking agent's Ruby process drops one wake-request file into
`<session cwd>/.ace-local/hitl/wake-requests/<case id>.json`:

```json
{"schema": "ace.wake.ask/v1", "kind": "ask", "case_id": "8xhkep",
 "case_path": "/abs/worktree/.ace-local/hitl/8xhkep-slug/8xhkep-slug.hitl.s.md"}
```

The extension consumes that folder WITHOUT any agent turn activity
(`wake/ask-bridge.js`, wired in `index.js` as `startAskBridge`): a small
internal watch port anchors on the folder — or, while it does not exist yet
(the first `ask` creates it), on its nearest existing ancestor and promotes
itself once it appears — and its reconcile passes arm one scoped registry
watch named `ask-<case id>` on the case file, then consume the request.
When the answer lands (the Captain's reply flows through the transport into
the case file), the case file's fingerprint changes and the wake fires with
the `## Answer` section as its excerpt, so the wake carries the answer
content; the agent acts immediately on wake. Arming is idempotent (an
already-armed case consumes a stale request without re-arming, which would
reset the baseline and could swallow a landed answer), an unreadable case
file leaves the request pending, and the armed watch persists through
reload/restart like any registry watch — nothing expires on the asker side.
On unreliable mounts the armed watch fires only through the poll fallback
above; that fallback is what makes ask work end to end there.

## Tests

```sh
node --test test/
```

The tests inject every host port (watch factory, stat, statfs, timers), so
the suite is deterministic and never touches real mounts. The acceptance
case `test/poll-fallback.test.mjs` proves a watcher whose `fs.watch` never
fires still wakes via the poll fallback.
