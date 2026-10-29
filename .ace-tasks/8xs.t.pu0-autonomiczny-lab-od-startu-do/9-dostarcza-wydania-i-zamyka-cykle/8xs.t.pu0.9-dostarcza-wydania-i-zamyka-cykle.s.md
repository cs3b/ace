---
id: 8xs.t.pu0.9
status: pending
priority: medium
created_at: "2026-10-29 17:13:44"
estimate: large
dependencies: [8xs.t.pu0.8]
tags: []
parent: 8xs.t.pu0
needs_review: false
bundle:
  presets: [project]
  files: [AGENTS.md, docs/lab-flow.md, docs/tools.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md, ace-overseer/docs/usage.md, ace-lab/docs/usage.md, ace-hitl/docs/usage.md, .ace-handbook/workflow-instructions/release/rubygems-publish.wf.md, .ace-handbook/workflow-instructions/release/local.wf.md, .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/8xg.t.sbz.9-l10-wydanie-gemow-i-odbior-nowego-laba.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/8-prowadzi-zadania-przez-review-i/8xs.t.pu0.8-prowadzi-zadania-przez-review-i-merge.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/9-dostarcza-wydania-i-zamyka-cykle/ux/usage.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/7-delegowa-zadania-z-w-a/8xs.t.pu0.7-delegowa-zadania-z-w-a-ciwymi-uprawnieniami.s.md, .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/auth-mechanics.md]
  commands: []
---

# Dostarczać wydania i zamykać cykle

## Cel

Doprowadzić zmergowaną zmianę do potwierdzonego runtime i trwałego zamknięcia cyklu.

## Specyfikacja zachowania

Krok 10/16. Typ: bezpośredni podtask. Rozmiar orientacyjny: large.
Wejście: konfiguracja i jawne warunki poniżej; po odbiorze poprzednika, jeśli istnieje. Wyjście: obserwowalny rezultat i dowody określone w tym wycinku.

- Nadzorca deleguje release inventory/bumps/build/publish zgodnie z istniejącymi workflow projektu.
- Publisher obsługuje OTP przez HITL; sekret klucza pozostaje w dozwolonym wrapperze/env. Ask kończy turę, oczekiwanie nie jest pętlą modelu.
- Po publikacji instalacja uzgadnia runtime i rozszerzenia oraz wykonuje odbiór pod docelowym kontem.
- Rekord cyklu trafia do .ace-tasks/_records przez właściwy reviewowany PR. Cykl pozostaje otwarty do integracji rekordu; jego commit nie uruchamia kolejnego wydania bez zmian produktu.
- Przerwanie zachowuje znany etap i rzeczywiste wersje. Wznowienie rozpoznaje już opublikowane artefakty i nie udaje zakończenia częściowo wdrożonego cyklu.

## Kontrakt interfejsu i scenariusze

| Scenariusz | Wejście / wywołanie | Oczekiwany wynik |
|---|---|---|
| Pełne dostarczenie | Po merge nadzorca deleguje release → publish → install → verify → record | Zmiana działa pod docelowym kontem, a rekord cyklu jest w Git. |
| Opóźnione OTP | Kapitan odpowiada później na pytanie publishera | Publikacja kontynuuje właściwy etap; wygasłe OTP wymaga nowego pytania, bez ujawniania wartości. |
| Awaria instalacji | Przerwać instalację po udanej publikacji, następnie wznowić | Cykl pozostaje otwarty; wznowienie rozpoznaje opublikowane wersje i doprowadza do odbioru. |

Nazwy poleceń opisują interfejs docelowy. W repo używać bin/ace-*; w labie z ACE_TOOLCHAIN=installed używać instalowanych CLI i instrukcji. Nie dodawać flag ani warstw pośrednich wyłącznie na podstawie przykładów.

## Kryteria akceptacji

- [ ] Raport pokazuje osobno źródła, integrację, publikację, instalację i wynik runtime.
- [ ] Opóźnione OTP wznawia poprawny krok publikacji bez ręcznego relay i bez tokenów podczas oczekiwania.
- [ ] Zadanie jest zakończone dopiero po udanym odbiorze i zintegrowanym rekordzie; awaria pozostawia wznowialną blokadę.
- [ ] Zachowane są właściciele stanu i reguły wspólnego briefu.
- [ ] Wynik ma dowód producent → konsument oraz jawny przypadek błędu; dokumentacja odpowiada faktycznemu zachowaniu.

## Plan weryfikacji

- Kontrola komponentowa: sprawdzić rozróżnienia stanów i warunki błędu wymienione w kontrakcie; dla operacji/dokumentacji sprawdzić rzeczywiste wejścia i dowody.
- Integracja/E2E: przejść trzy scenariusze tabeli przez właściwych właścicieli i docelowe konta; nie zastępować odbioru samą rejestracją lub statusem wysłania.
- Regresja: zachować naprawy wskazane w mapie problemów, zbadać ponowienie i brak niepożądanych skutków.
- Odbiór runtime: gdy zmienia się zachowanie produktu, oddzielnie wykazać kod, integrację, publikację, instalację i wynik pod kontem wykonawcy.

Planowane komendy sprawdzające (nie wykonane podczas draftowania):

- bin/ace-test ace-overseer
- bin/ace-test ace-lab
- bin/ace-test ace-hitl
- bin/ace-test-suite zgodnie z workflow weryfikacji dla zmienionych pakietów.

## Kontekst i zależności

Bundle w frontmatter jest kompletny dla świeżej sesji; kontekst rodzica nie jest dziedziczony.
Poprzednik: 8xs.t.pu0.8.
Następny krok: 8xs.t.pu0.a.
Starsze zakresy do wykorzystania: 8xg.t.sbz.9.

## Decyzje i granice

Review 2026-10-29: źródła, decyzje i sprawdzalne granice są zapisane poniżej oraz w docs/review-source-map.md tej rodziny. Brak pytań wymagających decyzji człowieka dla tego wycinka.
Nie tworzyć wnuków, nowej kolejki ani magazynu stanu. Nie implementować innych kroków pod pozorem zależności; ujawnioną zmianę krytycznej ścieżki zapisać w tej rodzinie.

## Rezultaty do dostarczenia

- Zachowanie i dokumentacja opisane powyżej, z dowodami akceptacji oraz ograniczeniami.
- Aktualny wynik pracy w tasku/assignmencie; brak sekretów i fabrykowanych identyfikatorów.

## Ustalenia review i kontrakt wykonania — 2026-10-29

Publisher jest osobną rolą coworkera z pakietowym workflow; source-work na hoście,
lab instaluje opublikowane artefakty. Plan release korzysta z istniejącego inventory,
wersjonowania i kolejki publikacji. Nie zamykać taska przy merge, jeśli wymaga wdrożenia.
Stan bieżącego cyklu żyje w istniejącym tasku/assignmencie; `_records` to końcowy
reviewowany zapis dowodów, nie kolejka sterująca ani kopia żywego stanu.

Sekret OTP konsumuje wykonawca poza modelem przez istniejący wrapper; ask/wake pokazuje
referencję. Nie ustanawiać terminu odpowiedzi Kapitana. Odrzucenie/wygasłe OTP wymaga
nowej sprawy, bez replay starej wartości. Przerwana publikacja sprawdza repozytorium
artefaktów: zgodna wersja i digest oznacza już opublikowane, konflikt wersji/digestu
blokuje; nie nadpisywać wersji ani nie bumpować automatycznie jako obejście.

Rekord wskazuje task/cycle, source HEAD, review/test evidence, publish versions/digests,
runtime paths i wynik. Record-only PR przechodzi normalne review/integrację, ale nie
uruchamia release bez zmiany produktu i nie wymaga rekurencyjnego rekordu własnego merge.
Zakończenie odnotowuje task po integracji rekordu. Resume po każdym etapie weryfikuje
właściciela i wykonuje tylko brakujący etap. Konsumenci: ace-coworker, ace-overseer,
ace-lab, ace-hitl/ace-wake, workflow release i używany publisher projektu.

### Integracja ace-lab auth po decyzji Kapitana

Publisher korzysta z profilu ace-lab auth z .7 i kanału przekazania właściwego dla
istniejącego narzędzia publikacji. Czasowe tokeny forge mają osobny request/revoke;
static env deklaruje wyłącznie ekspozycję procesu i nie jest dowodem remote expiry.
OTP pozostaje osobnym sekretem HITL. Przy oczekiwaniu wymagającym pause dostępu nie
przedłużać; po odpowiedzi ponownie uzyskać dozwolony lease. Dowód kryteriów 1–2 obejmuje
expiry podczas oczekiwania, wznowienie z nowym dostępem i cleanup po publish/failure.

### Mapa kryteriów do dowodów

| Kryterium | Wymagany dowód |
|---|---|
| 1 | Merge → delegated publisher → registry version/digest → install/activation → runtime acceptance → reviewed record PR; record-only merge nie publikuje ponownie. |
| 2 | Opóźnione OTP, wygasłe OTP i człowiek odpowiadający przed arm: poprawny etap, zero idle model calls i brak wartości w prompt/log/history uczenia. |
| 3 | Crash po publish, w install i po merge rekordu; resume nie powiela publish; mismatch digest i nieudany verify pozostawiają cykl otwarty. |
| 4–5 | Kontrola właścicieli zapisów i diffu, wykonana ścieżka producent → konsument, negatywna próba oraz aktualne usage; reguły w review-source-map.md. |

## Referencje

- AGENTS.md
- docs/lab-flow.md
- docs/tools.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/brief.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/context.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/session-problems.md
- ace-overseer/docs/usage.md
- ace-lab/docs/usage.md
- ace-hitl/docs/usage.md
- .ace-handbook/workflow-instructions/release/rubygems-publish.wf.md
- .ace-handbook/workflow-instructions/release/local.wf.md
- .ace-tasks/8xg.t.sbz-lab-ace-pliki-zadania-role/9-l10-wydanie-gemow-i-odbior/8xg.t.sbz.9-l10-wydanie-gemow-i-odbior-nowego-laba.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/8-prowadzi-zadania-przez-review-i/8xs.t.pu0.8-prowadzi-zadania-przez-review-i-merge.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/9-dostarcza-wydania-i-zamyka-cykle/ux/usage.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/review-source-map.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/sources/standing-wake-af68f8fc1.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/7-delegowa-zadania-z-w-a/8xs.t.pu0.7-delegowa-zadania-z-w-a-ciwymi-uprawnieniami.s.md
- .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/docs/auth-mechanics.md
