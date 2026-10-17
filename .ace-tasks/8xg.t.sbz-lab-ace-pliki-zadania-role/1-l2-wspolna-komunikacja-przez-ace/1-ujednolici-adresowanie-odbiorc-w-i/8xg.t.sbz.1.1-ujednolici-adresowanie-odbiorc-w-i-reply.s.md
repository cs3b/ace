---
id: 8xg.t.sbz.1.1
status: draft
priority: medium
created_at: "2026-10-17 18:54:11"
estimate: medium
dependencies: ["8xg.t.sbz.1.0"]
tags: ["lab", "lab-l2", "file-based"]
parent: 8xg.t.sbz.1
needs_review: true
bundle: {"presets": ["project"], "files": ["AGENTS.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/8xg.t.sbz-lab-ace-pliki-zadania-role-i-komunikacja.s.md", "ace-hitl/README.md", "ace-hitl/docs/usage.md", "ace-hitl-hermes/README.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/8xg.t.sbz.1-l2-wspolna-komunikacja-przez-ace-hitl-i.s.md", ".ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/1-ujednolici-adresowanie-odbiorc-w-i/ux/usage.md", ".ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md"], "commands": []}
title: "Ujednolicić adresowanie odbiorców i Reply"
---

# Ujednolicić adresowanie odbiorców i Reply

## Cel

Nadawca komunikuje się z człowiekiem i agentem przez ten sam interfejs. Ten subtask dostarcza następujący wycinek: Zachować adres odbiorcy: maszyna, folder i ID albo maszyna i panel. Odpowiedź wiąże się z pierwotną sprawą i właściwym agentem.

Reguły wspólne są częścią tej specyfikacji: [kontrakt programu](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/contract.md). Obowiązuje zatwierdzony model plikowy; stare materiały są źródłem kontekstu, nie nakazem zachowania ich architektury.

## Zachowanie i interfejs

ace-hitl: raport lub prośba o odpowiedź, skonfigurowany odbiorca i adaptery, Reply do pierwotnej sprawy.

Zachować adres odbiorcy: maszyna, folder i ID albo maszyna i panel. Odpowiedź wiąże się z pierwotną sprawą i właściwym agentem.

## Kryteria odbioru

- [ ] Dwa worktree z różnymi pytaniami otrzymują swoje Reply; raport można powiązać z właściwym taskiem i assignmentem.
- [ ] Nieznany odbiorca lub niepasujące ID daje jawny błąd i nie zapisuje odpowiedzi w cudzym zadaniu.
- [ ] Wynik jest zgodny z kontraktem programu i możliwy do użycia przez następną rolę lub narzędzie.

## Plan weryfikacji

- Scenariusz pozytywny / integracyjny: Dwa worktree z różnymi pytaniami otrzymują swoje Reply; raport można powiązać z właściwym taskiem i assignmentem.
- Scenariusz błędu / niepoprawnego wejścia: Nieznany odbiorca lub niepasujące ID daje jawny błąd i nie zapisuje odpowiedzi w cudzym zadaniu.
- Zapisać rzeczywisty wynik i odnośniki do testów lub przeglądu w folderze tego taska.

Dla zmian implementacji: `bin/ace-test <zmieniony-pakiet> all`, `bin/ace-test-suite` i niezależny review przed merge; commity ograniczone do właściwych ścieżek. Dla samych instrukcji: weryfikacja rozwiązywania workflow, kompletności i zgodności scenariuszy. Poniższe scenariusze są wymaganiami odbioru, nie deklaracją wykonanych testów.

## Zależności i granice

[L2.1 / 8xg.t.sbz.1.0](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/1-l2-wspolna-komunikacja-przez-ace/0-obs-u-y-raporty-oraz/8xg.t.sbz.1.0-obs-u-y-raporty-oraz-pro-by.s.md)

Poprzednik oznacza odebrany i zintegrowany wynik; gotowy PR nie zastępuje merge. [Fale pracy i zasady integracji](.ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/execution-order.md).

To zależności implementacyjne backlogu; nie tworzą runtime'owej kolejki _overseer.
Status `draft`: specyfikacja zatwierdzona co do kierunku, do późniejszego review gotowości i planowania wykonania.
Rozmiar orientacyjny: medium. Nie otwierać osobnej usługi lub magazynu stanu dla tej funkcji.

## Przejęty zakres i materiały

- [8xg.t.qn6](.ace-tasks/_archive/8x/x/8xg.t.qn6-python-ruby-migration-file-based/8xg.t.qn6-python-ruby-migration-file-based-lab-zero.s.md)

Zachować przydatny kod, worktree i dowody z poprzednich zadań. Nie oznaczać ich ponownie jako wykonanych bez sprawdzenia zakresu; nie odtwarzać odrzuconych mechanizmów starego laba.
