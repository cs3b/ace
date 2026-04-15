# frozen_string_literal: true

require_relative "../../test_helper"

class ForkSessionLauncherTest < AceAssignTestCase
  class FakeTmuxRunner
    def initialize(enabled: false, session: "dev", window: "task")
      @enabled = enabled
      @session = session
      @window = window
    end

    def tmux_context?
      @enabled
    end

    def current_session
      @session if @enabled
    end

    def current_window
      @window if @enabled
    end

    def fork_window_name(base_window)
      "#{base_window}-fs"
    end

    def ensure_window(session:, name:, root:)
      {created: true, target: "#{session}:#{name}", root: root}
    end

    def prepare_pane(session:, window:, root:, keep_existing:)
      @last_prepare = {session: session, window: window, root: root, keep_existing: keep_existing}
      "%42"
    end

    def run_script_in_pane(pane_target:, script_path:)
      @last_script = {pane_target: pane_target, script_path: script_path}
    end

    def select_window(session:, window:)
      @last_select = {session: session, window: window}
    end

    def merge_tmux_metadata(session_meta_file:, session:, window:, pane:)
      meta = File.exist?(session_meta_file) ? YAML.safe_load_file(session_meta_file) : {}
      meta["launch_mode"] = "tmux"
      meta["tmux_session"] = session
      meta["tmux_window"] = window
      meta["tmux_pane_id"] = pane
      File.write(session_meta_file, meta.to_yaml)
    end
  end

  class FakeInteractiveBuilder
    attr_reader :calls

    def initialize
      @calls = []
    end

    def build(provider_model:, prompt:, cli_args: nil, **_options)
      @calls << {provider_model: provider_model, prompt: prompt, cli_args: cli_args}
      {
        command: ["ace-llm", provider_model, prompt, "--interactive"],
        env: {},
        working_dir: Dir.pwd,
        prompt: "$as-assign-drive abc123@010",
        provider: provider_model.split(":").first,
        model: provider_model.split(":")[1]
      }
    end
  end

  class FakeQueryInterface
    attr_reader :calls

    def initialize
      @calls = []
    end

    def query(provider_model, prompt = nil, **options)
      @calls << {
        provider_model: provider_model,
        prompt: prompt,
        options: options
      }
      {text: "ok", provider: provider_model.split(":").first, model: provider_model.split(":")[1]}
    end
  end

  def build_launcher(config:, query_interface:, tmux_enabled: false, session: "dev", window: "task", interactive_builder: nil)
    Ace::Assign::Molecules::ForkSessionLauncher.new(
      config: config,
      query_interface: query_interface,
      tmux_runner: FakeTmuxRunner.new(enabled: tmux_enabled, session: session, window: window),
      interactive_builder: interactive_builder
    )
  end

  def test_launch_uses_config_defaults_and_passes_scoped_assignment_argument
    fake = FakeQueryInterface.new
    config = {
      "execution" => {"provider" => "codex:gpt-5@yolo", "timeout" => 900},
      "providers" => {}
    }
    launcher = build_launcher(config: config, query_interface: fake)

    launcher.launch(assignment_id: "abc123", fork_root: "010.01")

    call = fake.calls.last
    assert_equal "codex:gpt-5@yolo", call[:provider_model]
    assert_equal "/as-assign-drive abc123@010.01", call[:prompt]
    assert_nil call[:options][:cli_args]
    assert_equal 900, call[:options][:timeout]
    assert_equal false, call[:options][:fallback]
  end

  def test_launch_passes_user_cli_args_without_merging
    fake = FakeQueryInterface.new
    config = {
      "execution" => {"provider" => "claude:sonnet@yolo", "timeout" => 1800},
      "providers" => {}
    }
    launcher = build_launcher(config: config, query_interface: fake)

    launcher.launch(
      assignment_id: "abc123",
      fork_root: "010",
      cli_args: "--model-settings x"
    )

    call = fake.calls.last
    assert_equal "--model-settings x", call[:options][:cli_args]
  end

  def test_launch_passes_nil_cli_args_when_not_provided
    fake = FakeQueryInterface.new
    config = {
      "execution" => {"provider" => "codex:gpt-5@yolo", "timeout" => 900},
      "providers" => {}
    }
    launcher = build_launcher(config: config, query_interface: fake)

    launcher.launch(assignment_id: "abc123", fork_root: "010")

    call = fake.calls.last
    assert_nil call[:options][:cli_args]
  end

  def test_launch_passes_last_message_file_when_cache_dir_provided
    fake = FakeQueryInterface.new
    config = {
      "execution" => {"provider" => "claude:sonnet", "timeout" => 1800},
      "providers" => {}
    }
    launcher = build_launcher(config: config, query_interface: fake)

    with_temp_cache do |tmp_dir|
      launcher.launch(assignment_id: "abc123", fork_root: "010.01", cache_dir: tmp_dir)

      call = fake.calls.last
      expected_path = File.join(tmp_dir, "sessions", "010.01-last-message.md")
      assert_equal expected_path, call[:options][:last_message_file]
    end
  end

  def test_launch_writes_last_message_file_from_result_text
    response_text = "Agent completed execution."
    fake_with_text = Class.new do
      define_method(:query) do |_provider, _prompt, **_opts|
        {text: response_text, provider: "claude", model: "sonnet"}
      end
    end.new

    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 1800}, "providers" => {}}
    launcher = build_launcher(config: config, query_interface: fake_with_text)

    with_temp_cache do |tmp_dir|
      launcher.launch(assignment_id: "abc123", fork_root: "010.02", cache_dir: tmp_dir)

      last_msg_file = File.join(tmp_dir, "sessions", "010.02-last-message.md")
      assert File.exist?(last_msg_file), "Last message file should be created"
      assert_equal response_text, File.read(last_msg_file)
    end
  end

  def test_launch_does_not_overwrite_existing_nonempty_last_message_file
    native_content = "Written by Codex natively."
    fake_with_text = Class.new do
      define_method(:query) do |_provider, _prompt, **_opts|
        {text: "Response from query.", provider: "codex", model: "gpt-5"}
      end
    end.new

    config = {"execution" => {"provider" => "codex:gpt-5", "timeout" => 900}, "providers" => {}}
    launcher = build_launcher(config: config, query_interface: fake_with_text)

    with_temp_cache do |tmp_dir|
      sessions_dir = File.join(tmp_dir, "sessions")
      FileUtils.mkdir_p(sessions_dir)
      last_msg_file = File.join(sessions_dir, "010-last-message.md")
      File.write(last_msg_file, native_content)

      launcher.launch(assignment_id: "abc123", fork_root: "010", cache_dir: tmp_dir)

      assert_equal native_content, File.read(last_msg_file), "Existing file should not be overwritten"
    end
  end

  def test_launch_writes_session_metadata_file
    fake_with_metadata = Class.new do
      define_method(:query) do |_provider, _prompt, **_opts|
        {text: "Done.", provider: "claude", model: "sonnet", metadata: {session_id: "sess-abc123"}}
      end
    end.new

    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 1800}, "providers" => {}}
    launcher = build_launcher(config: config, query_interface: fake_with_metadata)

    with_temp_cache do |tmp_dir|
      launcher.launch(assignment_id: "abc123", fork_root: "010.02", cache_dir: tmp_dir)

      session_file = File.join(tmp_dir, "sessions", "010.02-session.yml")
      assert File.exist?(session_file), "Session metadata file should be created"
      meta = YAML.safe_load_file(session_file)
      assert_equal "sess-abc123", meta["session_id"]
      assert_equal "claude", meta["provider"]
      assert_equal "sonnet", meta["model"]
      assert meta["completed_at"], "completed_at should be present"
    end
  end

  def test_launch_writes_session_metadata_without_session_id
    fake_no_session = Class.new do
      define_method(:query) do |_provider, _prompt, **_opts|
        {text: "Done.", provider: "codex", model: "gpt-5", metadata: {}}
      end
    end.new

    config = {"execution" => {"provider" => "codex:gpt-5", "timeout" => 900}, "providers" => {}}
    launcher = build_launcher(config: config, query_interface: fake_no_session)

    with_temp_cache do |tmp_dir|
      launcher.launch(assignment_id: "abc123", fork_root: "010", cache_dir: tmp_dir)

      session_file = File.join(tmp_dir, "sessions", "010-session.yml")
      assert File.exist?(session_file), "Session metadata file should still be created"
      meta = YAML.safe_load_file(session_file)
      assert_equal "codex", meta["provider"]
    end
  end

  def test_launch_uses_session_finder_fallback_when_session_id_nil
    fake_no_session = Class.new do
      define_method(:query) do |_provider, _prompt, **_opts|
        {text: "Done.", provider: "pi", model: "pi-model", metadata: {}}
      end
    end.new

    config = {"execution" => {"provider" => "pi:pi-model", "timeout" => 900}, "providers" => {}}
    launcher = build_launcher(config: config, query_interface: fake_no_session)

    launcher.define_singleton_method(:detect_provider_session) do |_provider, _prompt|
      {session_id: "detected-pi-sess-001", session_path: "/fake/path"}
    end

    with_temp_cache do |tmp_dir|
      launcher.launch(assignment_id: "abc123", fork_root: "010", cache_dir: tmp_dir)

      session_file = File.join(tmp_dir, "sessions", "010-session.yml")
      assert File.exist?(session_file), "Session metadata file should be created"
      meta = YAML.safe_load_file(session_file)
      assert_equal "detected-pi-sess-001", meta["session_id"]
      assert_equal "pi", meta["provider"]
    end
  end

  def test_launch_does_not_use_fallback_when_session_id_present
    fake_with_session = Class.new do
      define_method(:query) do |_provider, _prompt, **_opts|
        {text: "Done.", provider: "claude", model: "sonnet", metadata: {session_id: "native-sess"}}
      end
    end.new

    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 1800}, "providers" => {}}
    launcher = build_launcher(config: config, query_interface: fake_with_session)

    fallback_called = false
    launcher.define_singleton_method(:detect_provider_session) do |_provider, _prompt|
      fallback_called = true
      {session_id: "should-not-use", session_path: "/fake"}
    end

    with_temp_cache do |tmp_dir|
      launcher.launch(assignment_id: "abc123", fork_root: "010", cache_dir: tmp_dir)

      session_file = File.join(tmp_dir, "sessions", "010-session.yml")
      meta = YAML.safe_load_file(session_file)
      assert_equal "native-sess", meta["session_id"]
      refute fallback_called, "Fallback should not be called when native session_id exists"
    end
  end

  def test_launch_skips_session_metadata_when_no_cache_dir
    fake = FakeQueryInterface.new
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 1800}, "providers" => {}}
    launcher = build_launcher(config: config, query_interface: fake)

    launcher.launch(assignment_id: "abc123", fork_root: "010")

    assert true
  end

  def test_launch_omits_last_message_file_when_no_cache_dir
    fake = FakeQueryInterface.new
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 1800}, "providers" => {}}
    launcher = build_launcher(config: config, query_interface: fake)

    launcher.launch(assignment_id: "abc123", fork_root: "010")

    call = fake.calls.last
    assert_nil call[:options][:last_message_file]
  end

  def test_launch_mode_tmux_requires_tmux_context
    fake = FakeQueryInterface.new
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 1800}, "providers" => {}}
    launcher = build_launcher(config: config, query_interface: fake, tmux_enabled: false)

    error = assert_raises(Ace::Support::Cli::Error) do
      launcher.launch(assignment_id: "abc123", fork_root: "010", launch_mode: "tmux")
    end

    assert_includes error.message, "requires an active tmux session"
  end

  def test_launch_mode_auto_uses_tmux_when_context_available
    fake = FakeQueryInterface.new
    interactive = FakeInteractiveBuilder.new
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 30}, "providers" => {}}
    launcher = build_launcher(
      config: config,
      query_interface: fake,
      tmux_enabled: true,
      session: "dev",
      window: "work",
      interactive_builder: interactive
    )

    with_temp_cache do |tmp_dir|
      steps_dir = File.join(tmp_dir, "steps")
      FileUtils.mkdir_p(steps_dir)
      File.write(File.join(steps_dir, "010-demo-root.st.md"), <<~STEP)
        ---
        name: demo-root
        status: done
        context: fork
        ---
        done
      STEP
      launcher.launch(assignment_id: "abc123", fork_root: "010", cache_dir: tmp_dir, launch_mode: "auto")

      session_file = File.join(tmp_dir, "sessions", "010-session.yml")
      meta = YAML.safe_load_file(session_file)
      assert_equal "tmux", meta["launch_mode"]
      assert_equal "dev", meta["tmux_session"]
      assert_equal "work-fs", meta["tmux_window"]
      assert_equal "%42", meta["tmux_pane_id"]

      wrapper = File.join(tmp_dir, "sessions", "010-tmux-launch.sh")
      assert File.exist?(wrapper), "tmux launch wrapper should be written"
      wrapper_contents = File.read(wrapper)
      assert_includes wrapper_contents, "export PROJECT_ROOT_PATH=#{Dir.pwd}"
      assert_includes wrapper_contents, "printf '%s\n' \\$as-assign-drive\\ abc123@010"
      assert_equal [], fake.calls, "tmux mode should run through the pane wrapper, not direct query"
      assert_equal "claude:sonnet", interactive.calls.last[:provider_model]
      assert_equal "/as-assign-drive abc123@010", interactive.calls.last[:prompt]
    end
  end
end
