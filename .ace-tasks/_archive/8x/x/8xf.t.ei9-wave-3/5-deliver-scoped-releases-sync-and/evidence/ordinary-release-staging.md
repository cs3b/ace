# Ordinary release staging consumer — 2026-10-17

OrdinaryReleaseStaging (ace-lab) is the .5 staging join: it reads retained
release artifacts through the sole Assign owner (release_artifact_at!, now
reachable with the public result_events/journal surface), verifies every
canonical byte digest, reconciles each artifact against the AUTHORITATIVE
registry readback (RubyGems versions API; the CDN-cached latest.json is
deliberately not used), and produces the publisher's staged queue —
dependency-ordered per the manifest's declared order, with per-artifact
states: published (digest match — skip), pending (absent — publish),
conflict (digest mismatch — the registry is immutable; a differing digest
means a different build and hard-blocks, never republish), uncertain
(readback unreachable — reconcile before any retry). It never pushes and
never holds credentials; execution stays with the existing project publisher
in its authorized executor (the .5 contract). Receipts: 5 tests / 20
assertions PASS (published+pending+order, conflict-blocks, uncertain, exact-
set-once order validation, unknown-artifact refusal).

Remaining .5 source: wiring the staged queue into the project publisher's
run owner (iy6 command execution with the declared inputs/executor identity)
and the per-artifact partial-success reconciliation loop on the execution
side; the OTP route stays with child .9 per the spec.

## Publication execution + reconciliation (OrdinaryReleasePublication)

The execution side of the .5 join: publishes the staged queue through the
authorized project publisher — strictly one artifact at a time in dependency
order, never parallel — and reconciles every attempted effect against the
authoritative registry readback. Semantics proven: already-published artifacts
are skipped (executor never called); a failed push whose registry readback
shows the exact digest RECONCILES to published and the chain continues (a
retry that landed); exit-zero with absent/unreachable readback stays UNCERTAIN
(never assumed published) and halts dependents; conflict artifacts halt the
chain with no push at all; partial success retains per-artifact
published/uncertain/dependent_blocked sets with halted_by. Receipts: 5 tests /
21 assertions PASS.

Remaining .5 source: the executor seam binding to the real iy6 project-command
channel (credentials resolved only in the child after UID drop per the spec;
OTP route stays with .9), and all-consumer install/sync which is installed
acceptance.

## Publisher executor binding (OrdinaryReleasePublisher)

The .5 executor seam: materializes staged artifacts' canonical bytes into the
staging root the policy's own publish-command argv names (pending/uncertain
only; published artifacts need no bytes; 0600 files in a 0700 root), then runs
the configured publish command through the iy6 CommandRunClient under the
GRANTED executor (uid/gid/groups/home/cwd/path/environment from the validated
project policy — credentials resolve only in the child after its UID drop per
the iy6 contract). A lost channel maps to exit_status nil/signal unknown —
the publication organism's reconciliation treats it as attempted-effect
unknown, never success. Missing publish command refuses precisely. The policy
gains read-only commands/grants accessors. Receipts: 4 tests / 13 assertions
PASS; staging 5/20 and the runner integration 1/3 remain green.

The .5 source chain is now complete end to end: retained artifacts →
staging/reconciliation → serial publication with per-artifact states → the
iy6-bound executor. Remaining .5 items are installed acceptance (all-consumer
install/sync) and the OTP route (.9).
