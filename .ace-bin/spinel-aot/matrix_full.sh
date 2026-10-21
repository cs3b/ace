#!/bin/bash
# Run 4 extended matrix: full CLI surface vs CRuby.
set -u
WT="$(cd "$(dirname "$0")/../.." && pwd)"
NATIVE="$WT/.ace-local/ace-aot/ace-b36ts-full"
RUBY="$WT/bin/ace-b36ts"
pass=0; fail=0; n=0
check() {
  desc="$1"; shift
  n=$((n+1))
  cruby_out=$(cd "$WT" && "$RUBY" "$@" 2>/tmp/m-c.err; echo "rc=$?")
  native_out=$(cd "$WT" && "$NATIVE" "$@" 2>/tmp/m-n.err; echo "rc=$?")
  if [ "$cruby_out" = "$native_out" ]; then
    pass=$((pass+1)); echo "PASS: $desc"
  else
    fail=$((fail+1)); echo "FAIL: $desc"
    echo "$cruby_out" > /tmp/m-c.out; echo "$native_out" > /tmp/m-n.out
    diff /tmp/m-c.out /tmp/m-n.out | head -8
  fi
}
check "root (no args)"
check "--help"                --help
check "-h"                    -h
check "help"                  help
check "help encode"           help encode
check "encode --help"         encode --help
check "encode -h"             encode -h
check "decode --help"         decode --help
check "config --help"         config --help
check "version"               version
check "--version"             --version
check "unknown cmd"           bogus
check "unknown sub args"      bogus xyz
check "encode default fmt"    encode -q "2025-01-06 12:30:00"
for f in month week day 40min 50ms ms 2sec; do
  check "encode $f"           encode -q --format "$f" "2025-01-06 12:30:00"
done
check "encode -f day"         encode -q -f day "2025-01-06 12:30:00"
check "encode ISO-Z"          encode -q "2025-01-06T12:30:00Z"
check "encode +offset"        encode -q "2025-01-06T12:30:00+01:00"
check "encode date-only"      encode -q "2025-01-06"
check "encode readable"       encode -q "2025-01-06 12:30:00"
check "encode legacy ts"      encode -q "20250106-123000"
check "encode year-zero"      encode -q --year-zero 2025 "2025-01-06 12:30:00"
check "encode -y 1990"        encode -q -y 1990 "2025-01-06 12:30:00"
check "encode count 3"        encode -q --count 3 "2025-01-06 12:30:00"
check "encode count ms"       encode -q --count 3 --format ms "2025-01-06 12:30:00"
check "encode count json"     encode -q --count 3 --json "2025-01-06 12:30:00"
check "encode split m,w"      encode -q --split month,week "2025-01-06 12:30:00"
check "encode split path"     encode -q --split month,week,day --path-only "2025-01-06 12:30:00"
check "encode split json"     encode -q --split month,day --json "2025-01-06 12:30:00"
check "encode quiet"          encode -q "2025-01-06 12:30:00"
check "encode non-quiet"      encode "2025-01-06 12:30:00"
check "encode bad format"     encode -q --format nope "2025-01-06 12:30:00"
check "encode split+format"   encode -q --split month --format day "2025-01-06 12:30:00"
check "encode missing ts"     encode -q
check "decode roundtrip 2sec" decode "$("$RUBY" encode -q '2025-01-06 12:30:00' | tail -1)"
check "decode roundtrip day"  decode "$("$RUBY" encode -q --format day '2025-01-06 12:30:00' | tail -1)"
check "decode roundtrip ms"   decode "$("$RUBY" encode -q --format ms '2025-01-06 12:30:00' | tail -1)"
check "decode bad id"         decode "zzzzzzzz"
check "decode empty"          decode
check "config plain"          config
check "config verbose"        config --verbose
check "config extra arg"      config xyz
echo "matrix: $pass/$n passed, $fail failed"
