#!/bin/sh
# Run as the unprivileged lab-operator on the working ARM64 VM after runtime
# provisioning. The resulting artifact is not installed by this script.
set -eu
test "$(id -u)" != 0
test "$(uname -m)" = aarch64
input=/var/lib/ace-e2e/input
manifest="$input/release-manifest.json"
ruby_version=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["ruby"])' "$manifest")
zig_version=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["zig"]["version"])' "$manifest")
rust_version=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["herdr"]["rust_version"])' "$manifest")
target=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["herdr"]["target"])' "$manifest")
baseline=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["herdr"]["baseline_commit"])' "$manifest")
expected_selection=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["herdr"]["selection_sha256"])' "$manifest")
expected_rustup=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["rustup"]["sha256"])' "$manifest")
expected_channel=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["rustup"]["channel_manifest_sha256"])' "$manifest")
printf '%s  %s\n' "$expected_rustup" "$input/artifacts/rustup-init" | sha256sum -c -
printf '%s  %s\n' "$expected_channel" "$input/artifacts/channel-rust-$rust_version.toml" | sha256sum -c -

export GEM_HOME=/opt/ace/runtime/gems GEM_PATH=/opt/ace/runtime/gems ACE_TOOLCHAIN=installed
export PATH="/opt/ace/runtime/gems/bin:/opt/ace/toolchains/ruby-$ruby_version/bin:/opt/ace/toolchains/zig-aarch64-linux-$zig_version:$HOME/.cargo/bin:/usr/bin:/bin"
selection=$(find "$GEM_HOME/gems" -path '*/ace-herdr-*/lib/ace/herdr/native_source/selection.json' -type f)
test -f "$selection"
printf '%s  %s\n' "$expected_selection" "$selection" | sha256sum -c -

test ! -e "$HOME/herdr-source"
test ! -e "$HOME/herdr-build"
"$input/artifacts/rustup-init" -y --profile minimal --default-toolchain "$rust_version" --no-modify-path
rustup target add --toolchain "$rust_version" "$target"
git init "$HOME/herdr-source"
git -C "$HOME/herdr-source" remote add origin https://github.com/herdrdev/herdr.git
git -C "$HOME/herdr-source" fetch --depth=1 origin "$baseline"
git -C "$HOME/herdr-source" checkout --detach "$baseline"
ace-herdr native-source build --source "$HOME/herdr-source" --output "$HOME/herdr-build" --target "$target"
ace-herdr native-source verify --artifact "$HOME/herdr-build"
