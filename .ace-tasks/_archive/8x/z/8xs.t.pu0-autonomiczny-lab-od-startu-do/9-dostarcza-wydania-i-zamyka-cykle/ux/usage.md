# Dostarczać wydania i zamykać cykle — usage specyfikacji

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Pełne dostarczenie

Wejście / wywołanie: Po merge nadzorca deleguje release → publish → install → verify → record.

Oczekiwany wynik: Zmiana działa pod docelowym kontem, a rekord cyklu jest w Git.

## Scenariusz 2: Opóźnione OTP

Wejście / wywołanie: Kapitan odpowiada później na pytanie publishera.

Oczekiwany wynik: Publikacja kontynuuje właściwy etap; wygasłe OTP wymaga nowego pytania, bez ujawniania wartości.

## Scenariusz 3: Awaria instalacji

Wejście / wywołanie: Przerwać instalację po udanej publikacji, następnie wznowić.

Oczekiwany wynik: Cykl pozostaje otwarty; wznowienie rozpoznaje opublikowane wersje i doprowadza do odbioru.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/9-dostarcza-wydania-i-zamyka-cykle/8xs.t.pu0.9-dostarcza-wydania-i-zamyka-cykle.s.md.

## Uściślenia review

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

## Dostęp roli przez auth

Publisher korzysta z profilu ace-lab auth z .7 i kanału przekazania właściwego dla
istniejącego narzędzia publikacji. Czasowe tokeny forge mają osobny request/revoke;
static env deklaruje wyłącznie ekspozycję procesu i nie jest dowodem remote expiry.
OTP pozostaje osobnym sekretem HITL. Przy oczekiwaniu wymagającym pause dostępu nie
przedłużać; po odpowiedzi ponownie uzyskać dozwolony lease. Dowód kryteriów 1–2 obejmuje
expiry podczas oczekiwania, wznowienie z nowym dostępem i cleanup po publish/failure.
