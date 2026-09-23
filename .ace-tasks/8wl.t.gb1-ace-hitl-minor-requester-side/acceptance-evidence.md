# Acceptance Evidence: Task 8wl.t.gb1 (ace-hitl 0.9.0)

Task: `8wl.t.gb1` (ace-hitl MINOR, requester-side effect-callback API)  
Work: W685 (delivery), W687 (live acceptance drill), W688 (acceptance evidence recording)

## 1. Delivery

- **PR:** Forgejo PR #27
- **Merge Head:** `e507bed7d4d4eeef4785f861c1fc56ffb4af28b8` (fast-forward merge to `main`)
- **Review Evidence:** `E-a79b666b` + `E-80538a71` (verdict: APPROVE at head `e507bed7d4d4eeef4785f861c1fc56ffb4af28b8`)
- **Delivered Gem:** `ace-hitl` 0.9.0
- **Artifact SHA-256:** `2157b5852a9fcb1097d8973a5ba202bffdbc057a04168d3d1440db696d974c68`
- **Pinned Artifact Location:** `/lab/state/admin/delivery/W685/artifacts/ace-hitl-0.9.0.gem`

## 2. Review Chain

Independent review executed across three rounds during Work W685:

- **Round 1 (Attempt A-ff92a34cc94af2b048255f7a, head `59a1f99778f84d5157c87ed7cbd129eeff56b43b`):**
  - Verdict: **NEEDS_CHANGES**
  - Primary finding: Observer read wrong projection field (F1: `wait` observed lifecycle `state` instead of separating lifecycle `state` and `effect_state`), plus 5 new lint offenses introduced. Fixed in subsequent commits (`50924ad1b`, `14179f05b`, `cee683365`, `ebd7a771d`, `0c0112afe`).
- **Round 2 (Attempt A-106bfdff2d2f86c4b594dae0, head `62c54a31aedd549a94a29787711d500e1cafc8f7`):**
  - Verdict: **NEEDS_CHANGES**
  - Findings: 3 minor polish items (duplicate bullet in `docs/usage.md`, 1 new standardrb lint offense, missing 0.9.0 CHANGELOG section). Fixed in commit `e507bed7d`.
- **Round 3 (Attempt A-fc33548e151cf852a806d2d5, head `e507bed7d4d4eeef4785f861c1fc56ffb4af28b8`):**
  - Verdict: **APPROVE**
  - All test suites green (89 tests, 350 assertions, 0 failures), zero new lint offenses, contract verified against deployed `lab-hitl` binary, release hygiene complete.

## 3. Live Acceptance (Work W687)

Live acceptance drill ran as admin Work W687 (Attempt `A-fc74df36d97e1ca0746e36a4`).  
Full verbatim evidence source: `/lab/state/admin/tasks/W687/report.md`.

### Requester-Side Contract Verification

- Clean-context checkout at exact merge head `e507bed7d4d4eeef4785f861c1fc56ffb4af28b8`.
- CLI binary verification:
  - `bin/ace-hitl --help` showed `ask` command present.
  - `bin/ace-hitl --version` confirmed `ace-hitl 0.9.0`.
- The real ask command executed:
  ```bash
  bin/ace-hitl ask "W685 live acceptance probe" --work W687 --effect-arg /bin/false --effect-cwd /tmp
  ```
  - Event ID printed: `8wm51h`
  - Lab Request ID printed: `hitl-e12cb8b5c2f6cab1`
  - Answer relay pointer: `lab-hitl consume hitl-e12cb8b5c2f6cab1`

### Request JSON with Effect Declaration

Raw request record captured at `/run/lab/hitl/requests/hitl-e12cb8b5c2f6cab1.json` before cancellation:

```json
{
  "ace_hitl_id": "8wm51h",
  "attempt": "A-fc74df36d97e1ca0746e36a4",
  "created_at": 1790133699,
  "effect": {
    "argv": [
      "/bin/false"
    ],
    "cwd": "/tmp",
    "match": null,
    "timeout_s": 120
  },
  "harness": "lab-admin",
  "id": "hitl-e12cb8b5c2f6cab1",
  "kind": "text",
  "options": [],
  "plan": "ace-hitl ask",
  "project": "ace",
  "question": "W685 live acceptance probe",
  "requester": "lab-admin",
  "sensitive": false,
  "work": "W687"
}
```

### Public Projection States

Public projection at creation (`/run/lab/hitl/public/hitl-e12cb8b5c2f6cab1.json`):

```json
{
  "attempt": "A-fc74df36d97e1ca0746e36a4",
  "created_at": 1790133699,
  "harness": "lab-admin",
  "id": "hitl-e12cb8b5c2f6cab1",
  "kind": "text",
  "project": "ace",
  "state": "created",
  "updated_at": 1790133699,
  "work": "W687"
}
```

### Duty Output

`lab-hitl duty` before cancellation showed the effect declaration visible with `has_effect: true`:

```json
{"escalated": [], "pending": [{"attempt": "A-fc74df36d97e1ca0746e36a4", "created_at": 1790133699, "harness": "lab-admin", "has_effect": true, "id": "hitl-e12cb8b5c2f6cab1", "kind": "text", "project": "ace", "requester": "lab-admin", "state": "created", "work": "W687"}]}
```

### Deliver Root-Only Boundary Evidence

Attempting deliver via `lab-hitl deliver`:

```
$ printf 'ack' | lab-hitl deliver hitl-e12cb8b5c2f6cab1
lab-hitl: deliver is a host-broker operation
(exit 1)
```

Exact boundary evidence:
- `/usr/local/bin/lab-hitl` lines 1771-1772: `if os.geteuid() != 0: raise RuntimeError("deliver is a host-broker operation")` — `deliver` is strictly euid-0; even `mo` cannot deliver non-root.
- No sudo path: `sudo -n -l` returns `sudo: The "no new privileges" flag is set, which prevents sudo from running as root.`
- `labd` daemon socket operation surface for `lab-admin`: `{"hitl_binding", "hitl_status", "store_credential", "clear_credential", "credential_status"}` — no deliver broker operation exists.
- The whole chain after deliver is root-performed: the effect executor is a child of the root deliverer (drops to requester uid only for the callback), and `_project_escalation_wake` raises for non-root ("only the Root Overseer or host broker can spool wakes").
- The coordinator (overseer) confirmed: *"root deliver is unavailable on this host right now (no HITL broker process deployed; overseer sandbox has no root). Do NOT wait for a human."*
- Consequently, the deliver->effect->escalation demonstration was **BLOCKED-on-deliver-authority**.

### Cancellation Audit

The live probe was cancelled as requester per coordinator directive:

```
$ lab-hitl cancel hitl-e12cb8b5c2f6cab1 --reason 'root deliver unavailable on this host; coordinator-directed end of W687 drill (BLOCKED-on-deliver-authority)'
{"attempt": "A-fc74df36d97e1ca0746e36a4", "cancelled": true, "cancelled_by": "lab-admin", "id": "hitl-e12cb8b5c2f6cab1", "reason": "root deliver unavailable on this host; coordinator-directed end of W687 drill (BLOCKED-on-deliver-authority)", "work": "W687"}
```

Final projection record (`/run/lab/hitl/public/hitl-e12cb8b5c2f6cab1.json`):

```json
{
  "attempt": "A-fc74df36d97e1ca0746e36a4",
  "cancelled_by": "lab-admin",
  "created_at": 1790133699,
  "harness": "lab-admin",
  "id": "hitl-e12cb8b5c2f6cab1",
  "kind": "text",
  "project": "ace",
  "reason": "root deliver unavailable on this host; coordinator-directed end of W687 drill (BLOCKED-on-deliver-authority)",
  "state": "cancelled",
  "updated_at": 1790136346,
  "work": "W687"
}
```

Final duty clean: `{"escalated": [], "pending": []}`.

### Re-run Precondition

A root host broker must be deployed for non-Telegram answer injection. Once a root host broker is deployed on this host, the post-deliver steps (deliver → effect execution → escalation wake to overseer) can be re-run cleanly.

## 4. Publication Status

- **Gem Build:** `ace-hitl` 0.9.0 built and pinned in `/lab/state/admin/delivery/W685/artifacts/ace-hitl-0.9.0.gem` (SHA-256: `2157b5852a9fcb1097d8973a5ba202bffdbc057a04168d3d1440db696d974c68`).
- **Publication Pending:** RubyGems publication is pending:
  1. The admin GitHub credential (required by the deterministic `github-sync` + release chain).
  2. The standard RubyGems OTP answer.
