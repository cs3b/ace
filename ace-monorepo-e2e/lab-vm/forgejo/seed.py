#!/usr/bin/env python3
"""Populate the disposable loopback-only forge; never print credentials."""
import json
import os
from pathlib import Path
import subprocess
import urllib.error
import urllib.request

BASE = 'http://127.0.0.1:3000'
OWNER = 'e2e-integrator'
REPO = 'ace'
TOKENS = Path('/run/ace-e2e-forgejo')

def api(method, path, token, payload=None):
    data = None if payload is None else json.dumps(payload).encode()
    request = urllib.request.Request(BASE + '/api/v1' + path, data=data, method=method,
        headers={'Authorization': 'token ' + token, 'Content-Type': 'application/json'})
    try:
        with urllib.request.urlopen(request, timeout=20) as response:
            body = response.read()
            return json.loads(body) if body else None
    except urllib.error.HTTPError as error:
        raise RuntimeError(f'Forgejo API {method} {path} returned HTTP {error.code}') from None

admin = (TOKENS / 'e2e-admin.token').read_text().strip()
owner = (TOKENS / 'e2e-integrator.token').read_text().strip()
assert admin and owner
api('POST', '/admin/users/e2e-integrator/repos', admin,
    {'name': REPO, 'private': True, 'auto_init': False, 'default_branch': 'main'})
api('PUT', f'/repos/{OWNER}/{REPO}/collaborators/e2e-reviewer', owner, {'permission': 'write'})
# The credential file is temporary, readable only by the seeding account and is
# removed immediately afterwards. The remote URL and process argv contain no token.
credential = Path('/home/lab-operator/.ace-e2e-seed-token')
credential.write_text(owner)
os.chown(credential, int(os.environ['OPERATOR_UID']), int(os.environ['OPERATOR_GID']))
credential.chmod(0o400)
askpass = Path('/home/lab-operator/.ace-e2e-askpass')
askpass.write_text('#!/bin/sh\ncase "$1" in *sername*) printf "%s\\n" e2e-integrator ;; *) cat /home/lab-operator/.ace-e2e-seed-token ;; esac\n')
os.chown(askpass, int(os.environ['OPERATOR_UID']), int(os.environ['OPERATOR_GID']))
askpass.chmod(0o500)
try:
    subprocess.run(['runuser', '-u', 'lab-operator', '--', 'env',
        'GIT_TERMINAL_PROMPT=0', 'GIT_ASKPASS=' + str(askpass),
        'git', 'clone', '--bare', '/var/lib/ace-e2e/forgejo-input/fixture.bundle',
        '/home/lab-operator/ace-e2e-seed.git'], check=True, stdout=subprocess.DEVNULL)
    subprocess.run(['runuser', '-u', 'lab-operator', '--', 'env',
        'GIT_TERMINAL_PROMPT=0', 'GIT_ASKPASS=' + str(askpass),
        'git', '-C', '/home/lab-operator/ace-e2e-seed.git', 'push',
        BASE + '/' + OWNER + '/' + REPO + '.git', 'main:main'], check=True)
finally:
    credential.unlink(missing_ok=True)
    askpass.unlink(missing_ok=True)

expected = Path('/var/lib/ace-e2e/forgejo-input/initial-sha').read_text().strip()
reference = api('GET', f'/repos/{OWNER}/{REPO}/git/refs/heads/main', owner)
if reference['object']['sha'] != expected:
    raise RuntimeError('local forge main does not match the seeded commit')
issues = json.loads(Path('/var/lib/ace-e2e/forgejo-input/issues.json').read_text())
created = {}
for issue in issues:
    body = issue['body']
    for key, item in created.items():
        body = body.replace('{{issue:' + key + '}}', item['url'])
    if '{{issue:' in body:
        raise RuntimeError('issue dependency is not yet created')
    result = api('POST', f'/repos/{OWNER}/{REPO}/issues', owner,
        {'title': issue['title'], 'body': body})
    number = result['number']
    created[issue['key']] = {'url': f'{BASE}/{OWNER}/{REPO}/issues/{number}',
        'number': number, 'depends_on': issue.get('depends_on', []), 'kind': issue.get('kind')}
Path('/var/lib/ace-e2e/forgejo-issues.json').write_text(json.dumps(created) + '\n')
print(json.dumps({'repository': OWNER + '/' + REPO, 'issues': created}))
