# frozen_string_literal: true

require_relative "../../test_helper"

class ForkSessionLauncherTest < AceAssignTestCase
  def setup
    super
    @lifecycle_root = Dir.mktmpdir("controlled-fork-exclusion")
    @exclusion = Ace::Assign::Molecules::LifecycleExclusion.new(root: @lifecycle_root)
  end

  def teardown
    FileUtils.rm_rf(@lifecycle_root)
    super
  end

  class FakeRuntimeRunner
    attr_reader :last_ensure, :last_prepare, :last_invocation, :last_metadata

    def initialize(runtime: "tmux", detected: nil, context: nil, pane: "%9")
      @runtime_name = runtime
      @detected = detected
      @context = context || {in_runtime: true, session: "dev", window: "work", pane: pane}
    end

    def runtime_name
      @runtime_name
    end

    def detect_runtime
      @detected
    end

    def context
      @context
    end

    def current_pane
      @context[:pane] if @context[:in_runtime]
    end

    def fork_window_name(base_window)
      "#{base_window}-fs"
    end

    def ensure_window(name:, root:)
      @last_ensure = {name: name, root: root}
      "@42"
    end

    def prepare_pane(window:)
      @last_prepare = {window: window}
      "%42"
    end

    def run_invocation_in_pane(pane_target:, command:, env: nil, working_dir: nil, visible_handoff: nil)
      @last_invocation = {
        pane_target: pane_target,
        command: command,
        env: env,
        working_dir: working_dir,
        visible_handoff: visible_handoff
      }
    end

    def merge_runtime_metadata(session_meta_file:, session:, window:, pane:, window_id: nil, callback_pane: nil)
      @last_metadata = {
        session_meta_file: session_meta_file, session: session, window: window,
        pane: pane, window_id: window_id, callback_pane: callback_pane
      }
      meta = File.exist?(session_meta_file) ? YAML.safe_load_file(session_meta_file) : {}
      meta["launch_mode"] = runtime_name
      meta["runtime"] = runtime_name
      meta["session"] = session
      meta["window"] = window
      meta["window_id"] = window_id if window_id
      meta["pane"] = pane
      meta["callback_pane"] = callback_pane if callback_pane
      File.write(session_meta_file, meta.to_yaml)
    end
  end

  class FakeInteractiveBuilder
    attr_reader :calls

    def initialize
      @calls = []
    end

    def build(provider_model:, prompt:, cli_args: nil, **options)
      @calls << {provider_model: provider_model, prompt: prompt, cli_args: cli_args, options: options}
      {
        command: ["ace-llm", provider_model, prompt, "--interactive"],
        env: {"FROM_BUILDER" => "1"},
        working_dir: options[:working_dir] || Dir.pwd,
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

  def with_env(vars)
    original = {}
    vars.each_key do |key|
      original[key] = ENV[key]
    end
    vars.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
    yield
  ensure
    original.each { |key, value| value.nil? ? ENV.delete(key) : ENV[key] = value }
  end

  def build_launcher(config:, query_interface:, runner: nil, interactive_builder: nil, lifecycle_exclusion: nil)
    Ace::Assign::Molecules::ForkSessionLauncher.new(
      config: config,
      query_interface: query_interface,
      runner: runner || FakeRuntimeRunner.new,
      interactive_builder: interactive_builder,
      lifecycle_exclusion: lifecycle_exclusion || @exclusion
    )
  end

  def with_fork_step(tmp_dir, fork_root = "010")
    steps_dir = File.join(tmp_dir, "steps")
    FileUtils.mkdir_p(steps_dir)
    File.write(File.join(steps_dir, "#{fork_root}-demo-root.st.md"), <<~STEP)
      ---
      name: demo-root
      status: done
      context: fork
      ---
      done
    STEP
  end

  def test_launch_refuses_after_prune_recorded_removal
    fake = FakeQueryInterface.new
    config = {"execution" => {"provider" => "codex:gpt-5@yolo"}, "providers" => {}}
    exclusion = Ace::Assign::Molecules::LifecycleExclusion.new(root: File.join(Dir.mktmpdir("fork-excl"), ".exclusion"))
    exclusion.record_removed!(exclusion.assignment_key("abc123"))

    launcher = build_launcher(config: config, query_interface: fake, lifecycle_exclusion: exclusion)

    error = assert_raises(Ace::Assign::AttemptErrors::Conflict) do
      launcher.launch(assignment_id: "abc123", fork_root: "010.01")
    end
    assert_includes error.message, "was pruned"
    assert_empty fake.calls
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
    assert_equal(
      {
        "ACE_ASSIGN_DEFAULT_TARGET" => "abc123@010.01",
        "ACE_ASSIGN_CURRENT_ASSIGNMENT_ID" => "abc123",
        "ACE_ASSIGN_CURRENT_FORK_ROOT" => "010.01"
      },
      call[:options][:subprocess_env]
    )
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

  def test_launch_mode_tmux_requires_live_runtime
    fake = FakeQueryInterface.new
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 1800}, "providers" => {}}
    runner = FakeRuntimeRunner.new(context: {in_runtime: false, session: nil, window: nil, pane: nil})
    launcher = build_launcher(config: config, query_interface: fake, runner: runner)

    error = assert_raises(Ace::Support::Cli::Error) do
      launcher.launch(assignment_id: "abc123", fork_root: "010", launch_mode: "tmux")
    end

    assert_includes error.message, "requires a live tmux runtime"
  end

  def test_launch_mode_herdr_requires_live_runtime
    fake = FakeQueryInterface.new
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 1800}, "providers" => {}}
    runner = FakeRuntimeRunner.new(
      runtime: "herdr",
      context: {in_runtime: false, session: nil, window: nil, pane: nil}
    )
    launcher = build_launcher(config: config, query_interface: fake, runner: runner)

    error = assert_raises(Ace::Support::Cli::Error) do
      launcher.launch(assignment_id: "abc123", fork_root: "010", launch_mode: "herdr")
    end

    assert_includes error.message, "requires a live herdr runtime"
  end

  def test_launch_mode_unknown_fails_closed_with_valid_list
    fake = FakeQueryInterface.new
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 1800}, "providers" => {}}
    launcher = build_launcher(config: config, query_interface: fake)

    error = assert_raises(Ace::Support::Cli::Error) do
      launcher.launch(assignment_id: "abc123", fork_root: "010", launch_mode: "pty")
    end

    assert_includes error.message, "Invalid launch mode 'pty'"
    assert_includes error.message, "auto, headless, tmux, herdr"
    assert_empty fake.calls
  end

  def test_launch_uses_config_launch_mode_when_explicit_mode_missing
    fake = FakeQueryInterface.new
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 1800, "launch_mode" => "headless"}, "providers" => {}}
    launcher = build_launcher(config: config, query_interface: fake)

    launcher.launch(assignment_id: "abc123", fork_root: "010")

    assert_equal 1, fake.calls.size
  end

  def test_launch_mode_auto_uses_tmux_when_detected
    fake = FakeQueryInterface.new
    interactive = FakeInteractiveBuilder.new
    runner = FakeRuntimeRunner.new(detected: "tmux", runtime: "tmux", context: {in_runtime: true, session: "dev", window: "work", pane: "%9"})
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 30}, "providers" => {}}
    launcher = build_launcher(
      config: config,
      query_interface: fake,
      runner: runner,
      interactive_builder: interactive
    )

    with_temp_cache do |tmp_dir|
      with_fork_step(tmp_dir)
      launcher.launch(assignment_id: "abc123", fork_root: "010", cache_dir: tmp_dir, launch_mode: "auto")

      session_file = File.join(tmp_dir, "sessions", "010-session.yml")
      meta = YAML.safe_load_file(session_file)
      assert_equal "tmux", meta["launch_mode"]
      assert_equal "tmux", meta["runtime"]
      assert_equal "dev", meta["session"]
      assert_equal "work-fs", meta["window"]
      assert_equal "@42", meta["window_id"]
      assert_equal "%42", meta["pane"]

      wrapper = File.join(tmp_dir, "sessions", "010-tmux-launch.sh")
      refute File.exist?(wrapper), "tmux launch wrapper should not be written"
      assert_equal [], fake.calls, "tmux mode should launch directly in the pane, not use direct query"
      assert_equal "claude:sonnet", interactive.calls.last[:provider_model]
      assert_equal "/as-assign-drive abc123@010", interactive.calls.last[:prompt]
      assert_equal(
        {
          "PROJECT_ROOT_PATH" => Dir.pwd,
          "ACE_RUNTIME" => "tmux",
          "ACE_ASSIGN_LAUNCH_MODE" => "tmux",
          "ACE_ASSIGN_FORK_WINDOW" => "work-fs",
          "ACE_ASSIGN_DEFAULT_TARGET" => "abc123@010",
          "ACE_ASSIGN_CURRENT_ASSIGNMENT_ID" => "abc123",
          "ACE_ASSIGN_CURRENT_FORK_ROOT" => "010"
        },
        interactive.calls.last[:options][:subprocess_env]
      )
      assert_equal "%42", runner.last_invocation[:pane_target]
      assert_equal ["ace-llm", "claude:sonnet", "/as-assign-drive abc123@010", "--interactive"],
        runner.last_invocation[:command]
      assert_equal({"FROM_BUILDER" => "1"}, runner.last_invocation[:env])
      assert_equal Dir.pwd, runner.last_invocation[:working_dir]
      assert_equal "$as-assign-drive abc123@010", runner.last_invocation[:visible_handoff]
    end
  end

  def test_launch_mode_auto_uses_herdr_when_detected
    fake = FakeQueryInterface.new
    interactive = FakeInteractiveBuilder.new
    runner = FakeRuntimeRunner.new(
      detected: "herdr",
      runtime: "herdr",
      context: {in_runtime: true, session: "ws-1", window: "tab-1", pane: "p9"}
    )
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 30}, "providers" => {}}
    launcher = build_launcher(
      config: config,
      query_interface: fake,
      runner: runner,
      interactive_builder: interactive
    )

    with_temp_cache do |tmp_dir|
      with_fork_step(tmp_dir)
      launcher.launch(assignment_id: "abc123", fork_root: "010", cache_dir: tmp_dir, launch_mode: "auto")

      session_file = File.join(tmp_dir, "sessions", "010-session.yml")
      meta = YAML.safe_load_file(session_file)
      assert_equal "herdr", meta["launch_mode"]
      assert_equal "herdr", meta["runtime"]
      assert_equal "ws-1", meta["session"]
      assert_equal "tab-1-fs", meta["window"]
      assert_equal "%42", meta["pane"]
      assert_equal(
        "herdr",
        interactive.calls.last[:options][:subprocess_env]["ACE_RUNTIME"]
      )
      assert_equal [], fake.calls, "herdr mode should launch directly in the pane, not use direct query"
      assert_equal "tab-1-fs", runner.last_ensure[:name]
    end
  end

  def test_launch_mode_auto_selects_headless_without_runtime
    fake = FakeQueryInterface.new
    interactive = FakeInteractiveBuilder.new
    runner = FakeRuntimeRunner.new(detected: nil)
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 30}, "providers" => {}}
    launcher = build_launcher(
      config: config,
      query_interface: fake,
      runner: runner,
      interactive_builder: interactive
    )

    with_temp_cache do |tmp_dir|
      with_fork_step(tmp_dir)
      launcher.launch(assignment_id: "abc123", fork_root: "010", cache_dir: tmp_dir, launch_mode: "auto")

      assert_equal 1, fake.calls.size, "headless auto mode should use direct query"
      assert_empty interactive.calls
      assert_nil runner.last_ensure, "headless auto mode must not open terminal surfaces"
    end
  end

  def test_launch_mode_tmux_uses_origin_window_name_for_fork_target
    fake = FakeQueryInterface.new
    interactive = FakeInteractiveBuilder.new
    runner = FakeRuntimeRunner.new(context: {in_runtime: true, session: "dev", window: "ace-t-ks9", pane: "%9"})
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 30}, "providers" => {}}
    launcher = build_launcher(
      config: config,
      query_interface: fake,
      runner: runner,
      interactive_builder: interactive
    )

    with_temp_cache do |tmp_dir|
      with_fork_step(tmp_dir)
      launcher.launch(assignment_id: "abc123", fork_root: "010", cache_dir: tmp_dir, launch_mode: "tmux")

      assert_equal "ace-t-ks9-fs", runner.last_ensure[:name]
      assert_equal "ace-t-ks9-fs", runner.last_prepare[:window]
    end
  end

  def test_callback_pane_uses_runner_current_pane
    fake = FakeQueryInterface.new
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 30}, "providers" => {}}
    runner = FakeRuntimeRunner.new(pane: "%11")
    launcher = build_launcher(config: config, query_interface: fake, runner: runner)

    assert_equal "%11", launcher.callback_pane(runtime: "tmux")
  end

  def test_launch_callback_mode_skips_subtree_wait_and_exports_callback_pane
    fake = FakeQueryInterface.new
    interactive = FakeInteractiveBuilder.new
    runner = FakeRuntimeRunner.new(context: {in_runtime: true, session: "dev", window: "work", pane: "%9"})
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 30}, "providers" => {}}
    launcher = build_launcher(
      config: config,
      query_interface: fake,
      runner: runner,
      interactive_builder: interactive
    )

    with_temp_cache do |tmp_dir|
      with_fork_step(tmp_dir)
      result = launcher.launch(
        assignment_id: "abc123",
        fork_root: "010",
        cache_dir: tmp_dir,
        launch_mode: "tmux",
        callback_pane: "%9"
      )

      assert_equal true, result[:callback_mode]
      assert_equal "tmux", result[:runtime]
      assert_equal "%9", result[:callback_pane]

      session_file = File.join(tmp_dir, "sessions", "010-session.yml")
      meta = YAML.safe_load_file(session_file)
      assert_equal "%9", meta["callback_pane"]
      assert_equal "%9", interactive.calls.last[:options][:subprocess_env]["ACE_ASSIGN_CALLBACK_PANE"]
    end
  end

  def test_launch_rejects_same_scoped_refork_before_query
    fake = FakeQueryInterface.new
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 1800}, "providers" => {}}
    launcher = build_launcher(config: config, query_interface: fake)

    with_env(
      "ACE_ASSIGN_CURRENT_ASSIGNMENT_ID" => "abc123",
      "ACE_ASSIGN_CURRENT_FORK_ROOT" => "010"
    ) do
      error = assert_raises(Ace::Support::Cli::Error) do
        launcher.launch(assignment_id: "abc123", fork_root: "010")
      end

      assert_includes error.message, "already running inside that scoped subtree"
    end

    assert_equal [], fake.calls
  end

  def test_launch_allows_same_root_for_different_assignment
    fake = FakeQueryInterface.new
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 1800}, "providers" => {}}
    launcher = build_launcher(config: config, query_interface: fake)

    with_env(
      "ACE_ASSIGN_CURRENT_ASSIGNMENT_ID" => "other-assignment",
      "ACE_ASSIGN_CURRENT_FORK_ROOT" => "010"
    ) do
      launcher.launch(assignment_id: "abc123", fork_root: "010")
    end

    call = fake.calls.last
    assert_equal "/as-assign-drive abc123@010", call[:prompt]
    assert_equal(
      {
        "ACE_ASSIGN_DEFAULT_TARGET" => "abc123@010",
        "ACE_ASSIGN_CURRENT_ASSIGNMENT_ID" => "abc123",
        "ACE_ASSIGN_CURRENT_FORK_ROOT" => "010"
      },
      call[:options][:subprocess_env]
    )
  end

  def test_launch_mode_tmux_rejects_same_scoped_refork_before_pane_creation
    fake = FakeQueryInterface.new
    interactive = FakeInteractiveBuilder.new
    runner = FakeRuntimeRunner.new
    config = {"execution" => {"provider" => "claude:sonnet", "timeout" => 30}, "providers" => {}}
    launcher = build_launcher(
      config: config,
      query_interface: fake,
      runner: runner,
      interactive_builder: interactive
    )

    with_temp_cache do |tmp_dir|
      with_env(
        "ACE_ASSIGN_CURRENT_ASSIGNMENT_ID" => "abc123",
        "ACE_ASSIGN_CURRENT_FORK_ROOT" => "010"
      ) do
        error = assert_raises(Ace::Support::Cli::Error) do
          launcher.launch(assignment_id: "abc123", fork_root: "010", cache_dir: tmp_dir, launch_mode: "tmux")
        end

        assert_includes error.message, "already running inside that scoped subtree"
      end
    end

    assert_nil runner.last_ensure
    assert_nil runner.last_prepare
    assert_equal [], interactive.calls
    assert_equal [], fake.calls
  end
end
