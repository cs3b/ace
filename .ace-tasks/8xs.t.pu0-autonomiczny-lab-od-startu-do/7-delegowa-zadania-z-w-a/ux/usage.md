# Delegacja i ace-lab auth — usage specyfikacji

To kontrakt docelowy kroku .7, nie opis obecnie dostępnego polecenia. W repo używać
bin/ace-*; w installed — instalowanych executables i instrukcji. TASK, ASSIGNMENT,
PROFILE i LEASE pochodzą z rzeczywistego zlecenia/odpowiedzi CLI.

## Agent prosi o dostęp

Nadzorca przygotowuje task/worktree/assignment i rolę zwykłym commission/prepare.
Wykonawca ma w briefie nazwę skonfigurowanego profilu oraz zasady zakończenia dostępu.

```text
ace-lab auth request --profile PROFILE --role developer --task TASK --assignment ASSIGNMENT --ttl 30m --format json
ace-lab auth status LEASE --format json
ace-lab auth exec LEASE -- COMMAND ...
```

Request zwraca referencję, rzeczywisty principal, repo/scopes, use_until,
provider_expires_at i expiry_mode. Sekret dostaje wyłącznie proces COMMAND przez
kanał profilu. Exec pracuje jako wykonawca, nie jako issuer. Po zakończeniu odwołuje
lease i raportuje oddzielnie wynik komendy oraz cleanup. Kolejna operacja po revoke
wymaga nowego request; status nigdy nie przedłuża dostępu.

## Review i inne role

Reviewer używa osobnego profilu i tożsamości. Developer nie otrzymuje approval/merge
przez zmianę --role. Host sprawdza faktyczne konto, zadanie i zakres. W razie odmowy
agent zgłasza przez HITL konkretny brak; nie używa tokenu nadzorcy. Nazwa developer
mapuje istniejącego coworkera worker, nie dodaje drugiej roli wykonawczej.

## Forgejo, GitHub i env

Forgejo wydaje osobny token na rolę/przydział i usuwa jego ID. GitHub wydaje token
instalacji App z wybranym repo i permissions, natywnym expiry i jawnym revoke.
Oba mogą używać env jako sposobu przekazania. Static env sam nie odwołuje zdalnego
sekretu: status pokazuje process-scoped exposure, a profil wymagający remote expiry
odrzuca takie źródło. Brak pluginu lub konfiguracji oznacza not-ready, bez przejścia
na domyślne globalne credentials.

## Koniec, przerwanie i recovery

```text
ace-lab auth revoke LEASE
ace-lab auth status LEASE --format json
```

Zwykłe zakończenie/cancel/pause odwołuje token od razu; termin jest także pilnowany
niezależnie od coworkera. Status rozróżnia native expiry i host-revoke. Przy braku
łączności pokazuje revoke-pending, blokuje lokalne użycie i eskaluje bez deklaracji
zdalnego sukcesu. Uprawniony host wykonuje `ace-lab auth reconcile` po restarcie
oraz przy retry. Wznowienie pracy po expiry wymaga ponownego request; nie rozszerza
roli. Dwa request dla tego samego żywego przydziału nie tworzą dwóch tokenów.

## Granice i dowody

Domyślny TTL 30 min, domyślne maksimum 60 min; host może ustalić inne limity profilu.
Brak wymaganego schedulera host-revoke jest odmową przed przekazaniem sekretu.
Awaria całego hosta/sieci może opóźnić host-revoke; profil wymagający niezależnego
od hosta expiry musi używać providera z taką zdolnością. Samo skasowanie pliku/env
nie jest dowodem revoke. Próby live muszą wykazać odrzucenie ponownego użycia tokenu.

Pełny kontrakt i mapa kryteriów: ../8xs.t.pu0.7-delegowa-zadania-z-w-a-ciwymi-uprawnieniami.s.md.
Źródła istniejącej mechaniki: ../../docs/auth-mechanics.md.
