#!/bin/sh
# Build the Spinel-compiled ace-b36ts binary (Gate A pilot).
# Compiles from a filtered copy of the gem lib dirs: the CRuby-only
# API extension (compact_id_encoder_api.rb) is excluded -- its generic
# params poison Spinel's Time-typed call chains.
set -e
WT="$(cd "$(dirname "$0")/../.." && pwd)"
SPINEL=/tmp/spinel/spinel
OUT="$WT/.ace-local/ace-aot/ace-b36ts-native"  # binary stays in scratch (artifact)
COPY="$WT/.ace-bin/spinel-aot/gemlib"

rm -rf "$COPY"
mkdir -p "$COPY"
for g in ace-b36ts ace-support-cli ace-support-core ace-support-config ace-support-fs; do
  mkdir -p "$COPY/$g"
  cp -R "$WT/$g/lib" "$COPY/$g/"
done
rm "$COPY/ace-b36ts/lib/ace/b36ts/atoms/compact_id_encoder_api.rb"
# CRuby-only Date wrapper: the standalone CompactDate shim (entry shims)
# must not be reopened with a ::Date superclass in compiled builds.
rm "$COPY/ace-b36ts/lib/ace/b36ts/compact_date.rb"
# and leave a stub so the encoder's require resolves
printf '# frozen_string_literal: true\n# CRuby-only wrapper excluded from compiled builds (see REPORT.md).\n' > "$COPY/ace-b36ts/lib/ace/b36ts/compact_date.rb"
# EncodeCommand.execute's CRuby Time.parse path cannot type-check under
# Spinel; the compiled CLI uses CompactIdEncoder.encode_cli instead.
python3 - "$COPY/ace-b36ts/lib/ace/b36ts/commands/encode_command.rb" <<'PYSTUB'
import sys
p = sys.argv[1]
stub = """# frozen_string_literal: true

# Stubbed for Spinel builds: execute's CRuby Time.parse path cannot
# type-check in the AOT chain; the compiled CLI entry uses
# CompactIdEncoder.encode_cli instead. See build.sh / REPORT.md.
module Ace
  module B36ts
    module Commands
      class EncodeCommand
        def self.execute(_time_string, _options = {})
          raise NotImplementedError, "use CompactIdEncoder.encode_cli in compiled builds"
        end
      end
    end
  end
end
"""
open(sys.argv[1], "w").write(stub)
PYSTUB
# SetupDoctor.parse_time's Time.parse branch is CRuby-only generic code,
# off the compiled CLI path; new Spinel refuses Time.parse at compile
# time, so stub the parse like other dead generic callers (REPORT.md).
python3 - "$COPY/ace-support-config/lib/ace/support/config/organisms/setup_doctor.rb" <<'PYSTUB2'
import sys
p = sys.argv[1]
s = open(p).read()
old = "            Time.parse(value.to_s)\n"
new = "            raise NotImplementedError, \"Time.parse is CRuby-only in compiled builds\"\n"
assert s.count(old) == 1, "setup_doctor Time.parse anchor not found"
open(p, "w").write(s.replace(old, new))
PYSTUB2
# SetupDoctor's dead generic Hash#merge calls: rewrite to dup+each
# (Hash#merge is refused by the AOT compiler; these paths are CRuby-only).
python3 - "$COPY/ace-support-config/lib/ace/support/config/organisms/setup_doctor.rb" <<'PYSTUB3'
import sys
p = sys.argv[1]
s = open(p).read()
repl = [
    ("            result = build_summary(checks).merge(\n"
     "              valid: !health_blocking?(checks),\n"
     "              duration: Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at,\n"
     "              stats: build_stats(checks)\n"
     "            )\n",
     "            result = build_summary(checks)\n"
     "            result[:valid] = !health_blocking?(checks)\n"
     "            result[:duration] = Process.clock_gettime(Process::CLOCK_MONOTONIC) - started_at\n"
     "            result[:stats] = build_stats(checks)\n"),
    ("              target.merge(provider_kind: provider_kind, timeout_seconds: timeout_seconds, _order: index)\n",
     "              ordered_target = target.dup\n"
     "              ordered_target[:provider_kind] = provider_kind\n"
     "              ordered_target[:timeout_seconds] = timeout_seconds\n"
     "              ordered_target[:_order] = index\n"
     "              ordered_target\n"),
    ("            {id: id, kind: kind, status: status, message: message, next_action: next_action}.merge(extra)\n",
     "            check_hash = {id: id, kind: kind, status: status, message: message, next_action: next_action}\n"
     "            extra.each { |extra_key, extra_value| check_hash[extra_key] = extra_value }\n"
     "            check_hash\n"),
]
for old, new in repl:
    assert s.count(old) == 1, "setup_doctor merge anchor not found: %r" % old[:60]
    s = s.replace(old, new)
open(p, "w").write(s)
PYSTUB3
# ConfigSummaryMixin::GemClassMixin is dead in compiled builds (no summary
# display); its dynamic `self.class.gem_class` dispatch cannot type-check.
python3 - "$COPY/ace-support-core/lib/ace/core/cli/config_summary_mixin.rb" <<'PYSTUB4'
import sys
p = sys.argv[1]
s = open(p).read()
old = "            self.class.gem_class.config\n"
new = "            raise NotImplementedError, \"ConfigSummary is CRuby-only in compiled builds\"\n"
assert s.count(old) == 1, "gem_class config anchor not found"
s = s.replace(old, new)
old2 = "            self.class.gem_class.default_config\n"
new2 = "            raise NotImplementedError, \"ConfigSummary is CRuby-only in compiled builds\"\n"
assert s.count(old2) == 1, "gem_class default_config anchor not found"
s = s.replace(old2, new2)
open(p, "w").write(s)
PYSTUB4
perl -pi -e 's/^require_relative "compact_id_encoder_api"\n//' \
  "$COPY/ace-b36ts/lib/ace/b36ts/atoms/compact_id_encoder.rb"

cd "$WT"
exec "$SPINEL" .ace-bin/spinel-aot/entry_b36ts.rb \
  -I .ace-local/ace-aot/shims \
  -I "$COPY/ace-b36ts/lib" \
  -I "$COPY/ace-support-cli/lib" \
  -I "$COPY/ace-support-core/lib" \
  -I "$COPY/ace-support-config/lib" \
  -I "$COPY/ace-support-fs/lib" \
  --rbs .ace-local/ace-aot/rbs \
  --jobs=1 --require-gate -o "$OUT"
