# Protected admission cold-load source checkpoint

Parent `05483d27b`. The actual ProtectedCleanupOwnerAdmission→LaunchLifecycle→launch_stop→AttemptCoordinator graph must not initialize broad Herdr configuration. AttemptCoordinator now explicitly requires Herdr errors and DeliveryRecord model/store. Its ordinary local recovery_inboxes method requires the existing broad configuration owner only at the actual ordinary operation; protected canonical recovery does not call that method. No fallback or loader exemption is added.

ServiceEvidence defines its field contract from EvidenceJournal, so the actual owner now explicitly requires EvidenceJournal. The cold regression loads ProtectedCleanupOwnerAdmission itself first, then the independent narrow ProtectedServicePolicy required by production composition; it never supplies an ad-hoc journal preload or broad Assign/Herdr/Lab entry. All cold children reject broad package/config loading.

## Executed retained evidence

- AttemptCoordinator before repair: `herdr/c8228489-7091-400a-aaf3-827a2a539f14` FAIL1/1 broad entry loaded.
- Final six separate primitive children including AttemptCoordinator: `herdr/a074417b-075d-4040-ac26-6410e1b703be` PASS1/24.
- Actual admission cold require before EvidenceJournal owner require: `lab/fc430e21-401c-40da-a0ed-2bc326687e52` FAIL1/9, missing EvidenceJournal. Intermediate `lab/867ed9d4-9674-4997-978e-311f0edceb64` failed because the test additionally tried policy/default-loader behavior without requiring that separate actual policy; corrected to require the narrow policy after the independently selected entry, no production dependency added for an unused collaborator.
- Final three cold entry children plus ProtectedServicePolicy/ServicePolicy behavior: `lab/b9ba1de3-ba0b-420e-aeb2-f6d92375b93a` PASS12/71. Includes actual refusing canonical proposal classification and unchanged fixed-path empty-grant refusal.
- Inspected ordinary coordinator resume adoption/dry-run, lost-cache, unresolved-effect methods at lines1240/1256/1289: `assign/195a95e8-99df-49e5-8e27-13778e5784df` PASS3/14. Temporary canonical Git fixtures and fixed execution identity resolver; no native service, installed or Linux identity probes.

This verifies source loading and existing controlled owner behavior, not actual physical Installer acceptance; no xza.3 closure.

## Independent review and main integration

`/root/review_lab_bootstrap` independently approved frozen `6ae9a49b0`: all direct coordinator dependencies remain explicit, ordinary recovery retains its existing configuration behavior at point of use, and ServiceEvidence now loads the owner of its field constants. No actionable finding; reviewer ran no additional tests or probes.

Integrated on main as `0f5ed5054`. Root executed `../bin/ace-test test/molecules/protected_service_loading_test.rb --timeout 120` from ace-lab: **1 test / 12 assertions PASS**, no skips/errors, report `.ace-local/test/reports/lab/e36f765b-1efa-41ad-b7a0-01ffa1fe25db/`. The actual Installer composition remains a separate pending source check; this receipt does not replace it.
