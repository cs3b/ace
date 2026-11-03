"""Check per-command cgroup containment in a disposable Linux ACE VM.

This tests kernel/systemd primitives only; it does not enable the issuer.
"""

import ctypes
import os
import re
import secrets
import select
import signal
import stat
import subprocess
import sys
import time

if os.geteuid() != 0 or not os.path.isdir('/var/lib/ace-e2e'):
    sys.exit('requires root in a disposable ACE VM')


def run(args):
    return subprocess.run(args, check=True, timeout=15, text=True, capture_output=True).stdout.strip()


unit = 'ace-e2e-containment-' + secrets.token_hex(12) + '.service'
subgroup = None
child_handle = None
main_handle = None
control = None
started = False
try:
    run(['/usr/bin/systemd-run', '--quiet', '--unit=' + unit, '--property=Type=exec', '--property=DynamicUser=yes',
         '--property=Delegate=no', '--property=NoNewPrivileges=yes', '/bin/sleep', '60'])
    started = True
    pid = int(run(['/usr/bin/systemctl', 'show', '--property=MainPID', '--value', unit]))
    group = run(['/usr/bin/systemctl', 'show', '--property=ControlGroup', '--value', unit])
    delegation = run(['/usr/bin/systemctl', 'show', '--property=Delegate', '--value', unit])
    if pid <= 0 or delegation != 'no' or not re.fullmatch(r'/[A-Za-z0-9_.:/-]+/' + re.escape(unit), group):
        raise RuntimeError('unexpected session identity or delegation')
    main_handle = os.pidfd_open(pid)
    info = os.stat(f'/proc/{pid}')
    if info.st_uid <= 0 or info.st_gid != info.st_uid:
        raise RuntimeError('session has no isolated UID/GID')
    parent = '/sys/fs/cgroup' + group
    for path in (parent, parent + '/cgroup.procs'):
        entry = os.lstat(path)
        if entry.st_uid != 0 or entry.st_mode & 0o022 or stat.S_ISLNK(entry.st_mode):
            raise RuntimeError('session cgroup is not root-controlled')
    subgroup = parent + '/ace-exec-' + secrets.token_hex(12)
    os.mkdir(subgroup, 0o700)
    control = os.open(subgroup + '/cgroup.procs', os.O_WRONLY | os.O_CLOEXEC | os.O_NOFOLLOW)
    reader, writer = os.pipe()
    child = os.fork()
    if child == 0:
        try:
            os.close(reader)
            os.setgroups([])
            if ctypes.CDLL(None, use_errno=True).prctl(38, 1, 0, 0, 0) != 0:
                os._exit(10)
            os.setgid(info.st_gid)
            os.setuid(info.st_uid)
            status_fields = {}
            with open('/proc/self/status', encoding='ascii') as status_file:
                for line in status_file:
                    if ':' in line:
                        key, value = line.split(':', 1)
                        status_fields[key] = value.strip()
            if (int(status_fields['CapEff'], 16) != 0 or int(status_fields['CapPrm'], 16) != 0 or
                    status_fields['NoNewPrivs'] != '1' or status_fields['Groups']):
                os._exit(13)
            os.write(control, b'0\n')
            os.close(control)
            try:
                fd = os.open(parent + '/cgroup.procs', os.O_WRONLY)
            except PermissionError:
                pass
            else:
                os.close(fd)
                os._exit(11)
            detached = os.fork()
            if detached == 0:
                os.close(writer)
                os.setsid()
                time.sleep(60)
                os._exit(0)
            os.write(writer, f'{detached}\n'.encode())
            os.close(writer)
            os._exit(0)
        except BaseException:
            os._exit(12)
    os.close(writer)
    if not select.select([reader], [], [], 10)[0]:
        raise RuntimeError('command did not report its detached child')
    value = os.read(reader, 64).decode().strip()
    os.close(reader)
    _, status = os.waitpid(child, 0)
    if os.waitstatus_to_exitcode(status) != 0 or not value.isdecimal():
        raise RuntimeError('session could not enter containment or escape was possible')
    descendant = int(value)
    child_handle = os.pidfd_open(descendant)
    membership = open(f'/proc/{descendant}/cgroup', encoding='utf-8').read()
    if not any(line.strip().endswith('/' + os.path.basename(subgroup)) for line in membership.splitlines()):
        raise RuntimeError('detached child left its command cgroup')
    with open(subgroup + '/cgroup.kill', 'w', encoding='ascii') as kill:
        kill.write('1\n')
    if not select.select([child_handle], [], [], 5)[0]:
        raise RuntimeError('detached child survived command cleanup')
    if select.select([main_handle], [], [], 0)[0]:
        raise RuntimeError('command cleanup terminated the session main process')
    run(['/usr/bin/systemctl', 'is-active', '--quiet', unit])
    print('detached child contained and killed; session main remained active')
finally:
    cleanup_failed = False
    if control is not None:
        os.close(control)
    if subgroup and os.path.isdir(subgroup):
        try:
            with open(subgroup + '/cgroup.kill', 'w', encoding='ascii') as kill:
                kill.write('1\n')
            deadline = time.monotonic() + 5
            while time.monotonic() < deadline:
                try:
                    os.rmdir(subgroup)
                    break
                except OSError:
                    time.sleep(0.05)
            else:
                print('could not remove probe cgroup: ' + subgroup, file=sys.stderr)
                cleanup_failed = True
        except OSError as error:
            print('could not clean probe cgroup: ' + str(error), file=sys.stderr)
            cleanup_failed = True
    for fd in (child_handle, main_handle):
        if fd is not None:
            os.close(fd)
    if started:
        run(['/usr/bin/systemctl', 'stop', unit])
    if cleanup_failed:
        raise RuntimeError('probe cgroup cleanup was incomplete')
