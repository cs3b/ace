---
id: 8ws.t.m0a
status: done
priority: high
created_at: "2026-09-29 14:40:20"
estimate: 
dependencies: []
tags: [spinel, aot, shims]
---

# Shim layer for Spinel-compiled builds (yaml-subset, rubygems, timeout, Dir.glob, CompactDate, OptionParser)

Shim layer at .ace-local/ace-aot/shims/ (loaded before gem sources via entry -I):

- **yaml.rb**: pure-Ruby YAML-subset reader/writer (nested maps, block lists, scalars, quoted strings, comments) covering ace's ADR-022 config surface; Psych::Exception/SyntaxError defined.
- **rubygems.rb**: Gem.loaded_specs stub (callers fall back to source-tree gem dirs).
- **compact_date.rb**: standalone Date shim (proleptic Gregorian, jd math); add_days/sub_days avoid user-defined +/- operators (Spinel codegen bug); jd reader boxes via +0.
- **dir_glob.rb**: Dir.glob on Dir.new/children (**, *, ?, {a,b} alternates, base:).
- **optparse.rb**: full shim for ace's 6-point API surface (on/parse!/banner/version/ParseError hierarchy, type coercion, --[no-] booleans) — needed because Spinel's optparse is a silent no-op.
- **timeout.rb**: pass-through (documented divergence).

Excluded-from-copy pattern (build.sh) keeps CRuby-only files out of compiled builds.
