#!/bin/sh
# Install only inside the disposable working clone; input files are SHA-checked by the host.
set -eu
umask 077
input=/var/lib/ace-e2e/forgejo-input
test "$(id -u)" = 0
test ! -e /etc/forgejo/app.ini
test ! -e /var/lib/forgejo
test ! -e /opt/ace/runtime/bin/fj
python3 - <<'PY'
import socket
with socket.socket() as listener:
    listener.bind(('127.0.0.1', 3000))
PY
id forgejo >/dev/null 2>&1 || useradd --system --home-dir /var/lib/forgejo --shell /usr/sbin/nologin forgejo
install -d -o forgejo -g forgejo -m 0750 /var/lib/forgejo /var/lib/forgejo/custom /var/lib/forgejo/data /var/lib/forgejo/log
install -d -o root -g forgejo -m 0750 /etc/forgejo
install -o root -g root -m 0755 "$input/forgejo" /usr/local/bin/forgejo
# Validate the member name before extraction; never execute an unverified archive.
test "$(tar -tzf "$input/fj.tar.gz")" = fj
tar -xzf "$input/fj.tar.gz" -C "$input"
test -f "$input/fj" && test ! -L "$input/fj"
install -o root -g root -m 0755 "$input/fj" /opt/ace/runtime/bin/fj
python3 - <<'PY'
import subprocess
from pathlib import Path
def secret(kind):
    return subprocess.check_output(['/usr/local/bin/forgejo', 'generate', 'secret', kind], text=True).strip()
p = Path('/etc/forgejo/app.ini')
p.write_text('''APP_NAME = ACE disposable E2E forge
RUN_USER = forgejo
RUN_MODE = prod
[server]
PROTOCOL = http
DOMAIN = 127.0.0.1
HTTP_ADDR = 127.0.0.1
HTTP_PORT = 3000
ROOT_URL = http://127.0.0.1:3000/
DISABLE_SSH = true
OFFLINE_MODE = true
[database]
DB_TYPE = sqlite3
PATH = /var/lib/forgejo/data/forgejo.db
[repository]
ROOT = /var/lib/forgejo/data/repositories
[security]
INSTALL_LOCK = true
SECRET_KEY = {secret}
INTERNAL_TOKEN = {internal}
[oauth2]
JWT_SECRET = {jwt}
[service]
DISABLE_REGISTRATION = true
REQUIRE_SIGNIN_VIEW = true
[actions]
ENABLED = false
[log]
MODE = console
LEVEL = warn
'''.format(secret=secret('SECRET_KEY'), internal=secret('INTERNAL_TOKEN'), jwt=secret('JWT_SECRET')))
p.chmod(0o640)
PY
chown root:forgejo /etc/forgejo/app.ini
cat > /etc/systemd/system/ace-e2e-forgejo.service <<'UNIT'
[Unit]
Description=Disposable ACE E2E local Forgejo
After=network.target
[Service]
Type=simple
User=forgejo
Group=forgejo
WorkingDirectory=/var/lib/forgejo
Environment=FORGEJO_WORK_DIR=/var/lib/forgejo
ExecStart=/usr/local/bin/forgejo web --config /etc/forgejo/app.ini --work-path /var/lib/forgejo
Restart=on-failure
NoNewPrivileges=true
[Install]
WantedBy=multi-user.target
UNIT
systemctl daemon-reload
systemctl enable --now ace-e2e-forgejo.service
python3 - <<'PY'
import time, urllib.error, urllib.request
for attempt in range(90):
    try:
        with urllib.request.urlopen('http://127.0.0.1:3000/api/v1/version', timeout=2) as response:
            if response.status == 200:
                break
    except urllib.error.HTTPError as error:
        # REQUIRE_SIGNIN_VIEW blocks even the anonymous version endpoint.
        if error.code == 403:
            break
    except OSError:
        time.sleep(1)
else:
    raise SystemExit('Forgejo did not become ready')
PY
systemctl is-active --quiet ace-e2e-forgejo.service
pid=$(systemctl show --property MainPID --value ace-e2e-forgejo.service)
case "$pid" in ''|*[!0-9]*) exit 1 ;; esac
test "$pid" -gt 1
ss -lntp '( sport = :3000 )' | grep -F "pid=$pid," >/dev/null
# Passwords and token output remain root-only, inside the working VM.
install -d -o root -g root -m 0700 /run/ace-e2e-forgejo
for user in e2e-admin e2e-integrator e2e-reviewer e2e-worker; do
  admin=
  [ "$user" != e2e-admin ] || admin=--admin
  runuser -u forgejo -- /usr/local/bin/forgejo admin user create --config /etc/forgejo/app.ini --work-path /var/lib/forgejo --username "$user" --email "$user@example.invalid" --random-password --must-change-password=false $admin > "/run/ace-e2e-forgejo/$user.password" 2>&1
done
for user in e2e-admin e2e-integrator e2e-reviewer; do
  runuser -u forgejo -- /usr/local/bin/forgejo admin user generate-access-token --config /etc/forgejo/app.ini --work-path /var/lib/forgejo --username "$user" --token-name ace-e2e-fixture --scopes all --raw > "/run/ace-e2e-forgejo/$user.token" 2>/dev/null
  test -s "/run/ace-e2e-forgejo/$user.token"
done
printf 'Forgejo service and local identities created.\n'
