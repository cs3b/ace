# 9c2 runtime primitives — corrective review

Exact head: `23bf5ed50b3cfd948c86c8073e8d423697c22d4b`. **APPROVE this corrected source checkpoint**. Own isolated reviewer worktree is detached at this exact head and has no tracked changes. Whole-task/installed acceptance remains open.

## Verified prior defect and repair

Prior head `0a53295ef00c19d42a6dbb34f875d62142547b28` used one strict property set for both slice and service, including MainPID. A real slice has no Service.MainPID; requiring that property makes inspect_units refuse a valid installation. This was missed in the original review because the controlled fixture fabricated MainPID for the slice. The initial approval is preserved as historical, limited evidence and explicitly superseded.

Pinned v257 [slice source](https://raw.githubusercontent.com/systemd/systemd/v257/src/core/dbus-slice.c) has an empty slice-specific vtable; [service source](https://raw.githubusercontent.com/systemd/systemd/v257/src/core/dbus-service.c) exposes MainPID at line 321. Precision: Slice itself is **not service-only**; it appears alongside ControlGroup in the common cgroup vtable at [dbus-unit.c lines 1482–1485](https://raw.githubusercontent.com/systemd/systemd/v257/src/core/dbus-unit.c). The correction may safely omit Slice from the parent query because only child service placement is used. InvocationID belongs to the common Unit vtable at line 872.

Corrected source uses the common required projection for the slice and adds MainPID/Slice only for the service. The requested and parser-required projections remain identical for each call, with exact identity, duplicate/unknown/missing-field refusal preserved. Test fixture now returns only requested properties and assertions explicitly check both query projections. Actual delta is limited to this separation and regression coverage. No new verified findings.

## Independent executed receipts

- Two candidate focused files: **14 tests / 90 assertions PASS**, `40e09d3e-9cbd-423a-92f0-81cae8c72688`.
- Reviewer ordinary-child command boundary checks: **4 / 29 PASS**, `f9adeb60-40be-4382-a2cc-eb1ddb06489a`.
- Runtime all: **189 / 575 PASS**, `90de17ee-32d4-43fa-b487-b0d0b21e5b98`.

Ran via bin/ace-test in `/Users/mc/Ps/ace/.ace-wt/review-9c2-runtime`; read immutable execution summaries under its `.ace-local/test/reports/runtime/<id>/summary.json`. Command boundary checks redirect spawn to an owned harmless Ruby fixture and exercise actual drain/output-bound/timeout/reap behavior. No systemctl or system-manager/native/VM/privilege probe was made. Source lookup was read-only pinned upstream code, not an installed test.

This verdict covers runtime primitives only. Canonical lifecycle admission, seal/proof/replay, native/boundary validation and installed Lab acceptance are later layers and remain required.
