# Goal 3 — Full-Index Fallback Install

## Goal

Run `bundle install --full-index` in the sandbox with isolated install paths and
capture user-visible fallback-path outcomes. Record machine-readable lockfile
and activated-version receipts, plus isolated consumer-only resolutions
matching the normal mode, so the full-index graph can be compared against the
same frozen manifest.

## Workspace

Save all output to `results/tc/03/`.

## Steps

1. Define the isolated proof environment once, before any install command.
   It runs the dedicated sandbox Ruby's own bundler directly — never a
   PATH-resolved or shim-resolved `bundle`:
```bash
proof_ruby_root="${ACE_E2E_SANDBOX_RUBY_ROOT:?}"
proof_bundle() {
  proof_case="$1"
  shift
  env -i \
    HOME="$HOME" \
    PATH="$proof_ruby_root/bin:$PATH" \
    PROJECT_ROOT_PATH="$PWD" \
    BUNDLE_GEMFILE="$PWD/Gemfile" \
    BUNDLE_APP_CONFIG="$proof_case/.bundle" \
    BUNDLE_PATH="$proof_case/.bundle" \
    BUNDLE_USER_HOME="$proof_case/bundler-home" \
    BUNDLE_USER_CACHE="$proof_case/bundler-cache" \
    BUNDLE_USER_CONFIG="$proof_case/bundler-config" \
    BUNDLE_DISABLE_SHARED_GEMS=true \
    BUNDLE_WITHOUT="" \
    GEM_HOME="$proof_case/.gem" \
    GEM_PATH="$proof_case/.gem" \
    "$proof_ruby_root/bin/ruby" "$proof_ruby_root/bin/bundle" "$@"
}
consumer_bundle() {
  # Function-local absolute path: the caller keeps its relative path.
  bundle_case="$PWD/$1"
  shift
  env -i \
    HOME="$HOME" \
    PATH="$proof_ruby_root/bin:$PATH" \
    PROJECT_ROOT_PATH="$PWD" \
    BUNDLE_GEMFILE="$bundle_case/Gemfile" \
    BUNDLE_APP_CONFIG="$bundle_case/.bundle" \
    BUNDLE_PATH="$bundle_case/.bundle" \
    BUNDLE_USER_HOME="$bundle_case/bundler-home" \
    BUNDLE_USER_CACHE="$bundle_case/bundler-cache" \
    BUNDLE_USER_CONFIG="$bundle_case/bundler-config" \
    BUNDLE_DISABLE_SHARED_GEMS=true \
    BUNDLE_WITHOUT="" \
    GEM_HOME="$bundle_case/.gem" \
    GEM_PATH="$bundle_case/.gem" \
    "$proof_ruby_root/bin/ruby" "$proof_ruby_root/bin/bundle" "$@"
}
```
   Execute the scenario-prescribed isolation exactly as written: do not drop
   `env -i`, do not substitute partial environment overrides, and do not
   replace the direct `$proof_ruby_root/bin` executables with PATH lookups.

2. Remove any existing `Gemfile.lock` and isolate the fallback install surface:
   - `rm -f Gemfile.lock`
   - `rm -rf .bundle .gem results/tc/03`
   - `mkdir -p results/tc/03/.bundle results/tc/03/.gem results/tc/03/bundler-home results/tc/03/bundler-cache`
   - Pre-create the remaining verifier input contracts (placeholders are NOT
     postcondition evidence; `bundler-config` must be an empty FILE — bundler
     reads `BUNDLE_USER_CONFIG` as a file):
```bash
: > results/tc/03/install-summary.txt
: > results/tc/03/bundler-config
```

3. Record the exact command contract used for fallback execution:
```bash
cat > results/tc/03/install-command.txt <<'EOF'
proof_ruby_root="${ACE_E2E_SANDBOX_RUBY_ROOT:?}"
proof_bundle() {
  proof_case="$1"; shift
  env -i HOME="$HOME" PATH="$proof_ruby_root/bin:$PATH" \
    PROJECT_ROOT_PATH="$PWD" \
    BUNDLE_GEMFILE="$PWD/Gemfile" \
    BUNDLE_APP_CONFIG="$proof_case/.bundle" \
    BUNDLE_PATH="$proof_case/.bundle" \
    BUNDLE_USER_HOME="$proof_case/bundler-home" \
    BUNDLE_USER_CACHE="$proof_case/bundler-cache" \
    BUNDLE_USER_CONFIG="$proof_case/bundler-config" \
    BUNDLE_DISABLE_SHARED_GEMS=true \
    BUNDLE_WITHOUT="" \
    GEM_HOME="$proof_case/.gem" \
    GEM_PATH="$proof_case/.gem" \
    "$proof_ruby_root/bin/ruby" "$proof_ruby_root/bin/bundle" "$@"
}
proof_bundle results/tc/03 install --full-index
EOF
```

4. Run `bundle install --full-index` with the isolated environment:
```bash
proof_bundle results/tc/03 install --full-index > results/tc/03/fullindex.stdout 2> results/tc/03/fullindex.stderr
echo $? > results/tc/03/fullindex.exit
```

5. If install succeeds, capture end-state evidence with the same environment:
   ```bash
   proof_bundle results/tc/03 list > results/tc/03/bundle-list.stdout 2> results/tc/03/bundle-list.stderr
   rg '^\s*\* ace-' results/tc/03/bundle-list.stdout > results/tc/03/installed-ace-gems.txt
   if [ -f Gemfile.lock ]; then
     cp Gemfile.lock results/tc/03/Gemfile.lock
   fi
   cat > results/tc/03/install-summary.txt <<'EOF'
SUCCESS: bundle install --full-index completed.
EOF
```

6. If full-index install fails, write explicit summary evidence:
```bash
if [ "$(cat results/tc/03/fullindex.exit)" != "0" ]; then
  cat > results/tc/03/install-summary.txt <<'EOF'
FAILED: bundle install --full-index did not complete successfully.
See fullindex.stdout and fullindex.stderr for details.
EOF
fi
```

7. Record machine-readable version receipts for the installed graph. The
   receipts — never console output — are the version oracle for acceptance:
```bash
receipt_script="$PWD/ace-monorepo-e2e/test/e2e/TS-MONO-001-rubygems-install/install_receipt.rb"
if [ -s results/tc/03/Gemfile.lock ]; then
  "$proof_ruby_root/bin/ruby" "$receipt_script" receipt \
    --lockfile results/tc/03/Gemfile.lock \
    --out results/tc/03/lockfile-receipt.json
fi
if [ "$(cat results/tc/03/fullindex.exit)" = "0" ]; then
  proof_bundle results/tc/03 exec ruby "$receipt_script" activated \
    --out results/tc/03/install-receipt.json
fi
```

8. Run the isolated consumer-only resolutions for `ace-bundle`, `ace-review`,
   and `ace-task`, matching the full-index mode. Each consumer Gemfile is
   generated from the frozen manifest and names only that consumer at its
   exact artifact version — no direct `ace-git-github` entry:
```bash
for consumer in ace-bundle ace-review ace-task; do
  consumer_dir="results/tc/03/consumer/$consumer"
  rm -rf "$consumer_dir"
  mkdir -p "$consumer_dir"
  "$proof_ruby_root/bin/ruby" "$receipt_script" consumer-gemfile \
    --manifest results/tc/01/release-manifest.json \
    --name "$consumer" \
    --out "$consumer_dir/Gemfile"
  consumer_bundle "$consumer_dir" install --full-index \
    > "$consumer_dir/install.stdout" 2> "$consumer_dir/install.stderr"
  echo $? > "$consumer_dir/install.exit"
  if [ "$(cat "$consumer_dir/install.exit")" = "0" ]; then
    consumer_bundle "$consumer_dir" exec ruby "$receipt_script" activated \
      --out "$consumer_dir/install-receipt.json"
  fi
done
```

## Constraints

- Must use `--full-index` flag.
- Do not modify the Gemfile.
- Do not edit `results/tc/01/release-manifest.json` or generate receipts by
  hand; all receipts must come from `install_receipt.rb` runs.
- Capture command output regardless of success or failure.
- Do not weaken the isolation: keep `env -i`, the confined `results/tc/03/`
  paths, and the direct sandbox-Ruby executables exactly as prescribed.
