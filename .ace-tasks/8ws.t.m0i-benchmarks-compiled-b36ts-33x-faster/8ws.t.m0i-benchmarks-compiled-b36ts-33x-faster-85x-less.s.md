---
id: 8ws.t.m0i
status: done
priority: high
created_at: "2026-09-29 14:40:35"
estimate: 
dependencies: []
tags: [spinel, aot, benchmarks]
---

# Benchmarks: compiled b36ts 33x faster, 8.5x less RSS, 1.27 MB binary

Benchmarks at .ace-local/ace-aot/bench.sh — 20 runs/case, median wall + max RSS, 4 comparators:

| case | native | binstub 3.4.8+bundler | ruby exe no bundler | ruby 4.0.4 |
|---|---|---|---|---|
| encode fixed ts | 8.8 ms | 293.9 ms | ~210 ms | ~130 ms |
| encode --format day | <5 ms | 390 ms | 150 ms | 110 ms |
| decode | <5 ms | 530 ms | 140 ms | 110 ms |
| config | <5 ms | 420 ms | 200 ms | 140 ms |
| peak RSS | 3.8-4.1 MB | 34.8 MB | 23.8 MB | 23.2 MB |

Artifact: 1.27 MB self-contained binary (libc/libm only). Full methodology: docs/research/spinel-aot-pilot.md.
