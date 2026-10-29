# Mechanika dostępu i decyzja o ace-lab auth

## Decyzja Kapitana — 2026-10-29

Odpowiedź na pytanie review .7: dostarczyć `ace-lab auth` i pluginy Forgejo
(issue/revoke tokenów), GitHub oraz zmiennych środowiskowych. Agent prosi o krótkotrwały
dostęp dla roli, np. developer/reviewer. Istniejące mechaniki trzeba uporządkować
i spakować. Nie ograniczamy wymagania do czasu życia procesu.

To rozszerza obowiązki ace-lab o cykl poświadczeń. Nie przywraca starego brokera mutacji,
labd, Work/Attempt ledger ani kolejki. W .7 trzeba odpowiednio uaktualnić
`docs/lab-flow.md`, ADR-034 i dokumentację coworkera; obecne stwierdzenie, że coworker
nie uzyskuje tokenów, nie opisuje zaakceptowanego celu.

## Odnalezione źródła

Repozytorium `cs3b/lab-config`, lokalnie `/Users/mc/Ps/lab-config`, HEAD
`ced5f99a08766a1058e2bf745307a5459638f10a`. Odczytano kod, nie sekrety ani stan VM.
`lab-admin.py` i `labd.py` mają obce lokalne zmiany; wymienione poniżej funkcje
issue/revoke oraz kopiowanie admin PAT porównano również z `git show HEAD:<path>`.
Wnioski nie wymagają tych zmian. Nie uruchamiano mechanik ani ich testów w tym review.

| Źródło w tym commicie | Istniejący mechanizm | Co wykorzystać / poprawić |
|---|---|---|
| `lab-admin.py`: `create_token` (936–957), `lease_integrator` (2060–2078), `revoke` (2019–2057), `revoke_integrator` (2081–2091) | Tworzenie tokenu użytkownika Forgejo przez admin API z nazwą, scopes i repositories; zapis ID; DELETE po ID; czyszczenie przekazania. | Wzorzec odrębnego tokenu na przydział i rolę, ograniczenie repo oraz idempotentny revoke. Uogólnić konta, host, repo i ID; dodać termin oraz odzyskanie po crash. Nie kopiować szerokiego kasowania po prefiksie ani globalnego odebrania praw współbieżnym zadaniom. |
| `lab-github-app.py`: `lease`, `lease_read`, `revoke`, `revoke_read`, `status` | JWT instalacji → token z repositories/permissions; sprawdzenie odpowiedzi; expires_at; bezpieczne przekazanie przez stdin; metadata bez sekretu. | Wybrane repo i uprawnienia per rola/przydział. Nie przenosić domyślnego all-repositories ani jednego wspólnego slotu admin-write. |
| `lab-deliver.py`: `revoke_github` (203–219) | DELETE `/installation/token`; 401 traktowane jako już nieważny token; host czyści lokalne przekazanie po potwierdzeniu. | Rozróżnienie już nieważnego tokenu od niepewnego wyniku sieciowego. |
| `labd.py`: `store_credential`, `credential_path`, `clear_credential`; `git-credential-lab`; `fj-wrapper.py` | Pliki pod `/run/lab/credentials`, właściciel roli, tryb 0400, kontrole ścieżki/symlinków; Git/fj dostają referencję, nie sekret w argv. | Bezpieczny handoff do narzędzia jako file/env/stdin. Wydzielić do pakietów ACE bez zależności od dawnego daemona i jego modelu pracy. |
| `labd.py`: `mint_admin_work_lease` (2072–2097) | Kopiuje bajty stałego admin PAT do pliku Work. | To ograniczenie ekspozycji, nie nowy scoped token ani zdalny revoke. Nie spełnia kontraktu krótkotrwałego dostępu. |
| `lab-forgejo-admin-lease.py` | Dawny lease/run jest jawnie wyłączony; pozostał kod historycznego recovery. | Nie reaktywować wycofanego CLI jako zależności produktu. |
| `tests/test_github.py`, `tests/test_credential_isolation.py`, `tests/test_git_credential_lab.py`, `tests/test_lease.py` | Przykłady prób zakresu, izolacji kont, własności plików, sekretów poza argv oraz cleanup. | Przenieść potrzebne regresje do testów właściwych pakietów. Obecność testu nie jest dowodem odbioru nowego API. |

Źródła można ponownie odczytać w repo lab-config przez
`git show ced5f99a08766a1058e2bf745307a5459638f10a:<path>`.
Ten dokument daje świeżej sesji opis kontraktu bez zależności bundle od lokalnego
checkoutu innego repo. Nie ma potrzeby kopiowania całego control plane do ACE.

## Wzorce providerów i ograniczenia

GitHub App wydaje installation token dla wybranych repozytoriów i permissions;
odpowiedź niesie rzeczywiste expires_at (standardowo po godzinie). Klucz App pozostaje
po stronie issuera. Tożsamość instalacji jest tożsamością aplikacji, nie dowolnego
użytkownika. [GitHub: issuing installation tokens](https://docs.github.com/en/apps/creating-github-apps/authenticating-with-a-github-app/generating-an-installation-access-token-for-a-github-app).
Jawne odwołanie używa DELETE `/installation/token`.
[GitHub: revocation](https://docs.github.com/en/rest/apps/installations#revoke-an-installation-access-token).

Forgejo dokumentuje wydawanie tokenów i zwraca pełny sekret tylko przy utworzeniu.
Dokumentacja wskazuje swagger wdrożonego serwera jako opis jego API.
[Forgejo: API usage](https://forgejo.org/docs/latest/user/api/usage/).
Odczytany lab-config używa admin API i repo-scoped tokenów. Nie dowodzi to obsługi
natywnego TTL na każdej wersji Forgejo. Plugin weryfikuje używaną wersję/API oraz
rzeczywisty zakres. Bez natywnego expiry termin realizuje zaplanowany revoke hosta,
a status jawnie odróżnia tę metodę od expiry serwera. Awaria hosta lub sieci może
opóźnić zdalny revoke: wynik pozostaje pending/unknown, nigdy fałszywe expired.

Plugin `env` udostępnia tylko nazwane wartości procesu w ramach profilu. Statyczny
sekret z env nie staje się krótkotrwałym tokenem po skopiowaniu; jego sprzątnięcie
nie unieważnia kopii u odbiorcy. Dla zdalnego, czasowego dostępu env jest sposobem
przekazania lease od providera, a samodzielnie deklaruje tylko process-scoped exposure.
Polityka wymagająca remote expiry/revoke odrzuca taki samodzielny profil.

## Granica implementacji

Publiczny kontrakt i cykl lease należą do ace-lab; protokoły providerów do pluginów.
Wzorzec rejestracji istnieje w `ace-git/lib/ace/git/providers.rb` oraz rejestrze
adapterów ace-hitl. To precedens modularności, nie powód do łączenia auth z operacjami PR.
Host posiada issuer credentials i konfigurację kont/profili. Agent dostaje wyłącznie
dostęp wynikający z tej konfiguracji; wybór `--role` nie jest źródłem uprawnienia.
Szczegółowe wejścia/wyjścia, ownership, odmowy, retry oraz odbiór są w specyfikacji .7.
