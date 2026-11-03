"""Check installed lease recovery after SIGKILL with a synthetic provider."""

import argparse
import json
import os
import re
import shutil
import signal
import stat
import subprocess
import sys
import tempfile
import time

parser = argparse.ArgumentParser()
for option in ('ruby', 'gem-home', 'shared-gems', 'version'):
    parser.add_argument('--' + option, required=True)
args = parser.parse_args()
if os.geteuid() != 0 or not os.path.isdir('/var/lib/ace-e2e'):
    parser.error('requires root in a disposable ACE VM')
for path in (args.ruby, args.gem_home, args.shared_gems):
    if not re.fullmatch(r'/[A-Za-z0-9_./-]+', path) or os.path.normpath(path) != path:
        parser.error('paths must be canonical simple absolute paths')
if not re.fullmatch(r'[A-Za-z0-9.]+', args.version):
    parser.error('invalid version')
parent = os.lstat('/var/lib/ace-e2e')
if not stat.S_ISDIR(parent.st_mode) or parent.st_uid != 0 or parent.st_mode & 0o022:
    parser.error('probe parent is not root-controlled')

root = tempfile.mkdtemp(prefix='execution-crash.', dir='/var/lib/ace-e2e')
os.chmod(root, 0o700)
config = os.path.join(root, 'authorization.yml')
ready = os.path.join(root, 'ready')
leases = os.path.join(root, 'leases')
credentials = os.path.join(root, 'credentials')
with open(config, 'x', encoding='utf-8') as file:
    file.write(f'''auth:
  leases_dir: {leases}
  credentials_dir: {credentials}
  profiles:
    test:
      provider: synthetic
      roles: [worker]
      principals: [probe]
      repos: [fixture]
''')
os.chmod(config, 0o600)
ruby = r'''
gem "ace-lab", "= #{ARGV.fetch(0)}"
require "ace/lab/auth"
class SyntheticProvider
  def capabilities = {"expiry_mode" => "process"}
  def issue(profile:, lease:) = {"token" => "synthetic-only", "token_ref" => "synthetic-ref", "provider_expiry" => nil}
  def revoke(profile:, token_ref:, token: nil) = :revoked
end
Ace::Lab::Auth::Providers.register("synthetic", SyntheticProvider.new)
mode, config, ready = ARGV.values_at(1, 2, 3)
runner = ->(_argv, _env) { File.write(ready, "ready"); sleep 60; 0 }
service = Ace::Lab::Auth::Service.new(authorization_path: config, principal: -> { "probe" }, runner: runner)
if mode == "issue"
  lease = service.request(profile_name: "test", role: "worker", task: "t", assignment: "a", repos: ["fixture"])
  service.exec(lease_id: lease.fetch("id"), argv: ["true"])
  abort "issuer was not killed"
end
records = service.status
raise "wrong lease inventory" unless records.size == 1 && records.first["execution"] == "in-progress" && !records.first["live"]
begin
  service.request(profile_name: "test", role: "worker", task: "t", assignment: "a", repos: ["fixture"])
  abort "reissued an unresolved lease"
rescue Ace::Lab::Auth::Refusal
end
row = service.reconcile.fetch(0)
raise "recovery claimed completion" unless row.fetch("reconciled").include?("execution unresolved")
puts "killed issuer left unresolved execution; retry and false recovery refused"
'''
env = {'PATH': '/usr/bin:/bin', 'HOME': '/var/empty', 'ACE_TOOLCHAIN': 'installed',
       'GEM_HOME': args.gem_home, 'GEM_PATH': args.gem_home + ':' + args.shared_gems}
process = None
passed = False
try:
    process = subprocess.Popen([args.ruby, '-e', ruby, args.version, 'issue', config, ready],
                               env=env, start_new_session=True, stdout=subprocess.DEVNULL, stderr=subprocess.PIPE)
    deadline = time.monotonic() + 15
    while not os.path.isfile(ready) and process.poll() is None and time.monotonic() < deadline:
        time.sleep(0.05)
    if not os.path.isfile(ready):
        raise RuntimeError('issuer did not begin execution')
    os.killpg(process.pid, signal.SIGKILL)
    process.wait(timeout=5)
    files = [name for name in os.listdir(leases) if name.endswith('.json')]
    if len(files) != 1:
        raise RuntimeError('unexpected lease inventory')
    with open(os.path.join(leases, files[0]), encoding='utf-8') as file:
        record = json.load(file)
    if record.get('execution') != 'in-progress':
        raise RuntimeError('execution marker was not persisted')
    result = subprocess.run([args.ruby, '-e', ruby, args.version, 'recover', config, ready],
                            env=env, check=True, timeout=20, text=True, capture_output=True)
    print(result.stdout.strip())
    passed = True
finally:
    if process is not None:
        if process.poll() is None:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)
        process.stderr.close()
    if passed:
        shutil.rmtree(root)
    else:
        print('probe failed; preserve ' + root, file=sys.stderr)
