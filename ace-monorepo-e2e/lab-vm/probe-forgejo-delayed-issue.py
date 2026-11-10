"""Reproduce a late token creation after a timed-out issue on disposable Forgejo."""

import argparse
import base64
import hmac
import json
import os
import re
import secrets
import selectors
import shutil
import signal
import subprocess
import tempfile
import threading
import time
import urllib.error
import urllib.request
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

parser = argparse.ArgumentParser()
for option in ('ruby', 'gem-home', 'shared-gems', 'version'):
    parser.add_argument('--' + option, required=True)
args = parser.parse_args()
if os.geteuid() != 0 or not os.path.isdir('/var/lib/ace-e2e'):
    parser.error('requires root in a provisioned disposable ACE VM')
for value in (args.ruby, args.gem_home, args.shared_gems):
    if not re.fullmatch(r'/[A-Za-z0-9_./-]+', value):
        parser.error('paths must be simple absolute paths')
if not re.fullmatch(r'[A-Za-z0-9.]+', args.version):
    parser.error('invalid gem version')


def bounded_run(argv, *, timeout, env=None):
    process = subprocess.Popen(argv, stdin=subprocess.DEVNULL, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
                               env=env, start_new_session=True)
    streams = {process.stdout: bytearray(), process.stderr: bytearray()}
    selector = selectors.DefaultSelector()
    deadline = time.monotonic() + timeout
    try:
        for stream in streams:
            selector.register(stream, selectors.EVENT_READ)
        while selector.get_map():
            remaining = deadline - time.monotonic()
            if remaining <= 0:
                raise subprocess.TimeoutExpired(argv, timeout)
            ready = selector.select(remaining)
            if not ready:
                raise subprocess.TimeoutExpired(argv, timeout)
            for key, _ in ready:
                chunk = os.read(key.fileobj.fileno(), 8192)
                if not chunk:
                    selector.unregister(key.fileobj)
                    continue
                streams[key.fileobj].extend(chunk)
                if sum(map(len, streams.values())) > 1_048_576:
                    raise RuntimeError('probe subprocess output limit exceeded')
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            raise subprocess.TimeoutExpired(argv, timeout)
        code = process.wait(timeout=remaining)
        return subprocess.CompletedProcess(argv, code,
            bytes(streams[process.stdout]).decode('utf-8', 'replace'),
            bytes(streams[process.stderr]).decode('utf-8', 'replace'))
    except BaseException:
        try:
            os.killpg(process.pid, signal.SIGKILL)
        except ProcessLookupError:
            pass
        try:
            process.wait(timeout=3)
        except subprocess.TimeoutExpired:
            pass
        raise
    finally:
        selector.close()
        for stream in streams:
            stream.close()


if bounded_run(['/usr/bin/systemctl', 'is-active', '--quiet', 'ace-e2e-forgejo.service'], timeout=10).returncode:
    raise RuntimeError('local test Forgejo is not active')

name = 'acelate' + secrets.token_hex(16)
root = tempfile.mkdtemp(prefix='ace-forgejo-delayed-', dir='/run')
os.chmod(root, 0o700)
base = ['/usr/sbin/runuser', '-u', 'forgejo', '--', '/usr/local/bin/forgejo', 'admin', 'user']
common = ['--config', '/etc/forgejo/app.ini', '--work-path', '/var/lib/forgejo']
release = threading.Event()
completed = threading.Event()
state_lock = threading.Lock()
state = {'name': None, 'headers': None, 'post_status': None, 'delete_statuses': [],
         'posts': 0, 'forward_started': False, 'expected_auth': None}
created = False
creation_attempted = False
cleaned = False
passed = False
opener = urllib.request.build_opener(urllib.request.ProxyHandler({}))


def forward(method, path, headers, body=None):
    request = urllib.request.Request('http://127.0.0.1:3000' + path, data=body,
                                     headers=headers, method=method)
    outcome = []

    def perform():
        try:
            with opener.open(request, timeout=10) as response:
                content = response.read(1_048_577)
                outcome.append((response.status, content))
        except urllib.error.HTTPError as error:
            outcome.append((error.code, error.read(1_048_577)))
        except Exception as error:
            outcome.append(error)

    worker = threading.Thread(target=perform, daemon=True)
    worker.start()
    worker.join(10)
    if worker.is_alive() or not outcome:
        raise TimeoutError('forge response deadline exceeded')
    if isinstance(outcome[0], Exception):
        raise outcome[0]
    status, content = outcome[0]
    if len(content) > 1_048_576:
        raise RuntimeError('forge response is oversized')
    return status, content


class Proxy(BaseHTTPRequestHandler):
    def setup(self):
        super().setup()
        self.connection.settimeout(10)

    def log_message(self, *_args):
        pass

    def do_POST(self):
        if self.path != '/api/v1/users/' + name + '/tokens' or not self.authenticated():
            self.send_error(403)
            return
        size = int(self.headers['Content-Length'])
        if size < 1 or size > 65536:
            self.send_error(413)
            return
        body = self.rfile.read(size)
        token_name = json.loads(body)['name']
        if not re.fullmatch(r'ace-lab-lease-[0-9a-f]{16}', token_name):
            self.send_error(400)
            return
        with state_lock:
            state['posts'] += 1
            if state['posts'] != 1:
                self.send_error(409)
                return
            state['name'] = token_name
            state['headers'] = {key: self.headers[key] for key in ('Authorization', 'Sudo', 'Content-Type')}
        try:
            if not release.wait(45):
                return
            state['forward_started'] = True
            state['post_status'], _ = forward('POST', self.path, state['headers'], body)
        finally:
            completed.set()

    def do_DELETE(self):
        expected = '/api/v1/users/' + name + '/tokens/' + str(state['name'])
        if state['name'] is None or self.path != expected or not self.authenticated():
            self.send_error(403)
            return
        headers = {key: self.headers[key] for key in ('Authorization', 'Sudo')}
        status, body = forward('DELETE', self.path, headers)
        state['delete_statuses'].append(status)
        self.send_response(status)
        self.end_headers()
        self.wfile.write(body)

    def authenticated(self):
        expected = state['expected_auth']
        supplied = self.headers.get('Authorization', '')
        return bool(expected and hmac.compare_digest(expected, supplied) and
                    self.headers.get('Sudo') == name)

    def do_GET(self):
        if self.path != '/release':
            self.send_error(404)
            return
        release.set()
        if state['posts'] and not completed.wait(15):
            self.send_error(504)
            return
        self.send_response(200)
        self.end_headers()


ruby = r"""
gem 'ace-lab', '= ' + ENV.fetch('ACE_E2E_GEM_VERSION')
require 'ace/lab'; require 'ace/lab/auth'; require 'yaml'; require 'net/http'
root, admin, port = ARGV
issuer={'url'=>"http://127.0.0.1:#{port}", 'account'=>admin,
  'admin_username'=>admin, 'password_file'=>root+'/admin-password'}
doc={'auth'=>{'leases_dir'=>root+'/leases', 'credentials_dir'=>root+'/credentials',
  'profiles'=>{'forge'=>{'provider'=>'forgejo', 'roles'=>['worker'],
  'repos'=>['e2e-integrator/ace'], 'scopes'=>['write:repository'], 'issuer'=>issuer}}}}.to_yaml
Ace::Lab::Molecules::GrantResolver.define_singleton_method(:read_verified){|_| doc}
svc=Ace::Lab::Auth::Service.new(runner: ->(*) { raise 'unused test runner' })
request=-> { svc.request(profile_name:'forge', role:'worker', task:'delayed',
  assignment:'delayed', repos:['e2e-integrator/ace']) }
begin
  begin
    request.call
    raise 'issue unexpectedly returned'
  rescue Ace::Lab::Auth::Error => e
    raise unless e.message.include?('issuance failed with unknown outcome')
  end
  record=svc.store.all.fetch(0)
  raise 'unknown issue not pending' unless record['state']=='revoke-pending'
  begin; request.call; raise 'retry unexpectedly issued'; rescue Ace::Lab::Auth::Refusal; end
  raise '404 falsely settled issue' unless svc.store.load(record.fetch('id'))['state']=='revoke-pending'
  response=Net::HTTP.new('127.0.0.1', port.to_i, nil).get('/release')
  raise 'delayed request did not finish' unless response.code=='200'
  # The service retains the proxy URL, so switch only the test proxy to
  # forward the recovery DELETE to the real forge after the POST finishes.
  outcome=svc.revoke(lease_id:record.fetch('id'))
  raise 'late token revocation unconfirmed' unless outcome==:revoked &&
    svc.store.load(record.fetch('id'))['state']=='revoked'
  puts 'timeout_404_kept_pending=true retry_refused=true late_token_revoked=true'
ensure
  begin; Net::HTTP.new('127.0.0.1', port.to_i, nil).get('/release'); rescue StandardError; end
end
"""

class BoundedServer(ThreadingHTTPServer):
    daemon_threads = True

    def __init__(self, *args):
        self.condition = threading.Condition()
        self.handlers = 0
        super().__init__(*args)

    def process_request(self, request, client_address):
        with self.condition:
            self.handlers += 1
        try:
            super().process_request(request, client_address)
        except Exception:
            with self.condition:
                self.handlers -= 1
                self.condition.notify_all()
            raise

    def process_request_thread(self, request, client_address):
        try:
            super().process_request_thread(request, client_address)
        finally:
            with self.condition:
                self.handlers -= 1
                self.condition.notify_all()

    def wait_handlers(self, timeout):
        deadline = time.monotonic() + timeout
        with self.condition:
            while self.handlers:
                remaining = deadline - time.monotonic()
                if remaining <= 0:
                    return False
                self.condition.wait(remaining)
            return True


server = BoundedServer(('127.0.0.1', 0), Proxy)
thread = threading.Thread(target=server.serve_forever, daemon=True)
thread.start()
try:
    creation_attempted = True
    result = bounded_run(base + ['create'] + common + [
        '--username', name, '--email', name + '@example.invalid', '--random-password',
        '--must-change-password=false', '--admin'], timeout=60)
    if result.returncode:
        raise RuntimeError('temporary administrator creation failed')
    created = True
    match = re.search(r"(?i)password\s+is\s+'([^']+)'", result.stdout + '\n' + result.stderr)
    if not match:
        raise RuntimeError('generated password format differs')
    fd = os.open(root + '/admin-password', os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as file:
        file.write(match.group(1))
    state['expected_auth'] = 'Basic ' + base64.b64encode((name + ':' + match.group(1)).encode()).decode()
    env = {key: value for key, value in os.environ.items() if not key.lower().endswith('_proxy')}
    env.update({'GEM_HOME': args.gem_home, 'GEM_PATH': args.gem_home + ':' + args.shared_gems,
                'ACE_TOOLCHAIN': 'installed', 'ACE_E2E_GEM_VERSION': args.version,
                'PATH': os.path.dirname(args.ruby) + ':/usr/bin:/bin'})
    probe = bounded_run([args.ruby, '-e', ruby, root, name, str(server.server_port)], env=env, timeout=90)
    if probe.returncode:
        fd = os.open(root + '/failure.log', os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, 'w') as file:
            file.write(probe.stdout + '\n' + probe.stderr)
        raise RuntimeError('delayed-issue probe failed; guest evidence retained')
    if state['posts'] != 1 or state['delete_statuses'] != [404, 204] or state['post_status'] not in (200, 201):
        raise RuntimeError('delayed Forgejo request did not exercise the intended race')
    print(probe.stdout.strip())
    passed = True
finally:
    release.set()
    # Stop accepting requests, then join all handlers before deciding
    # whether a forwarded POST can still create a token.
    server.shutdown()
    server.server_close()
    handlers_finished = server.wait_handlers(20)
    if not handlers_finished:
        print('proxy_handlers_outcome_unknown=true')
    elif state['posts'] and (not completed.wait(20) or
                            state['forward_started'] and state['post_status'] not in (200, 201)):
        print('delayed_request_outcome_unknown=true')
    elif state['name'] and state['headers']:
        try:
            status, _ = forward('DELETE', '/api/v1/users/' + name + '/tokens/' + state['name'],
                                {key: state['headers'][key] for key in ('Authorization', 'Sudo')})
            cleaned = status in (204, 404)
        except Exception:
            cleaned = False
    else:
        cleaned = True
    if creation_attempted and not created:
        # A timed-out create may still complete after an absent-user check.
        # Without confirmed creation we cannot establish ownership of an
        # existing name; preserve it for operator inspection, never delete it.
        cleaned = False
        print('administrator_creation_outcome_unknown=' + name)
    if created and cleaned:
        try:
            deleted = bounded_run(base + ['delete'] + common + ['--username', name], timeout=60)
        except (OSError, RuntimeError, subprocess.TimeoutExpired):
            cleaned = False
        else:
            if deleted.returncode:
                cleaned = False
            else:
                print('temporary_admin_removed=true')
    if cleaned and passed:
        shutil.rmtree(root)
    elif not cleaned:
        print('diagnostic_state_retained=' + root + ' admin=' + name)
        raise RuntimeError('late token or temporary administrator cleanup was not confirmed')
    else:
        print('diagnostic_state_retained=' + root)
