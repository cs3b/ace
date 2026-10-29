# Proponować odpowiedzi jako Second Captain — usage specyfikacji

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Sugestia przed decyzją

Wejście / wywołanie: Nadzorca kieruje pytanie do Kapitana i rolę doradczą do Second Captaina.

Oczekiwany wynik: W tej samej sprawie pojawia się oznaczona propozycja z uzasadnieniem.

## Scenariusz 2: Brak doradcy

Wejście / wywołanie: Wyłączyć dostępność coworkera doradczego i zadać pytanie.

Oczekiwany wynik: Pytanie dociera do Kapitana bez oczekiwania na sugestię.

## Scenariusz 3: Człowiek szybszy niż agent

Wejście / wywołanie: Kapitan odpowiada przed zakończeniem pracy doradcy.

Oczekiwany wynik: Decyzja człowieka pozostaje obowiązująca; brak drugiego zatwierdzenia.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/b-proponowa-odpowiedzi-jako-second-captain/8xs.t.pu0.b-proponowa-odpowiedzi-jako-second-captain.s.md.

## Uściślenia review

Nowy preset roli second-captain w ace-coworker ma tylko prawa doradcze; jest
delegowany dla konkretnej sprawy/revision. Typ zapisu w ace-hitl jest jawnie suggestion,
z autorem, case-id/revision, propozycją, uzasadnieniem i referencjami. To nie Answer ani
report zwalniający gate. Aktualizacja/odpowiedź nie może usunąć sugestii (obecny edytor
Answer zastępuje końcówkę pliku). API/CLI właściciela ma zapisywać odrębne sekcje atomowo.

Trigger: nowe nietajne pytanie do Kapitana, po rozpoczęciu jego dostawy. Brak doradcy
jest advisory i nie zatrzymuje pytania. Jedna propozycja na case/revision, identyczne
powtórzenie jest no-op. Wysłanie sugestii przez Hermes odpowiada w wątku dokładnego
message-id pytania; gdy brak potwierdzenia pytania, nie wysyła w przypadkowy wątek.
Gdy człowiek już odpowiedział, porzucić spóźnioną propozycję i oznaczyć zakończenie
assignmentu doradcy bez nowego powiadomienia ani otwarcia sprawy.

Pytania oznaczone secret/OTP nie są delegowane doradcy. Model/prompt treści pytania
nie może zmienić typu autora lub sugestii w human approval. Konsumenci: ace-coworker
role/brief/report, ace-overseer trigger, ace-hitl schema/editor/read i Hermes rendering.
