"""Native ACE file transport inside the existing Hermes gateway.

No subprocess, Ruby, bot credentials, network client, or polling owner. The
gateway supplies its already-running adapter. Files are transport receipts;
only ace-hitl imports an answer into the original canonical case.
"""
from __future__ import annotations

import asyncio
import contextlib
import fcntl
import hashlib
import json
import os
from pathlib import Path, PurePosixPath
import re
import secrets
import stat

SCHEMA = "ace.hitl.hermes.native/v1"
MAX_BYTES = 65536
KEY = re.compile(r"^[a-f0-9]{64}$")
TOKEN = re.compile(r"^[a-zA-Z0-9][a-zA-Z0-9_-]{0,63}$")

class GatewayUnavailable(RuntimeError):
    """Confirmed pre-send failure; unlike a lost response it is retryable."""


def digest(parts):
    return hashlib.sha256(json.dumps(parts, separators=(",", ":"), ensure_ascii=False).encode()).hexdigest()


class Folder:
    def __init__(self, path):
        self.path = Path(path)
        self.verify()

    def verify(self):
        info = self.path.lstat()
        if (not stat.S_ISDIR(info.st_mode) or self.path.resolve() != self.path
                or info.st_uid != os.geteuid() or info.st_mode & 0o077 or os.geteuid() == 0):
            raise ValueError("transport folder must be private and owned by the non-root user")

    def filename(self, kind, key):
        if kind not in ("request", "delivery", "incoming", "reply", "instruction") or not KEY.fullmatch(key):
            raise ValueError("invalid frame identity")
        self.verify()
        return self.path / f"{kind}-{key}.json"

    def keys(self, kind):
        self.verify()
        return sorted(p.name[len(kind) + 1:-5] for p in self.path.glob(f"{kind}-*.json")
                      if KEY.fullmatch(p.name[len(kind) + 1:-5]))

    def read(self, kind, key):
        try:
            fd = os.open(self.filename(kind, key), os.O_RDONLY | os.O_NOFOLLOW)
        except FileNotFoundError:
            return None
        with os.fdopen(fd, "rb") as file:
            info = os.fstat(file.fileno())
            if not stat.S_ISREG(info.st_mode) or info.st_uid != os.geteuid() or info.st_mode & 0o077:
                raise ValueError("transport file must be private")
            raw = file.read(MAX_BYTES + 1)
        if len(raw) > MAX_BYTES:
            raise ValueError("transport frame too large")
        value = json.loads(raw)
        if not isinstance(value, dict) or (value.get("schema"), value.get("kind"), value.get("key")) != (SCHEMA, kind, key):
            raise ValueError("transport frame binding differs")
        return value

    def write(self, kind, key, value, replace=False):
        destination = self.filename(kind, key)
        value = {**value, "schema": SCHEMA, "kind": kind, "key": key}
        raw = json.dumps(value, separators=(",", ":"), ensure_ascii=False).encode()
        if len(raw) > MAX_BYTES:
            raise ValueError("transport frame too large")
        temporary = self.path / (".native-" + secrets.token_hex(12))
        try:
            fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600)
            with os.fdopen(fd, "wb") as file:
                file.write(raw)
                file.flush()
                os.fsync(file.fileno())
            if replace:
                os.replace(temporary, destination)
            else:
                try:
                    os.link(temporary, destination)
                except FileExistsError:
                    if self.read(kind, key) != value:
                        raise ValueError("conflicting transport frame")
            self.fsync()
        finally:
            temporary.unlink(missing_ok=True)
        return value

    def fsync(self):
        fd = os.open(self.path, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
        try:
            os.fsync(fd)
        finally:
            os.close(fd)

    def ack(self, kind, key):
        self.filename(kind, key).unlink(missing_ok=True)
        self.fsync()

    @contextlib.contextmanager
    def lock(self):
        self.verify()
        fd = os.open(self.path / ".hermes-native.lock", os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW, 0o600)
        try:
            info = os.fstat(fd)
            if not stat.S_ISREG(info.st_mode) or info.st_uid != os.geteuid() or info.st_mode & 0o077:
                raise ValueError("transport lock must be private")
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
            yield
        finally:
            os.close(fd)


def absolute(path):
    return isinstance(path, str) and path.startswith("/") and str(PurePosixPath(path)) == path and ".." not in PurePosixPath(path).parts


class NativeTransport:
    def __init__(self, config, sender):
        if config.get("mode") != "native-folder":
            raise ValueError("native transport mode required")
        self.channels = config["channels"]
        self.sender = sender
        self.interval = config.get("interval_seconds", 1)
        if not isinstance(self.interval, (int, float)) or not 0.2 <= self.interval <= 60:
            raise ValueError("invalid native transport interval")
        if not isinstance(self.channels, list) or not self.channels:
            raise ValueError("channels required")
        seen_names, seen_chats, seen_folders = set(), set(), set()
        for channel in self.channels:
            name, machine = channel["name"], channel["machine"]
            if not all(isinstance(v, str) and TOKEN.fullmatch(v) for v in (name, machine)):
                raise ValueError("invalid channel identity")
            chat = str(channel["chat_id"])
            folder = Folder(channel["folder"])
            if name in seen_names or chat in seen_chats or str(folder.path) in seen_folders:
                raise ValueError("duplicate channel ownership")
            seen_names.add(name)
            seen_chats.add(chat)
            seen_folders.add(str(folder.path))
            users = channel["allowed_users"]
            if not isinstance(users, list) or not users or not all(isinstance(v, str) and v.isdecimal() for v in users):
                raise ValueError("explicit allowed users required")
            projects = channel["projects"]
            if not isinstance(projects, dict) or not projects or channel["instruction_project"] not in projects:
                raise ValueError("explicit instruction project required")
            for project, rule in projects.items():
                if not TOKEN.fullmatch(project):
                    raise ValueError("invalid project")
                roots = rule.get("event_roots", [])
                worktrees = rule.get("worktree_roots", [])
                if not isinstance(roots, list) or not isinstance(worktrees, list) or not roots + worktrees or not all(absolute(v) for v in roots + worktrees):
                    raise ValueError("explicit project/worktree roots required")

    def channel(self, chat):
        return next((c for c in self.channels if str(c["chat_id"]) == str(chat)), None)

    def validate_request(self, channel, request):
        project = request["project"]
        rule = channel["projects"][project]
        origin = request["origin"]
        path, root, case = origin["file"], origin["root"], origin["case_id"]
        allowed = root in rule.get("event_roots", []) or any(
            re.fullmatch(re.escape(base) + r"/[^/]+/\.ace-local/hitl", root or "")
            for base in rule.get("worktree_roots", []))
        if not allowed or not absolute(path) or not absolute(root) or not TOKEN.fullmatch(case):
            raise ValueError("origin is outside registered roots")
        if not path.startswith(root + "/") or not PurePosixPath(path).name.startswith(case + "-") or not path.endswith(".hitl.s.md"):
            raise ValueError("origin case path differs")
        if request["key"] != digest([project, path, case]):
            raise ValueError("origin key differs")
        if request["channel"] != channel["name"] or request["machine"] != channel["machine"]:
            raise ValueError("channel binding differs")
        if request["recipient"] != {"machine": channel["machine"], "panel": channel["name"]}:
            raise ValueError("recipient binding differs")
        if request["event_type"] == "question":
            if request["reply_to"] != {"machine": channel["machine"], "folder": root, "id": case}:
                raise ValueError("Reply address differs")
        elif request["event_type"] != "report" or request["reply_to"] is not None:
            raise ValueError("unsupported native event")
        if not isinstance(request["text"], str) or not request["text"].strip():
            raise ValueError("text required")

    def receive(self, event):
        source = getattr(event, "source", None)
        platform = getattr(source, "platform", "")
        if str(getattr(platform, "value", platform)).lower() != "telegram":
            return None
        channel = self.channel(getattr(source, "chat_id", ""))
        if channel is None:
            return None  # Other registered host groups retain their existing owner.
        # Registered group messages are intercepted before Hermes previews.
        skipped = {"action": "skip", "reason": "ace_hitl_hermes"}
        if str(getattr(source, "user_id", "")) not in channel["allowed_users"] or str(getattr(source, "chat_type", "")) not in ("group", "supergroup"):
            return skipped
        text = str(getattr(event, "text", "") or "")
        message_id = str(getattr(event, "message_id", "") or "")
        reply_to = str(getattr(event, "reply_to_message_id", "") or "")
        if not text.strip() or len(text.encode()) > 16384 or not message_id:
            return skipped
        if not reply_to and text.split(None, 1)[0].split("@", 1)[0].lower() == "/hitl-reply":
            return skipped  # Native replies require Telegram's exact Reply link.
        key = digest([channel["name"], str(channel["chat_id"]), message_id])
        frame = {"channel": channel["name"], "machine": channel["machine"], "chat_id": str(channel["chat_id"]),
                 "message_id": message_id, "reply_to_message_id": reply_to, "text": text}
        try:
            # No awaits/network here: persist before returning from interception.
            Folder(channel["folder"]).write("incoming", key, frame)
        except (OSError, ValueError, TypeError):
            pass  # Fail closed. Never expose answer text through an exception.
        return skipped

    async def once(self):
        for channel in self.channels:
            folder = Folder(channel["folder"])
            try:
                with folder.lock():
                    await self.send_pending(channel, folder)
                    self.correlate(channel, folder)
            except (OSError, ValueError, KeyError, TypeError):
                # A later pass may reconcile files; it must never resend a
                # receipt which says sending/unknown after a lost response.
                continue

    async def send_pending(self, channel, folder):
        attempts = 0
        for key in folder.keys("request"):
            try:
                request = folder.read("request", key)
                existing = folder.read("delivery", key)
                if existing and existing.get("state") != "waiting_gateway":
                    if existing.get("state") == "sending":
                        folder.write("delivery", key, {**existing, "state": "unknown"}, replace=True)
                    continue
                self.validate_request(channel, request)
                if attempts >= 100:
                    break
                attempts += 1
                folder.write("delivery", key, {"state": "sending", "message_ids": []}, replace=bool(existing))
                try:
                    result = await asyncio.wait_for(
                        self.sender(str(channel["chat_id"]), f"[{request['project']}] {request['text']}"), timeout=30)
                    ids = [str(v) for v in result.get("message_ids", []) if v]
                    state = "delivered" if result.get("success") and ids else "unknown"
                except GatewayUnavailable:
                    ids, state = [], "waiting_gateway"
                except Exception:
                    ids, state = [], "unknown"
                folder.write("delivery", key, {"state": state, "message_ids": list(dict.fromkeys(ids))}, replace=True)
            except (OSError, ValueError, KeyError, TypeError):
                # Invalid input cannot send or prevent unrelated valid cases.
                try:
                    if folder.read("delivery", key) is None:
                        folder.write("delivery", key, {"state": "rejected", "message_ids": []})
                except (OSError, ValueError, KeyError, TypeError):
                    pass
                continue

    def correlate(self, channel, folder):
        requests = []
        for key in folder.keys("request"):
            try:
                request, receipt = folder.read("request", key), folder.read("delivery", key)
                self.validate_request(channel, request)
                if (request["event_type"] == "question" and receipt and receipt.get("state") == "delivered"
                        and isinstance(receipt.get("message_ids"), list) and receipt["message_ids"]
                        and all(isinstance(v, str) and v for v in receipt["message_ids"])):
                    requests.append((request, receipt))
            except (OSError, ValueError, KeyError, TypeError):
                continue
        for key in folder.keys("incoming"):
            try:
                item = folder.read("incoming", key)
                if item["chat_id"] != str(channel["chat_id"]) or item["channel"] != channel["name"] or item["machine"] != channel["machine"]:
                    continue
                if item["reply_to_message_id"]:
                    matches = [req for req, receipt in requests if item["reply_to_message_id"] in receipt["message_ids"]]
                    if len(matches) != 1:
                        continue  # Unknown Reply is never a new instruction.
                    request = matches[0]
                    reply = {**item, "project": request["project"], "origin": request["origin"]}
                    folder.write("reply", request["key"], reply)
                else:
                    folder.write("instruction", key, {**item, "project": channel["instruction_project"]})
                folder.ack("incoming", key)
            except (OSError, ValueError, KeyError, TypeError):
                continue

    async def run(self):
        while True:
            await self.once()
            await asyncio.sleep(self.interval)


async def gateway_send(chat_id, text):
    # Existing Hermes live-adapter seam: never fall back to a standalone bot,
    # read credentials, or create a Telegram client. Active-profile selection is
    # supplied by Hermes' resolver, exactly as its send_message tool uses it.
    from tools.send_message_senders import _live_adapter
    from tools.send_message_tool import _dispatch_on_gateway_loop

    runner, adapter = _live_adapter("telegram")
    if runner is None or adapter is None or not adapter.is_connected:
        raise GatewayUnavailable("existing Telegram adapter unavailable before send")
    result = await _dispatch_on_gateway_loop(
        runner, lambda: adapter.send(chat_id=chat_id, content=text),
        "ACE native HITL send failed")
    ids = list(getattr(result, "continuation_message_ids", None) or [])
    if getattr(result, "message_id", None):
        ids.append(result.message_id)
    return {"success": bool(result.success), "message_ids": ids}
