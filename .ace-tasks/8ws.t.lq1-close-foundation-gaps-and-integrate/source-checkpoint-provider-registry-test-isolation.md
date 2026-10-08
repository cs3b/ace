# Provider registry test isolation

Base `6a6a36cbd`; isolated `codex/service-merge-registry-fixture`. Tests only; no product/provider fallback, registry API, configuration, assertion, native probe or external call changes. Independent review is required before integration.

## Analysis and fix decision

Root failure `c2cad9a3`: six `ServiceMergeTest` cases fail with unknown github/forgejo providers instead of reaching their actual provider/CLI assertions. Category **test infrastructure**. Confidence high.

Provider packages register once at Ruby require time. `ProvidersRegistryTest#teardown` and `PullRequestLifecycleTest#with_test_providers` destructively reset process-wide registrations. `ServiceMergeTest` requires actual provider packages during file load; requiring already loaded Ruby libraries cannot recreate the erased registrations. Normal split target execution can conceal the leak. No evidence warrants a production fallback or weakening missing-provider behavior.

Chosen fix target: the destructive test fixtures and shared `AceGitTestCase` helpers. Capture original registration and configured-loader maps under the registry's existing mutex, then restore both exact original maps on scope exit. Registry reset behavior remains explicitly tested; fake provider classes are removed at teardown without erasing already loaded real packages. Keep actual ServiceMerge adapters and all business assertions unchanged. Do not touch runtime Providers registration/loading policy or introduce a provider substitute.

Disconfirming check: same-seed single-batch package execution still fails or actual adapter/CLI assertions stop being exercised after restoration.

## Executed verification

Explicit local runner configuration at `.ace-local/test/git-registry-seed.yml` supplies hermetic `environment.overrides.SEED: "24560"`. Raw child output confirms seed24560 before and after; merely passing an unrecognized CLI seed flag is not used.

- Initial default split-target diagnostic `git/8fd3886f-5b3c-4c55-90b6-6784eba1e79c` passed but did not reproduce the retained single-batch mode, so it did not disconfirm the leak.
- Corrected baseline `git/15c18a8a-c69a-4cd6-8607-3d726bad2b1a`: actual single-batch571 tests/1427 assertions, same four failures/two errors and seed24560 as root evidence.
- Focused registry/lifecycle/actual-ServiceMerge composition `git/e458f044-23f8-483b-b315-408678d8077c`: PASS36/304, seed24560, single batch. This preserves actual real-adapter mutations/refusals and exact bounded evidence tests.
- Complete default-fast package selection in retained single-batch mode `git/4095b43a-e7ce-4aa1-8757-a6f2ffbc8fa6`: PASS571/1624, seed24560. Additional assertions are reached because the six original cases now reach their intended paths. No test is removed or skipped.

All handles are terminal. This repairs the classified package-suite failure only; other suite package failures remain separately owned. No source task criterion or installed acceptance is closed by this checkpoint.

## Independent integration review

Root reviewed frozen `5aa4c8567` against the actual provider registry, both destructive fixtures and retained before/after evidence: APPROVE. The fixture restores both process-wide maps without changing provider resolution or weakening assertions. Integrated as `a9b3a1d9b`.

Main verification: `../bin/ace-test fast --run-in-single-batch --config /Users/mc/.codex/worktrees/service-merge-registry-fixture/ace/.ace-local/test/git-registry-seed.yml` from `ace-git`, with seed24560: PASS571/1624, zero failures/errors. Receipt `.ace-local/test/reports/git/48e12185-1cc0-4f9f-a982-15ca8c7f34ad/`. This is package verification, not final monorepo or installed Lab acceptance.
