"""Verify explicit Pi extensions in a disposable, provisioned ACE VM."""

import json
import os
import pwd
import re
import shutil
import subprocess
import tempfile

if os.geteuid() != 0 or not os.path.isfile('/var/lib/ace-e2e/runtime-ready.sha256'):
    raise SystemExit('requires root in a provisioned disposable ACE VM')

with open('/var/lib/ace-e2e/input/release-manifest.json', encoding='utf-8') as file:
    manifest = json.load(file)
versions = [gem['version'] for gem in manifest['gems'] if gem['name'] == 'ace-wake']
node_version = manifest['node']['version']
if len(versions) != 1 or not re.fullmatch(r'[A-Za-z0-9.]+', versions[0]) or not re.fullmatch(r'[0-9.]+', node_version):
    raise SystemExit('invalid pinned runtime versions')
source = os.path.join('/opt/ace/runtime/gems/gems', 'ace-wake-' + versions[0], 'handbook/extensions/ace-wake')
integration = '/opt/ace/runtime/pi-agent/extensions/herdr-agent-state.ts'
if not os.path.isfile(os.path.join(source, 'index.js')) or not os.path.isfile(integration):
    raise SystemExit('required installed extensions are unavailable')

account = pwd.getpwnam('mo')
root = tempfile.mkdtemp(prefix='protected-pi-probe-', dir='/opt/ace')
os.chmod(root, 0o755)
passed = False
try:
    managed = os.path.join(root, 'managed')
    shutil.copytree(source, os.path.join(managed, 'ace-wake'), symlinks=False)
    shutil.copyfile(integration, os.path.join(managed, 'herdr-agent-state.ts'))
    for current, dirs, files in os.walk(managed):
        os.chmod(current, 0o755)
        for name in files:
            path = os.path.join(current, name)
            if os.path.islink(path):
                raise RuntimeError('managed extension contains a symlink')
            os.chown(path, 0, 0)
            os.chmod(path, 0o644)
        for name in dirs:
            os.chown(os.path.join(current, name), 0, 0)

    config = os.path.join(root, 'user-config')
    extensions = os.path.join(config, 'extensions')
    os.makedirs(extensions, mode=0o700)
    os.chown(config, account.pw_uid, account.pw_gid)
    os.chown(extensions, account.pw_uid, account.pw_gid)
    untrusted = os.path.join(extensions, 'untrusted-probe.js')
    with open(untrusted, 'x', encoding='utf-8') as file:
        file.write('export default function(pi) { pi.registerCommand("untrusted-probe", '
                   '{description: "probe", handler: async () => {}}); }\n')
    os.chown(untrusted, account.pw_uid, account.pw_gid)
    node = '/opt/ace/toolchains/node-v' + node_version + '-linux-arm64/bin'
    pi = '/opt/ace/runtime/pi/node_modules/.bin/pi'
    env = {'PATH': node + ':/opt/ace/runtime/bin:/usr/bin:/bin', 'HOME': root,
           'PI_CODING_AGENT_DIR': config, 'ACE_TOOLCHAIN': 'installed', 'PI_OFFLINE': '1'}
    command = ['/usr/sbin/runuser', '-u', 'mo', '--', pi, '--mode', 'rpc', '--offline', '--no-session']

    def inventory(extra):
        result = subprocess.run(command + extra, input='{"type":"get_commands"}\n', text=True,
                                stdout=subprocess.PIPE, stderr=subprocess.PIPE, timeout=45, env=env, cwd='/lab')
        if result.returncode:
            raise RuntimeError('Pi RPC did not start successfully (exit %s)' % result.returncode)
        responses = [json.loads(line) for line in result.stdout.splitlines() if line.startswith('{')]
        matches = [row for row in responses if row.get('type') == 'response' and row.get('command') == 'get_commands']
        if len(matches) != 1 or not matches[0].get('success'):
            raise RuntimeError('Pi did not return a successful command inventory')
        return matches[0].get('data', {}).get('commands', [])

    if 'untrusted-probe' not in {entry.get('name') for entry in inventory([])}:
        raise RuntimeError('untrusted control extension was not discovered')
    entries = inventory(['--no-extensions', '--extension', os.path.join(managed, 'ace-wake', 'index.js'),
                         '--extension', os.path.join(managed, 'herdr-agent-state.ts')])
    names = {entry.get('name') for entry in entries}
    if not {'eyes', 'watch'} <= names or 'untrusted-probe' in names:
        raise RuntimeError('managed commands missing or user extension was loaded')
    for entry in entries:
        origin = entry.get('sourceInfo') or {}
        if entry.get('name') in ('eyes', 'watch') and not str(origin.get('path', '')).startswith(managed + '/'):
            raise RuntimeError('managed command origin not reported as expected: ' + repr(entry))
    for path in (root, managed, os.path.join(managed, 'ace-wake'), os.path.join(managed, 'ace-wake', 'index.js')):
        check = subprocess.run(['/usr/sbin/runuser', '-u', 'mo', '--', '/usr/bin/test', '-w', path], timeout=10)
        if check.returncode != 1:
            raise RuntimeError('managed extension write check failed or agent has write access')
    installed = '/opt/ace/runtime/pi-agent/extensions'
    installed_entries = inventory(['--no-extensions', '--extension', os.path.join(installed, 'ace-wake/index.js'),
                                   '--extension', os.path.join(installed, 'herdr-agent-state.ts')])
    for name in ('eyes', 'watch'):
        matches = [entry for entry in installed_entries if entry.get('name') == name]
        if len(matches) != 1 or not str((matches[0].get('sourceInfo') or {}).get('path', '')).startswith(installed + '/'):
            raise RuntimeError('installed projection did not provide ' + name)
    if 'untrusted-probe' in {entry.get('name') for entry in installed_entries}:
        raise RuntimeError('installed projection loaded a user extension')
    for path in (installed, os.path.join(installed, 'ace-wake'),
                 os.path.join(installed, 'ace-wake/index.js'), integration):
        if subprocess.run(['/usr/sbin/runuser', '-u', 'mo', '--', '/usr/bin/test', '-w', path], timeout=10).returncode != 1:
            raise RuntimeError('installed extension is writable or cannot be checked')
    print('protected Pi extensions loaded; user extension excluded; agent cannot write managed files')
    passed = True
finally:
    if passed:
        shutil.rmtree(root)
    else:
        print('probe failed; preserved ' + root)
