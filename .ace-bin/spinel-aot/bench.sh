#!/bin/sh
# Benchmark: compiled binary vs interpreter paths.
# 20 runs per case; reports median wall time + max RSS.

WT="$(cd "$(dirname "$0")/../.." && pwd)"
NATIVE="$WT/.ace-local/ace-aot/ace-b36ts-native"
BINSTUB="$WT/bin/ace-b36ts"
EXE="$WT/ace-b36ts/exe/ace-b36ts"
R34="$HOME/.local/share/mise/installs/ruby/3.4.8/bin/ruby"
R40="$HOME/.local/share/mise/installs/ruby/4.0.4/bin/ruby"
INC="-I $WT/ace-b36ts/lib -I $WT/ace-support-cli/lib -I $WT/ace-support-core/lib -I $WT/ace-support-config/lib -I $WT/ace-support-fs/lib"
RUNS=20

bench() {
  label="$1"; shift
  times=""
  rss=""
  i=0
  while [ $i -lt $RUNS ]; do
    line=$(/usr/bin/time -l "$@" 2>&1 >/dev/null | grep "real\|maximum resident" | tr '\n' ' ')
    t=$(echo "$line" | sed -E 's/.* ([0-9]+\.[0-9]+) real.*/\1/')
    r=$(echo "$line" | sed -E 's/.* ([0-9]+) +maximum resident.*/\1/')
    times="$times $t"
    rss="$rss $r"
    i=$((i+1))
  done
  # median via sort
  med_t=$(printf '%s\n' $times | sort -n | awk '{a[NR]=$1} END {print a[int(NR/2)+1]}')
  med_r=$(printf '%s\n' $rss | sort -n | awk '{a[NR]=$1} END {print a[int(NR/2)+1]}')
  echo "$label|$med_t|$((med_r / 1024)) KB"
}

echo "case=encode_fixed (2025-01-06 12:30:00, 2sec)"
bench "native"        "$NATIVE" encode -q "2025-01-06 12:30:00"
bench "binstub-3.4.8" "$BINSTUB" encode -q "2025-01-06 12:30:00"
bench "exe-3.4.8"     $R34 $INC "$EXE" encode -q "2025-01-06 12:30:00"
bench "exe-4.0.4"     $R40 $INC "$EXE" encode -q "2025-01-06 12:30:00"

echo "case=encode_day (--format day)"
bench "native"        "$NATIVE" encode -q --format day "2025-01-06"
bench "binstub-3.4.8" "$BINSTUB" encode -q --format day "2025-01-06"
bench "exe-3.4.8"     $R34 $INC "$EXE" encode -q --format day "2025-01-06"
bench "exe-4.0.4"     $R40 $INC "$EXE" encode -q --format day "2025-01-06"

echo "case=decode (8c5ir0)"
bench "native"        "$NATIVE" decode 8c5ir0
bench "binstub-3.4.8" "$BINSTUB" decode 8c5ir0
bench "exe-3.4.8"     $R34 $INC "$EXE" decode 8c5ir0
bench "exe-4.0.4"     $R40 $INC "$EXE" decode 8c5ir0

echo "case=config"
bench "native"        "$NATIVE" config
bench "binstub-3.4.8" "$BINSTUB" config
bench "exe-3.4.8"     $R34 $INC "$EXE" config
bench "exe-4.0.4"     $R40 $INC "$EXE" config
