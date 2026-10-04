# frozen_string_literal: true

require_relative "../../test_helper"
require "shellwords"

class RuntimeControlSurfaceRunnerTest < AceAssignTestCase
  class FakeRuntimeAdapter
    attr_reader :calls

    def initialize(context: {in_runtime: true, session: "dev", window: "work", pane: "%9"})
      @context = context
      @calls = []
    end

    def context
      @context
    end

    def ensure_window(name:, root:)
      @calls << {op: :ensure_window, name: name, root: root}
      "@7"
    end

    def prepare_pane(window:)
      @calls << {op: :prepare_pane, window: window}
      "%3"
    end

    def send_command(pane:, command:)
      @calls << {op: :send_command, pane: pane, command: command}
      true
    end

    def capture(pane:, lines:)
      @calls << {op: :capture, pane: pane, lines: lines}
      "tail"
    end
  end

  def teardown
    Ace::Runtime.reset_registry!
    super
  end

  def test_detect_runtime_reads_environment_only
    assert_equal "tmux", build_runner(env: {"TMUX" => "/tmp/sock,0,0"}).detect_runtime
    assert_equal "herdr", build_runner(env: {"HERDR_SESSION" => "ws", "HERDR_PANE" => "p1"}).detect_runtime
    assert_nil build_runner(env: {}).detect_runtime
  end

  def test_current_context_comes_from_resolved_adapter
    adapter = register_fake_runtime

    runner = build_runner(runtime: "faketmux")

    assert_equal true, runner.in_runtime?
    assert_equal "dev", runner.current_session
    assert_equal "%9", runner.current_pane
    assert_empty adapter.calls
  end

  def test_env_override_wins_for_callback_pane
    register_fake_runtime

    runner = build_runner(
      runtime: "faketmux",
      env: {"ACE_ASSIGN_CALLBACK_PANE" => "%1"}
    )

    assert_equal "%1", runner.current_pane
  end

  def test_fork_window_name_sanitizes_and_is_suffix_idempotent
    register_fake_runtime
    runner = build_runner(runtime: "faketmux")

    assert_equal "my-work-fs", runner.fork_window_name("my work!")
    assert_equal "work-fs", runner.fork_window_name("work-fs")
  end

  def test_ensure_window_and_prepare_pane_delegate_to_adapter
    adapter = register_fake_runtime
    runner = build_runner(runtime: "faketmux")

    assert_equal "@7", runner.ensure_window(name: "work-fs", root: Dir.pwd)
    assert_equal "%3", runner.prepare_pane(window: "work-fs")
    assert_equal({op: :ensure_window, name: "work-fs", root: Dir.pwd}, adapter.calls[0])
    assert_equal({op: :prepare_pane, window: "work-fs"}, adapter.calls[1])
  end

  def test_runtime_failures_surface_as_assign_errors
    adapter = FakeRuntimeAdapter.new
    def adapter.ensure_window(name:, root:)
      raise Ace::Runtime::WindowConflictError, "window 'work-fs' has a different root"
    end

    def adapter.prepare_pane(window:)
      raise Ace::Runtime::RuntimeUnavailableError, "tmux runtime is unavailable"
    end

    Ace::Runtime.reset_registry!
    Ace::Runtime.register(:faketmux, -> { adapter })
    runner = build_runner(runtime: "faketmux")

    conflict = assert_raises(Ace::Assign::Error) { runner.ensure_window(name: "work-fs", root: Dir.pwd) }
    assert_includes conflict.message, "different root"

    unavailable = assert_raises(Ace::Assign::Error) { runner.prepare_pane(window: "work-fs") }
    assert_includes unavailable.message, "unavailable"
  end

  def test_run_invocation_builds_pane_shell_command
    adapter = register_fake_runtime
    runner = build_runner(runtime: "faketmux")

    runner.run_invocation_in_pane(
      pane_target: "%3",
      command: ["ace-llm", "claude:sonnet", "/as-assign-drive a@010"],
      env: {"FROM_BUILDER" => "1", "ACE_RUNTIME" => nil},
      working_dir: Dir.pwd,
      visible_handoff: "$as-assign-drive a@010"
    )

    command = adapter.calls.last.fetch(:command)
    assert shell_command_starts_with_cd?(command, Dir.pwd)
    assert shell_command_includes_handoff?(command, "$as-assign-drive a@010")
    assert shell_command_includes_env?(command, "FROM_BUILDER=1")
    assert shell_command_includes_env?(command, "-u ACE_RUNTIME")
  end

  def test_run_script_in_pane_sends_bash_invocation
    adapter = register_fake_runtime
    runner = build_runner(runtime: "faketmux")

    runner.run_script_in_pane(pane_target: "%3", script_path: "/tmp/fork.sh")

    assert_equal :send_command, adapter.calls.last[:op]
    assert_equal "%3", adapter.calls.last[:pane]
    assert_equal "bash /tmp/fork.sh", adapter.calls.last[:command]
  end

  def test_capture_delegates_to_adapter
    adapter = register_fake_runtime
    runner = build_runner(runtime: "faketmux")

    assert_equal "tail", runner.capture_recent_output(pane_target: "%3", lines: 12)
    assert_equal({op: :capture, pane: "%3", lines: 12}, adapter.calls.last)
  end

  def test_merge_runtime_metadata_writes_runtime_neutral_fields
    register_fake_runtime
    runner = build_runner(runtime: "herdr")

    with_temp_cache do |tmp_dir|
      meta_path = File.join(tmp_dir, "session.yml")
      runner.merge_runtime_metadata(
        session_meta_file: meta_path, session: "ws-1", window: "work-fs", pane: "p3",
        window_id: "tab-7", callback_pane: "p9"
      )

      data = YAML.safe_load_file(meta_path)
      assert_equal "herdr", data["launch_mode"]
      assert_equal "herdr", data["runtime"]
      assert_equal "ws-1", data["session"]
      assert_equal "work-fs", data["window"]
      assert_equal "tab-7", data["window_id"]
      assert_equal "p3", data["pane"]
      assert_equal "p9", data["callback_pane"]
      refute data.key?("tmux_session")
    end
  end

  def test_merge_runtime_metadata_omits_optional_fields
    register_fake_runtime
    runner = build_runner(runtime: "tmux")

    with_temp_cache do |tmp_dir|
      meta_path = File.join(tmp_dir, "session.yml")
      runner.merge_runtime_metadata(session_meta_file: meta_path, session: "dev", window: "work-fs", pane: "%3")

      data = YAML.safe_load_file(meta_path)
      refute data.key?("window_id")
      refute data.key?("callback_pane")
    end
  end

  private

  def build_runner(runtime: nil, env: {})
    Ace::Assign::Molecules::RuntimeControlSurfaceRunner.new(runtime: runtime, env: env)
  end

  def register_fake_runtime
    adapter = FakeRuntimeAdapter.new
    Ace::Runtime.reset_registry!
    Ace::Runtime.register(:faketmux, -> { adapter })
    adapter
  end

  def shell_command_starts_with_cd?(command, dir)
    command.start_with?("cd #{Shellwords.escape(File.expand_path(dir))} && ")
  end

  def shell_command_includes_handoff?(command, handoff)
    command.include?("printf '%s\\n' #{Shellwords.escape(handoff)}")
  end

  def shell_command_includes_env?(command, part)
    command.include?("#{part} ")
  end
end
