---
id: 8ws.t.m0c
status: done
priority: high
created_at: "2026-09-29 14:40:23"
estimate: 
dependencies: []
tags: [spinel, aot, conformance]
---

# Conformance oracle: 19 differential CLI cases, 19/19 byte-identical vs CRuby

Conformance oracle at .ace-local/ace-aot/conformance.sh — the Roundhouse pattern: the interpreter is the executable specification.

19 differential cases, byte-identical stdout + exit codes vs bin/ace-b36ts:
encode (2sec/day/month/40min/50ms/ms, ISO-Z, +offset wall-clock, date-only, --year-zero, error path), decode round-trips (2sec/day/ms ids), config, version.

**Result: 19/19 PASS.** Notable equivalence detail: offset-zone timestamps encode wall-clock fields (CRuby Time.parse semantics), documented in REPORT.md.
