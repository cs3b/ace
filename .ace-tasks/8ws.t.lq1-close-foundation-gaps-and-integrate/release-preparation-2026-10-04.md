# Integrated wave release preparation — 2026-10-04

Captain requested integration of all wave work into main before preparation, and reserved live publication for the interactive OTP publisher. All produced source slices and blocker evidence are now integrated. No gem was published by this preparation.

ACE release versions/floors: f509facd5; final test-isolation correction: f7416cbfc. lab-config source/review integration:5ded430ac082c00c80f3cf9eda48ed1ef32a7d0d; lab-overseer program map:2ffd12638d5bbdb1613e4b0a847e20fcfa0d78f8. Domain main branches were pushed. ACE main is pushed with this report.

## Review and executed verification

Exact-head independent implementation approvals for vft, vfv, vfw and k86.3 are retained in their task folders. Domain gad.9 installer and gad.b setup-project first source slice passed adversarial review; the latter required fixing external Git path redirection and hidden dirty-index flags, plus protected Linux test fixtures. Reviewer rechecked all repairs and real host/Linux tests. gad.8 contributes a verified producer-boundary blocker record, not a delivered topology installation. Live Lab, multi-UID and domain acceptance remain open.

Release-preparation diff was independently checked by wave3_otp_services_lane: nine patch versions plus new contract0.1.0, lockfile consistency, acyclic runtime dependencies, Herdr minimum0.3.2 on every consumer, assign minimum0.63.1 on HITL/overseer, and worktree minimum0.25.1 on overseer. Initial contract changelog was finalized as0.1.0.

The versioned clean-install proof initially exposed test-order-dependent RubyGems specification-cache contamination. Root reviewed the author correction91234cfcc (integrated f7416cbfc): fresh package-cwd evaluation without resetting global activation/cache, shared by both test loaders. A real archive regression deliberately poisons the global cache and checks isolation. Author executed both opposite test orders successfully; root independently inspected all four changed files and ran final versioned proof below. No product behavior was altered by this test correction.

- Final versioned contract/graph/empty-GEM_HOME install proof: `bin/ace-test ace-hitl-contract all --config-path /Users/mc/Ps/ace/.ace-local/release/wave3/install.yml`:14tests/714assertions,zero failures/errors/skips,receipt8x3xjd.
- Final versioned installed native Herdr CLI workflow:1test/69assertions,zero failures/errors,receipt8x3xjw. Earlier independent tmux/Herdr retention receipts remain in k86.3.
- Combined listener+OTP full HITL:228tests/1212assertions,zero failures/errors,one distinct-user skip,receipt8x3x5a.
- Integrated default suite:49/51packages passed;10324tests passed,2failed,24skipped. Assign exceeded120s and unchanged SafeCapture numeric-string test exceeded0.2s. Aggregate is NOT green. Separate assignfast rerun with300s bound passed770/2822 (8x3xac); separate SafeCapture24/74 passed (8x3x8y). These follow-ups do not rewrite the aggregate verdict.
- Domain source checks: reviewed Linux installer/taskID37pass, actual Pi SDK27pass; repaired setup-project focused46pass on both host and Linux. Post-merge setup-project+provenance12pass. Full installed Lab acceptance is not claimed.

## Prepared artifacts

`.ace-bin/ace-rubygems-publish --prepare` with these ten explicit packages succeeded:10 newly built archives,0 reused,7 dependency waves. Credentials were probed without exposing values; OTP was not requested or consumed. Each archive was verified against the final source file contents, file manifest, runtime dependency metadata, version/name and gem integrity. Detailed local hashes: `.ace-local/release/wave3/artifact-verification.json`; prepared queue: `.ace-local/rubygems-publish/pending-queue.yml`.

| Wave | Gem | Version | SHA256 |
|---|---|---|---|
| 1 | ace-hitl-contract | 0.1.0 | `1457ae63db138b3b3a03c5babaf481081dcad7c6e517dfb7c27dabf050f85614` |
| 1 | ace-support-test-helpers | 0.14.7 | `748a4e5b0910f49a53c11b06367ea7a050694f5e6a12364c8d121aad99665441` |
| 2 | ace-git | 0.28.1 | `e9957ae2195e102826f5a65890e6bbd61f28f8d30dc60134535f6eec064c4966` |
| 3 | ace-git-forgejo | 0.6.1 | `a8c9cfef71a18f5297efe9cead8b6fd23ca682553f30f1a5f968bd94ffb87c1d` |
| 3 | ace-herdr | 0.3.2 | `d08a4d870b88941462c6dd4e76519b6b12fe96ed7a29ca06bf34bcae6e441466` |
| 4 | ace-demo | 0.26.1 | `618eedf271fb20f13c45e8b3293ea1a7289235a99f04321f5a817fbf87c4bfe7` |
| 5 | ace-git-worktree | 0.25.1 | `0ad724ac2a06994976110b2964c6c870e33f84cbfe54736ad8f8f2711ca8f816` |
| 6 | ace-assign | 0.63.1 | `de142d501d4e0b90ab38034bbd24716bbeab8d4dea3dfeb87601e1d039aa557b` |
| 7 | ace-hitl | 0.11.1 | `dfc837cb93127056aa1f16b4a0844694c50a931b8fbeee7ed06ccc18096e4647` |
| 7 | ace-overseer | 0.19.1 | `3d0dc0e6655e3826ff466b0a42b5e63a0ddbdfac81ab5a962fc3f0a40a625009` |

## Operator handoff

From `/Users/mc/Ps/ace`, run `.ace-bin/ace-rubygems-publish --interactive`. It uses the prepared queue and prompts silently for a fresh OTP immediately before publication. Do not modify package source or versions between preparation and publication. Use rotated credentials after the separately recorded exposure incident; this preparation does not claim that rotation occurred.

After publication, run the repository TS-MONO-001 propagation proof. Current source-build/install evidence is not a claim of RubyGems propagation, published versions, or full Lab readiness. Domain tasks retain their explicit unfinished installed gates.
