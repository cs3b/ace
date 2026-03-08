# frozen_string_literal: true

require_relative "../test_helper"

class ForkSessionLauncherTest < AceAssignTestCase
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
      { text: "ok", provider: provider_model.split(":").first, model: provider_model.split(":")[1] }
    end
  end

  def test_launch_uses_config_defaults_and_passes_scoped_assignment_argument
    fake = FakeQueryInterface.new
    config = {
      "execution" => { "provider" => "codex:gpt-5@yolo", "timeout" => 900 },
      "providers" => {}
    }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake)

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
      "execution" => { "provider" => "claude:sonnet@yolo", "timeout" => 1800 },
      "providers" => {}
    }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake)

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
      "execution" => { "provider" => "codex:gpt-5@yolo", "timeout" => 900 },
      "providers" => {}
    }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake)

    launcher.launch(assignment_id: "abc123", fork_root: "010")

    call = fake.calls.last
    assert_nil call[:options][:cli_args]
  end

  def test_launch_passes_last_message_file_when_cache_dir_provided
    fake = FakeQueryInterface.new
    config = {
      "execution" => { "provider" => "claude:sonnet", "timeout" => 1800 },
      "providers" => {}
    }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake)

    Dir.mktmpdir do |tmp_dir|
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
        { text: response_text, provider: "claude", model: "sonnet" }
      end
    end.new

    config = { "execution" => { "provider" => "claude:sonnet", "timeout" => 1800 }, "providers" => {} }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake_with_text)

    Dir.mktmpdir do |tmp_dir|
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
        { text: "Response from query.", provider: "codex", model: "gpt-5" }
      end
    end.new

    config = { "execution" => { "provider" => "codex:gpt-5", "timeout" => 900 }, "providers" => {} }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake_with_text)

    Dir.mktmpdir do |tmp_dir|
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
        { text: "Done.", provider: "claude", model: "sonnet", metadata: { session_id: "sess-abc123" } }
      end
    end.new

    config = { "execution" => { "provider" => "claude:sonnet", "timeout" => 1800 }, "providers" => {} }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake_with_metadata)

    Dir.mktmpdir do |tmp_dir|
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
        { text: "Done.", provider: "codex", model: "gpt-5", metadata: {} }
      end
    end.new

    config = { "execution" => { "provider" => "codex:gpt-5", "timeout" => 900 }, "providers" => {} }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake_no_session)

    Dir.mktmpdir do |tmp_dir|
      launcher.launch(assignment_id: "abc123", fork_root: "010", cache_dir: tmp_dir)

      session_file = File.join(tmp_dir, "sessions", "010-session.yml")
      assert File.exist?(session_file), "Session metadata file should still be created"
      meta = YAML.safe_load_file(session_file)
      # session_id may be nil (if SessionFinder also returns nil) or detected by fallback
      assert_equal "codex", meta["provider"]
    end
  end

  def test_launch_uses_session_finder_fallback_when_session_id_nil
    fake_no_session = Class.new do
      define_method(:query) do |_provider, _prompt, **_opts|
        { text: "Done.", provider: "pi", model: "pi-model", metadata: {} }
      end
    end.new

    config = { "execution" => { "provider" => "pi:pi-model", "timeout" => 900 }, "providers" => {} }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake_no_session)

    # Stub detect_provider_session to return a detected session
    launcher.define_singleton_method(:detect_provider_session) do |_provider, _prompt|
      { session_id: "detected-pi-sess-001", session_path: "/fake/path" }
    end

    Dir.mktmpdir do |tmp_dir|
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
        { text: "Done.", provider: "claude", model: "sonnet", metadata: { session_id: "native-sess" } }
      end
    end.new

    config = { "execution" => { "provider" => "claude:sonnet", "timeout" => 1800 }, "providers" => {} }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake_with_session)

    # Stub detect_provider_session — should NOT be called
    fallback_called = false
    launcher.define_singleton_method(:detect_provider_session) do |_provider, _prompt|
      fallback_called = true
      { session_id: "should-not-use", session_path: "/fake" }
    end

    Dir.mktmpdir do |tmp_dir|
      launcher.launch(assignment_id: "abc123", fork_root: "010", cache_dir: tmp_dir)

      session_file = File.join(tmp_dir, "sessions", "010-session.yml")
      meta = YAML.safe_load_file(session_file)
      assert_equal "native-sess", meta["session_id"]
      refute fallback_called, "Fallback should not be called when native session_id exists"
    end
  end

  def test_launch_skips_session_metadata_when_no_cache_dir
    fake = FakeQueryInterface.new
    config = { "execution" => { "provider" => "claude:sonnet", "timeout" => 1800 }, "providers" => {} }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake)

    launcher.launch(assignment_id: "abc123", fork_root: "010")

    # No cache_dir means no sessions dir, so no file should be written — just verify no error
    assert true
  end

  def test_launch_omits_last_message_file_when_no_cache_dir
    fake = FakeQueryInterface.new
    config = { "execution" => { "provider" => "claude:sonnet", "timeout" => 1800 }, "providers" => {} }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake)

    launcher.launch(assignment_id: "abc123", fork_root: "010")

    call = fake.calls.last
    assert_nil call[:options][:last_message_file]
  end
end
