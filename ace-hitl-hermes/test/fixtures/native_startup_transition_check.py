"""Regression for Hermes' real pre-discovery -> connect ordering and cutover."""
import asyncio
import importlib.util
import json
import os
from pathlib import Path
import socket
import sys
import tempfile
import threading
import types
import unittest

plugin_path = Path(sys.argv.pop(1))


def load(name):
    spec = importlib.util.spec_from_file_location("checked_" + name, plugin_path / (name + ".py"))
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


native = load("native_transport")
legacy = load("legacy_transition")


class StartupAndTransitionTest(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.folder = native.Folder(self.tmp.name)
        self.config = {"mode": "native-folder", "interval_seconds": 0.2, "channels": [{
            "name": "lab", "machine": "lab", "folder": self.tmp.name, "chat_id": "-100",
            "allowed_users": ["42"], "instruction_project": "ace",
            "projects": {"ace": {"event_roots": ["/lab/projects/ace/.ace-local/hitl"]}}}]}
        self.projection = Path(self.tmp.name) / "channels.json"
        self.correlations = Path(self.tmp.name) / "correlations.json"
        self.projection.write_text(json.dumps({"captain_user_ids": ["42"], "channels": [
            {"name": name, "chat_id": chat} for name, chat in
            [("lab", "-100"), ("lab-config", "-200"), ("omarchy-config", "-300")]]}))
        self.correlations.write_text(json.dumps({"requests": {
            "old-lab": {"chat_id": "-100", "message_id": "10"},
            "old-host": {"chat_id": "-200", "message_id": "11"},
            "old-dm": {"chat_id": "42", "message_id": "12"}}, "recent": {}}))
        self.legacy_config = {"socket": self.tmp.name + "/broker.sock", "service_uid": os.geteuid(),
                              "channels": str(self.projection), "correlations": str(self.correlations)}
        self.calls = []

        async def sender(chat, text):
            raise AssertionError("fixture never sends live Telegram")

        self.transport = native.NativeTransport(self.config, sender)
        self.transition = legacy.LegacyTransition(self.legacy_config, self.transport, self.calls.append)

    def tearDown(self):
        self.tmp.cleanup()

    def event(self, chat="-100", reply="", user="42", message="20", text="Decision", chat_type="supergroup"):
        source = types.SimpleNamespace(platform="telegram", chat_id=chat, chat_type=chat_type, user_id=user)
        return types.SimpleNamespace(source=source, message_id=message, reply_to_message_id=reply, text=text)

    def test_sync_prediscovery_connect_sends_without_inbound_and_unload_cancels(self):
        plugin = load("__init__")
        config_path = Path(self.tmp.name) / "native.json"
        config_path.write_text(json.dumps(self.config))
        old = os.environ.get("ACE_HITL_HERMES_CONFIG")
        os.environ["ACE_HITL_HERMES_CONFIG"] = str(config_path)
        tasks, hooks, factories = [], [], []

        class Context:
            def register_command(self, *_args, **_kwargs):
                pass

            def register_hook(self, name, callback):
                hooks.append((name, callback))

            def register_platform_handler(self, platform, factory):
                factories.append((platform, factory))

            def spawn_task(self, coro, name):
                task = asyncio.create_task(coro, name=name)
                tasks.append(task)
                return task

        try:
            # Same ordering as Hermes main.py background plugin discovery.
            plugin.register(Context())
            self.assertEqual([], tasks)
            root = "/lab/projects/ace/.ace-local/hitl"
            origin = {"root": root, "file": root + "/abc-q/abc-q.hitl.s.md", "case_id": "abc"}
            key = native.digest(["ace", origin["file"], "abc"])
            self.folder.write("request", key, {
                "project": "ace", "channel": "lab", "machine": "lab", "origin": origin,
                "event_type": "question", "recipient": {"machine": "lab", "panel": "lab"},
                "reply_to": {"machine": "lab", "folder": root, "id": "abc"}, "text": "Proceed?"})

            async def gateway():
                sent = asyncio.Event()

                async def sender(chat, text):
                    self.calls.append(chat)
                    sent.set()
                    return {"success": True, "message_ids": ["10"]}

                plugin._native.sender = sender
                self.assertEqual("telegram", factories[0][0])
                # Actual TelegramAdapter.connect calls _wire_plugin_handlers.
                factories[0][1](None, types.SimpleNamespace(is_connected=True))
                factories[0][1](None, types.SimpleNamespace(is_connected=True))
                self.assertEqual(1, len(tasks))
                await asyncio.wait_for(sent.wait(), timeout=1)
                await asyncio.sleep(0)
                self.assertEqual(["-100"], self.calls)
                self.assertEqual("delivered", self.folder.read("delivery", key)["state"])
                self.assertEqual([], self.folder.keys("incoming"))  # No incoming wake required.
                # ctx.spawn_task is leased by Hermes; unload cancels its tasks.
                for task in tasks:
                    task.cancel()
                await asyncio.gather(*tasks, return_exceptions=True)
                self.assertTrue(all(task.cancelled() for task in tasks))

            asyncio.run(gateway())
        finally:
            if old is None:
                os.environ.pop("ACE_HITL_HERMES_CONFIG", None)
            else:
                os.environ["ACE_HITL_HERMES_CONFIG"] = old

    def test_old_lab_reply_keeps_owner_and_new_lab_events_are_native(self):
        before = self.correlations.read_bytes()
        self.transition.receive(self.event(reply="10"))
        self.assertEqual([("reply", "old-lab")], [(r["action"], r["id"]) for r in self.calls])
        self.assertEqual([], self.folder.keys("incoming"))
        self.transition.receive(self.event(reply="new-native", message="21"))
        self.transition.receive(self.event(message="22"))
        self.assertEqual(1, len(self.calls))
        self.assertEqual(2, len(self.folder.keys("incoming")))
        self.assertEqual(before, self.correlations.read_bytes())

    def test_host_groups_and_old_host_reply_keep_broker(self):
        self.transition.receive(self.event(chat="-200"))
        self.transition.receive(self.event(chat="-300", message="21"))
        self.transition.receive(self.event(chat="-200", reply="11", message="22"))
        self.assertEqual(["overseer-message", "overseer-message", "reply"],
                         [r["action"] for r in self.calls])
        self.assertEqual(["lab-config", "omarchy-config"], [r["channel"] for r in self.calls[:2]])
        self.assertEqual([], self.folder.keys("incoming"))

    def test_unknown_reply_never_becomes_plain_instruction_and_denial_has_no_effect(self):
        self.transition.receive(self.event(chat="-200", reply="unknown"))
        self.transition.receive(self.event(reply="10", user="99"))
        self.transition.receive(self.event(reply="native", user="99"))
        self.transition.receive(self.event(chat="-300", user="99"))
        self.transition.receive(self.event(user="99", text="/hitl-reply old-lab answer"))
        self.assertEqual([], self.calls)
        self.assertEqual([], self.folder.keys("incoming"))
        self.assertIsNone(self.transition.receive(self.event(chat="-999")))

    def test_old_dm_reply_and_explicit_legacy_command(self):
        self.transition.receive(self.event(chat="42", chat_type="dm", reply="12"))
        self.transition.receive(self.event(text="/hitl-reply old-lab decision"))
        self.assertEqual(["reply", "command"], [r["action"] for r in self.calls])
        self.assertEqual([], self.folder.keys("incoming"))

    def test_lost_broker_response_has_no_native_fallback_or_automatic_retry(self):
        calls = []

        def fail(payload):
            calls.append(payload["id"])
            raise ConnectionResetError("private response")

        transition = legacy.LegacyTransition(self.legacy_config, self.transport, fail)
        self.assertEqual("skip", transition.receive(self.event(reply="10"))["action"])
        self.assertEqual(["old-lab"], calls)
        self.assertEqual([], self.folder.keys("incoming"))

    def test_missing_projection_fails_closed_for_known_groups(self):
        self.correlations.unlink()
        for chat in ["-100", "-200", "-300"]:
            self.assertEqual("skip", self.transition.receive(self.event(chat=chat))["action"])
        self.assertEqual([], self.calls)
        self.assertEqual([], self.folder.keys("incoming"))

    def test_existing_unix_protocol_checks_peer_and_never_retries(self):
        captured = []
        with socket.socket(socket.AF_UNIX, socket.SOCK_STREAM) as server:
            server.bind(self.legacy_config["socket"])
            server.listen(1)

            def receive():
                connection, _ = server.accept()
                with connection:
                    captured.append(json.loads(connection.recv(8192)))
                    connection.sendall(b'{"ok":true,"status":"delivered"}\n')

            thread = threading.Thread(target=receive)
            thread.start()
            try:
                result = legacy.LegacyTransition(self.legacy_config, self.transport).broker({"action": "reply", "id": "old-lab"})
                self.assertEqual("delivered", result["status"])
            finally:
                thread.join(timeout=2)
            self.assertFalse(thread.is_alive())
            self.assertEqual([{"action": "reply", "id": "old-lab"}], captured)

    def test_single_packaged_hook_selects_only_one_owner(self):
        plugin = load("__init__")
        path = Path(self.tmp.name) / "combined.json"
        path.write_text(json.dumps({**self.config, "legacy_broker": self.legacy_config}))
        old = os.environ.get("ACE_HITL_HERMES_CONFIG")
        os.environ["ACE_HITL_HERMES_CONFIG"] = str(path)
        hooks = []

        class Context:
            def register_command(self, *_args, **_kwargs):
                pass

            def register_hook(self, name, callback):
                hooks.append(callback)

            def register_platform_handler(self, *_args):
                pass

            def spawn_task(self, *_args, **_kwargs):
                raise AssertionError("synchronous discovery cannot start a task")

        try:
            plugin.register(Context())
            plugin._transition._broker = self.calls.append
            self.assertEqual(1, len(hooks))
            hooks[0](self.event(reply="10"))
            hooks[0](self.event(chat="-200", message="21"))
            hooks[0](self.event(message="22"))
            self.assertEqual(["reply", "overseer-message"], [v["action"] for v in self.calls])
            self.assertEqual(1, len(self.folder.keys("incoming")))
        finally:
            if old is None:
                os.environ.pop("ACE_HITL_HERMES_CONFIG", None)
            else:
                os.environ["ACE_HITL_HERMES_CONFIG"] = old


if __name__ == "__main__":
    unittest.main()
