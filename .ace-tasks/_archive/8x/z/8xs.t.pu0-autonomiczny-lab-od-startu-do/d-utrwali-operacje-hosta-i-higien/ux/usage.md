# Utrwalić operacje hosta i higienę — usage specyfikacji

## Powierzchnia interfejsu

Kontrakt CLI, konfiguracji lub workflow agenta opisany w specyfikacji. To scenariusze docelowe; nie deklarują aktualnej dostępności.

## Scenariusz 1: Powtarzalny sync

Wejście / wywołanie: Uruchomić udokumentowaną operację hosta na ustalonych repozytoriach.

Oczekiwany wynik: Wynik zawiera rzeczywiste źródłowe i docelowe SHA oraz rezultat sprawdzenia.

## Scenariusz 2: Usunięcie protez

Wejście / wywołanie: Po odbiorze zastępstw usunąć wskazane stare skrypty/config i wykonać zimny start.

Oczekiwany wynik: Start używa zasobów gema i właściwego konta, bez zależności od protez.

## Scenariusz 3: Rozbieżność lub aktywny zasób

Wejście / wywołanie: Wykryć divergence mirroru albo pozostałość używaną przez aktywną sprawę.

Oczekiwany wynik: Operacja zgłasza konkretną sytuację i zachowuje wartościową pracę.

## Uwagi do wykonania

W repo: bin/ace-*. W installed labie: zainstalowane CLI i workflow.
Pełną dokumentację interfejsu uzupełnić podczas as-task-work przez workflow aktualizacji usage.
Kryteria i kontekst: .ace-tasks/8xs.t.pu0-autonomiczny-lab-od-startu-do/d-utrwali-operacje-hosta-i-higien/8xs.t.pu0.d-utrwali-operacje-hosta-i-higien.s.md.

## Uściślenia review

Sync jest operacją hosta dla jawnego źródła/celu/ref w istniejącym workflow Git.
Dla tej rodziny źródłem wdrożonego laba jest wskazany Forgejo cs3b/ace, a mirror GitHub
cs3b/ace; przed każdym działaniem odczytać oba pełne SHA. Identity source=target to
no-op. Domyślnie tylko fast-forward; divergence wymaga osobnego reviewowanego uzgodnienia,
bez reset, force ani kasowania refów. Odczytane af68f8fc1 jest historyczną bazą, nie SHA
do bezwarunkowego narzucenia aktualnemu GitHub.

Po odbiorze .1/.a/.5 przygotować konkretny wykaz pozostałości i odczytać ich użycie.
Usuwać wyłącznie zastąpione interim-start, ręczny guide, duplikaty route i potwierdzone
zbędne uprawnienie collaboratora. Ta sama nazwa w innym repo lub aktywny zasób nie
kwalifikuje się do usunięcia. Zbędne granty zmienia właściciel platformy, nie manifest
install, który obecnie tylko powiększa grants. Salvage i historia HITL pozostają.

Konsumenci/deliverables: utrwalony workflow operacji hosta, jego scenariusz dry-run,
odczyt dowodów remote, aktualny guide i wykaz sprzątania. Jeśli potrzebna jest zmiana
narzędzia, należy do ace-git/adaptera lub ace-lab, bez nowego skryptu hardkodującego lab.
Pane-close nadal poza zakresem; nie zastępować go zamknięciem całego tab.
