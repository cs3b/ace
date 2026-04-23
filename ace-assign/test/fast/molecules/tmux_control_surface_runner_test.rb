# frozen_string_literal: true

require_relative "../../test_helper"

class TmuxControlSurfaceRunnerTest < AceAssignTestCase
  class FakeExecutor
    attr_reader :capture_commands, :run_commands

    def initialize(capture_results: {}, run_results: {})
      @capture_results = capture_results
      @run_results = run_results
      @capture_commands = []
      @run_commands = []
    end

    def capture(cmd)
      @capture_commands << cmd
      @capture_results.fetch(cmd) do
        Ace::Tmux::Molecules::ExecutionResult.new(stdout: "", stderr: "", success: true, exit_code: 0)
      end
    end

    def run(cmd)
      @run_commands << cmd
      @run_results.fetch(cmd, true)
    end
  end

  class FakeControlSurface
    attr_reader :commands, :captures

    def initialize(capture_output: "tail")
      @capture_output = capture_output
      @commands = []
      @captures = []
    end

    def send_command(pane:, command:)
      @commands << {pane: pane, command: command}
      true
    end

    def capture_recent_output(pane:, lines:)
      @captures << {pane: pane, lines: lines}
      @capture_output
    end
  end

  def test_current_window_prefers_explicit_fork_window
    runner = build_runner(env: {"ACE_ASSIGN_FORK_WINDOW" => "work-fs"})

    assert_equal "work-fs", runner.current_window
  end

  def test_current_window_uses_shared_runtime_target_resolution
    resolver = Object.new
    resolver.define_singleton_method(:resolve_session) do
      Ace::Tmux::Models::RuntimeTarget.new(session: "demo", source: "env")
    end
    resolver.define_singleton_method(:resolve_window) do |session:|
      Ace::Tmux::Models::RuntimeTarget.new(session: session, window: "work", source: "live")
    end

    runner = build_runner(resolver: resolver)

    assert_equal "work", runner.current_window
  end

  def test_current_pane_uses_shared_runtime_target_resolution
    resolver = Object.new
    resolver.define_singleton_method(:resolve_session) do
      Ace::Tmux::Models::RuntimeTarget.new(session: "demo", source: "env")
    end
    resolver.define_singleton_method(:resolve_window) do |session:|
      Ace::Tmux::Models::RuntimeTarget.new(session: session, window: "work", source: "live")
    end
    resolver.define_singleton_method(:resolve_pane) do |session:, window:|
      Ace::Tmux::Models::RuntimeTarget.new(session: session, window: window, pane: "3", source: "live")
    end

    runner = build_runner(resolver: resolver)

    assert_equal "demo:work.3", runner.current_pane
  end

  def test_ensure_window_reuses_existing_window
    executor = FakeExecutor.new(
      capture_results: {
        ["tmux", "list-windows", "-t", "demo", "-F", '#{window_id}' + "\t" + '#{window_name}'] =>
          result(stdout: "@7\twork-fs\n@8\tlogs")
      }
    )
    runner = build_runner(executor: executor)

    info = runner.ensure_window(session: "demo", name: "work-fs", root: Dir.pwd)

    assert_equal false, info[:created]
    assert_equal "@7", info[:target]
    assert_equal "@7", info[:window_id]
  end

  def test_prepare_pane_reuses_first_pane_when_window_created
    executor = FakeExecutor.new(
      capture_results: {
        ["tmux", "list-panes", "-t", "demo:work-fs", "-F", '#{pane_id}'] =>
          result(stdout: "%12")
      }
    )
    runner = build_runner(executor: executor)

    pane = runner.prepare_pane(session: "demo", window: "work-fs", root: Dir.pwd, keep_existing: true)

    assert_equal "%12", pane
    assert_includes executor.run_commands, ["tmux", "set-option", "-p", "-t", "%12", "remain-on-exit", "on"]
    assert_includes executor.run_commands, ["tmux", "select-layout", "-t", "demo:work-fs", "tiled"]
  end

  def test_prepare_pane_creates_new_pane_when_window_reused
    executor = FakeExecutor.new(
      capture_results: {
        ["tmux", "split-window", "-t", "demo:work-fs", "-c", File.expand_path("~/tmp"), "-P", "-F", '#{pane_id}'] =>
          result(stdout: "%44")
      }
    )
    runner = build_runner(executor: executor)

    pane = runner.prepare_pane(session: "demo", window: "work-fs", root: "~/tmp", keep_existing: false)

    assert_equal "%44", pane
  end

  def test_run_script_in_pane_uses_shared_control_surface
    control_surface = FakeControlSurface.new
    runner = build_runner(control_surface: control_surface)

    runner.run_script_in_pane(pane_target: "%42", script_path: "/tmp/fork.sh")

    assert_equal [{pane: "%42", command: "bash /tmp/fork.sh"}], control_surface.commands
  end

  def test_merge_tmux_metadata_writes_shared_fields
    runner = build_runner

    with_temp_cache do |tmp_dir|
      meta_path = File.join(tmp_dir, "session.yml")
      runner.merge_tmux_metadata(session_meta_file: meta_path, session: "demo", window: "work-fs", pane: "%42", callback_pane: "%8")

      data = YAML.safe_load_file(meta_path)
      assert_equal "tmux", data["launch_mode"]
      assert_equal "demo", data["tmux_session"]
      assert_equal "work-fs", data["tmux_window"]
      assert_equal "%42", data["tmux_pane_id"]
      assert_equal "%8", data["callback_pane"]
    end
  end

  private

  def build_runner(executor: FakeExecutor.new, resolver: nil, control_surface: nil, env: {})
    resolver ||= default_resolver
    control_surface ||= FakeControlSurface.new
    Ace::Assign::Molecules::TmuxControlSurfaceRunner.new(
      executor: executor,
      resolver: resolver,
      control_surface: control_surface,
      env: env
    )
  end

  def default_resolver
    resolver = Object.new
    resolver.define_singleton_method(:resolve_session) do |session: nil|
      Ace::Tmux::Models::RuntimeTarget.new(session: session || "demo", source: "explicit")
    end
    resolver.define_singleton_method(:resolve_window) do |session: nil, window: nil|
      Ace::Tmux::Models::RuntimeTarget.new(session: session || "demo", window: window || "work", source: "explicit")
    end
    resolver.define_singleton_method(:resolve_pane) do |session: nil, window: nil, pane: nil|
      Ace::Tmux::Models::RuntimeTarget.new(session: session || "demo", window: window || "work", pane: pane || "1", source: "explicit")
    end
    resolver
  end

  def result(stdout: "", stderr: "", success: true, exit_code: 0)
    Ace::Tmux::Molecules::ExecutionResult.new(
      stdout: stdout,
      stderr: stderr,
      success: success,
      exit_code: exit_code
    )
  end
end
