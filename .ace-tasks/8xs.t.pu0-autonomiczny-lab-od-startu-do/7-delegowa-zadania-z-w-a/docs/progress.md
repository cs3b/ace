# Postęp 8xs.t.pu0.7 — delegacja z właściwą rolą i dostępem (2026-10-30)

Praca na wspólnym worktree/PR rodziny (#398). Rzeczywiste wydanie tokenów
Forgejo/GitHub na labie i praca coworkera na leasie — odbiór odroczony na
koniec programu (decyzja Kapitana).

## Zrealizowane w źródłach

1. **`ace-lab auth`** — publiczny interfejs request/status/exec/revoke/
   reconcile (`cli/commands/auth.rb`, `Auth::Service`):
   - profil w ZAUFANYM dokumencie (`auth:` w authorization.yml, root-owned,
     konwergowany przez install); istniejące `principals` pozostają mapą
     widoczności; konfiguracja projektu/coworkera może tylko wskazać profil;
   - weryfikacja rzeczywistego konta wołającego (principals) i roli; odmowy
     z powodem i adresatem eskalacji, bez fallbacku tożsamości;
   - TTL: default 30 min, max 60 (host może ustawić jawny limit profilu);
     przekroczenie = odmowa, nie ciche obcięcie; status pokazuje osobno
     use_until i provider expiry;
   - request idempotentny dla żywej korelacji task/assignment/profil/rola
     (współbieżne = jeden token); zakres = przecięcie profilu i żądania;
   - exec: kod procesu zachowany; sukces procesu + błąd cleanupu = błąd;
     raport niesie oba wyniki; jeden exec na lease (flock); child dostaje
     REFERENCJĘ (ACE_LAB_CREDENTIAL_FILE), nigdy wartość w argv; żaden
     tryb nie drukuje tokenu;
   - revoke idempotentny (już odwołany nie dzwoni ponownie do providera);
     wynik sieciowy pozostaje widoczny revoke-pending (nigdy rzekomy
     sukces); reconcile rozstrzyga przerwane cykle i przeterminowane
     przydziały w tym samym magazynie.
2. **Jeden minimalny rekord lease** (`LeaseStore`,
   /var/lib/lab/ace-lab/auth/leases/<id>.json): korelacja, token_ref,
   terminy, wynik cleanupu — bez sekretów i bez postępu tasków; handoff
   efemeryczny `/run/lab/credentials/<lease>-<recipient>` 0400 z kontrolą
   symlink (`CredentialHandoff`).
3. **Pluginy** (jawna rejestracja `Auth::Providers`, wzorzec ace-git):
   - forgejo: osobny token na lease na koncie roli (admin API, scopes,
     repo-limited), revoke dokładnego ID (nigdy prefiks/glob); brak
     natywnego TTL widoczny przed handoffem (host-revoke);
   - github: App JWT (RS256, stdlib) → installation token dla wybranych
     repo+permissions, rzeczywisty expires_at, DELETE /installation/token
     (401 = already invalid, sieć = outcome-unknown); klucz App po stronie
     issuera;
   - env: wyłącznie nazwane wartości z konfigurowanych źródeł, ekspozycja
     process-scoped; samodzielny env profil odrzucony przy wymaganiu
     remote expiry/revoke (schema).
4. **Właściciele stanu**: docs/lab-flow.md (nowy wiersz mapy: lease +
   handoff, właściciel ace-lab auth) + ADR-034 amendment (jatynie
   zatwierdzony zakres auth — to nie jest przywrócony admission/broker);
   docs/usage.md ace-lab (pełna sekcja Auth).

## Dowody

- `bin/ace-test ace-lab` — 621 testów, 0 fail; nowe `auth/service_test`
  (9): issuance z handoffem 0400 i bez sekretu w rekordzie, idempotentny
  request (jeden token), odmowy roli/principala/TTL („refused, not
  clipped", „escalate to the host owner"), exec z referencją i dwoma
  wynikami + zachowanym kodem wyjścia, exec na martwym leasie odmówiony,
  revoke idempotentny (jedno wywołanie providera) + nieznany lease,
  revoke-pending przy outcome-unknown (nigdy claimed), reconcile
  przeterminowanego leasu.
- Plugin contract pinowany przez FakeProvider; forgejo/github po seamie
  transportowym (curl argv), env w pełni funkcjonalny.

## Granice / odroczone

- Realne tokeny Forgejo/GitHub na labie (wersja API Forgejo, installation
  GitHub), scheduler hosta (systemd) dla host-revoke po terminie, brief z
  identyfikatorem lease w commission/coworker prepare, usunięcie
  zastępowanych ścieżek lab-config — po odbiorze nowej ścieżki na labie.
- Publikacja gemu ace-lab.
