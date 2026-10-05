# Gated cross-user runtime launch — draft usage

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

Protected launch creates one new, non-restored layout. The original authenticated
layout response fixes workspace/tab/pane and server generation; exact-pane queries
supply terminal and child identity, checked against kernel birth/UID/lineage and
pidfd. Labels, current/focused panes, supplied IDs and restored panes cannot select
the gate. Closing/replacing/moving a pane must not change the admitted original
identity. If the create reply is lost, status stays uncertain: searching for a
similar pane or retrying spawn cannot recover permission to bind/release.
