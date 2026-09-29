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
perl -pi -e 's/^require_relative "compact_id_encoder_api"\n//' \
  "$COPY/ace-b36ts/lib/ace/b36ts/atoms/compact_id_encoder.rb"

cd "$WT"
exec "$SPINEL" .ace-local/ace-aot/entry_b36ts.rb \
  -I .ace-local/ace-aot/shims \
  -I "$COPY/ace-b36ts/lib" \
  -I "$COPY/ace-support-cli/lib" \
  -I "$COPY/ace-support-core/lib" \
  -I "$COPY/ace-support-config/lib" \
  -I "$COPY/ace-support-fs/lib" \
  --rbs .ace-local/ace-aot/rbs \
  --jobs=1 --require-gate -o "$OUT"
