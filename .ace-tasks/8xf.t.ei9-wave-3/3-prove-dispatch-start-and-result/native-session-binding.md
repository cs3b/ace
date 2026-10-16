# Native Pi session binding repair

Live read-only observation of pinned Herdr pane w1:pS returned a Pi agent_session
selector of kind:path naming session UUID01a144bd-f8d1-74b1-8ba8-0e131c678b0c.
RuntimeAdapter.process_binding requires kind:id and therefore rejects the genuine
supervisor before ordinary registration. OrdinaryNativeRead correctly preserves
the native protocol response. Inbox already normalizes the supported Pi path.

Repair the owning ace-herdr primitive: share immutable session normalization
between Inbox and RuntimeAdapter. Keep agent match, UUID validation, foreground
process ownership, native ancestry and Inbox's independent live pi_identity check.
Do not normalize names, malformed paths or other agents' paths into identities.

Regression first reproduces rejection using actual native protocol shape. Then
verify both consumers, ordinary admission composition and independently review.
Installed acceptance requires the released repair and genuine native requester;
source tests never authorize an SSH process as a supervisor.

## Executed source evidence

Before repair, the new RuntimeAdapter regression failed because the binding was
nil:34 tests/152assertions,1failure (herdr/a31e831a). After shared normalization,
RuntimeAdapter+Inbox passed76/408. Complete Herdr fast passed591/2444 with zero
failures/errors (herdr/5db68797-95fd-452d-b972-67a5694f227e). Lab's actual child-PID
ordinary admission fixture now supplies the native Pi path; admission/native read
passed14/62 (lab/2b36bb57-1f0d-4c58-b83d-5a398e5da8ac).

Native foreground PID ancestry, live peer birth and fixed supervisor placement
remain checked. Inbox independently compares normalized UUID with its live Pi
session. Independent review, publication and actual installed native admission
remain open; no package version or deployed source was changed by these tests.
