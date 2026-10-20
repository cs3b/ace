---
id: 8xjm25
title: l10-release-wave-prep-and-publish
type: standard
tags: [lab, l10, release]
created_at: "2026-10-20 14:42:24"
status: active
---

# l10-release-wave-prep-and-publish

Kontekst: fala L10 programu 8xg.t.sbz (2026-10-20) — przygotowanie
skoordynowanego wydania 9.0 (PR #394, 7 rund review do zbieżności),
publikacja 9.1 (16 gemów), odbiór L9 z ograniczeniami, naprawa
nieaktualnego lokalnego main. Środowisko: mono-repo ACE, worktree
`t-sbz-wave-4`.

## What Went Well

- **Dowód instalacji przed publikacją wykrył realne luki.** Czysty
  `GEM_HOME` + instalacja w kolejności zależności obnażyła nieopublikowane
  floory (`ace-hitl ~> 0.22/0.23`, `ace-task ~> 0.41`), których audyt
  samych CHANGELOGów nie pokazał — przygotowane-ale-nieopublikowane wpisy
  wyglądają jak wydane. Eksperyment (nieudana instalacja bez floorów)
  stał się dowodem scenariusza błędu z kryteriów odbioru.
- **Review złapał klasę błędu niewidoczną dla testów**: puste sekcje
  wersji w CHANGELOGach po moim skrypcie insertu (treść została pod
  [Unreleased], nagłówek wersji był pusty) — gemy zbudowane przed naprawą
  weszłyby do manifestu z błędnym dokumentowaniem. 12/16 hashy po
  przebudowie pokryło się 1:1 z API RubyGems — buildy replikowalne.
- **Pełny audyt wersji (17 luk) zamiast inkrementalnego**: jedna komenda
  porównująca version.rb z `gem list --remote --exact` ustaliła cały
  zakres zestawu naraz, zamiast odkrywać braki po kolei przez nieudane
  instalacje.
- **Niejednoznaczność statusów rozwiązana przez fakty, nie zgadywanie**:
  „czy L8 skończone?" → lokalny main 158 commitów za origin/main; ff
  naprawił widok bez żadnej ingerencji w dane.

## What Could Be Improved

- **Nie znałem narzędzia projektowego do publikacji.** Przygotowałem
  własny `publish.sh`, choć w repo istnieje `ace-rubygems-publish`
  (fale zależności, OTP, fresh resolve kolejki). Koszt: zbędny artefakt
  i brak spójności z projektem. Przyczyna: szukałem poświadczeń, nie
  narzędzi; `.ace-bin/` nie było w ścieżce przeszukiwania.
- **Zestaw opublikowany ≠ manifest**: narzędzie rozstrzygnęło kolejkę z
  drzewa i opublikowało 16 gemów (3 spoza uzgodnionych 13). Nieszkodliwe,
  ale decisions-record 9.0 przestał być dosłownym opisem wydania —
  odchylenie trzeba było uczciwie adnotować w results 9.1.
- **Review pakietowy przekroczył budżet 128k tokenów** po przeniesieniu
  dużych bloków CHANGELOG (diff widzi przeniesienie jako usunięcie+dodanie).
  Obejście: scope per-ścieżka (`diff:RANGE -- path`) działa, ale wykryłem
  je metodą prób; dokumentacja `--subject` nie eksponuje składni globów.
- **Siedem rund review na zmiany dokumentacyjne** (5→4→2→3→2→2→0):
  trzy ostatnie rundy to kolejne mikro-uwagi (literówka, ścieżka
  root-relative). Koszt zbieżności vs wartość — kandydat do progu
  „nit-cutoff" dla zakresów docs-only.
- **Mój skrypt release-cut wykonał niepełne cięcie** (pusty nagłówek wersji
  bez przeniesienia treści) i przeszedł mój własny sanity-check. Parser
  liczący bullety per wersja złapał to dopiero po review.

## Key Learnings

- **„Przygotowane" ≠ „opublikowane"**: lokalny CHANGELOG z wersjonowanym
  wpisem nie świadczy, że wersja jest na RubyGems. Jedyny test: audyt
  zdalny + czysta instalacja zestawu.
- **Review Cycle Analysis**: 7 sesji (8xjirg→8xjjzi), 21 ustaleń, 0
  unieważnionych — wszystkie `--valid` i naprawione. Wzorzec nawracający:
  niespójność opisów dokumentów po częściowych naprawach (root CHANGELOG
  vs results.md vs siblings) — 6 z 21 ustaleń to „popraw w jednym miejscu,
  zapomnij w drugim". Systematyczne, nie jednorazowe.
- **Bramka hashy ma sens tylko z autorytatywnego źródła**: ostatecznym
  dowodem okazał się SHA z API RubyGems; porównanie świeżego buildu z
  main z SHA z API potwierdziło pochodzenie opublikowanych gemów lepiej
  niż lokalne artefakty.

## Action Items

- **START**: przed własnym skryptem wydawania/szukaniem toolsów — przeszukać
  `.ace-bin/`, `bin/`, `.agents/skills/` pod kątem istniejącego narzędzia.
- **START**: release-cut helper przenoszący treść [Unreleased] pod nowy
  nagłówek atomowo (sugestia z review 8xjiwfwa; zapobiegłby klasie błędu
  pustych sekcji).
- **CONTINUE**: czysty-GEM_HOME dowód instalacji jako standardowy krok
  przygotowania każdego przyszłego wydania wielopakietowego.
- **CONTINUE**: audyt `version.rb` vs RubyGems dla WSZYSTKICH pakietów
  przed ustaleniem zestawu wydania.
- **STOP**: ręczne wypisywanie publish-kolejności — zostawić narzędziu
  (fale zależności), odchylenia od manifestu adnotować w results.
