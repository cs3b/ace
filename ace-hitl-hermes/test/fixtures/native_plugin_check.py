"""Executed by ace-test; stdlib only, PATH intentionally contains no Ruby."""
import asyncio
import importlib.util
import json
import os
from pathlib import Path
import stat
import sys
import tempfile
import types
import unittest

spec = importlib.util.spec_from_file_location("native", sys.argv.pop(1))
native = importlib.util.module_from_spec(spec)
spec.loader.exec_module(native)


class NativePluginTest(unittest.IsolatedAsyncioTestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.folder = native.Folder(self.tmp.name)
        self.roots = ["/lab/projects/ace/.ace-local/hitl", "/lab/worktrees/ace/fix/.ace-local/hitl"]
        self.channel = {"name": "lab", "machine": "lab", "folder": self.tmp.name,
                        "chat_id": "-100", "allowed_users": ["42"], "instruction_project": "overseer-lab",
                        "projects": {"ace": {"event_roots": [self.roots[0]], "worktree_roots": ["/lab/worktrees/ace"]},
                                     "overseer-lab": {"event_roots": ["/lab/coordinator/.ace-local/hitl"]}}}
        self.config = {"mode": "native-folder", "channels": [self.channel]}
        self.sent = []

        async def sender(chat, text):
            self.sent.append((chat, text))
            count = str(len(self.sent))
            return {"success": True, "message_ids": [count + "a", count + "b"]}

        self.sender = sender
        self.transport = native.NativeTransport(self.config, sender)

    def tearDown(self):
        self.tmp.cleanup()

    def request(self, index=0):
        root = self.roots[index]
        origin = {"root": root, "file": root + "/abc-question/abc-question.hitl.s.md", "case_id": "abc"}
        key = native.digest(["ace", origin["file"], "abc"])
        return self.folder.write("request", key, {
            "project": "ace", "channel": "lab", "machine": "lab", "origin": origin,
            "event_type": "question", "recipient": {"machine": "lab", "panel": "lab"},
            "reply_to": {"machine": "lab", "folder": root, "id": "abc"}, "text": "Proceed?"})

    def event(self, reply="1a", message="20", text="123456", user="42", chat="-100"):
        source = types.SimpleNamespace(platform="telegram", chat_id=chat, chat_type="supergroup", user_id=user)
        return types.SimpleNamespace(source=source, message_id=message, text=text, reply_to_message_id=reply)

    async def test_two_worktrees_exact_reply_continuation_duplicate_and_restart(self):
        first, second = self.request(), self.request(1)
        self.assertNotEqual(first["key"], second["key"])
        await self.transport.once()
        self.assertEqual(2, len(self.sent))
        # Use the first sent receipt, sorted transport-key order is immaterial.
        receipt = self.folder.read("delivery", first["key"])
        target = receipt["message_ids"][0]
        self.assertEqual("delivered", receipt["state"])
        self.transport.receive(self.event(reply=target))
        self.transport.receive(self.event(reply=target))
        await self.transport.once()
        reply = self.folder.read("reply", first["key"])
        self.assertEqual(first["origin"], reply["origin"])
        self.assertEqual("123456", reply["text"])
        self.assertIsNone(self.folder.read("reply", second["key"]))
        restarted = native.NativeTransport(self.config, self.sender)
        restarted.receive(self.event(reply=target))
        await restarted.once()
        self.assertEqual(2, len(self.sent))
        self.assertEqual(reply, self.folder.read("reply", first["key"]))
        self.assertEqual(0o600, stat.S_IMODE(self.folder.filename("reply", first["key"]).stat().st_mode))

    async def test_reply_before_send_receipt_is_retained_and_then_correlated(self):
        record = self.request()
        self.transport.receive(self.event())
        self.assertEqual(1, len(self.folder.keys("incoming")))
        await self.transport.once()
        self.assertEqual("123456", self.folder.read("reply", record["key"])["text"])
        self.assertEqual([], self.folder.keys("incoming"))

    async def test_unauthorized_unknown_reply_and_other_group_do_not_route(self):
        self.request()
        self.assertEqual("skip", self.transport.receive(self.event(user="99"))["action"])
        self.assertEqual([], self.folder.keys("incoming"))
        self.assertIsNone(self.transport.receive(self.event(chat="-200")))
        self.transport.receive(self.event(reply="unknown"))
        await self.transport.once()
        self.assertEqual([], self.folder.keys("reply"))
        self.assertEqual([], self.folder.keys("instruction"))
        self.assertEqual(1, len(self.folder.keys("incoming")))

    async def test_plain_message_is_coordinator_instruction(self):
        self.transport.receive(self.event(reply="", text="Work on ace"))
        await self.transport.once()
        key = self.folder.keys("instruction")[0]
        self.assertEqual("overseer-lab", self.folder.read("instruction", key)["project"])
        self.assertEqual([], self.sent)

    async def test_lost_send_response_and_sending_restart_never_resend(self):
        record = self.request()
        calls = []

        async def uncertain(chat, text):
            calls.append(chat)
            raise ConnectionResetError("secret response must not be logged")

        transport = native.NativeTransport(self.config, uncertain)
        await transport.once()
        self.assertEqual("unknown", self.folder.read("delivery", record["key"])["state"])
        await native.NativeTransport(self.config, uncertain).once()
        self.assertEqual(1, len(calls))
        other = self.request(1)
        self.folder.write("delivery", other["key"], {"state": "sending", "message_ids": []})
        await transport.once()
        self.assertEqual("unknown", self.folder.read("delivery", other["key"])["state"])
        self.assertEqual(1, len(calls))

    async def test_forged_origin_and_private_file_checks(self):
        record = self.request()
        record["origin"]["file"] = "/etc/secret"
        self.folder.write("request", record["key"], record, replace=True)
        await self.transport.once()
        self.assertEqual([], self.sent)
        symlink_key = "a" * 64
        os.symlink(self.folder.filename("request", record["key"]), self.folder.filename("request", symlink_key))
        with self.assertRaises(OSError):
            self.folder.read("request", symlink_key)
        os.chmod(self.tmp.name, 0o750)
        with self.assertRaises(ValueError):
            native.Folder(self.tmp.name)

    async def test_live_gateway_adapter_only_no_cli_or_new_client(self):
        calls = []

        class Adapter:
            is_connected = True
            async def send(self, **kwargs):
                calls.append(kwargs)
                return types.SimpleNamespace(success=True, message_id="2", continuation_message_ids=["1"])

        async def dispatch(runner, callback, _message):
            return await callback()

        sys.modules["tools"] = types.ModuleType("tools")
        senders = types.ModuleType("tools.send_message_senders")
        senders._live_adapter = lambda platform: (object(), Adapter())
        tool = types.ModuleType("tools.send_message_tool")
        tool._dispatch_on_gateway_loop = dispatch
        sys.modules["tools.send_message_senders"] = senders
        sys.modules["tools.send_message_tool"] = tool
        result = await native.gateway_send("-100", "Question")
        self.assertEqual(["1", "2"], result["message_ids"])
        self.assertEqual([{"chat_id": "-100", "content": "Question"}], calls)
        senders._live_adapter = lambda platform: (None, None)
        with self.assertRaises(RuntimeError):
            await native.gateway_send("-100", "Question")
        self.assertEqual(1, len(calls))

    async def test_gateway_startup_waits_before_effect_then_sends_once(self):
        record = self.request()

        async def unavailable(chat, text):
            raise native.GatewayUnavailable("not yet connected")

        await native.NativeTransport(self.config, unavailable).once()
        self.assertEqual("waiting_gateway", self.folder.read("delivery", record["key"])["state"])
        self.assertEqual([], self.sent)
        await self.transport.once()
        await self.transport.once()
        self.assertEqual(1, len(self.sent))
        self.assertEqual("delivered", self.folder.read("delivery", record["key"])["state"])

    async def test_packaged_plugin_registers_one_gateway_task_and_routes_without_subprocess(self):
        init_path = Path(native.__file__).with_name("__init__.py")
        spec = importlib.util.spec_from_file_location("ace_plugin", init_path)
        plugin = importlib.util.module_from_spec(spec)
        spec.loader.exec_module(plugin)
        config_path = Path(self.tmp.name) / "config.json"
        config_path.write_text(json.dumps(self.config))
        saved = os.environ.get("ACE_HITL_HERMES_CONFIG")
        os.environ["ACE_HITL_HERMES_CONFIG"] = str(config_path)
        tasks, hooks, factories = [], [], []

        class Context:
            def register_command(self, *_args, **_kwargs):
                pass

            def register_hook(self, name, callback):
                hooks.append((name, callback))

            def spawn_task(self, coro, name):
                tasks.append(asyncio.create_task(coro, name=name))
                return tasks[-1]

            def register_platform_handler(self, platform, callback):
                factories.append((platform, callback))

        def forbidden(*_args, **_kwargs):
            raise AssertionError("native plugin must not launch a Ruby subprocess")

        plugin.subprocess.run = forbidden
        try:
            plugin.register(Context())
            self.assertEqual("telegram", factories[0][0])
            factories[0][1](None, None)
            factories[0][1](None, None)
            self.assertEqual(1, len(tasks))
            self.assertEqual("ace-hitl-native-folder", tasks[0].get_name())
            self.assertEqual("pre_gateway_dispatch", hooks[0][0])
            self.assertEqual("skip", hooks[0][1](self.event(reply=""))["action"])
            self.assertEqual(1, len(self.folder.keys("incoming")))
            self.assertIsNone(hooks[0][1](self.event(chat="-200")))
        finally:
            for task in tasks:
                task.cancel()
            await asyncio.gather(*tasks, return_exceptions=True)
            if saved is None:
                os.environ.pop("ACE_HITL_HERMES_CONFIG", None)
            else:
                os.environ["ACE_HITL_HERMES_CONFIG"] = saved


if __name__ == "__main__":
    unittest.main()
