"""ACE Hermes pre-dispatch guard: secrets never reach the inbound preview.

The supervised ace-hitl-hermes actor owns Telegram polling. This hook is also
usable with an existing gateway for interception, but cannot prove drainage.
"""
from __future__ import annotations

import json
import os
import subprocess
from pathlib import Path


def _handle(_args):
    return "Use Telegram Reply or /hitl-reply ID ANSWER in the registered group."


def _pre_dispatch(event, **_kwargs):
    source = getattr(event, "source", None)
    platform = getattr(source, "platform", "")
    if str(getattr(platform, "value", platform)).lower() != "telegram":
        return None
    text = str(getattr(event, "text", "") or "")
    command = text.split(None, 1)[0].split("@", 1)[0].lower() if text.strip() else ""
    reply = str(getattr(event, "reply_to_message_id", "") or "")
    config_path = os.environ.get("ACE_HITL_HERMES_CONFIG", "")
    chat = str(getattr(source, "chat_id", "") or "")
    try:
        config = json.loads(Path(config_path).read_text())
        registry = json.loads(Path(config["registry"]).read_text())
        registered = any(str(c["chat_id"]) == chat for c in registry["channels"])
    except (OSError, ValueError, KeyError, TypeError):
        # Replies and commands are still intercepted when configuration fails.
        registered = False
    if not registered and not reply and command != "/hitl-reply":
        return None
    payload = {
        "platform": "telegram", "chat_id": chat,
        "chat_type": str(getattr(source, "chat_type", "") or ""),
        "user_id": str(getattr(source, "user_id", "") or ""),
        "message_id": str(getattr(event, "message_id", "") or ""),
        "reply_to_message_id": reply, "text": text,
    }
    try:
        subprocess.run(
            [os.environ.get("ACE_HITL_HERMES_EXE", "ace-hitl-hermes"),
             "receive", "--config", config_path],
            input=json.dumps(payload), stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL, text=True, timeout=15, check=False,
        )
    except (OSError, subprocess.SubprocessError):
        pass
    # Never include answer text in the reason or retry logs. Unavailability,
    # unauthorized/unknown Reply and malformed commands all fail closed.
    return {"action": "skip", "reason": "ace_hitl_hermes"}


def register(ctx):
    ctx.register_command("hitl-reply", handler=_handle,
                         description="Answer one correlated ACE HITL request.",
                         args_hint="ID ANSWER")
    ctx.register_hook("pre_gateway_dispatch", _pre_dispatch)
