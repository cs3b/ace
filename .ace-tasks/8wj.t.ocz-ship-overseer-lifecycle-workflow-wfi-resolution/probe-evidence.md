# Installed-consumer probe evidence — task 8wj.t.ocz

Date: 2026-09-28 · Environment: macOS (darwin 25.6.0, arm64), Ruby 3.4.8 (mise), RubyGems bundled with 3.4.8.

Scope: local verification only. This does not claim Lab deployment or a published release; changed packaged content is recorded under `ace-overseer/CHANGELOG.md` `[Unreleased]` with no version bump (no release prepared in this pass).

## Built package (STEP-02)

`ace-overseer` built from the task worktree (`8wj-t-ocz-overseer-wfi-packaging` @ f062edfcf):

- Package version: **0.16.0** (unchanged; workflow contract change recorded as Unreleased).
- Archive inspection (tar reader over `data.tar.gz`): 45 data entries; both required payload paths present:
  - `handbook/workflow-instructions/overseer.wf.md`
  - `.ace-defaults/nav/protocols/wfi-sources/ace-overseer.yml`
- `ace-overseer/test/fast/molecules/gem_packaging_test.rb` locks both payload paths in the built archive and the gemspec globs (executed in suite).

## Consumer closure installed (STEP-03)

All artifacts built from the same worktree source and installed via the RubyGems API (`Gem::Installer.at`, fresh `install_dir`, no docs) into a disposable consumer `GEM_HOME`:

| Gem | Version |
|-----|---------|
| ace-support-config | 0.18.2 |
| ace-support-fs | 0.3.4 |
| ace-support-cli | 0.6.8 |
| ace-support-core | 0.32.0 |
| ace-git | 0.24.0 |
| ace-git-github | 0.1.2 |
| ace-compressor | 0.25.5 |
| ace-support-nav | 0.28.7 |
| ace-bundle | 0.44.1 |
| ace-overseer | 0.16.0 (installed `--ignore-dependencies`: the probe reads its payload only; deeper runtime closure would pull external gems) |

Isolation: fresh `GEM_HOME`/`GEM_PATH`/`GEM_SPEC_CACHE`, sanitized `HOME`, unrelated cwd under the consumer temp root (canonicalized via `File.realpath`), `unsetenv_others` spawn so no `RUBYOPT`/`BUNDLE_*`/project config leaks in. Executed both as a manual probe and as permanent suite coverage (`test/fast/molecules/installed_workflow_resolution_test.rb`).

## Positive probes (SC1)

From the unrelated consumer cwd, invoking only installed executables:

- `ace-nav resolve wfi://overseer` → rc=0, prints `/…/consumer-root/gems/gems/ace-overseer-0.16.0/handbook/workflow-instructions/overseer.wf.md` — the **installed gem payload**, no monorepo path involved.
- `ace-bundle wfi://overseer` → rc=0, payload served from the installed gem (`FILE| …/ace-overseer-0.16.0/handbook/workflow-instructions/overseer.wf.md`) and includes the lifecycle contracts (`prune_safety_non_negotiable_executed_check`, `status_truth_non_negotiable_executed_check`).
- Strengthened-content spot check on the bundle payload: 4 marker hits for the new proof model (`range-diff`, `no-active-writer`, `merge-base --is-ancestor <dest-ref>`, matching-subject warning); **0** occurrences of the removed subject-only `log --all --grep` proof.

## Negative masking fixture (SC2)

After removing only the installed `.ace-defaults/nav/protocols/wfi-sources/ace-overseer.yml` (workflow file retained, no project-local `.ace` registration exists in the sanitized cwd):

- `ace-nav resolve wfi://overseer` → rc=1, `Resource not found: wfi://overseer`.
- `ace-bundle wfi://overseer` → rc=1, `Failed to resolve protocol: wfi://overseer`.

This proves the probe detects masking: a project-local or user-level registration cannot hide an absent gem registration, because with the packaged registration gone both commands fail despite the workflow file being present.

## Executed tests (SC3)

`ace-test ace-overseer all` (worktree, after all changes): **177 tests, 688 assertions, 0 failures, 0 errors** (4.2s), including:

- `gem_packaging_test` (archive payload, pre-existing, retained)
- `installed_workflow_resolution_test` (new: clean-consumer positive + negative masking, 17 assertions)
- `overseer_workflow_contract_test` (updated: verified destination + tree/artifact or patch equivalence, no-active-writer gate, ambiguity preservation, explicit rejection of subject-only `log --all --grep` / "subject-level search" proofs)

Tested gem versions are the worktree source versions listed above. The suite installs the closure itself, so evidence is reproducible from a clean checkout.
