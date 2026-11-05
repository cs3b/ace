# Checkout recovery and acceptance restart — 2026-11-05

The previous worktree and its ignored local state were absent on resumption.
The Git branch survived at bc3c8e796d6f5a6edfea2ac5b8160fbaaa899f5e and was restored using ace-git-worktree.
The previous test processes no longer existed. Both previously registered UTM machines were stopped.
The old working VM B3F20591-D7E6-4C53-BB80-A8A977BC637F was inspected through QEMU guest execution: /opt/ace, /lab and /var/lib/ace-e2e were absent. It was stopped again and retained. No acceptance is inferred from the prior run.

The missing local state also included the operator SSH key and native artifact cache. A new base was built through the existing helper; old machines were not adopted or deleted.
New base: 2C545973-0B40-4AFF-806B-BABD53BCA155, ace-e2e-base-698aa19d002d42d3.
Base ready fingerprint: d6c6cf1fee24cc9077b03439bff56d3054d045b4cb673be8352746b2b7583f12.

Artifact reconstruction exposed a moving rustup URL. Official archived rustup 1.29.2 has the original pinned SHA a9c168dbea81a84671c6b7a5c1795cb0eb699020110d107ddfca427bd797e697. Commit aa7f835ca pins that archive URL; no expected bytes or checksum were relaxed. All 60 artifact inputs verified. The artifact test passed 4 tests / 19 assertions (report d50e06fa-b604-4891-807d-2c58a7d51af0).

TS-MONO-003 was started through bin/ace-test-e2e with runner and independent verifier, run 8y4mxlz-monorepo-e2e-ts003. It created working VM 83B56952-B5F1-474F-A73D-73DF473F3A8C, ace-e2e-work-bbf7c36fb8c1699d. At this checkpoint provisioning had completed apt dependencies and was compiling Ruby. This is a live setup checkpoint, not an acceptance result. TS004 and two complete clean pairs remain unproven.

## Native build failure and verified correction

TS003 setup failed after successfully compiling native Herdr: its SHA did not match the previously pinned diagnostic artifact. The produced binary embedded absolute cargo registry paths below the output directory. Owner fix f1af8006c supplies CARGO_ENCODED_RUSTFLAGS with a staging-prefix remap. Full ace-herdr fast suite passed 632 tests / 2618 assertions (11203302-1638-4761-9fc0-38d9b5939f95). Independent read-only review found no confirmed defect and required real different-directory builds because host build scripts and Zig are separate paths.

Installed diagnostic gem ace-herdr 0.10.1.pre.utm98 was built from f1af8006c62b3e2829c9fed1be15fc48a5570d94. Two owner-CLI builds in /home/lab-operator/repro98-a and /home/lab-operator/repro98-longer-second-location both produced 28348632-byte artifact SHA f349835e623887463ecc17d8edf825bc4ed1d5c44716fa6929305c7b1610ef6a and provenance SHA 6954b1b1f60dce1bd63311ab7ba209f10002910f4ae5e4b191d7509735e60ae4. The first artifact no longer contained /home/lab-operator strings. Native source selection is unchanged. Verified bytes were copied to the host artifact cache; the manifest now pins the corrected builder gem and artifact. This proves the tested path-independence case, not full autonomous acceptance. A new clean E2E run is required.
