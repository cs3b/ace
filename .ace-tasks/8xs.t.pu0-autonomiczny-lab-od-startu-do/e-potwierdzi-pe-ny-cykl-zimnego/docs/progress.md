# Postęp 8xs.t.pu0.e — pełny cykl od zimnego startu (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398). WYKONANIE scenariusza na
zainstalowanym labie = finalny odbiór całej rodziny, odroczony na koniec
programu (decyzja Kapitana: gem release i testing na labie na samym końcu).

## Zrealizowane w źródłach

**`wfi://overseer/cold-cycle-acceptance`** — powtarzalny scenariusz
odbioru, żyjący u istniejącego właściciela (ace-overseer handbook), bez
osobnego serwisu testowego:

- **Preconditions jawne** (nie ukryta autonomia): świeży runtime z
  OPUBLIKOWANEGO zestawu (core + projekcja wake + 3 pluginy auth z .7);
  brak zależności/runnera/projekcji = readiness failure, nigdy fallback do
  binstubów checkoutu (ACE_TOOLCHAIN=installed); install+verify
  skonwergowane pod kontami docelowymi; ≥2 skonfigurowane projekty.
- **Run**: start laba → jawny cel z kryteriami (jedna wiadomość; dalej
  operator odpowiada WYŁĄCZNIE decyzje/OTP) → nadzorca przyjmuje cel,
  deleguje spec/planning istniejącym rolom (dowód delegacji:
  assignmenty/role, nie praca nadzorcy) → worker/reviewer/integrator na
  lease'ach auth (principal/scope/use_until/expiry_mode; tożsamość reviewera
  ≠ autor) → HITL z oznaczoną sugestią Second Captaina w TEJ samej sprawie
  przed odpowiedzią; OTP jako --secret → merge przez gate (HEAD-bound
  tests/review/approval + expected-head adaptera) → publish (resume wg
  wersja+digest) → install → odbiór runtime pod kontem docelowym →
  record-only PR (wfi://release/cycle-record); task done dopiero po
  odbiorze i rekordzie.
- **Jedna oś tożsamości** zapisu odbioru: task → assignmenty/role + lease'e
  → sprawa HITL (sugestia/decyzja/lekcja) → PR+HEAD → review/tests (head,
  komendy, wyniki) → wersje+digesty publish → ścieżki/wersje zainstalowane
  + wynik pod kontem docelowym → record PR. Bez fabrykowanych końcówek.
- **Przebieg negatywny (obowiązkowy)**: po publish odmówić jeden wymagany
  krok instalacji → brak done/ready/rekordu, konkretny brak + właściwy
  adresat blokady, zdrowe części raportują; po usunięciu przyczyny wznowić
  TEN SAM cykl bez ponownej publikacji.
- **Ponowny start po sukcesie**: bez re-delegacji, re-publikacji,
  ponownego zastosowania zamkniętej decyzji; replay zastosowanej decyzji
  odrzucony przez lifecycle (.6).
- Dokumentacja usage (sekcja Cold-cycle acceptance) + CHANGELOG.

## Dowody (źródłowe)

- `bin/ace-test ace-overseer` — 399 testów, 0 fail (workflow w tree).
- Komponenty scenariusza pokryte testami jednostkowymi w krokach .0–.d
  (installer/verify, start project+lab, observe lokalne+zdalne, watch/eyes,
  reply/lifecycle/sweep/suggest/lesson/history, auth z odmowami, gate z
  HEAD-binding, mirror-sync, record) — pełny wykaz w progressach kroków.

## Granice / odroczone (finalny odbiór programu)

- Wykonanie scenariusza na labie z opublikowanymi gemami + zebranie dowodów
  jednej osi tożsamości; przebieg negatywny; idempotentny re-run.
- Publikacja gemów rodzinnych przed scenariuszem (as-release workflow).
