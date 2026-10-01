# Goal 2 — Normal Bundle Install

## Goal

Run `bundle install` in an isolated sandbox and capture user-visible install
outcomes as the primary evidence for normal-path viability. Record
machine-readable lockfile and activated-version receipts, plus isolated
consumer-only resolutions that prove the released `ace-bundle`, `ace-review`,
and `ace-task` dependency edges reach `ace-git-github` without a direct
Gemfile entry.

## Workspace

Save all output to `results/tc/02/`.

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
    LANG="${ACE_E2E_LANG:-C.UTF-8}" \
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
    LANG="${ACE_E2E_LANG:-C.UTF-8}" \
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

2. Ensure a clean local install surface and output workspace:
   - `rm -f Gemfile.lock`
   - `rm -rf .bundle .gem results/tc/02`
   - `mkdir -p results/tc/02/.bundle results/tc/02/.gem results/tc/02/bundler-home results/tc/02/bundler-cache`
   - Pre-create the remaining verifier input contracts (placeholders are NOT
     postcondition evidence; `bundler-config` must be an empty FILE — bundler
     reads `BUNDLE_USER_CONFIG` as a file):
```bash
: > results/tc/02/install-summary.txt
: > results/tc/02/bundler-config
```

3. Record the exact command contract used for execution:
```bash
cat > results/tc/02/install-command.txt <<'EOF'
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
proof_bundle results/tc/02 install
EOF
```

4. Run `bundle install` with the isolated environment:
```bash
proof_bundle results/tc/02 install > results/tc/02/install.stdout 2> results/tc/02/install.stderr
echo $? > results/tc/02/install.exit
```

5. If install succeeds, capture end-state evidence with the same environment:
   ```bash
   proof_bundle results/tc/02 list > results/tc/02/bundle-list.stdout 2> results/tc/02/bundle-list.stderr
   rg '^\s*\* ace-' results/tc/02/bundle-list.stdout > results/tc/02/installed-ace-gems.txt
   if [ -f Gemfile.lock ]; then
     cp Gemfile.lock results/tc/02/Gemfile.lock
   fi
   if [ -s results/tc/02/installed-ace-gems.txt ] && [ -s results/tc/02/Gemfile.lock ]; then
     cat > results/tc/02/install-summary.txt <<'EOF'
SUCCESS: bundle install completed in normal mode with installed ace gem evidence.
EOF
   else
     cat > results/tc/02/install-summary.txt <<'EOF'
SUCCESS: bundle install completed in normal mode, but post-install bundle evidence was incomplete. See bundle-list stdout/stderr and copied lockfile artifacts.
EOF
   fi
   ```

6. If install fails, write an explicit summary and preserve command output as evidence:
```bash
if [ "$(cat results/tc/02/install.exit)" != "0" ]; then
  cat > results/tc/02/install-summary.txt <<'EOF'
FAILED: bundle install did not complete successfully in normal mode.
See install.stdout and install.stderr for details.
EOF
fi
```

7. Record machine-readable version receipts for the installed graph. The
   receipts — never console output — are the version oracle for acceptance:
```bash
receipt_script="$PWD/ace-monorepo-e2e/test/e2e/TS-MONO-001-rubygems-install/install_receipt.rb"
if [ -s results/tc/02/Gemfile.lock ]; then
  "$proof_ruby_root/bin/ruby" "$receipt_script" receipt \
    --lockfile results/tc/02/Gemfile.lock \
    --out results/tc/02/lockfile-receipt.json
fi
if [ "$(cat results/tc/02/install.exit)" = "0" ]; then
  proof_bundle results/tc/02 exec ruby "$receipt_script" activated \
    --out results/tc/02/install-receipt.json
fi
```

8. Run the isolated consumer-only resolutions for `ace-bundle`, `ace-review`,
   and `ace-task`. Each consumer Gemfile is generated from the frozen
   manifest (`results/tc/01/release-manifest.json`) and names only that
   consumer at its exact artifact version — no direct `ace-git-github`
   entry — so the provider version can only come from the consumer's
   published dependency edge:
```bash
for consumer in ace-bundle ace-review ace-task; do
  consumer_dir="results/tc/02/consumer/$consumer"
  rm -rf "$consumer_dir"
  mkdir -p "$consumer_dir"
  "$proof_ruby_root/bin/ruby" "$receipt_script" consumer-gemfile \
    --manifest results/tc/01/release-manifest.json \
    --name "$consumer" \
    --out "$consumer_dir/Gemfile"
  consumer_bundle "$consumer_dir" install \
    > "$consumer_dir/install.stdout" 2> "$consumer_dir/install.stderr"
  echo $? > "$consumer_dir/install.exit"
  if [ "$(cat "$consumer_dir/install.exit")" = "0" ]; then
    consumer_bundle "$consumer_dir" exec ruby "$receipt_script" activated \
      --out "$consumer_dir/install-receipt.json"
  fi
done
```

## Declared consumer receipt contract (verifier input)

The consumer-only resolutions produce exactly these verifier-consumed
artifacts (three consumers x Gemfile, install exit, lockfile, activated
receipt):

- `results/tc/02/consumer/ace-bundle/Gemfile`
- `results/tc/02/consumer/ace-bundle/install.exit`
- `results/tc/02/consumer/ace-bundle/Gemfile.lock`
- `results/tc/02/consumer/ace-bundle/install-receipt.json`
- `results/tc/02/consumer/ace-review/Gemfile`
- `results/tc/02/consumer/ace-review/install.exit`
- `results/tc/02/consumer/ace-review/Gemfile.lock`
- `results/tc/02/consumer/ace-review/install-receipt.json`
- `results/tc/02/consumer/ace-task/Gemfile`
- `results/tc/02/consumer/ace-task/install.exit`
- `results/tc/02/consumer/ace-task/Gemfile.lock`
- `results/tc/02/consumer/ace-task/install-receipt.json`

## Constraints


- Do not use `--full-index` — that is tested in Goal 3.
- Do not modify the Gemfile.
- Do not edit `results/tc/01/release-manifest.json` or generate receipts by
  hand; all receipts must come from `install_receipt.rb` runs.
- Capture command output regardless of success or failure.
- Do not weaken the isolation: keep `env -i`, the confined `results/tc/02/`
  paths, and the direct sandbox-Ruby executables exactly as prescribed.
