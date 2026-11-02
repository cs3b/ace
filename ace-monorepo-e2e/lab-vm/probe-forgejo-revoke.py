"""Probe scoped token recovery on the disposable VM's local Forgejo."""

import argparse
import os
import re
import secrets
import shutil
import subprocess
import tempfile

parser = argparse.ArgumentParser(description='Probe token issue and revocation against the disposable VM Forgejo fixture')
parser.add_argument('--ruby', required=True)
parser.add_argument('--gem-home', required=True)
parser.add_argument('--shared-gems', required=True)
parser.add_argument('--version', required=True)
args = parser.parse_args()
if os.geteuid() != 0 or not os.path.isdir('/var/lib/ace-e2e'):
    parser.error('requires root inside a provisioned disposable ACE VM')
for path in (args.ruby, args.gem_home, args.shared_gems):
    if not path.startswith('/') or not re.fullmatch(r'/[A-Za-z0-9_./-]+', path):
        parser.error('paths must be simple absolute paths')
if not re.fullmatch(r'[A-Za-z0-9.]+', args.version):
    parser.error('invalid gem version')
subprocess.run(['/usr/bin/systemctl', 'is-active', '--quiet', 'ace-e2e-forgejo.service'], check=True)
name = 'aceprobe' + secrets.token_hex(4)
nonce = secrets.token_hex(8)
root = tempfile.mkdtemp(prefix='ace-forgejo-revoke-probe-', dir='/run')
os.chmod(root, 0o700)
session = '/run/ace-auth-' + nonce
os.mkdir(session, 0o711)
os.chmod(session, 0o711)
base = ['/usr/sbin/runuser', '-u', 'forgejo', '--', '/usr/local/bin/forgejo', 'admin', 'user']
common = ['--config', '/etc/forgejo/app.ini', '--work-path', '/var/lib/forgejo']
created = False
passed = False
ruby = r"""
gem 'ace-lab','= '+ENV.fetch('ACE_E2E_GEM_VERSION')
require 'ace/lab'; require 'ace/lab/auth/issuer_cleanup'; require 'etc'; require 'yaml'; require 'time'; require 'net/http'; require 'securerandom'
root,nonce,admin=ARGV; account=Etc.getpwnam('nobody')
issuer={'url'=>'http://127.0.0.1:3000','account'=>'e2e-integrator','admin_username'=>admin,'password_file'=>root+'/admin-password'}
document={'auth'=>{'leases_dir'=>root+'/leases','credentials_dir'=>root+'/other','profiles'=>{'forge'=>{'provider'=>'forgejo','roles'=>['worker'],'repos'=>['e2e-integrator/ace'],'scopes'=>['write:repository'],'issuer'=>issuer}}}}.to_yaml
Ace::Lab::Molecules::GrantResolver.define_singleton_method(:read_verified){|_| document}
svc=Ace::Lab::Auth::Service.new
profile=svc.config.fetch('profiles').fetch('forge'); provider=Ace::Lab::Auth::Providers.resolve('forgejo')
id='lease-'+SecureRandom.hex(8)
lease=svc.store.create(id:id,profile:'forge',role:'worker',principal:account.name,task:'t',assignment:'a',repos:['e2e-integrator/ace'],use_until:(Time.now.utc+120).iso8601,provider_expiry:nil,token_ref:provider.token_ref_for(lease_id:id),session_uid:account.uid,session_id:'a'*32,session_unit:'ace-auth-session-worker-'+nonce+'.service',issuer_invocation:'b'*32)
issued=provider.issue(profile:profile,lease:lease); token=issued.fetch('token')
h=Ace::Lab::Auth::CredentialHandoff.new('/run/ace-auth-'+nonce,recipient:account.name,owner_uid:account.uid); file=h.deliver(id,token)
svc.store.update(id){|r|r['state']='issued';r['token_ref']=issued.fetch('token_ref')}
def probe(token)
 uri=URI('http://127.0.0.1:3000/api/v1/repos/e2e-integrator/ace')
 request=Net::HTTP::Get.new(uri); request['Authorization']='token '+token
 Net::HTTP.start(uri.hostname,uri.port,open_timeout:5,read_timeout:5){|http|http.request(request).code.to_i}
end
raise 'issued token did not access the repository' unless probe(token)==200
results=svc.revoke_issuer(invocation:'b'*32)
raise 'cleanup was not confirmed' unless results.first['cleanup']=='revoked' && !File.exist?(file)
raise 'token still authorizes after revoke' unless [401,403].include?(probe(token))
puts 'local_forgejo_token_before=200 revoked=true token_after_denied=true handoff_removed=true'
"""
try:
    command = base + ['create'] + common + [
        '--username', name, '--email', name + '@example.invalid', '--random-password',
        '--must-change-password=false', '--admin',
    ]
    result = subprocess.run(command, capture_output=True, text=True, timeout=60)
    if result.returncode:
        raise RuntimeError('temporary administrator creation failed')
    created = True
    match = re.search(r"(?i)password\s+is\s+'([^']+)'", result.stdout + '\n' + result.stderr)
    if not match:
        raise RuntimeError('generated password format differs')
    fd = os.open(root + '/admin-password', os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
    with os.fdopen(fd, 'w') as file:
        file.write(match.group(1))
    env = os.environ.copy()
    env.update({
        'GEM_HOME': args.gem_home,
        'GEM_PATH': args.gem_home + ':' + args.shared_gems,
        'ACE_TOOLCHAIN': 'installed',
        'ACE_E2E_GEM_VERSION': args.version,
        'PATH': os.path.dirname(args.ruby) + ':/usr/bin:/bin',
    })
    probe = subprocess.run([args.ruby, '-e', ruby, root, nonce, name], env=env,
                           capture_output=True, text=True, timeout=90)
    if probe.returncode:
        fd = os.open(root + '/failure.log', os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
        with os.fdopen(fd, 'w') as file:
            file.write(probe.stdout + '\n' + probe.stderr)
        raise RuntimeError('provider probe failed; guest evidence retained')
    print(probe.stdout.strip())
    passed = True
finally:
    cleanup_failed = False
    if passed and created:
        deleted = subprocess.run(base + ['delete'] + common + ['--username', name],
                                 capture_output=True, text=True, timeout=60)
        if deleted.returncode:
            passed = False
            cleanup_failed = True
            print('temporary_admin_removal_failed=' + name)
        else:
            print('temporary_admin_removed=true')
    if passed:
        shutil.rmtree(root)
        shutil.rmtree(session)
    else:
        print('diagnostic_state_retained=' + root + ' session=' + session + ' admin=' + name)
    if cleanup_failed:
        raise RuntimeError('temporary administrator removal failed')

