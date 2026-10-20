---
id: 8xg.t.sbz.9.2
status: in-progress
priority: medium
created_at: "2026-10-17 18:54:30"
estimate: medium
dependencies: [8xg.t.sbz.9.1]
tags: [lab, lab-l10, file-based]
parent: 8xg.t.sbz.9
needs_review: true
bundle:
  presets: [project]
  files: [AGENTS.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md, ace-lab/README.md, ace-handbook/handbook/skills/as-release/SKILL.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/8xg.t.sbz.9-l10-wydanie-gemow-i-odbior-nowego-laba.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md, .ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md, .ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/2-sprawdzi-wie-y-lab-z/ux/usage.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md]
  commands: []
title: Sprawdzić świeży lab z RubyGems
---

# Sprawdzić świeży lab z RubyGems

## Cel

Publicznie wydany zestaw instaluje się i wykonuje pełny proces w nowym labie. Ten subtask dostarcza następujący wycinek: W nowym środowisku użyć wyłącznie wydanych gemów: gem install ace-lab → ace-lab install → ace-lab project add → pełna sekwencja zadania → statusy.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

gem install ace-lab → ace-lab install → ace-lab project add → sekwencja zadania → ace-overseer status / ace-lab status / ace-herdr status.

W nowym środowisku użyć wyłącznie wydanych gemów: gem install ace-lab → ace-lab install → ace-lab project add → pełna sekwencja zadania → statusy.

## Kryteria odbioru

- [ ] Potwierdzone wersje i ścieżki pochodzą z RubyGems, a cały proces działa bez checkoutowych binstubów i lokalnych override.
- [ ] Nieopublikowana zależność, niegotowa instalacja albo nieukończone zadanie oznaczają niezaliczony odbiór, nie przejście na źródła lokalne.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Potwierdzone wersje i ścieżki pochodzą z RubyGems, a cały proces działa bez checkoutowych binstubów i lokalnych override.
- Scenariusz błędu / niepoprawnego wejścia: Nieopublikowana zależność, niegotowa instalacja albo nieukończone zadanie oznaczają niezaliczony odbiór, nie przejście na źródła lokalne.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L10.2 / 8xg.t.sbz.9.1](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/1-opublikowa-gemy-w-kolejno-ci/8xg.t.sbz.9.1-opublikowa-gemy-w-kolejno-ci-zale-no.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)
- [8xg.t.qn6.5](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/5-ace-lab-install-complete-new/8xg.t.qn6.5-ace-lab-install-complete-new-lab-setup.s.md)
- [8xa.t.h8x](.ace-tasks/_archive/8x/w/8xa.t.h8x-deliver-project-specific-supervision-workflows/8xa.t.h8x-deliver-project-specific-supervision-workflows-and.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.

## Authorized installed-toolchain slice (2026-10-20)

Captain authorizes `ACE_TOOLCHAIN=installed` with default `auto` retaining source development. Existing project checkout remains domain/task/worktree data; installed mode must not select its binstubs, path gems, generic skills/workflows or navigation source registrations. Missing installed dependencies fail closed. Launch/reuse/resume must preserve the mode and expose effective executable/document origins. Tests use poisoned project binstubs, Gemfile and workflow definitions, and assert auto behavior remains unchanged. This implements the source prerequisite of this acceptance task; published installation and two-overseer/Telegram acceptance remain separate and unpassed. Existing VM, user-owned configuration and root-free execution are the current acceptance scope.

Observed before correction: coworker prefers project binstubs; Assign discovers package workflow sources; `ace-nav` executable unconditionally activates Bundler from project cwd. Shared selection belongs ace-support-cli with consumers in nav/Assign/coworker/Herdr, not duplicate per-project launch logic. Task CLI shorthand `sbz.9.2` was unresolved with no mutation; full tool-minted ID succeeded.

Test setup friction: first `ace-test ace-support-cli` ran zero tests because hermetic child execution dropped external BUNDLE_PATH and found no development gems. Reuse the existing completed bundle through this isolated worktree local vendor path; no global configuration or package change.

Validation observations: real poisoned child environment exposed inherited `BUNDLER_SETUP`; it is now cleared alongside Bundler/Ruby injection and covered by the subprocess regression. Initial new Assign test incorrectly called private readers; corrected the test, 16 tests/42 assertions pass. Broad Herdr fast suite stopped at existing context-lifetime fixture (`context service epoch is unavailable`, 204 tests, 1 error); baseline comparison is required before calling this unrelated. No installed acceptance claimed.

### Source-slice validation (not installed acceptance)

Public RubyGems metadata read on 2026-10-20 confirmed existing versions support-cli 0.6.9, support-nav 0.28.7, assign 0.73.0, coworker 0.6.0, overseer 0.25.0, herdr 0.8.0. Candidate patch versions are respectively 0.6.10, 0.28.8, 0.73.1, 0.6.1, 0.25.1, 0.8.1 with explicit dependency floors. Publication/install remain pending.

Executed `bin/ace-test` against the isolated source tree, using the completed development bundle; summaries below are raw final result lines:

```text
ace-test ace-support-cli
✅ 67 tests, 236 assertions, 0 failures, 0 errors
ace-test ace-support-nav
✅ 140 tests, 444 assertions, 0 failures, 0 errors
ace-test ace-coworker
✅ 396 tests, 1860 assertions, 0 failures, 0 errors
ace-test ace-overseer
✅ 362 tests, 1600 assertions, 0 failures, 0 errors
ace-test ace-assign test/fast/molecules/runtime_control_surface_runner_test.rb test/fast/molecules/skill_assign_source_resolver_test.rb
✅ 28 tests, 92 assertions, 0 failures, 0 errors
ace-test ace-herdr test/fast/organisms/dispatcher_test.rb test/fast/organisms/control_surface_test.rb test/fast/organisms/deliverer_test.rb
✅ 90 tests, 292 assertions, 0 failures, 0 errors
```

Full Herdr fast was attempted: 204 tests, 667 assertions, 0 failures, 1 error. The exact `InboxContextLifetimeTest#test_full_verified_installation_and_exact_observed_owner_create_one_immutable_epoch` error `context service epoch is unavailable` reproduced on unchanged base `234f6f36f9603f875665c3fca10719fe50c5fd22` (2 tests, 18 assertions, 1 error). This is not a full-suite green claim.

Task provenance gate (host repository):
```text
python3 -m unittest tests.test_task_ids
.
----------------------------------------------------------------------
Ran 1 test in 0.001s

OK
```
ACE `ace-task doctor` exit 0: Tasks scanned: 860; Folders checked: 31; Warnings (509); Health Score: 0/100 (Poor). Clean base has the same 509 warnings/0 health; no broad ledger cleanup included. `git diff --check` passed.

Independent R1 rejected candidate f9771808: actual installed six-gem export resolved packaged Nav workflow sources, but Assign discarded those external gem-default paths in `external_implicit_source?`, leaving no workflow/skill paths. Negative poison-only tests missed the positive installed discovery contract. Correct this shared filter and add a real installed-gem fixture covering both workflow rendering and skill discovery before renewed review.

R1 correction: installed gem-default sources are accepted by Assign after Nav has confined them to installed gem directories; auto's external-source rule is unchanged. New filesystem regression covers positive installed workflow rendering and assign-capable skill discovery outside the project. Focused Assign result: 29 tests, 96 assertions, 0 failures, 0 errors. Also built/installed the corrected ace-assign 0.73.1 into a separate temporary gem home and executed against the independent review's installed dependency tree (no source load path): loaded-closure verification passed, `wfi://coworker/worker` resolved inside installed ace-coworker 0.6.1, and 10 assign-capable packaged skills were discovered. This is local built-gem evidence, not published Lab acceptance.
