# Gated cross-user runtime launch — draft usage

## Start one mapped worker

Protected driver calls reserve_attempt for installed project/worker mapping and
passes returned launch_ticket to the selected native gated-launch operation.
Observe exact worker UID/PID/OS birth/session; record_launch and bind_process
admit that child. Only canonical bind reply permits release. Expected result:
one running attempt and one harmless payload execution counter.

Exact native commands remain review questions; this is an acceptance contract.

## Lost bind reply

Retry bind_process with exact ticket/binding. Return original canonical generation;
changed child conflicts. Release only the still-owned positively observed gate.
Missing gate/unknown child stays uncertain and never launches another child.

## Forged or unsupported endpoint

Dry-run inaccessible, caller-selected or wrong-owner/version mapping. Expected
refusal, unchanged qjl and no child. Native restart closes mapped access until
installer reapplies the narrow connect ACL and endpoint verification succeeds.
No force or local fallback grants protected launch authority.
