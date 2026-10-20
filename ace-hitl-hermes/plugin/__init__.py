"""ACE pre-dispatch guard and optional native-folder gateway transport.

Native mode uses only the existing gateway; the explicit lifecycle mode keeps
its published CLI interception contract.
"""
from __future__ import annotations

import json
import os
import subprocess
import asyncio
import importlib.util
from pathlib import Path

_native = None
_transition = None


def _packaged_module(name):
    spec = importlib.util.spec_from_file_location(
        __name__ + "." + name, Path(__file__).with_name(name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def _handle(_args):
    if _native is not None:
        return "Reply to the original ACE question in its registered Telegram group."
    return "Use Telegram Reply or /hitl-reply ID ANSWER in the registered group."


def _pre_dispatch(event, **_kwargs):
    if _transition is not None:
        return _transition.receive(event)
    if _native is not None:
        return _native.receive(event)
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
    global _native, _transition
    config_path = os.environ.get("ACE_HITL_HERMES_CONFIG", "")
    config = json.loads(Path(config_path).read_text()) if config_path else {}
    _native = None
    _transition = None
    if config.get("mode") == "native-folder":
        module = _packaged_module("native_transport")
        # Validate before registering any hook: a rejected native configuration
        # must not accidentally install the unrelated lifecycle interception.
        _native = module.NativeTransport(config, module.gateway_send)
        if config.get("legacy_broker") is not None:
            _transition = _packaged_module("legacy_transition").LegacyTransition(config["legacy_broker"], _native)
    ctx.register_command("hitl-reply", handler=_handle,
                         description="Answer one correlated ACE HITL request.",
                         args_hint="ID ANSWER")
    ctx.register_hook("pre_gateway_dispatch", _pre_dispatch)
    if _native is not None:
        native = _native
        task = None

        def activate(_native_client=None, _adapter=None):
            nonlocal task
            if task is None or task.done():
                task = ctx.spawn_task(native.run(), name="ace-hitl-native-folder")

        # Hermes pre-discovers plugins synchronously in a background thread.
        # Its existing adapter-connect factory runs later on the gateway loop,
        # even when idempotent discover does not call register a second time.
        ctx.register_platform_handler("telegram", activate)
        # Hot reload of an already connected gateway has no new connect call.
        try:
            asyncio.get_running_loop()
        except RuntimeError:
            return
        if module.gateway_available():
            activate()
