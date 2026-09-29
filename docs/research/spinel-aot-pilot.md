# Spinel AOT Pilot — ace-b36ts compiled to a native binary

Worktree: `spinel-aot-pilot` · 2026-09-29 · Spinel pinned @ `d7092d1` (built from source, macOS arm64)

## Headline

`ace-b36ts` compiles to a **1.27 MB self-contained native binary** (no Ruby runtime,
libc/libm only) that is **byte-identical** to the CRuby CLI across the 19-case
conformance oracle, and **~33x faster** with **~8.5x less memory** than today's
binstub startup.

| metric (median, 15-20 runs) | native | binstub (ruby 3.4.8 + bundler) | ruby exe, no bundler | ruby 4.0.4 |
|---|---|---|---|---|
| encode fixed ts | **8.8 ms** (min 6.5) | 293.9 ms | ~210 ms | ~130 ms |
| encode --format day | <5 ms | 390 ms | 150 ms | 110 ms |
| decode | <5 ms | 530 ms | 140 ms | 110 ms |
| config | <5 ms | 420 ms | 200 ms | 140 ms |
| peak RSS | **3.8-4.1 MB** | 34.8 MB | 23.8 MB | 23.2 MB |
| artifact | 1.27 MB binary | needs Ruby 3.4 + bundle | needs Ruby 3.4 | needs Ruby 4.0 |

The interpreter startup floor alone (`ruby -e ''`) costs ~10 MB RSS; the entire
compiled CLI runs in less than that. Reproduce with `.ace-bin/spinel-aot/build.sh`,
`.ace-bin/spinel-aot/conformance.sh`, `.ace-bin/spinel-aot/bench.sh`.

## What the research found

**Spinel** (github.com/matz/spinel) — Matz's AOT compiler: Ruby → whole-program type
inference → C → `cc -O2` → self-contained binary. No eval, no dynamic metaprogramming,
no encodings, no Date, no YAML, no Psych, no Time.parse, no Dir.glob. Upstream velocity
is high (Time, Rational, keyword args landed recently).

**Roundhouse** (github.com/rubys/roundhouse) — Sam Ruby's "Rails as a specification"
transpiler. Its analyzer runs on CRuby at build time and lowers routes/schema/i18n-YAML
to plain Ruby before Spinel compiles; YAML is never ported to the runtime. Correctness
is enforced by a conformance oracle: same URL from Rails and every target must return
identical responses on every push. Campfire passes its full suite this way.

## How ace compiles (the Gate A architecture)

Spinel can't run ace's generic frameworks as-is, so the pilot wraps three layers:

1. **Shims** (`.ace-bin/spinel-aot/shims/`): yaml-subset reader (nested maps/scalars/
   comments/lists — ace's real config surface), rubygems stub, timeout pass-through,
   Dir.glob reimplementation, standalone `CompactDate` (Date shim), OptionParser shim.
2. **Glue** (`ace-b36ts/lib/ace/b36ts/glue.rb`, shared with CRuby): flat config cascade
   (defaults file → `~/.ace` → `.ace` → overrides, through the yaml shim) and helpers.
3. **In-class orchestration**: `CompactIdEncoder.encode_cli/decode_cli/parse_iso8601`
   keep every `Time` operation inside one statically-typed context; the entry passes
   only strings/hashes across dispatch boundaries.

Build (`build.sh`) compiles from a filtered copy of the gem libs: the CRuby-only
`compact_id_encoder_api.rb` (the `encode` wrapper) and `compact_date.rb` are excluded,
and `EncodeCommand.execute` (whose CRuby `Time.parse` path cannot type-check) is stubbed.
`SPINEL`-guarded branches keep every CRuby behavior identical.

## Conformance oracle (Phase 2)

`conformance.sh` — 19/19 PASS. Byte-identical stdout + exit codes vs `bin/ace-b36ts`:
encode (fixed ts × formats 2sec/day/month/40min/50ms/ms, ISO-Z, +offset, date-only,
--year-zero), decode round-trips (2sec/day/ms ids), config, version, and the
garbage-input error path (both reject, same rc). `encode now` is time-dependent and
was verified interactively (IDs advance together).

## Spinel gaps catalog (what bit us — the real cost of AOT-for-ace)

Compile-time refusals / codegen bugs hit by ace's codebase:
- **No YAML** → yaml-subset shim (config cascade only).
- **No Date** → standalone CompactDate shim (CRuby wrapper kept, guarded).
- **No Time.parse** → ISO-8601 subset parser in glue/encoder.
- **optparse is a silent no-op stub** (compiles, parses nothing!) → real shim needed.
- **timeout is an ignored stub.**
- **`class << self; include Module` not modeled at runtime** → FormatCodecs mixin had
  to move inline into CompactIdEncoder's singleton class.
- **Constant-receiver class-method dispatch boxes args (RbVal)** — strips types; fatal
  for `Time` (a builtin struct that cannot be called polymorphically) → Time handling
  must stay inside one static context (hence encode_cli/decode_cli).
- **Dead generic callers poison Time-typed chains** (slot mismatches at C level) →
  dead-in-binary wrappers (`CompactIdEncoder.encode`, `EncodeCommand.execute`) are
  CRuby-only files / stubbed in the build.
- **User-defined `+`/`-` on custom classes generate broken C** (poly dispatch boxing)
  → `add_days`/`sub_days` instead.
- **Bare-ivar readers misbox in poly dispatch** → `jd` returns via `+0`; double dispatch.
- **`Class.new` unsupported** (class graph baked at compile time) → Help/VersionCommand
  rebuilt as static classes returning instances.
- **`return` inside a block (reduce) misboxes** → loop rewrite in `Config#get`.
- **`String#[range]` slicing misboxes on poly receivers** → `start,length` form.
- **Splat-collected arrays forwarded across calls hit boxing bugs** → arity-explicit.
- **Multiple assignment (MultiWriteNode) unsupported** → indexed reads.
- **`.freeze` on locals generates non-assignable C** → removed (output-neutral).
- **Dyn-`new` dispatch tables misbox** (Registry/Runner class-value shell) → thin entry
  dispatches commands itself (Gate A).
- **`respond_to?`/duck-typed registries can't type** → usage/registry lowered to
  concrete shapes.

## Public CLI parity (native binary vs CRuby API)

Derived from the public CLI surface (cli/commands option declarations + ADR-022 dynamic
configuration). Check = ported and conformance-verified; cross = not in the compiled
binary (Ruby channel only).

Run-over-run: **Run 1** (initial Gate A port) 27/44 (61%); **Run 2** (parity pass)
31/44 (70%, +4: config default_format, decode --format iso/timestamp, decode
--year-zero — each byte-identical to CRuby). Remaining 13 misses cluster in the
split/count family, verbose/debug cosmetics, and legacy time parsing.

| Surface | CRuby | Native | Notes |
|---|---|---|---|
| **encode [TIMESTAMP]** | | | |
| `now` | yes | yes | |
| ISO-8601 (naive / Z / offset / date-only) | yes | yes | wall-clock field semantics matched |
| legacy `YYYYMMDD-HHMMSS` | yes | no | CRuby Time.parse grammar |
| full CRuby Time.parse grammar (RFC 2822, "6 Jan 2025", ...) | yes | no | ISO-8601 subset only |
| `-f 2sec` / `month` / `week` / `day` / `40min` / `50ms` / `ms` | yes | yes (7/7) | byte-identical ids |
| `-n, --count` | yes | no | rejected with pointer to Ruby channel |
| `--split` (+ `--path-only`, `--json`) | yes | no | encoder math compiled; orchestration not wired |
| `-y, --year-zero` | yes | yes | |
| `-q, --quiet` | yes | yes | native output is always summary-free (equivalent to -q) |
| non-quiet config summary block | yes | no | ConfigSummary display not ported |
| `-v` / `-d` | yes | no | accepted, no effect |
| `-h, --help` | yes | yes | compact text, not byte-identical |
| **decode ID** | | | |
| ID + format auto-detection | yes | yes | |
| `-f readable` (default) | yes | yes | byte-identical |
| `-f iso` | yes | yes | byte-identical |
| `-f timestamp` | yes | yes | byte-identical |
| `--split` (hierarchical path decoding) | yes | no | |
| `-y, --year-zero` | yes | yes | |
| `-q` / `-v` / `-d` | yes | yes / no / no | |
| `-h, --help` | yes | yes | compact text |
| **config** | | | |
| plain output | yes | yes | byte-identical |
| `--verbose` (sources, ranges) | yes | no | |
| `-h, --help` | yes | yes | compact text |
| **top-level** | | | |
| `version` / `--version` | yes | yes | byte-identical |
| `help` / `-h` | yes | yes | compact text |
| unknown-command rejection | yes | yes | same rc; message wording differs |
| **dynamic configuration (ADR-022 cascade)** | | | |
| gem defaults file (`.ace-defaults/b36ts/config.yml`) | yes | yes | via yaml-subset shim |
| user config (`~/.ace/b36ts/config.yml`) | yes | yes | |
| project config (`.ace/b36ts/config.yml` in cwd) | yes | yes | |
| project config discovered in parent directories | yes | no | upward traversal not ported |
| `default_format` honored | yes | yes | fixed in this pass |
| runtime overrides (`-y`, `-f`) | yes | yes | |
| config validation (alphabet 36/unique, year_zero 1900-2100, known format) | yes | yes | shared validate_config! |
| ace-config test_mode / mock hooks | yes | n/a | test-only, not public CLI |

## Distribution (3-target matrix, per Captain)

| | gems today | AOT binaries |
|---|---|---|
| runtime dep | Ruby ≥3.4 + bundler | none (libc/libm) |
| artifacts/release | 25 .gem files | **3 builds**: linux-x64, linux-arm64 (both cover WSL), mac-arm64 |
| cross-compile | n/a | unsupported; sanctioned path: ship C (`spinel -c` + 1.4 MB runtime) and compile on target |
| macOS | n/a | codesign + notarize; no universal/lipo needed |
| config | .ace/ cascade | unchanged (file-based, survives) |
| updates | `gem update` | re-download |
| fit | all 25 gems | pure-compute CLIs (b36ts, search, bundle, nav, docs); LLM-shelling gems stay gems |

**Recommendation:** gems remain the primary channel; add an optional binaries channel
via a **multiplexed busybox-style `ace` binary** (one artifact per platform +
installer script/homebrew tap), built by a GH Actions matrix (ubuntu-24.04 x64/arm,
macos-14 arm64) using this worktree's build recipe. The per-CLI port cost observed
here (~1 session for one small gem with heavy shimming) means the multiplexed binary
should start with the pure-compute CLIs and grow per Spinel releases; the conformance
oracle pattern (differential CLI cases) is the gating tool for each addition.

## Verdict

The Roundhouse thesis holds for ace: the **interpreter is the specification**, and a
compiled binary is viable when (a) the command's hot path lives in statically-typable
plain Ruby and (b) a differential oracle proves equivalence. ace-b36ts: proven, with
33x startup improvement and no-Ruby distribution. The blocker list above is the price
list — it shrinks with every Spinel release.
