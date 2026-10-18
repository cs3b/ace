---
id: 8xh0wk
title: pr379-spec-review-architecture-overengineering
type: self-review
tags: [architecture, review, specification, simplicity, lab]
created_at: "2026-10-18 00:36:12"
status: active
---

# PR #379: review poprawiało mechanizm, którego nie powinniśmy budować

Date: 2026-10-18 (Atlantic/Canary)
Context: specyfikacja laba ACE, kolejne review PR #379 i korekta granic odpowiedzialności po uwagach użytkownika.
Author: Codex — self-review agenta prowadzącego rozmowę.
Type: Conversation Analysis / Self-Review.

## What Went Well

- Użytkownik konsekwentnie przywracał prosty model: istniejące zadania, assignmenty, worktree, pliki i komunikacja. Nie potrzebujemy odwzorowania starego silnika Pythona, dodatkowego journala ani pośrednika zarządzającego zadaniami.
- Review na konkretnych SHA, niezależne zakresy i rzeczywiste reprodukcje wykryły błędy, których nie pokrywała suita: wyjście prywatnych tasków do trackowanego archiwum, zależność guarda od cwd, brak baseline w prune oraz niedostosowany test zależności HITL.
- Trzecia runda niezależnie uruchomiła całą suitę na bb87edef4: 51 pakietów, 11 621 testów, 38 279 asercji, zero failures, 41 skipped. Osobna reprodukcja wykazała cztery błędy sortowania zależności w dwunastu przypadkach. Dowody techniczne były użyteczne, choć nie dowodziły sensowności projektu.
- Audyt rozszerzono poza ace-task: potwierdzono nowe wyjątki nazwowe w ace-assign i ace-git-worktree oraz odróżniono je od starszych reguł HITL/runtime. Nie uznano samej nazwy adaptera za powód usuwania transportu.

## What Could Be Improved

### Specyfikacja przeniosła mechanizmy zamiast intencji

Początkowy plan traktował journal, listenery i authority jako rdzeń nowego laba. Użytkownik chciał złożenia istniejących narzędzi ACE, z jednym właścicielem zadań zarządczych i sekwencyjną pracą ról. Nie wykonaliśmy wystarczająco wcześnie rozpoznania istniejących możliwości i minimalnego przepływu end-to-end. Zabezpieczaliśmy hipotetyczne konflikty zamiast respektować ustaloną odpowiedzialność overseera.

Specyfikacje następnie utrwaliły nazwy i szczegóły implementacyjne jako wymagania. Odwołania L1–L10 i wielopoziomowe drzewo nie odpowiadały pytaniom użytkownika o rzeczywiste ID, jednostkę pracy w worktree oraz równoległość i integrację. Plan musi pokazywać te informacje wprost; sama hierarchia tasków ich nie wyjaśnia.

### Review produkowało kolejne wyjątki

Łańcuch błędu był konkretny:

1. Zakończenie ostatniego subtaska uruchamiało istniejącą autoarchiwizację.
2. Zadania spod gitignorowanego _overseer trafiały do wspólnego, trackowanego archiwum.
3. Review potraktowało autoarchiwizację jako niepodważalne wymaganie i wskazało prywatne archiwum jako naprawę.
4. Powstały TaskScope, _overseer/_archive, wyjątki listowania, doctor i blokady commitowania.
5. Zachowanie klasyfikacji _overseer ujawniło błąd sortera. Review zaleciło dalszą obsługę prywatnego archiwum zamiast zakwestionować jego istnienie.
6. Dopiero pytania użytkownika „po co?” doprowadziły do usunięcia założenia, na którym oparto te poprawki.

To błąd rozumowania agenta prowadzącego review, nie brak jasności wymagań użytkownika. Technicznie prawdziwa diagnoza nie uzasadnia proponowanej architektury. Użytkownik już wcześniej wymagał prostoty i uniwersalności.

### Naruszono granice pakietów

- ace-task otrzymał wiedzę o nazwie folderu i roli overseera, mimo istniejącego uniwersalnego skanowania zadań.
- ace-assign i ace-git-worktree zaczęły zabraniać operacji na _overseer. Przeniesiono politykę zlecającego do narzędzi, których można używać bez overseera.
- Kolejna potencjalna nadkorekta to zakaz tworzenia assignmentu/worktree dla każdego ignorowanego zadania. Użytkownik wyraźnie to odrzucił: ignorowanie przez Git nie definiuje uprawnień do delegowania pracy.
- Pozostałe stare reguły — konto mo i redakcyjne ograniczenia odpowiedzi w HITL, zakaz słowa overseer w nazwach jednostek runtime — wymagają osobnego rozpatrzenia. Nie są nowymi regresjami dodanymi przez ten PR; nie wolno też usuwać rzeczywistych zabezpieczeń transportu tylko dlatego, że wykryto politykę roli.

### Komunikacja zacierała stan faktyczny

Używaliśmy sformułowań „prywatny cel”, „wyłączamy z archiwizacji” i „wycofujemy”, nie rozdzielając dostatecznie kodu na sprawdzonym SHA od proponowanej zmiany. Użytkownik musiał wielokrotnie pytać, co już działa i po co. Część wcześniejszych zapewnień była niepełna: samo cofnięcie prywatnego archiwum przywraca wyciek do zwykłego archiwum, nie pozostawianie tasków na miejscu.

Duże listy plików powodowały ucinanie wyników. Dodatkowy provider review długo nie zwracał raportu, a agent wielokrotnie powtarzał niezmieniony status. Trzy niezależne zakresy były już ukończone; pomocnicze wywołanie zakończono przerwaniem i prawidłowo nie zaliczono go jako sukcesu.

## Key Learnings

- Najpierw ustalić właściciela reguły. Overseer odpowiada za własne decyzje; narzędzia bazowe operują na zadaniach, plikach, Git i assignmentach.
- Przed nowym mechanizmem sprawdzić, ile celu realizują już istniejące komendy i formaty. Nazwa folderu nie jest typem zadania ani polityką bezpieczeństwa.
- Ogólna reguła musi wynikać z właściwości operacji: Git ignore może wpływać na commitowanie i automatyczne przenoszenie plików, ale nie implikuje zakazu tworzenia assignmentu.
- Test może potwierdzić wadliwą specyfikację. Sprawny kod, zielona suita i kilku reviewerów nie zastępują sprawdzenia, czy rozwiązanie jest potrzebne.
- Usunięcie niepotrzebnego mechanizmu jest pełnoprawną naprawą. Nie dokładać warstw naprawiających skutki poprzedniej warstwy.
- Review odróżnia: obserwację, wpływ, wymaganie i możliwą naprawę. Naprawa nie staje się wymaganiem tylko dlatego, że zaproponował ją reviewer.

### Review Cycle Analysis

| Head / etap | Co wykryto | Wniosek po korekcie wymagań |
|---|---|---|
| 661ec56b | Journal w lokalnym przepływie, pozostała ścieżka ordinary, błędna obietnica recovery PR, problem root z podkatalogu; doprecyzowanie miejsca zadań overseera | Uzasadnione diagnozy; wybór specjalnej obsługi _overseer nie był konieczną konsekwencją |
| e3db4bdd9 | Wyciek przy autoarchiwizacji, cwd/custom-root guard, utracony baseline prune, stary kontrakt zależności | Wyciek był prawdziwy; prywatne archiwum i dopracowywanie guarda były niewłaściwymi kierunkami naprawy |
| bb87edef4 | Cztery poprzednie poprawki działały; sorter nie rozpoznawał prywatnego archiwum dla skipped/cancelled | Reprodukcja pozostaje faktem, lecz zalecenie rozszerzenia sortera zostało wycofane: usuwamy prywatne archiwum |
| Dyskusja architektury po review | Wyjątki nazwowe w ace-task, ace-assign i ace-git-worktree | Użytkownik zakwestionował potrzebę mechanizmu, czego review powinno było dopilnować wcześniej |

Przy pisaniu retro dostępne były metadane sesji review-8xh075 (dry-run) i review-8xh081 (wykonanie przerwane, exit 130), obie na bb87edef4, selektor role:review-default. Nie zawierały ukończonej syntezy feedbacku. Dodatkowy delta packet mieścił się w limicie około 46k/128k, mimo że wcześniejszy pełny pakiet przekraczał limit. Nie wolno przypisywać tym sesjom czystego werdyktu ani z niepełnych danych wyliczać skuteczności modeli, odsetka false positives lub czasu zakończonego review. Delegowane zakresy dostarczyły osobne ukończone raporty.

## Action Items

### Stop Doing

- Traktować istniejący kod i rekomendacje reviewerów jako automatycznie obowiązujące wymagania.
- Dodawać do uniwersalnych pakietów wyjątki dla nazw ról, użytkowników i folderów konkretnego wdrożenia.
- Zamieniać każdą błędną decyzję orchestratora w nowy guard we wszystkich niższych warstwach.
- Proponować kolejne kolejki, scope'y, archiwa lub polityki bez wykazania potrzeby w obecnym przepływie.

### Continue Doing

- Wiązać wyniki z konkretnym SHA, reprodukować błędy, sprawdzać rzeczywiste ścieżki integracji i rozróżniać nowe zmiany od zastanego kodu.
- Zachowywać dowody nieudanych testów oraz jawnie oznaczać nieukończone review.

### Start Doing

| Działanie | Odpowiedzialność | Kryterium wykonania |
|---|---|---|
| Zastosować końcowy feedback upraszczający PR #379 | Agent implementujący PR | Brak wyjątków _overseer w ace-task/assign/git-worktree; ogólne zabezpieczenia ignorowanych ścieżek tylko tam, gdzie dotyczą operacji; testy zwykłych i ignorowanych tasków |
| Sprawdzić pozostawioną politykę HITL/runtime | Agent implementujący i niezależny reviewer | Rozdzielone reguły roli od transportu i izolacji; brak usuwania zabezpieczeń na podstawie samej nazwy |
| Przy specyfikacji podać istniejący przepływ, brakującą funkcję i właściciela każdej nowej reguły | Autor specyfikacji | Każda zmiana ma uzasadnienie względem obecnych narzędzi; brak mechanizmu dodanego tylko z przyzwyczajenia do starego systemu |
| Przed rekomendacją naprawy sprawdzić wariant usunięcia mechanizmu oraz wpływ na pozostałe pakiety | Reviewer | Feedback wyjaśnia wymagane zachowanie bez narzucania niepotrzebnej architektury |
| Plany przedstawiać przez rzeczywiste ID, jednostki worktree i zależności integracji | Autor planu | Użytkownik widzi, co można budować równolegle i co musi być wcześniej zintegrowane |
| Oznaczać wycofany feedback przy jego dalszym przekazywaniu | Agent prowadzący | Prywatne archiwum, poprawka jego sortera i guardy nazwowe nie wracają jako niezrealizowane wymagania |
| Raportować stan kodu i rekomendację osobno | Agent prowadzący | „Na SHA X działa Y; proponujemy Z; Z nie zostało jeszcze wdrożone” zamiast niejednoznacznego „wycofujemy” |

Powyższe działania implementacyjne i zmiany workflow są zaleceniami; utworzenie tej retrospektywy nie oznacza ich wykonania. Nie tworzymy nowego narzędzia ani automatycznego gate'a w odpowiedzi na tę sesję. Ulepszenia należy włączyć do istniejącej pracy nad specyfikacją i review.

## Additional Context

- PR: https://github.com/cs3b/ace/pull/379
- Ostatni sprawdzony head: bb87edef44e188ab2411d99d6077b4a07b3ee1ef. Retro nie certyfikuje późniejszych zmian.
- Lokalny raport historyczny: `.ace-wt/ace-t.unknown/.ace-local/review379/round3-bb87edef4.md`; jego zalecenie rozszerzenia sortera zostało później wycofane w rozmowie.
- Lokalna reprodukcja: `.ace-wt/ace-t.unknown/.ace-local/review379/private_archive_dependencies_test.rb` (12 przypadków, 4 failures). Ścieżki lokalne są pomocnicze; trwałe ustalenia i wyniki zawarto powyżej.
- Końcowy feedback w rozmowie zastępuje wcześniejsze zalecenia prywatnego archiwum i blokad delegowania. Nie wprowadzono tu poprawek produktu, nie zmergowano ani nie opublikowano PR.
