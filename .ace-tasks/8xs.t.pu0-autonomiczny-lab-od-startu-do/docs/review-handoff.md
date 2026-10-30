# Przygotowane pakiety review dla PR #398 (2026-10-30, HEAD f92a4b691)

Provider LLM w sandboxie tej sesji jest uszkodzony (node:fs — udokumentowane),
więc werdykt nie mógł zostać tu wykonany. Przygotowałem gotowe pakiety review
(dry-run, bez wykonania LLM) o rozsądnych zakresach — reviewer z działającym
providerem wykonuje je przez ace-review lub czyta prompty bezpośrednio:

| Pakiet (session) | Zakres | Rozmiar |
|---|---|---|
| review-8xt43t | kroki 01–05 (runtime, start, watch, observe lokalne, observe PR) — delta od 6f8dd9cc8 | ~pokrywa pierwszą połowę |
| review-8xt417 | kroki 06–16 (reply, lifecycle, auth, gate, delivery, lab, second-captain, learning, host-ops, acceptance, resilience) — delta od 02ed496f4 | 97k/128k tokeni |

Każdy pakiet zawiera system.prompt.md + user.prompt.md (diff + kontekst).
Kolejność rekomendowana: 8xt43t, potem 8xt417. Werdykt wiąże się z HEAD
f92a4b691 (kontrakt gate z kroku 09).

Alternatywnie pełny review jednym przebiegiem wymaga podziału na mniejsze
scopy lub reviewera z większym budżetem kontekstu.
