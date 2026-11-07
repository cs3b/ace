"""Operator probe for a live worker lease in the disposable Forgejo fixture."""

from contextlib import closing
from datetime import datetime
import http.client
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import time


ISSUER = "ace-lab-auth.service"
REPOSITORY = "e2e-integrator/ace"
LEASES = Path("/var/lib/lab/ace-lab/auth/leases")
UNIT = re.compile(r"ace-auth-session-worker-([0-9a-f]{16})\.service")


class EvidenceError(Exception):
    pass


def require(condition, reason):
    if not condition:
        raise EvidenceError(reason)


def invocation(unit):
    result = subprocess.run(
        ["/usr/bin/systemctl", "show", "--property=InvocationID", "--value", unit],
        check=True, capture_output=True, text=True, timeout=5,
    )
    return result.stdout.strip()


def credential(record, lease, session):
    principal = record["principal"]
    require(re.fullmatch(r"[a-zA-Z0-9_-]+", principal), "invalid lease principal")
    handoff = Path(f"/run/ace-auth-{session}") / f"{lease}-{principal}"
    with os.fdopen(os.open(handoff, os.O_RDONLY | os.O_NOFOLLOW | os.O_NONBLOCK), "rb") as stream:
        status = os.fstat(stream.fileno())
        require(stat.S_ISREG(status.st_mode) and stat.S_IMODE(status.st_mode) == 0o400
                and status.st_uid == status.st_gid == record["session_uid"], "invalid lease handoff")
        token = stream.read(64)
    require(re.fullmatch(rb"[0-9a-f]{40}", token), "invalid Forgejo credential format")
    return handoff, token.decode("ascii")


def forgejo_status(token):
    with closing(http.client.HTTPConnection("127.0.0.1", 3000, timeout=5)) as connection:
        connection.request("GET", f"/api/v1/repos/{REPOSITORY}", headers={"Authorization": "token " + token})
        return connection.getresponse().status


def populated(group):
    try:
        return "populated 1" in (group / "cgroup.events").read_text().splitlines()
    except FileNotFoundError:
        return False


def probe(mode, lease):
    require(os.geteuid() == 0, "operator privileges required")
    require(mode in ("expiry", "crash") and re.fullmatch(r"lease-[0-9a-f]{16}", lease),
            "expected expiry|crash and a lease ID")
    path = LEASES / f"{lease}.json"
    initial = json.loads(path.read_text())
    unit = initial["session_unit"]
    session = UNIT.fullmatch(unit)
    require(session and initial["id"] == lease and initial["role"] == "worker"
            and initial["repos"] == [REPOSITORY] and initial["state"] == "issued"
            and initial["execution"] == "in-progress", "no active fixture worker execution")
    issuer = invocation(ISSUER)
    require(issuer == initial["issuer_invocation"] and re.fullmatch(r"[0-9a-f]{32}", issuer)
            and invocation(unit) == initial["session_id"], "lease invocation differs")
    group = Path(initial["execution_cgroup"])
    group_pattern = rf"/sys/fs/cgroup/(?:[a-zA-Z0-9_.:-]+/)*{re.escape(unit)}/ace-exec-[0-9a-f]{{32}}"
    require(re.fullmatch(group_pattern, str(group)) and group.resolve() == group
            and populated(group), "no populated lease command cgroup")
    use_until = datetime.fromisoformat(initial["use_until"])
    issued_at = datetime.fromisoformat(initial["requested_at"])
    if mode == "expiry":
        # The deadline is computed before LeaseStore stamps requested_at.
        require(0 < (use_until - issued_at).total_seconds() <= 60, "expiry probe requires a one-minute lease")

    handoff, token = credential(initial, lease, session[1])
    before = forgejo_status(token)
    require(before == 200 and populated(group) and datetime.now(use_until.tzinfo) < use_until,
            "live lease access was not proven")
    identity = {"mode": mode, "lease": lease, "issuer_invocation": issuer,
                "session_unit": unit, "session_id": initial["session_id"], "execution_cgroup": str(group)}
    print(json.dumps({**identity, "before": {"http_status": before, "populated": True,
                                          "use_until": initial["use_until"]}}), flush=True)
    if mode == "crash":
        require(invocation(ISSUER) == issuer, "issuer changed before fault injection")
        fault_at = datetime.now(use_until.tzinfo)
        require((use_until - fault_at).total_seconds() > 95 and populated(group),
                "issuer crash requires an active command with more than 95 seconds remaining")
        subprocess.run(
            ["/usr/bin/systemctl", "kill", "--kill-whom=main", "--signal=SIGKILL", ISSUER],
            check=True, capture_output=True, timeout=5,
        )

    deadline = time.monotonic() + 90
    while time.monotonic() < deadline:
        final = json.loads(path.read_text())
        cleanup = final.get("cleanup") or {}
        if (final.get("state") == "revoked" and cleanup.get("result") in ("revoked", "already_invalid")
                and "execution" not in final and "execution_cgroup" not in final
                and not populated(group) and not os.path.lexists(handoff)):
            break
        time.sleep(0.25)
    else:
        raise EvidenceError("lease revocation or command containment remains unconfirmed")

    cleanup_at = datetime.fromisoformat(cleanup["at"])
    if mode == "expiry":
        require(cleanup_at >= use_until and invocation(ISSUER) == issuer,
                "command ended before expiry or issuer changed during the probe")
    else:
        require(fault_at.replace(microsecond=0) <= cleanup_at < use_until,
                "issuer cleanup was not proven between the crash and natural expiry")
    after = forgejo_status(token)
    require(after in (401, 403), "Forgejo did not reject the revoked credential")
    print(json.dumps({**identity,
        "after": {"http_status": after, "populated": False, "handoff_exists": False,
                  "state": final["state"], "cleanup": cleanup["result"], "cleanup_at": cleanup.get("at")},
    }))


if __name__ == "__main__":
    try:
        if len(sys.argv) != 3:
            raise EvidenceError("expected expiry|crash and a lease ID")
        probe(*sys.argv[1:])
    except EvidenceError as error:
        print(f"lease-fault-evidence: {error}", file=sys.stderr)
        sys.exit(1)
    except (ValueError, KeyError, TypeError, OSError, subprocess.SubprocessError, http.client.HTTPException) as error:
        # Provider/OS/parser exception text may contain confidential inputs.
        print(f"lease-fault-evidence: {type(error).__name__}", file=sys.stderr)
        sys.exit(1)
