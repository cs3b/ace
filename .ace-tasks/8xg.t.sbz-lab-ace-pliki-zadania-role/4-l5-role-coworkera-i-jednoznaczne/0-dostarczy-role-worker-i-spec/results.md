# Wynik wykonania — 8xg.t.sbz.4.0 (L5.1)

Data: 2026-10-18. Branch: `t-sbz-wave-2`, zakres `8d2d0f09a..2ce5fd54b`.

## Dostarczenie

Role **worker** i **spec** jako konfiguracja i instrukcje ace-coworker (0.4.0 → **0.5.0**):

- presety `.ace-defaults/coworker/roles/{worker,spec}.yml` (instrukcje `wfi://coworker/<role>`, szablony `{{task}}/{{assignment}}/{{role}}/{{overseer}}`), nadpisy projektowe `.ace/coworker/roles/*.yml` (merge po nazwie pliku + walidacja name==basename);
- `ace-coworker roles` (katalog) i **`ace-coworker commission`** — prymityw rozwinięcia presetu do `.ace-local/coworker/config.yml` (kontrole tożsamości jak `start`, round-trip ConfigSchema, atomowy zapis, odmowa nadpisania bez `--force`, `--dry-run`, containment w project root);
- workflowy `handbook/workflow-instructions/coworker/{worker,spec}.wf.md` (ADR-001 self-contained): worker — nieudane wymagane testy blokują sukces (`ace-assign fail`, nigdy fałszywe done); spec — nierozstrzygnięty istotny brak wymagań → pytanie HITL do overseera, nigdy zgadywanie;
- rejestracja wfi (gem + mirror projektowy `.ace/nav/protocols/wfi-sources/ace-coworker.yml`), zależność `ace-support-nav ~> 0.28`.

**Koordynacja toru ról**: plan zakładał komendę `prepare`, ale ta nazwa została zajęta przez sibling 3.0 (planner) — prymityw zapisu konfigu roli dostarczono jako `commission`; wersja 0.5.0 zamiast 0.4.0.

## Kryteria odbioru → dowody

1. **Każda rola własny assignment + właściwy rezultat** — testy deterministyczne: round-trip preset→config→`ConfigLoader.load`; `commission --dry-run`; odmowy (unknown role/task, mismatch assignment, escape `--config`, katalog jako cel, nadpisanie bez `--force`); workflowy opisują prowadzenie assignmentu (`ace-assign`).
2. **Nieudane testy blokują worker / brak wymagań zgłasza spec** — `worker.wf.md` (fail-step rule, existing gate `report` refuses forced success), `spec.wf.md` (HITL question, poprawiona forma `ace-hitl create "<title>" ... --question`); pokryte testami preset↔handbook + instrukcje zweryfikowane w review.
3. **Zgodność z kontraktem** — ADR-034 (brak nowych właścicieli stanu; jedyny zapis: istniejący `.ace-local/coworker/config.yml`), role-agnostic (presety to domyślne, nie allowlista).

## Weryfikacja

- `bin/ace-test ace-coworker all` → **256 testów, 1036 asercji, 0 failed**.
- `bin/ace-test-suite` → 52 pakiety, **12 024 testów, 0 failed**, 41 skipped.
- `bin/ace-nav resolve wfi://coworker/worker` i `wfi://coworker/spec` → poprawna rezolucja; `bin/ace-lint` zmienionego markdown: bez nowych rodzajów ostrzeżeń.

## Review

- Runda 1 (`.ace-local/review/sessions/review-8xhwlm`): 3×Medium + 4×Low — wszystkie naprawione (`c2529d30e`, `08f79832f`, `b43b02696`, `7f3981a83`); feedback `8xhwoots`–`8xhwooty` resolved `fixed`.
- Runda 2 (`review-8xhwsy`): 2×Medium (Psych::SyntaxError crash; `spec.wf.md` bez tytułu w `ace-hitl create`) + Low (single-pass render) — naprawione w `4df802d1f`.
- Runda 3 (`review-8xhwz9`): 3×Medium (dead PLACEHOLDERS, rescue Psych::Exception, CHANGELOG Unreleased) — naprawione w `2ce5fd54b`. Zanotowany pre-existing gap: `config_loader.rb` ma identyczny wąski rescue (follow-up).

## Commity (zakres 4.0)

`d0a3801bd`, `d86c7e0a9`, `c2529d30e`, `08f79832f`, `b43b02696`, `7f3981a83`, `4df802d1f`, `2ce5fd54b`.
