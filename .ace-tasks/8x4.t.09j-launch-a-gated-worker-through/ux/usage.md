# Gated cross-user runtime launch

## Start one mapped worker

Protected driver calls reserve_attempt for installed project/worker mapping and
passes returned launch_ticket to the selected native gated-launch operation.
Observe exact worker UID/PID/OS birth/session; record_launch and bind_process
admit that child. Canonical bind permits a separate launcher-only release_launch call. Expected result:
one running attempt and one harmless payload execution counter.

Native layout.apply launches the installed bootstrap argv. It connects to the existing authority socket using gate_ready; pane.process_info is matched to kernel peer PID/birth. release_launch journals issuance once and sends the framed release. pane.close plus an already acquired pidfd proves exact child exit. Linux protected launch requires installer-pinned server identity and enforced Yama=2/capability policy.

## Lost bind reply

Retry bind_process with exact ticket/binding. Return original canonical generation;
changed child conflicts. Request release_launch only for the still-owned positively observed gate. Exact release replay returns issued state without resending. A lost release reply stays potentially executed and retains ownership.
Missing gate/unknown child stays uncertain and never launches another child.

## Forged or unsupported endpoint

Dry-run inaccessible, caller-selected or wrong-owner/version mapping. Expected
refusal, unchanged qjl and no child. Native restart closes mapped access until
installer reapplies the narrow connect ACL and endpoint verification succeeds.
No force or local fallback grants protected launch authority.


## Native creation provenance and an unknown creation result

Protected launch calls only layout.apply in the root-installed native.workspace_id
container and creates one new, non-restored tab/pane/bootstrap. It never calls
workspace.create or uses an existing shell as worker evidence. A missing/stale
container refuses without fallback. The original authenticated layout response
fixes the configured workspace, fresh tab/pane and server generation; exact-pane queries
supply terminal and child identity, checked against kernel birth/UID/lineage and
pidfd. Labels, current/focused panes, supplied IDs and restored panes cannot select
the gate. Closing/replacing/moving a pane must not change the admitted original
identity. If the create reply is lost, status stays uncertain: searching for a
similar pane or retrying spawn cannot recover permission to bind/release.

## Lost reservation response and authority observation

The driver creates a native layout only after an unequivocally fresh reservation
response. The authority reports a transport `replayed` boolean atomically with
journal mutation deduplication; this metadata does not change the canonical
reservation result, generation or commit. A replay, response loss, or existing
reservation grants no new creation permission. Inspect the retained reservation;
do not repeat native creation even when no process binding has been recorded.

The trusted mapped launcher reports the original authenticated creation response
and exact native child binding. The authority independently validates kernel
peer credentials, server lineage and birth, and acquires the exact child pidfd.
This does not claim that the authority directly queried a native endpoint to
which it has no configured access. Native close is performed by the authorized
launcher; authoritative termination additionally requires the authority's
pre-acquired pidfd exit observation. Launcher loss without positive termination
proof retains an uncertain attempt and its scope ownership.

## Public source entrypoint and installed policy

`ace-assign authority serve --authority ID` runs the fixed launch composition.
`ace-assign authority launch --mapping ID --dry-run` checks installed policy without
mutation/native creation. A real launch supplies managed definition, assignment,
scope, exact base head and stable mutation ID. Status/terminate use the retained
canonical attempt; they do not accept caller-selected native origin.

See `ace-assign/docs/protected-authority.md` and the gem-shipped
`ace-runtime/native/README.md` for the complete installed schema and reproducible
native build inputs. The root-owned authority composition must match the source
entrypoint; duplicate project owners/endpoints fail before listener creation.
Every participant, including the pinned root-started Herdr service, requires empty
Inh/Prm/Eff/Bnd/Amb capabilities and NoNewPrivs=1 in addition to enforced Yama=2,
fixed UID/GID/groups and protected immutable paths. No host sysctl is changed by
ACE. Compilation, package inclusion, actual UID/kernel primitives and Yama=0
refusal can be demonstrated in Docker; positive enforced-policy native acceptance
remains a separate installed fixture requirement.
