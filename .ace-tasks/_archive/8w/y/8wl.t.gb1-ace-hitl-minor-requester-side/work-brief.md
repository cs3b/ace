# Work brief — ace-hitl MINOR: requester-side Lab effect passthrough

Target repo: **cs3b/ace** (`/lab/projects/ace`), gem `ace-hitl` — scoped
overseer `lab-overseer-ace`. Task: `8wl.t.gb1` (record lives in the ace
repo's `.ace-tasks/`). Provenance: HITL program umbrella `8wl.t.gad`
(lab-config); the effect contract it consumes is specced and DEPLOYED in
lab-config `8wl.t.ga9`.

## Context (self-contained — no ledger access needed)

The Lab's HITL transport (container tool `/usr/local/bin/lab-hitl`, root
broker, Telegram via the Hermes plugin) now carries an answer-effect
layer, deployed 2026-09-22:

- A HITL **request** may declare an `effect`: an optional callback that
  runs automatically when the answer arrives, **as the requester**
  (same Unix identity; root drops via setgroups/setgid/setuid; a
  non-root deliverer facing a foreign requester fails closed).
- Callback: exec-style argv (a shell NEVER sees the answer),
  `{answer}` substitutes once per argv element (plain string replace —
  no format strings), bounded timeout, optional fullmatch regex gate
  on the answer (mismatch → no execution, recorded as match-failed).
- The answer itself is ALWAYS relayed unchanged to
  `answers/<id>.answer` (owner=requester, 0400) — existing polling
  consumers (`lab-hitl consume`) keep working identically.
- On callback failure/match-failure: one deduped `hitl-escalation`
  wake is recorded and spooled to the overseer channel; states live in
  the public projection (`callback-ok` / `callback-escalated`); full
  attempts live in the root-only effects log. Never retried in a loop.
- `lab-hitl.py duty` (daemon op `hitl_status`) projects pending +
  escalated for every overseer's standing-duty check.

The contract flags, deployed and live in the container:

```
--effect-match RE        # bounded regex (<=200 chars, must compile);
                         # for kind=otp defaults to exactly-six-digits
--effect-arg S           # repeatable, 1..16 elements, each 1..512 chars;
                         # at least one element required when any effect
                         # flag is present; "{answer}" substitutes once
--effect-cwd DIR         # absolute, must exist at request time
--effect-timeout-s N     # 1..600, default 120
```

The lab request also requires (existing, unchanged): `--id`,
`--work`, `--attempt`, `--project`, `--harness`, `--plan`,
`--question`, `--ace-hitl-id`.

Today the ace→Lab bridge is agent convention: an agent creates an
ace-hitl event, separately calls `lab-hitl request`, polls both, and
copies the answer over by hand. That is the gap this Work closes.

## Goal

Ship the ace-hitl MINOR version: the requester declares everything in
ONE place, ace-hitl drives the Lab pattern natively.

1. **New command `ace-hitl ask`** (or the equivalent minimal surface —
   your call, keep it small):
   - creates the local HITL event (existing `HitlManager.create`);
   - invokes `/usr/local/bin/lab-hitl request` with the existing
     required flags, binding `--ace-hitl-id <event-id>`;
   - passes the effect flags through **verbatim** after mirroring the
     client-side validation (bounds below) so bad declarations fail
     fast; the lab tool remains the authority;
   - prints both ids (event id + lab request id).
2. **`ace-hitl wait` gains Lab awareness** (smallest sensible change):
   while waiting for the event answer, also observe the lab request's
   public projection (`/run/lab/hitl/public/<id>.json`) so the waiter
   reports lab-side states (`answer-delivered`, `callback-ok`,
   `callback-escalated`) instead of hanging blind. Relay consumption
   stays the agent's choice (`lab-hitl consume`), as today.
3. **Client-side validation mirror** (fail fast, exact bounds):
   match ≤200 chars and compilable; argv 1..16 × 1..512 chars;
   cwd absolute + existing; timeout 1..600. Never "helpfully" rewrite
   a declaration — pass it through verbatim.

## Security invariants (binding, Captain decisions 2026-09-22)

- A command can never come FROM Telegram; effects execute as the
  requester through the Lab's own identity boundary. ace-hitl adds no
  privilege and no allowlist — capability follows identity.
- No answer content, no `{answer}` substitutions, and no effect argv
  in logs or in the event file's answer field before the answer
  exists; otp answers are six digits and are never logged.
- No secrets in transport, logs, or tests.

## Tests (repo's existing framework)

- Flag validation: bounds, cwd existence, regex compile, otp default
  match — each with a failing and a passing case.
- Contract test: the EXACT argv built for `lab-hitl request`
  (including `--ace-hitl-id` binding and effect passthrough order
  stability).
- Wait awareness: public-projection states surface in `wait` output
  (fixture the projection file; do not call the real lab tool in
  unit specs).
- Existing suite stays green; `rake` defaults pass.

## Gates (project workflow, unchanged)

- Branch + PR in cs3b/ace; INDEPENDENT review (author ≠ reviewer);
  verdict pasted before merge; minor version bump + CHANGELOG entry;
  gem builds.
- Deploy rides the normal Lab container pipeline (`install-host.sh`
  path) — verify `ace-hitl --version` in the container after install.
- Live acceptance (small, real): inside the container, as a real
  session user, run one `ace-hitl ask` with a deliberately failing
  callback (`--effect-arg /bin/false --effect-cwd /tmp`), answer it
  through the normal Telegram loop or the broker deliver path, and
  show: `callback-escalated` in the public projection + the escalation
  visible in `lab-hitl duty`. Paste raw outputs into the task record.
- Coordination: do NOT restart labd while any Work attempt is in
  flight; the lab-config side (transport + effects + duty) is already
  deployed and must not be modified by this Work.

## Out of scope

- No changes to lab-hitl.py, labd, broker, plugin (all in lab-config,
  already deployed). No OTP/publish flow work (that is the follow-up
  pilot, lab-config `8wl.t.gac`). No new network exposure.
