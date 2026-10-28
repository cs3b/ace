---
id: 8ws.t.m0b
status: done
priority: high
created_at: "2026-09-29 14:40:22"
estimate: 
dependencies: []
tags: [spinel, aot, b36ts]
---

# b36ts AOT lowering (codecs inline, encode_cli/decode_cli, glue cascade, API split)

ace-b36ts lowered for AOT (CRuby behavior preserved):

- **FormatCodecs moved inline** into CompactIdEncoder's singleton class — Spinel does not model `class << self; include Module` at runtime; format_codecs.rb remains as a load stub.
- **encode_cli/decode_cli/parse_iso8601** added: parse+encode/decode stay in one statically-typed context (Spinel's constant-receiver dispatch boxes args, and its Time is a builtin struct that cannot be called polymorphically).
- **glue.rb**: flat compiled-config cascade (gem defaults file -> ~/.ace -> .ace -> overrides) through the yaml shim; SPINEL-guarded so CRuby keeps the full ADR-022 cascade.
- **CRuby-only API split**: encode wrapper moved to compact_id_encoder_api.rb (excluded from compiled copy — its generic param poisons Time-typed chains); CompactDate CRuby wrapper in compact_date.rb.
- Structural fixes: multi-assign -> indexed reads, String#[range] -> [start,length], result.freeze removed (output-neutral), add_days/sub_days instead of user-defined +/-.
