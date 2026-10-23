# frozen_string_literal: true

require "test_helper"
require "ace/hitl/hermes/organisms/native_sync"
require "ace/hitl/adapters/hermes_native"
require "ace/hitl/hermes/cli"
require "open3"

class NativeSyncTest < AceHermesTestCase
  H = Ace::Hitl
  N = H::Hermes::Molecules::NativeFolder
  S = H::Hermes::Organisms::NativeSync

  def setup
    super
    @tmp = Dir.mktmpdir("native-hitl")
    @folder = File.join(@tmp, "transport")
    @roots = %w[ace/work-a ace/work-b coordinator].map { |p| File.join(@tmp, p, ".ace-local/hitl") }
    FileUtils.mkdir_p([@folder, *@roots], mode: 0o700)
    @route = {"route" => "captain", "adapter" => "hermes_native", "folder" => @folder,
      "project" => "ace", "channel" => "lab", "machine" => "lab",
      "event_roots" => @roots.take(2)}
    @config = {"hitl" => {"machine" => "lab", "recipients" => {"captain" => {"machine" => "lab", "panel" => "lab"}}}}
  end

  def teardown
    FileUtils.remove_entry(@tmp)
    super
  end

  def owner(root)
    H::Organisms::HitlManager.new(root_dir: root,
      config: @config.merge("hitl" => @config["hitl"].merge("root_dir" => root)),
      scope_resolver: S::OriginScope.new(root))
  end

  def question(index = 0)
    owner(@roots[index]).create("Choose next task", to: "captain", questions: ["Continue?"],
      time: Time.utc(2026, 10, 20))
  end

  def publish(event)
    N.new(@route).publish(event, "Question")
  end

  def receipt(record, state: "delivered", ids: ["10"])
    N.new(@route).write_once("delivery", record["key"],
      {"schema" => N::SCHEMA, "kind" => "delivery", "key" => record["key"], "state" => state, "message_ids" => ids})
  end

  def reply(record, text: "Yes", reply_to: "10")
    N.new(@route).write_once("reply", record["key"],
      record.merge("kind" => "reply", "text" => text, "reply_to_message_id" => reply_to, "message_id" => "20"))
  end

  def test_two_worktrees_with_same_case_id_bind_reply_to_original_file
    first, second = question(0), question(1)
    assert_equal first.id, second.id
    record = publish(first)
    other = publish(second)
    refute_equal record["key"], other["key"]
    receipt(record)
    reply(record, text: "Yes\n")
    result = S.new(@route).run
    assert_empty result["errors"]
    assert_equal 1, result["replies"]
    assert_equal "Yes", owner(@roots[0]).show(first.id, scope: "current")[:event].answer
    assert_equal "delivered", owner(@roots[0]).show(first.id, scope: "current")[:event].metadata.dig("delivery", "captain", "status")
    assert_nil owner(@roots[1]).show(second.id, scope: "current")[:event].answer
    # Replayed exact transport reply is idempotent after a new sync instance.
    reply(record, text: "Yes\n")
    before = File.binread(first.file_path)
    assert_empty S.new(@route).run["errors"]
    assert_equal before, File.binread(first.file_path)
  end

  def test_spooling_is_not_delivery_and_unknown_receipt_does_not_confirm
    event = question
    adapter = H::Hermes::Organisms::NativeHitlAdapter.new(@route)
    args = {event: event, text: "Question", recipient: event.recipient, reply_to: event.reply_to}
    assert_equal :unavailable, adapter.deliver(**args).status
    record = publish(event)
    receipt(record, state: "unknown", ids: [])
    assert_equal :unavailable, adapter.deliver(**args).status
    assert_equal 1, N.new(@route).keys("request").size
    assert_equal "unknown", S.new(@route).run["deliveries"].first["state"]
  end

  def test_confirmed_delivery_then_send_reads_receipt_without_another_request
    event = question
    record = publish(event)
    receipt(record)
    result = H::Hermes::Organisms::NativeHitlAdapter.new(@route).deliver(
      event: event, text: "Question", recipient: event.recipient, reply_to: event.reply_to)
    assert_equal :delivered, result.status
    assert_equal 1, N.new(@route).keys("request").size
  end

  def test_managed_lifecycle_question_cannot_migrate_into_native_transport
    event = question
    managed = owner(@roots[0]).update(event.id, scope: "current", set: {"lab_request_id" => "managed-1"})
    assert_raises(H::Hermes::ContractError) { publish(managed) }
    assert_raises(H::Organisms::HitlManager::NotAnswerableError) do
      owner(@roots[0]).accept_answer(event.id, scope: "current", answer: "Yes")
    end
    assert_empty N.new(@route).keys("request")
  end

  def test_wrong_reply_and_preexisting_answer_are_not_overwritten
    event = question
    record = publish(event)
    receipt(record)
    reply(record, reply_to: "other")
    assert_equal 1, S.new(@route).run["errors"].size
    assert_nil owner(@roots[0]).show(event.id, scope: "current")[:event].answer
    N.new(@route).ack("reply", record["key"])
    reply(record)
    owner(@roots[0]).update(event.id, scope: "current", answer: "Human decision")
    assert_equal 1, S.new(@route).run["errors"].size
    assert_equal "Human decision", owner(@roots[0]).show(event.id, scope: "current")[:event].answer
  end

  def test_strict_owner_allowlist_and_real_symlink_refusal
    event = question
    wrong = @route.merge("event_roots" => [@roots[1]])
    assert_raises(H::Hermes::ContractError) { N.new(wrong).publish(event, "Question") }
    link = File.join(@tmp, "linked")
    File.symlink(@folder, link)
    assert_raises(H::Hermes::ContractError) { N.new(@route.merge("folder" => link)) }
    record = publish(event)
    path = File.join(@folder, "reply-#{record['key']}.json")
    File.symlink(event.file_path, path)
    assert_raises(H::Hermes::ContractError) { N.new(@route).read("reply", record["key"]) }
    File.chmod(0o750, @folder)
    assert_raises(H::Hermes::ContractError) { N.new(@route) }
  end

  def test_plain_instructions_import_only_coordinator_and_replay_without_duplicates
    route = @route.merge("project" => "overseer-lab", "event_roots" => [@roots[2]], "instruction_root" => @roots[2])
    folder = N.new(route)
    key = "c" * 64
    item = {"schema" => N::SCHEMA, "kind" => "instruction", "key" => key,
      "project" => "overseer-lab", "channel" => "lab", "machine" => "lab", "text" => "Work on ace"}
    folder.write_once("instruction", key, item)
    assert_equal 0, S.new(@route).run["instructions"]
    assert_equal 1, S.new(route).run["instructions"]
    folder.write_once("instruction", key, item)
    assert_equal 1, S.new(route).run["instructions"]
    events = owner(@roots[2]).list(in_folder: "all", scope: "current")
    assert_equal 1, events.size
    assert events.first.report?
    assert_includes events.first.tags, "hermes-instruction"
  end

  def test_native_reply_to_semantic_eyes_runs_real_commands_without_model_or_broker
    event = question
    record = publish(event)
    receipt(record)
    reply(record, text: "private-eyes-answer")
    project = File.dirname(File.dirname(@roots.first))
    FileUtils.mkdir_p(File.join(project, ".ace", "hitl"))
    File.write(File.join(project, ".ace", "hitl", "config.yml"), {"root_dir" => @roots.first, "machine" => "lab", "recipients" => {"self" => {"machine" => "lab", "panel" => "w1:p1"}}}.to_yaml)
    route_path = File.join(@tmp, "route.json")
    File.write(route_path, JSON.generate(@route))
    source_root = File.expand_path("../../../..", __dir__)
    eyes_root = File.join(source_root, "ace-handbook-integration-pi/handbook/extensions/ace-wake/wake")
    script = <<~JS
      import assert from "node:assert/strict";
      import { Eyes } from #{File.join(eyes_root, "eyes.js").to_json};
      import { observeHitl } from #{File.join(eyes_root, "eyes-runtime.js").to_json};
      let snapshot, sends=[];
      const build=()=>new Eyes({snapshot,save:s=>{snapshot=s;},
        observe:config=>observeHitl(#{project.to_json},config),
        deliver:batch=>{sends.push(batch);return true;}});
      let eyes=build();eyes.start({syncRoutes:[#{route_path.to_json}]});
      await eyes.tick();assert.equal(sends.length,1);
      const [key,value]=sends[0][0];eyes.ack(key,value.revision);
      await eyes.tick();eyes.dispose();eyes=build();await eyes.tick();
      assert.equal(sends.length,1);assert.equal(snapshot.breaker,null);
      assert.ok(!JSON.stringify(snapshot).includes("private-eyes-answer"));
      console.log("native-sync/semantic-observe/eyes/ack/restart PASS");
    JS
    env = {"PATH" => "#{File.join(source_root, 'bin')}:#{ENV.fetch('PATH')}",
      "BUNDLE_GEMFILE" => File.join(source_root, "Gemfile")}
    out, err, status = Open3.capture3(env, "node", "--input-type=module", "-e", script)
    assert status.success?, "eyes integration failed: #{out} #{err}"
    assert_includes out, "eyes/ack/restart PASS"
    assert_equal "private-eyes-answer", owner(@roots.first).show(event.id, scope: "current")[:event].answer
  end

  def test_sync_cli_needs_no_lifecycle_endpoint_and_prints_no_reply_content
    record = publish(question)
    receipt(record)
    reply(record, text: "123456")
    path = File.join(@tmp, "route.json")
    File.write(path, JSON.generate(@route))
    out = StringIO.new
    H::Hermes::CLI.start(["sync", "--config", path], output: out)
    assert_equal 1, JSON.parse(out.string)["replies"]
    refute_includes out.string, "123456"
    assert_equal 0o600, File.stat(File.join(@folder, "request-#{record['key']}.json")).mode & 0o777
  end

  def test_real_ruby_frame_python_gateway_fixture_and_ruby_owner_round_trip
    event = question
    record = publish(event)
    config_path = File.join(@tmp, "gateway.json")
    File.write(config_path, JSON.generate({"mode" => "native-folder", "channels" => [{
      "name" => "lab", "machine" => "lab", "folder" => @folder, "chat_id" => "-100",
      "allowed_users" => ["42"], "instruction_project" => "ace",
      "projects" => {"ace" => {"event_roots" => @route["event_roots"]}}
    }]}))
    package = File.expand_path("../../..", __dir__)
    script = <<~PY
      import asyncio, importlib.util, json, types
      spec=importlib.util.spec_from_file_location("native", #{File.join(package, "plugin/native_transport.py").inspect})
      native=importlib.util.module_from_spec(spec); spec.loader.exec_module(native)
      with open(#{config_path.inspect}) as file: config=json.load(file)
      calls=[]
      async def send(chat,text):
          calls.append(chat)
          return {"success":True,"message_ids":["42a","42b"]}
      transport=native.NativeTransport(config, send)
      async def run():
          await transport.once()
          source=types.SimpleNamespace(platform="telegram",chat_id="-100",chat_type="supergroup",user_id="42")
          event=types.SimpleNamespace(source=source,message_id="99",reply_to_message_id="42b",text="Exact original answer")
          assert transport.receive(event)["action"]=="skip"
          await transport.once()
          assert calls==["-100"]
      asyncio.run(run())
    PY
    python, status = Open3.capture2("which", "python3")
    assert status.success?
    out, err, status = Open3.capture3({"PATH" => "/nonexistent", "PYTHONDONTWRITEBYTECODE" => "1"},
      python.strip, "-c", script)
    assert status.success?, out + err
    result = S.new(@route).run
    assert_empty result["errors"]
    assert_equal 1, result["replies"]
    assert_equal "Exact original answer", owner(@roots[0]).show(event.id, scope: "current")[:event].answer
    assert_equal "delivered", N.new(@route).read("delivery", record["key"])["state"]
  end
end
