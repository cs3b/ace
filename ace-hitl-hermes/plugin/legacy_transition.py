"""Explicit, temporary ownership routing for the existing Lab broker.

This is an adapter for its already-running Unix endpoint, not a new broker.
Only sanitized channel/correlation projections are read. Native cases never
enter that endpoint; old cases are never replayed or converted into new cases.
"""
import json
import os
from pathlib import Path
import socket
import stat
import struct


class LegacyTransition:
    MAX_REPLY = 4096

    def __init__(self, config, native, broker=None):
        self.config, self.native = config, native
        for field in ("socket", "channels", "correlations"):
            value = config.get(field)
            if not isinstance(value, str) or not value.startswith("/") or os.path.normpath(value) != value:
                raise ValueError("legacy transition needs explicit absolute paths")
        if not isinstance(config.get("service_uid"), int) or config["service_uid"] < 0:
            raise ValueError("legacy broker identity required")
        self._broker = broker or self.broker
        self.channels, self.captains = self.load_channels()
        self.load_correlations()  # Reject broken cutover inputs before hooks install.

    def read_projection(self, name):
        path = self.config[name]
        fd = os.open(path, os.O_RDONLY | os.O_NOFOLLOW)
        with os.fdopen(fd, "rb") as file:
            info = os.fstat(file.fileno())
            if not stat.S_ISREG(info.st_mode) or info.st_mode & 0o022:
                raise ValueError("legacy projection must not be writable by other roles")
            if info.st_uid not in (os.geteuid(), self.config["service_uid"]):
                raise ValueError("legacy projection owner differs")
            raw = file.read(4 * 1024 * 1024 + 1)
        if len(raw) > 4 * 1024 * 1024:
            raise ValueError("legacy projection too large")
        value = json.loads(raw)
        if not isinstance(value, dict):
            raise ValueError("legacy projection must be an object")
        return value

    def load_channels(self):
        value = self.read_projection("channels")
        captains = {str(v) for v in value.get("captain_user_ids", [])}
        channels = value["channels"]
        if not isinstance(channels, list) or not channels:
            raise ValueError("legacy channel inventory required")
        result = {}
        for channel in channels:
            name, chat = channel["name"], str(channel["chat_id"])
            users = {str(v) for v in channel.get("captain_user_ids", [])} or captains
            if not name or not chat or not users or chat in result:
                raise ValueError("invalid legacy channel ownership")
            result[chat] = {**channel, "name": str(name), "users": users,
                            "chat_types": channel.get("chat_types", ["group", "supergroup"])}
        return result, captains

    def load_correlations(self):
        value = self.read_projection("correlations")
        requests, recent = value["requests"], value.get("recent", {})
        if not isinstance(requests, dict) or not isinstance(recent, dict):
            raise ValueError("legacy correlation inventory required")
        return {str(k): v for k, v in {**requests, **recent}.items() if isinstance(v, dict)}

    def broker(self, payload):
        # No retries: a lost response may follow an accepted answer.
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as connection:
            connection.settimeout(8)
            connection.connect(self.config["socket"])
            _, uid, _ = struct.unpack("3i", connection.getsockopt(socket.SOL_SOCKET, socket.SO_PEERCRED, 12))
            if uid != self.config["service_uid"]:
                raise ValueError("legacy broker peer identity differs")
            connection.sendall(json.dumps(payload, separators=(",", ":")).encode() + b"\n")
            raw = bytearray()
            while b"\n" not in raw and len(raw) <= 16384:
                part = connection.recv(4096)
                if not part:
                    break
                raw.extend(part)
            if len(raw) > 16384 or b"\n" not in raw:
                raise ValueError("legacy broker result incomplete")
            result = json.loads(bytes(raw).split(b"\n", 1)[0])
            return result if isinstance(result, dict) else {}

    def receive(self, event):
        source = getattr(event, "source", None)
        platform = getattr(source, "platform", "")
        if str(getattr(platform, "value", platform)).lower() != "telegram":
            return None
        chat, user, chat_type = (str(getattr(source, key, "") or "") for key in ("chat_id", "user_id", "chat_type"))
        text = str(getattr(event, "text", "") or "").strip()
        reply = str(getattr(event, "reply_to_message_id", "") or "")
        command, _, raw = text.partition(" ")
        is_command = command.split("@", 1)[0].lower() == "/hitl-reply"
        skip = {"action": "skip", "reason": "ace_hitl_legacy_transition"}
        try:
            channels, captains = self.load_channels()
            correlations = self.load_correlations()
        except (OSError, ValueError, KeyError, TypeError):
            # Keep old known groups private when a projection is unavailable.
            return skip if chat in self.channels or self.native.channel(chat) or reply or is_command else None
        self.channels, self.captains = channels, captains
        channel = channels.get(chat)
        allowed = bool(channel and user in channel["users"] and chat_type in channel["chat_types"])
        allowed_dm = chat_type == "dm" and user == chat and user in captains
        native_channel = self.native.channel(chat)

        if is_command:
            if allowed or allowed_dm:
                self.submit({"action": "command", "raw": raw.strip(), "chat_id": chat,
                             "chat_type": chat_type, "user_id": user})
            return skip

        matches = [key for key, value in correlations.items()
                   if reply and str(value.get("chat_id", "")) == chat and str(value.get("message_id", "")) == reply]
        if matches:
            if len(matches) == 1 and (allowed or allowed_dm) and 0 < len(text) <= self.MAX_REPLY and "\0" not in text:
                self.submit({"action": "reply", "id": matches[0], "answer": text,
                             "chat_id": chat, "chat_type": chat_type, "user_id": user,
                             "message_id": str(getattr(event, "message_id", "") or ""),
                             "reply_to_message_id": reply})
            return skip  # Legacy correlation always owns that Reply, even on refusal.
        if native_channel:
            return self.native.receive(event)
        if channel:
            if allowed and text and not reply:
                self.submit({"action": "overseer-message", "channel": channel["name"],
                             "text": text, "chat_id": chat, "chat_type": chat_type,
                             "user_id": user, "message_id": str(getattr(event, "message_id", "") or "")})
            return skip
        return skip if reply and allowed_dm else None

    def submit(self, payload):
        try:
            self._broker(payload)
        except (OSError, ValueError, KeyError, TypeError):
            pass  # Original broker owns recovery; no retry or reply-text logging.
