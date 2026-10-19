# Wynik wykonania — 8xg.t.sbz.4.1 (L5.2)

Data: 2026-10-18. Branch: `t-sbz-wave-2`, zakres `010b0f895..b5d2224ed`.

## Dostarczenie

Rola **reviewer** (L5.2) jako preset + workflow ace-coworker:

- `.ace-defaults/coworker/roles/reviewer.yml` (`instructions: wfi://coworker/reviewer`, szablon start_prompt, reporting hitl, errors report);
- `handbook/workflow-instructions/coworker/reviewer.wf.md` — pełna umowa 11-sekcyjna: niezależność od workera i jeden aktywny wykonawca; poprawki potwierdzonych błędów **wewnątrz jednego zlecenia reviewer** (`ace-assign add` — bez rundy overseera per poprawka); check diffu poprawki (nigdy nie zastępuje pełnej rundy); powrót do pełnych rund z regułą 3/2/10 (stwierdzona, deterministyczne wymuszenie = 4.2); eskalacja `ace-hitl create "<title>" --kind decision --question … --to` + send; nierozwiązany High/Critical nigdy nie jest sukcesem (deterministyczna podłoga: `report` odmawia wymuszonego sukcesu); forge-neutralne subjecty (`diff:<range>` / typowane `--pr` z zachowanym `--server`/`--default-server`); resume;
- `ace-review ~> 0.62` jako zależność runtime (polityka gemspecu: CLIs używane przez workflow roli);
- testy: ważność presetu + istnienie workflow + kontrakt presetu; commission dry-run dla reviewer (render szablonu, nic nie zapisane); wiersz tabeli `roles`.

## Kryteria odbioru → dowody

1. **Błąd naprawiony i sprawdzony w jednym zleceniu reviewer** — workflow (sekcje 4–6) wiąże `ace-assign add` → fix → `ace-test` → `ace-git-commit` → `resolve --resolution "Fixed in <sha>"`; mechanika istnieje od 2.1 (fixes w tym samym planie assignmentu), pokryta testami integracyjnymi L3.
2. **Brak skutecznej naprawy / decyzja produktowa → eskalacja; nigdy fałszywy sukces** — sekcje 7–8 + deterministyczna podłoga `outcome_planner` (odmowa forced success), eskalacja HITL decision question.
3. **Zgodność z kontraktem / użyteczność** — raport końcowy nazywa head kandydata, wykonane checki, per-rundowe rozliczenia (ścieżki sesji), commity poprawek, nierozwiązane findings — konsumowalne przez integratora (4.3) i future licznik rund (4.2); ADR-034 bez nowych właścicieli stanu.

## Weryfikacja

- `bin/ace-test ace-coworker all` → **258 testów, 1065 asercji, 0 failed**.
- `bin/ace-test-suite` → 52 pakiety, **12 035 testów, 0 failed**, 41 skipped (przed fixami review; coworker 258/0 po fixach).
- `bin/ace-nav resolve wfi://coworker/reviewer` → poprawna rezolucja; `bin/ace-lint`: bez nowych rodzajów ostrzeżeń.

## Review

- Runda 1 (`.ace-local/review/sessions/review-8xhx7k`): werdykt **Approve with minor changes**; 2×Medium (--delta guidance nieważne dla lokalnego subjectu; brak deklaracji ace-review w gemspec) + 2×Low (skip dla odroczonych P2; brak asercji wiersza tabeli roles) — wszystkie naprawione w `b5d2224ed` (+CHANGELOG, lockfile).
- Zanotowane follow-upy (poza zakresem, wskazane przez review): nieaktualne odniesienie „L5.5" w `ace-review/handbook/workflow-instructions/review/pr.wf.md`; unifikacja formy eskalacji `--type question` vs `--kind decision` (4.4); pre-existing wąski rescue w `config_loader.rb`.

## Commity (zakres 4.1)

`cda1e5cc9`, `b5d2224ed`.
