---
id: 8ws.t.lzx
status: done
priority: high
created_at: "2026-09-29 14:39:55"
estimate: 
dependencies: []
tags: [research, spinel, aot]
---

# Research Spinel AOT compiler + Roundhouse conformance model

Research completed 2026-09-29. Primary sources:

- **Spinel** (github.com/matz/spinel, pinned d7092d1): Matz's AOT compiler — Ruby -> whole-program type inference -> C -> cc -O2 -> self-contained native binary (libc/libm only). No eval, no dynamic metaprogramming, no encodings, no Date/YAML/Time.parse/Dir.glob; optparse is a silent no-op stub; --rbs type seeds drop kw-arg signatures. Claims ~8.5x geomean over Ruby 4.0.4+YJIT.
- **Roundhouse** (github.com/rubys/roundhouse): "Rails as a specification" transpiler — analyzer runs on CRuby at build time, lowers routes/schema/i18n-YAML to plain Ruby; YAML is never ported to the runtime. Correctness via conformance oracle (same URL from Rails and every target, byte-identical, every push). Campfire passes its full suite under Spinel.

Full findings: docs/research/spinel-aot-pilot.md (Research section).
