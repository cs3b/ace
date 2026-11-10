#!/usr/bin/env python3
"""Reset only an identified disposable scenario; retain its installed runtime."""
import hashlib
import json
import os
from pathlib import Path
import pwd
import re
import shutil
import subprocess
import sys
import tarfile
import time


class FixtureReset:
    PATHS = (
        '/lab', '/etc/forgejo', '/var/lib/forgejo', '/run/ace-e2e-forgejo',
        '/home/mo/.config/ace-e2e', '/home/mo/.pi', '/run/lab/herdr',
        '/home/mo/.config/herdr', '/home/mo/.local/state/herdr',
        '/var/lib/lab/ace-lab/auth', '/var/lib/ace-e2e/forgejo-input',
        '/var/lib/ace-e2e/forgejo-issues.json', '/var/lib/ace-e2e/session-fixture.rb',
        '/etc/lab/ace-lab/authorization.yml', '/etc/lab/ace-lab/pi-auth.json',
        '/home/lab-operator/lab', '/home/lab-operator/forgejo-input',
        '/home/lab-operator/.ace-e2e-auth',
        '/home/lab-operator/ace-e2e-seed.git', '/home/lab-operator/session-fixture.rb',
    )

    def __init__(self, run_id, vm_uuid, root=Path('/')):
        if not re.fullmatch(r'[a-f0-9]{16}', run_id) or not re.fullmatch(r'[a-fA-F0-9-]{36}', vm_uuid):
            raise RuntimeError('invalid fixture identity')
        self.root, self.run_id, self.vm_uuid = root, run_id, vm_uuid
        self.marker = self.path('/var/lib/ace-e2e/fixture-run.json')
        self.baseline = self.path('/var/lib/ace-e2e/install-base.yml')
        self.archive = self.path('/var/lib/ace-e2e/scenario-export-' + run_id + '.tar.gz')

    def path(self, name):
        return self.root / name.lstrip('/')

    def verify(self):
        for name in (*self.PATHS, '/var/lib/ace-e2e/fixture-run.json',
                     '/var/lib/ace-e2e/install-base.yml', '/etc/lab/ace-lab/install.yml',
                     '/etc/profile.d/ace-e2e.sh'):
            target = self.path(name)
            for component in (target, *target.parents):
                if component == self.root.parent:
                    break
                if component.is_symlink():
                    raise RuntimeError('symlink in fixture reset path: ' + name)
        if not self.marker.is_file() or not self.baseline.is_file():
            raise RuntimeError('fixture identity or installation baseline is missing')
        value = json.loads(self.marker.read_text())
        if value != {'run_id': self.run_id, 'vm_uuid': self.vm_uuid}:
            raise RuntimeError('fixture identity differs; reset refused')

    def session_paths(self):
        # The dedicated fixture account has stopped before these are exported
        # or removed. Native sessions keep transcripts beside temporary auth.
        root = self.path('/tmp')
        if root.is_symlink():
            raise RuntimeError('unsafe temporary fixture root')
        candidates = sorted([*root.glob('ace-session-*'), *root.glob('ace-environment-*')])
        if not candidates:
            return []
        uid = pwd.getpwnam('mo').pw_uid
        for path in candidates:
            if path.is_symlink() or path.stat().st_uid != uid:
                raise RuntimeError('unsafe temporary fixture session path')
        return candidates

    def export(self):
        self.verify()
        if self.archive.exists() or self.archive.is_symlink():
            raise RuntimeError('scenario export already exists; preserve it for inspection')
        # mo is the dedicated fixture account in this disposable VM. Never use
        # this operation against an arbitrary lab or without its owner receipt.
        subprocess.run(['pkill', '-TERM', '-u', 'mo'], check=False, stdout=subprocess.DEVNULL)
        time.sleep(1)
        subprocess.run(['pkill', '-KILL', '-u', 'mo'], check=False, stdout=subprocess.DEVNULL)
        for attempt in range(5):
            if subprocess.run(['pgrep', '-u', 'mo'], stdout=subprocess.DEVNULL).returncode == 1:
                break
            time.sleep(1)
        else:
            raise RuntimeError('fixture process exit is unconfirmed')
        subprocess.run(['systemctl', 'stop', 'ace-e2e-forgejo.service'], check=True)
        with self.archive.open('xb') as output:
            os.chmod(self.archive, 0o600)
            with tarfile.open(fileobj=output, mode='w:gz') as archive:
                for name in (*self.PATHS, '/var/lib/ace-e2e/fixture-run.json',
                             '/var/lib/ace-e2e/install-base.yml', '/etc/lab/ace-lab/install.yml'):
                    path = self.path(name)
                    if path.exists():
                        archive.add(path, arcname=name.lstrip('/'), recursive=True)
                for path in self.session_paths():
                    archive.add(path, arcname=str(path.relative_to(self.root)), recursive=True)
            output.flush()
            os.fsync(output.fileno())
        account = pwd.getpwnam('lab-operator')
        os.chown(self.archive, account.pw_uid, account.pw_gid)
        return {'path': str(self.archive), 'sha256': self.digest()}

    def digest(self):
        if self.archive.is_symlink() or not self.archive.is_file():
            raise RuntimeError('scenario export is missing or unsafe')
        with self.archive.open('rb') as source:
            return hashlib.file_digest(source, 'sha256').hexdigest()

    def clear(self, expected):
        self.verify()
        if not re.fullmatch(r'[a-f0-9]{64}', expected) or self.digest() != expected:
            raise RuntimeError('scenario export differs; reset refused')
        session_paths = self.session_paths()
        # The host has already downloaded and hashed this private export.
        subprocess.run(['systemctl', 'disable', '--now', 'ace-e2e-forgejo.service'], check=True)
        for name in self.PATHS:
            path = self.path(name)
            if path.is_dir():
                if name == '/lab':
                    for child in path.iterdir():
                        shutil.rmtree(child) if child.is_dir() and not child.is_symlink() else child.unlink()
                else:
                    shutil.rmtree(path)
            elif path.exists():
                path.unlink()
        for path in session_paths:
            shutil.rmtree(path) if path.is_dir() else path.unlink()
        self.path('/etc/systemd/system/ace-e2e-forgejo.service').unlink(missing_ok=True)
        self.path('/opt/ace/runtime/bin/fj').unlink(missing_ok=True)
        subprocess.run(['systemctl', 'daemon-reload'], check=True)
        shutil.copyfile(self.baseline, self.path('/etc/lab/ace-lab/install.yml'))
        os.chmod(self.path('/etc/lab/ace-lab/install.yml'), 0o644)
        profile = self.path('/etc/profile.d/ace-e2e.sh')
        profile.write_text(''.join(line for line in profile.read_text().splitlines(keepends=True)
                                   if line.strip() != 'export HERDR_SOCKET_PATH=/run/lab/herdr/herdr.sock'))
        self.marker.unlink()
        self.baseline.unlink()
        self.archive.unlink()
        return {'status': 'cleared', 'run_id': self.run_id, 'runtime': 'retained'}


if __name__ == '__main__':
    try:
        if os.geteuid() != 0 or len(sys.argv) not in (4, 5):
            raise RuntimeError('usage: reset-fixture.py export|clear RUN_ID VM_UUID [EXPORT_SHA256] (root)')
        mode, run_id, vm_uuid = sys.argv[1:4]
        fixture = FixtureReset(run_id, vm_uuid)
        if mode == 'export' and len(sys.argv) == 4:
            result = fixture.export()
        elif mode == 'clear' and len(sys.argv) == 5:
            result = fixture.clear(sys.argv[4])
        else:
            raise RuntimeError('invalid reset operation')
        print(json.dumps(result))
    except Exception as error:
        print('fixture reset: ' + str(error), file=sys.stderr)
        sys.exit(1)
