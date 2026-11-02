#!/bin/sh
# Run only in a disposable working clone, as root, with the fixture copied to
# /var/lib/ace-e2e/input. Never run this against the UTM base image.
set -eu

input=/var/lib/ace-e2e/input
runtime=/opt/ace
test "$(id -u)" = 0
test "$(uname -m)" = aarch64
test -f "$input/release-manifest.json"
test -d "$input/artifacts"
test -f "$input/pi/package-lock.json"

# Verify every downloaded input in the guest too, before executing any of it.
python3 - "$input" <<'PY'
import hashlib, json, pathlib, re, sys, urllib.parse
root = pathlib.Path(sys.argv[1])
manifest = json.loads((root / 'release-manifest.json').read_text())
assert manifest['schema'] == 'ace-e2e-release/v1'
for version in (manifest['ruby'], manifest['node']['version'], manifest['zig']['version']):
    assert re.fullmatch(r'[0-9]+(?:\.[0-9]+)+', version), version
for gem in manifest['gems']:
    assert re.fullmatch(r'[a-zA-Z0-9_-]+', gem['name'])
    assert re.fullmatch(r'[a-zA-Z0-9.]+', gem['version'])
files = [(g['name'] + '-' + g['version'] + '.gem', g['sha256']) for g in manifest['gems']]
files += [(pathlib.PurePosixPath(urllib.parse.urlsplit(manifest[k]['url']).path).name,
           manifest[k]['sha256']) for k in ('ruby_source', 'node', 'zig', 'rustup')]
files += [(pathlib.PurePosixPath(urllib.parse.urlsplit(manifest['rustup']['channel_manifest_url']).path).name,
           manifest['rustup']['channel_manifest_sha256'])]
for name, wanted in files:
    assert re.fullmatch(r'[a-zA-Z0-9_.-]+', name)
    path = root / 'artifacts' / name
    assert path.is_file() and not path.is_symlink(), name
    digest = hashlib.sha256()
    with path.open('rb') as stream:
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            digest.update(block)
    if digest.hexdigest() != wanted:
        raise SystemExit('checksum mismatch: ' + name)
print('verified', len(files), 'artifacts')
PY
chmod 0644 "$input"/artifacts/*
chmod 0755 "$input/artifacts/rustup-init"

export DEBIAN_FRONTEND=noninteractive
python3 - "$input/release-manifest.json" <<'PY'
import hashlib, json, re, sys, urllib.request
s = json.load(open(sys.argv[1]))['apt_snapshot']
stamp = s['timestamp']
assert re.fullmatch(r'\d{8}T\d{6}Z', stamp)
lines = []
for archive, suite, key in [('debian', 'trixie', 'debian_release_sha256'),
                            ('debian-security', 'trixie-security', 'security_release_sha256')]:
    base = 'https://snapshot.debian.org/archive/' + archive + '/' + stamp + '/'
    with urllib.request.urlopen(base + 'dists/' + suite + '/Release', timeout=60) as response:
        if hashlib.sha256(response.read()).hexdigest() != s[key]:
            raise SystemExit('Debian snapshot Release checksum mismatch: ' + archive)
    lines.append('deb [check-valid-until=no] ' + base + ' ' + suite + ' main\n')
open('/var/lib/ace-e2e/debian-snapshot.list', 'w').writelines(lines)
PY
apt-get -o Dir::Etc::sourcelist=/var/lib/ace-e2e/debian-snapshot.list -o Dir::Etc::sourceparts=- update
apt-get -o Dir::Etc::sourcelist=/var/lib/ace-e2e/debian-snapshot.list -o Dir::Etc::sourceparts=- install -y build-essential ca-certificates curl git libssl-dev zlib1g-dev \
  libyaml-dev libreadline-dev libffi-dev libgdbm-dev libncurses-dev libgmp-dev \
  pkg-config xz-utils musl-tools
mkdir -p "$runtime/toolchains" "$runtime/runtime" /var/lib/ace-e2e/build
cd /var/lib/ace-e2e/build

ruby_version=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["ruby"])' "$input/release-manifest.json")
node_version=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["node"]["version"])' "$input/release-manifest.json")
zig_version=$(python3 -c 'import json,sys; print(json.load(open(sys.argv[1]))["zig"]["version"])' "$input/release-manifest.json")
builder_version=$(python3 -c 'import json,sys; print(next(g["version"] for g in json.load(open(sys.argv[1]))["gems"] if g["name"] == "builder"))' "$input/release-manifest.json")
index_version=$(python3 -c 'import json,sys; print(next(g["version"] for g in json.load(open(sys.argv[1]))["gems"] if g["name"] == "rubygems-generate_index"))' "$input/release-manifest.json")
lab_version=$(python3 -c 'import json,sys; print(next(g["version"] for g in json.load(open(sys.argv[1]))["gems"] if g["name"] == "ace-lab"))' "$input/release-manifest.json")

if [ ! -x "$runtime/toolchains/ruby-$ruby_version/bin/ruby" ]; then
  tar -xzf "$input/artifacts/ruby-$ruby_version.tar.gz"
  cd "ruby-$ruby_version"
  ./configure --prefix="$runtime/toolchains/ruby-$ruby_version" --disable-install-doc '--with-out-ext=-test-/*'
  make -s -j4
  make install
  cd ..
fi
if [ ! -x "$runtime/toolchains/node-v$node_version-linux-arm64/bin/node" ]; then
  tar -xJf "$input/artifacts/node-v$node_version-linux-arm64.tar.xz" -C "$runtime/toolchains"
fi
if [ ! -x "$runtime/toolchains/zig-aarch64-linux-$zig_version/zig" ]; then
  tar -xJf "$input/artifacts/zig-aarch64-linux-$zig_version.tar.xz" -C "$runtime/toolchains"
fi
export PATH="$runtime/toolchains/ruby-$ruby_version/bin:$runtime/toolchains/node-v$node_version-linux-arm64/bin:$PATH"
export GEM_HOME="$runtime/runtime/gems" GEM_PATH="$runtime/runtime/gems"
mkdir -p "$GEM_HOME" /var/lib/ace-e2e/gem-repository/gems

# Converge a minimal set of roots. The local index contains one pinned
# version of every dependency, and the graph and complete installed set are
# checked independently. Listing every transitive dependency as another root
# makes ace-lab traverse the same closures repeatedly on every reset.
ruby "$input/gem-graph.rb" "$input/release-manifest.json" "$input/artifacts" /var/lib/ace-e2e/install-roots.json
python3 - "$input/release-manifest.json" "$input/artifacts" /var/lib/ace-e2e/gem-repository/gems <<'PY'
import json, pathlib, shutil, sys
manifest = json.load(open(sys.argv[1]))
source, destination = map(pathlib.Path, sys.argv[2:])
for gem in manifest['gems']:
    name = gem['name'] + '-' + gem['version'] + '.gem'
    shutil.copyfile(source / name, destination / name)
PY
cd /var/lib/ace-e2e/gem-repository/gems
cat > /root/.gemrc <<'EOF'
---
:sources:
- file:///var/lib/ace-e2e/gem-repository
EOF
gem install --local --no-document "./builder-$builder_version.gem"
gem install --local --no-document "./rubygems-generate_index-$index_version.gem"
gem generate_index --directory /var/lib/ace-e2e/gem-repository
# Explicitly install the pinned prerelease adapter before ace-lab resolves it.
forgejo_version=$(python3 -c 'import json,sys; print(next(g["version"] for g in json.load(open(sys.argv[1]))["gems"] if g["name"] == "ace-git-forgejo"))' "$input/release-manifest.json")
gem install --local --no-document "./ace-git-forgejo-$forgejo_version.gem"
gem install --local --no-document "./ace-lab-$lab_version.gem"
# Explicitly install the pinned prerelease ace-herdr before other roots resolve
# dependencies; RubyGems does not otherwise select prereleases implicitly.
herdr_version=$(python3 -c 'import json,sys; print(next(g["version"] for g in json.load(open(sys.argv[1]))["gems"] if g["name"] == "ace-herdr"))' "$input/release-manifest.json")
gem install --local --no-document "./ace-herdr-$herdr_version.gem"
ruby - "$forgejo_version" "$lab_version" "$herdr_version" <<'RUBY'
%w[ace-git-forgejo ace-lab ace-herdr].zip(ARGV).each do |name, version|
  gem name, "= #{version}"
  abort "pinned #{name} did not activate" unless Gem.loaded_specs.fetch(name).version.to_s == version
end
puts "verified pinned local candidate activation"
RUBY

# The installer is the state owner for the operational gem set. Its source is
# the verified local repository, so transitive fetches cannot escape the pin.
mkdir -p /etc/lab/ace-lab
python3 - "$input/release-manifest.json" > /etc/lab/ace-lab/install.yml <<'PY'
import json, sys
d = json.load(open(sys.argv[1]))
roots = json.load(open('/var/lib/ace-e2e/install-roots.json'))
gems = {g['name']: g for g in d['gems']}
print('schema_version: 1\nmachine: utm-e2e\naccounts:\n  - username: mo\n    role: worker\n    create: false')
print('directories:\n  - path: /lab\n    owner: mo\n    mode: "0755"')
print('gemset:\n  gem_home: /opt/ace/runtime/gems\n  gems:')
for name in roots:
    gem = gems[name]
    print('    - name: ' + gem['name'] + '\n      version: ' + gem['version'])
print('  extensions:\n    - gem: ace-wake\n      path: /home/mo/.pi/agent/extensions\n      account: mo')
PY
chmod 0644 /etc/lab/ace-lab/install.yml
export PATH="$GEM_HOME/bin:$PATH" ACE_TOOLCHAIN=installed
ace-lab install
ace-lab verify
ruby -rjson - "$input/release-manifest.json" <<'RUBY'
manifest = JSON.parse(File.read(ARGV.fetch(0)))
expected = manifest.fetch("gems").map { |gem| [gem.fetch("name"), gem.fetch("version")] }.sort
actual = Gem::Specification.reject(&:default_gem?).map { |gem| [gem.name, gem.version.to_s] }.sort
abort "external gemset differs from the pinned manifest" unless actual == expected
expected.each do |name, version|
  selected = Gem::Specification.find_all_by_name(name).max_by(&:version)
  abort "a different version would activate for #{name}" unless selected && selected.version == Gem::Version.new(version)
end
puts "verified exact external gemset: #{actual.length} entries"
RUBY

mkdir -p "$runtime/runtime/pi"
cp "$input/pi/package.json" "$input/pi/package-lock.json" "$runtime/runtime/pi/"
cd "$runtime/runtime/pi"
npm ci --no-audit --no-fund
cat > /etc/profile.d/ace-e2e.sh <<EOF
export GEM_HOME=/opt/ace/runtime/gems
export GEM_PATH=/opt/ace/runtime/gems
export ACE_TOOLCHAIN=installed
export PATH=/opt/ace/runtime/bin:/opt/ace/runtime/gems/bin:/opt/ace/runtime/pi/node_modules/.bin:/opt/ace/toolchains/ruby-$ruby_version/bin:/opt/ace/toolchains/node-v$node_version-linux-arm64/bin:\$PATH
EOF
chown -R root:root "$runtime"
chmod -R go-w "$runtime"
test "$(stat -c '%U:%G' /lab)" = mo:mo
! sudo -n -l -U mo >/dev/null 2>&1
printf '%s\n' 'Runtime provisioned; Herdr native build and E2E readiness remain separate checks.'
