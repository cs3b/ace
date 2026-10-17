# Runtime installation source review — round 2

Verdict **REQUEST CHANGES** at exact `42a0fd2a7002aa2783d9e92ebc39bb3ac3d8cb23`, cumulative dbe80493b + correction. Initial findings/report/failed receipt remain historical.

Both original findings are fixed: readonly bind projection resolves the most specific effective source path and requires its actual hash/ancestry; writable/optional/duplicate projections refuse. Native-generated RootDirectory WantsMountsFor, RuntimeDirectory RequiresMountsFor, mount ordering and journal ordering are retained; prerequisite mount/socket units must be exact active mounted/listening objects without pending jobs. Added v257 property signatures match primary dbus-execute.c definitions. No whole live scope/proof admission is claimed.

**P2 — Account for implicit namespace mounts before certifying artifact projection.** `ace-runtime/lib/ace/runtime/molecules/execution_unit_installation.rb:253` models only explicit BindPaths/BindReadOnlyPaths and otherwise chooses RootDirectory+view. Required PrivateDevices=true creates a new /dev, hiding files in the root image's /dev. No mapping/deployment restriction disallows an immutable executable/config/dependency there. Independent fixture changes native executable to `/dev/herdr`, hashes `root_directory/dev/herdr`, updates exact native mapping, argv and manifest; verify! approves although those bytes are not the executable visible in the private device mount. Refuse artifact locations covered by implicit mounts, or positively model their actual projection. Include other enabled/generated views such as MountAPIVFS and RuntimeDirectory in the same artifact-view invariant. This is an installation-identity error even though later activation/readiness would refuse the nonexistent executable.

Primary [v257 execution documentation](https://raw.githubusercontent.com/systemd/systemd/v257/man/systemd.exec.xml) defines PrivateDevices' new device filesystem; [v257 dbus-execute.c](https://raw.githubusercontent.com/systemd/systemd/v257/src/core/dbus-execute.c) confirms typed extra properties. No actual systemd/mount/native calls performed.

Own reviewer checkout, ordinary controlled tests:

- Candidate focused **23/129 PASS**, receipt `f100a2cf-f4ae-4052-9c38-9e0976f84e81`.
- Original independent overlay regression + inherited tests **31/107 PASS**, `4c7c3a53-f8ee-44f8-833c-7d7b17036f78`.
- Runtime molecules **62/242 PASS**, `4a2ceeac-9bc4-4eb9-b97c-d029f1c5ee4d`.
- Independent implicit device shadow expected-refusal regression **31 tests / 107 assertions / 1 failure / 0 errors**, `c43f3c7e-420f-4030-89e1-0380337b14cd`; no RuntimeUnavailableError raised. Scratch `.ace-local/review/installation_implicit_shadow_test.rb` retained in reviewer checkout. All receipts under `.ace-wt/review-9c2-runtime/.ace-local/test/reports/runtime/`.

No source edits/probes/broad suite. Approval remains withheld for this bounded checkpoint; installed and whole-task acceptance remain separate.
