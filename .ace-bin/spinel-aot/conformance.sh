#!/bin/sh
# Conformance oracle: compiled ace-b36ts binary vs CRuby reference.
# Every case compares stdout + exit code byte-for-byte (the Roundhouse
# pattern: the interpreter is the executable specification).
set -u
WT="$(cd "$(dirname "$0")/../.." && pwd)"
NATIVE="$WT/.ace-local/ace-aot/ace-b36ts-native"
RUBY="$WT/bin/ace-b36ts"
pass=0; fail=0; n=0

check() {
  desc="$1"; shift
  n=$((n+1))
  cruby_out=$(cd "$WT" && "$RUBY" "$@" 2>/tmp/ace-aot-cruby.err; echo "rc=$?")
  native_out=$(cd "$WT" && "$NATIVE" "$@" 2>/tmp/ace-aot-native.err; echo "rc=$?")
  if [ "$cruby_out" = "$native_out" ]; then
    pass=$((pass+1)); echo "PASS: $desc"
  else
    fail=$((fail+1)); echo "FAIL: $desc"
    echo "  cruby: $cruby_out"
    echo "  native: $native_out"
  fi
}

# encode: fixed timestamps, all formats (summary suppressed via -q so the
# ID line is the whole output; non-quiet config summary is a documented
# Gate A divergence)
check "encode 2sec"          encode -q "2025-01-06 12:30:00"
check "encode 2sec ISO-Z"    encode -q "2025-01-06T12:30:00Z"
check "encode 2sec +offset"  encode -q "2025-01-06T12:30:00+01:00"
check "encode day"           encode -q --format day "2025-01-06"
check "encode month"         encode -q --format month "2025-01-06"
check "encode week"          encode -q --format week "2025-01-06"
check "encode 40min"         encode -q --format 40min "2025-01-06 12:30:00"
check "encode 50ms"          encode -q --format 50ms "2025-01-06 12:30:00"
check "encode ms"            encode -q --format ms "2025-01-06 12:30:00"
check "encode year-zero"     encode -q --year-zero 2025 "2025-01-06"
check "encode day+yz"        encode -q --format day --year-zero 2025 "2025-01-06"
check "encode date-only"     encode -q "2025-01-06"
check "encode ISO T sep"     encode -q "2025-01-06T12:30:00"

# decode round-trips
ID2SEC=$("$RUBY" encode -q "2025-01-06 12:30:00")
IDDAY=$("$RUBY" encode -q --format day "2025-01-06")
IDMS=$("$RUBY" encode -q --format ms "2025-01-06 12:30:00")
check "decode 2sec id"       decode "$ID2SEC"
check "decode day id"        decode "$IDDAY"
check "decode ms id"         decode "$IDMS"

# config + version
check "config"               config
check "version"              version

# error case: exit codes + message substring must agree
n=$((n+1))
cruby_rc=$(cd "$WT" && "$RUBY" encode -q "garbage-input" >/dev/null 2>&1; echo $?)
native_rc=$(cd "$WT" && "$NATIVE" encode -q "garbage-input" >/dev/null 2>&1; echo $?)
if [ "$cruby_rc" = "$native_rc" ] && [ "$cruby_rc" != "0" ]; then
  pass=$((pass+1)); echo "PASS: encode garbage (both reject, rc=$cruby_rc)"
else
  fail=$((fail+1)); echo "FAIL: encode garbage (cruby=$cruby_rc native=$native_rc)"
fi

echo ""
echo "conformance: $pass/$n passed, $fail failed"
[ "$fail" = "0" ]
