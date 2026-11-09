"""Read timing evidence for the delivered bootstrap goal in one Pi session."""

from datetime import datetime, timezone
import json
import re
import sys

LIMIT_SECONDS = 45 * 60
RECONCILE_COMMAND = re.compile(
    r"""(?:cd\s+(?:/lab|"/lab"|'/lab')\s*&&\s*)?"""
    r"(?:ACE_TOOLCHAIN=installed\s+)?(?:/opt/ace/runtime/gems/bin/)?"
    r"ace-overseer\s+start\s+--reconcile(?:\s+--format\s+(?:json|table))?"
)


def parts(message, kind):
    content = message.get("content", [])
    if isinstance(content, str):
        return [{"text": content}] if kind == "text" else []
    return [item for item in content if isinstance(item, dict) and item.get("type") == kind]


def ready_terminal(text):
    try:
        report, _ = json.JSONDecoder().raw_decode(text.lstrip())
    except ValueError:
        if "ace-overseer start: ready" not in text.splitlines():
            return None
        match = re.search(r"^  project ace: (?:reused|started) \(/lab/ace, pane: (term_[0-9a-f]+)\)$", text, re.M)
        return match.group(1) if match else None
    if (not isinstance(report, dict) or report.get("scope") != "lab" or report.get("root") != "/lab"
            or report.get("status") != "ready" or report.get("ready") is not True):
        return None
    for project in report.get("projects", []):
        if project.get("id") == "ace" and project.get("path") == "/lab/ace" and project.get("ready") is True:
            pane = project.get("pane")
            return pane if isinstance(pane, str) and re.fullmatch(r"term_[0-9a-f]+", pane) else None
    return None


def evidence(records, goal, now):
    deliveries = []
    reconcile = set()
    ready = None
    terminal = None
    for line in records:
        row = json.loads(line)
        message = row.get("message", {})
        if message.get("role") == "user" and any(item.get("text") == goal for item in parts(message, "text")):
            deliveries.append(datetime.fromisoformat(row["timestamp"]))
        if not deliveries:
            continue
        for item in parts(message, "toolCall"):
            command = item.get("arguments", {}).get("command", "")
            if item.get("name") == "bash" and RECONCILE_COMMAND.fullmatch(command.strip()):
                reconcile.add(item["id"])
        if ready is None and message.get("role") == "toolResult" and message.get("toolCallId") in reconcile and message.get("isError") is False:
            terminal = ready_terminal("\n".join(item["text"] for item in parts(message, "text")))
            if terminal:
                ready = datetime.fromisoformat(row["timestamp"])
    if len(deliveries) != 1:
        raise ValueError("expected exactly one delivered bootstrap goal")
    delivered = deliveries[0]
    elapsed = (ready - delivered).total_seconds() if ready else None
    if delivered > now or (ready and (ready > now or elapsed < 0)):
        raise ValueError("bootstrap timestamps are out of order")
    status = "within_limit" if elapsed is not None and elapsed <= LIMIT_SECONDS else (
        "expired" if (now - delivered).total_seconds() > LIMIT_SECONDS else "waiting")
    return {"goal_delivered_at": delivered.isoformat(), "authenticated_ready_at": ready.isoformat() if ready else None,
            "elapsed_seconds": elapsed, "limit_seconds": LIMIT_SECONDS, "status": status, "project_terminal": terminal}


if __name__ == "__main__":
    with open(sys.argv[1], encoding="utf-8") as session:
        print(json.dumps(evidence(session, sys.argv[2], datetime.now(timezone.utc))))
