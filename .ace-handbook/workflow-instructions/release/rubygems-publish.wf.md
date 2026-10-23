---
name: release-rubygems-publish
allowed-tools: Bash, Read
description: Publish ACE gems to RubyGems.org in dependency order
argument-hint: "[gem-name...] [--dry-run|--prepare]"
doc-type: workflow
purpose: RubyGems publishing workflow
update:
  frequency: on-change
  last-updated: "2026-10-23"
---

# RubyGems Publish Workflow

## Goal

Publish pending ACE gems through the repository's tested publisher. The
publisher uses one remote snapshot, dependency-safe waves of at most five
pushes, build-before-OTP preparation, and artifact-preserving resume behavior.

This workflow never bumps versions, creates releases, or publishes in dry-run
or prepare mode.

## Public Planning

Dry-run needs no credential or OTP and performs no build or registry mutation:

```bash
.ace-bin/ace-rubygems-publish --dry-run [gem-name...]
```

Review the reported versions, artifact paths, and waves. Requested gems include
their pending internal runtime dependencies. Unknown gems and dependency cycles
fail before any build.

## Credential and Build Preparation

Configure RubyGems authentication through `GEM_HOST_API_KEY` or the standard
RubyGems credentials file without printing or reading the credential value.
Agent shells often do not hold these credentials; in that case skip prepare and
use the Agent Execution Contract handoff instead of asking for credential setup.
Then prepare every artifact:

```bash
.ace-bin/ace-rubygems-publish --prepare [gem-name...]
```

Prepare mode asks RubyGems to validate the configured credential, refreshes the
pending snapshot, and builds every missing artifact. It does not require an OTP
and never calls `gem push`. A failure stops before publication and retains all
artifacts. It also records the resolved queue in
`.ace-local/rubygems-publish/pending-queue.yml`, so the later live run with no
gem names publishes exactly the prepared set.

## OTP HITL Handoff

Use exactly one of these paths. Do not mix them.

### Interactive prompt (default)

On an operator terminal the simplest path is the built-in silent prompt:

```bash
.ace-bin/ace-rubygems-publish --interactive
```

The publisher reads the OTP with no echo straight from the terminal right
before the push burst; the value never touches argv, env dumps, or shell
history. `--interactive` requires a terminal on stdin and refuses to run under
agents or CI.

### Secure Lab broker

When the Lab deployment provides an approved secure secret broker, request one
fresh six-digit OTP through the canonical Lab Telegram/HITL prompt. That
six-digit OTP is the only secret allowed in an authenticated, exact Lab
Telegram/HITL reply. The broker validates that the complete reply is exactly
six ASCII digits, consumes it at the transport boundary, and injects it once
as `GEM_HOST_OTP_CODE` into the resumed publisher process.

The OTP reply body must not persist in ACE HITL data, evidence, logs, task
files, reports, or later resume instructions. Long-lived API keys, personal
access tokens (PATs), passwords, private keys, and recovery codes remain
forbidden in chat and HITL. If the broker cannot guarantee non-persistence and
one-time injection, this path is unavailable.

### Readiness-only fallback

Without a secure secret broker, create a non-secret readiness event:

```bash
ace-hitl create "RubyGems OTP environment ready" \
  --kind approval \
  --question "Configure a fresh GEM_HOST_OTP_CODE out of band, then answer ready. Do not include the OTP in this answer." \
  --tags release,rubygems,security \
  --resume "/as-release-rubygems-publish"
```

The persisted HITL answer is readiness only. The operator configures
`GEM_HOST_OTP_CODE` out of band in the resumed publisher process environment;
the OTP never enters Telegram, chat, or ACE HITL on this path.

### Inline OTP (operator override)

```bash
.ace-bin/ace-rubygems-publish --otp <value>
```

The owner has approved passing short-lived OTP values inline. The value is
visible in `ps` output and shell history, which is acceptable only because a
RubyGems OTP expires within roughly a minute of issue; prefer `--interactive`.
The publisher still never writes the value into its own output, errors, or
reports, and long-lived secrets (API keys, PATs, passwords, private keys,
recovery codes) remain forbidden in argv and chat.

## Agent Execution Contract

The agent shell is not the operator shell. An absent `GEM_HOST_API_KEY` or
`~/.gem/credentials` in agent subprocesses does not mean the operator is
unconfigured: credentials and the OTP belong to the operator's terminal. Never
ask the operator to create credentials that already exist there, and never print
or read credential values.

Choose exactly ONE path:

| Situation | Agent action |
|-----------|--------------|
| Credential resolves in the agent shell (agent can run `--prepare`) | `--dry-run` -> `--prepare` -> hand off the single live command |
| No credential or no TTY in the agent shell | `--dry-run` only -> state the wave plan -> hand off the single live command. `--prepare` is optional: `--interactive` re-resolves a stale prepared queue itself |
| Operator explicitly authorizes agent-driven publishing | request ONE fresh OTP (see below), wait through the semantic wait, then run the live publisher yourself |
| Requested versions are already live on RubyGems | do not re-run the publisher; go to post-publish verification |

### Operator handoff (default)

Send exactly this one command, and do not bundle it with credential-setup
instructions:

```text
Everything is ready — run in your terminal:
  .ace-bin/ace-rubygems-publish --interactive

It builds any missing artifacts, then prompts once (silent) for the OTP.
```

`--interactive` requires an operator terminal: it refuses to run under agents or
CI, which is expected. When the agent has no TTY, the handoff above IS the
correct completion of the agent's part.

### Agent-driven OTP (operator-authorized)

The owner permits short-lived OTP values in operator chat/HITL. When the
operator explicitly authorizes the agent to run the publish itself, request one
fresh OTP, wait through the semantic wait, then run the live publisher
immediately with the OTP in the environment (never in argv). The semantic wait:
while the answer is pending, register exactly ONE in-process `/watch` scoped to
the project ace-hitl transport folder (the folder holding that case's
request/reply files, e.g. `.ace-local/hitl`), then end the turn. On wake, run
the project `ace-hitl-hermes sync` ONCE, reconcile the exact case state
(`ace-hitl show <ref>` — answered, not merely replies>0), and act within the
answer window or report the precise blocker. Never block a model turn with
sleep/poll loops; no cron/systemd/external heartbeat exists or may be
introduced. Observed defect: during the eyes-20261023 OTP wait a supervising
session blocked its turn with a 36x sleep-8 poll loop.

```bash
# 1. Ask for exactly one fresh OTP (do not persist it anywhere else)
ace-hitl create "RubyGems publish OTP" \
  --kind approval \
  --question "Reply with one fresh six-digit RubyGems OTP (valid ~30-45s)." \
  --tags release,rubygems,security

# 2. While the answer is pending: register exactly ONE in-process /watch
#    scoped to the project ace-hitl transport folder (e.g. .ace-local/hitl),
#    then END THE TURN. Never sleep/poll, never run ace-hitl wait here.
# 3. On wake: run the project ace-hitl-hermes sync ONCE, reconcile the exact
#    case state with `ace-hitl show <ref>` (answered, not merely replies>0),
#    and publish within the answer window or report the precise blocker.

# 4. Publish immediately; RubyGems reads GEM_HOST_OTP_CODE from the environment
GEM_HOST_OTP_CODE=<otp> .ace-bin/ace-rubygems-publish [gem-name...]
```

The OTP is single-use and expires in roughly 30-45 seconds. Never write it to
files, logs, reports, retros, task records, evidence, commits, or shell history;
if the HITL transport persists the answer, clear or archive that event right
after use. Long-lived credentials (API keys, PATs, passwords, private keys,
recovery codes) remain forbidden in chat, argv, and HITL.

## Live Publish

After the operator confirms readiness, run the publisher without a mode flag:

```bash
.ace-bin/ace-rubygems-publish [gem-name...]
```

The publisher:

1. Revalidates the credential without exposing it.
2. Refreshes the remote version snapshot and skips versions already published.
3. Reuses prepared artifacts and builds only missing artifacts.
4. Validates that `GEM_HOST_OTP_CODE` has the expected shape.
5. Starts `gem push` in deterministic dependency waves of at most five.

RubyGems reads `GEM_HOST_OTP_CODE` directly from the inherited environment.
The publisher never copies it into argv, output, errors, or reports. All
non-push subprocesses run with that variable removed.

## Failure and Resume

The publisher waits for the current wave and stops before later waves when any
push fails. It removes only artifacts whose RubyGems result proves publication
or prior publication. Failed and not-yet-attempted artifacts remain on disk.

For an OTP rejection or partial release:

1. Review the generic failure and retained-artifact list; no secret is emitted.
2. Configure a fresh OTP through the approved secret environment.
3. Rerun the same live command.

The fresh remote snapshot skips successful versions, and retained artifacts are
reused for the remaining queue.

## Post-Publish Verification

After the complete burst succeeds, verify RubyGems metadata outside the OTP
window and run the repository propagation proof:

```bash
ace-test-e2e ace-monorepo-e2e TS-MONO-001
```

Use `ace-handbook/docs/release-rubygems-proof.md` to classify the result as
`SAFE`, `LAG_DETECTED`, or `METADATA_BROKEN`. Do not claim onboarding safety
without this proof.

The proof belongs to the e2e runner. If the agent runner is unavailable (for
example, no LLM provider is configured), report the blocked verification command
and hand it off; do not substitute the scenario with hand-rolled
`bundle install` runs. A completed release is confirmed by a fresh dry-run
report plus RubyGems metadata, never by re-running the publisher.

## Success Criteria

- The dry-run is credential-free and non-mutating.
- Every build finishes before the first OTP-consuming push.
- Credentials and OTP shape are validated before publication.
- Dependency waves are deterministic and contain no more than five pushes.
- Already-published versions are skipped from a fresh remote snapshot.
- Partial releases resume without rebuilding retained artifacts.
- Only proven-published artifacts are removed.
- Credential and OTP values never enter argv, output, reports, fixtures, or HITL records.
- When the agent lacks a credential or a TTY, it hands off exactly one live
  command instead of requesting credential setup.
- Agent-driven publishing (when authorized) consumes one fresh OTP through the
  environment and leaves no OTP in files, logs, or retros.
