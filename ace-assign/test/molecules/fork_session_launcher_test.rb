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
      "execution" => { "provider" => "codex:gpt-5", "timeout" => 900 },
      "providers" => { "cli_args" => { "codex" => ["full-auto"] } }
    }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake)

    launcher.launch(assignment_id: "abc123", fork_root: "010.01")

    call = fake.calls.last
    assert_equal "codex:gpt-5", call[:provider_model]
    assert_equal "/ace-assign-drive abc123@010.01", call[:prompt]
    assert_equal "full-auto", call[:options][:cli_args]
    assert_equal 900, call[:options][:timeout]
    assert_equal false, call[:options][:fallback]
  end

  def test_launch_merges_required_and_user_cli_args
    fake = FakeQueryInterface.new
    config = {
      "execution" => { "provider" => "claude:sonnet", "timeout" => 1800 },
      "providers" => { "cli_args" => { "claude" => ["dangerously-skip-permissions"] } }
    }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake)

    launcher.launch(
      assignment_id: "abc123",
      fork_root: "010",
      cli_args: "--model-settings x"
    )

    call = fake.calls.last
    assert_equal "dangerously-skip-permissions --model-settings x", call[:options][:cli_args]
  end

  def test_launch_merges_array_and_string_cli_args
    fake = FakeQueryInterface.new
    config = {
      "execution" => { "provider" => "codex:gpt-5", "timeout" => 900 },
      "providers" => { "cli_args" => { "codex" => ["--sandbox danger-full-access", "--ask-for-approval never"] } }
    }
    launcher = Ace::Assign::Molecules::ForkSessionLauncher.new(config: config, query_interface: fake)

    launcher.launch(
      assignment_id: "abc123",
      fork_root: "010",
      cli_args: "--model-settings x"
    )

    call = fake.calls.last
    assert_equal(
      "--sandbox danger-full-access --ask-for-approval never --model-settings x",
      call[:options][:cli_args]
    )
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
      refute meta.key?("session_id"), "session_id should be absent when not provided"
      assert_equal "codex", meta["provider"]
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
