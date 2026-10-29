# Postęp 8xs.t.pu0.0 — runtime z instalatora (2026-10-30)

Praca na wspólnym worktree/PR rodziny: `.ace-wt/ace-t.pu0`, branch
`pu0-autonomiczny-lab-od-startu-do-wdroenia`. Gem release i odbiór na labie
odroczone na koniec programu (decyzja Kapitana).

## Zrealizowane w źródłach

1. **Publikowalny pakiet ace-wake** — źródło rozszerzenia przeniesione do
   `ace-wake/handbook/extensions/ace-wake/` (jedyna kopia), gemspec,
   `lib/ace/wake/version.rb` (0.1.0), CHANGELOG, Rakefile; suite JS uruchamiany
   przez `bin/ace-test ace-wake` (wrapper `node --test`); wpis w root Gemfile;
   pakiet jest na liście `.ace/test/suite.yml` i podlega discovery release
   (ścieżka ace-* + version.rb + CHANGELOG).
2. **Pi korzysta z gema przez standardową projekcję** — manifest pi deklaruje
   `extensions_dir: .pi/extensions` + `extensions_package: ace-wake`;
   `ProviderRegistry#extensions_source_root` rozwiązuje pakiet (lokalny katalog
   projektu, potem zainstalowany gem); `ProviderSyncer` projektuje z tego
   źródła; gemspec pi zależny od `ace-wake ~> 0.1`; brak drugiej kopii JS
   (piowany testem).
3. **Konwergencja gemset w ace-lab** — domknięcie zależności przechodnich
   (instalacja brakujących, np. json, także gdy wersja rodzica figuruje w
   `gem list`; brak możliwy do spełnienia = sklasyfikowany błąd, nigdy
   gotowość); nowsza wersja obok zadeklarowanej usuwana w konwergencji, a
   verify FAIL, dopóki nowsza wersja przejęłaby aktywację CLI; dry-run
   przewiduje (would_uninstall/would_install) bez zapisów.
4. **Projekcje rozszerzeń w ace-lab** — `gemset.extensions {gem, path,
   account}` w manifeście; `ExtensionProvisioner` projektuje z DOKŁADNIEJ
   zainstalowanej wersji gema, receipt-based pruning (pliki użytkownika nietknięte),
   raport `loaded_version` + `restart_required`; installer nie restartuje
   wykonawcy; verify re-deriwuje projekcję (receipt/wersja/treść plików).
5. **Dokumentacja** — ace-lab usage (sekcje closure/CLI/extensions), pi usage,
   ace-wake README (provenance: konwergencja zamiast ręcznego kopiowania),
   `.ace/handbook/config.yml`, CHANGELOGe (Unreleased; wersje i publikacja na
   końcu programu).

## Dowody

- `bin/ace-test ace-wake` — 1 test (wykonany suits node --test, 12 plików), 0 fail.
- `bin/ace-test ace-handbook` — 64 testów, 0 fail.
- `bin/ace-test ace-handbook-integration-pi` — 9 testów, 0 fail.
- `bin/ace-test ace-lab` — 612 testów, 0 fail (nowe: closure konwergencja +
  porażki, newer-takeover, extension provisioner 6 scenariuszy, verify:
  brak zależności przechodniej / nowsza wersja / receipt projekcji + mismatch,
  prepare: projekcja z dokładnej wersji, idempotencja).
- Raporty: `.ace-local/test/reports/{wake,handbook,handbook-integration-pi,lab}/`.

Znane środowiskowe: Pi CLI (plan/commit-msg) niedostępne w tej sesji (`node:fs`
error) — plan prowadzony ręcznie wg speca; commity path-scoped przez fallback
git z opisem (udokumentowany fallback ace-git-commit).

## Odroczone (koniec programu, zgodnie z decyzją Kapitana)

- Publikacja gemów (ace-wake 0.1.0, ace-lab, ace-handbook, pi) i bump wersji.
- Odbiór na labie: świeża instalacja pod kontem docelowym, przerwana instalacja
  + ponowienie, brak zależności = brak gotowości; scenariusze 1–3 z tabeli.
- `ace-test-suite` całego monorepo.
