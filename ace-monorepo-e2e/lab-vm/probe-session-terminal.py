#!/usr/bin/env python3
"""Disposable terminal/systemd probe; not an autonomous-cycle acceptance."""
import errno
import json
import os
import pty
import select
import subprocess
import sys
import time
import uuid

assert os.geteuid() == 0
unit = "ace-e2e-terminal-" + uuid.uuid4().hex + ".service"
master, slave = pty.openpty()
program = """
import json,os
result = {"pid": os.getpid(), "uid": os.getuid(), "tty": os.isatty(0)}
try:
    result["foreground"] = os.tcgetpgrp(0)
except OSError as error:
    result["foreground_error"] = error.errno
print(json.dumps(result), flush=True)
"""
command = ["/usr/bin/systemd-run", "--quiet", "--wait", "--pipe", "--unit=" + unit,
           "--property=DynamicUser=yes", "--property=NoNewPrivileges=yes",
           "--property=CapabilityBoundingSet=", "--property=PrivateMounts=yes",
           "/usr/bin/python3", "-c", program]
if len(sys.argv) == 2:
    command = json.loads(sys.argv[1])
    assert isinstance(command, list) and command[0] == "/usr/bin/systemd-run"
    units = [arg.removeprefix("--unit=") for arg in command if arg.startswith("--unit=")]
    assert len(units) == 1 and units[0].startswith("ace-auth-session-worker-")
    unit = units[0]
else:
    assert len(sys.argv) == 1
process = None
try:
    process = subprocess.Popen(command, stdin=slave, stdout=slave, stderr=slave)
    os.close(slave)
    slave = None
    output = bytearray()
    deadline = time.monotonic() + 20
    while time.monotonic() < deadline:
        if select.select([master], [], [], 0.2)[0]:
            try:
                data = os.read(master, 4096)
            except OSError as error:
                if error.errno == errno.EIO:
                    break
                raise
            if not data:
                break
            output.extend(data)
            assert len(output) < 16384, "unexpected terminal output size"
        if process.poll() is not None:
            break
    assert process.wait(timeout=3) == 0, output.decode(errors="replace")
    result = json.loads(output.decode().strip())
    assert result["uid"] != 0 and result["tty"] is True, result
    assert result.get("foreground") == result["pid"], result
    print(json.dumps({"unit": unit, "observed": result}))
finally:
    subprocess.run(["/usr/bin/systemctl", "stop", unit], check=False, timeout=15,
                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    if process is not None and process.poll() is None:
        process.kill()
        process.wait(timeout=3)
    os.close(master)
    if slave is not None:
        os.close(slave)
