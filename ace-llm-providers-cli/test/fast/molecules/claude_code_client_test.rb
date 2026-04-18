# frozen_string_literal: true

require_relative "../../test_helper"

describe "ClaudeCodeClient" do
  before do
    @client = Ace::LLM::Providers::CLI::ClaudeCodeClient.new
  end

  def client_with_probe_guard
    guarded_client = Ace::LLM::Providers::CLI::ClaudeCodeClient.new
    guarded_client.define_singleton_method(:supports_max_tokens_flag?) do
      flunk "unexpected capability probe"
    end
    guarded_client
  end

  it "initializes with default model" do
    model = @client.instance_variable_get(:@model)
    assert_equal "claude-sonnet-4-0", model
  end

  it "needs_credentials? returns false" do
    refute @client.needs_credentials?
  end

  it "provider_name is 'claude'" do
    assert_equal "claude", Ace::LLM::Providers::CLI::ClaudeCodeClient.provider_name
  end

  describe "build_claude_command" do
    it "does not pass unsupported temperature flag" do
      cmd = client_with_probe_guard.send(:build_claude_command, temperature: 0.2)
      refute_includes cmd, "--temperature"
    end

    it "includes max tokens when the installed claude CLI supports the flag" do
      @client.stub(:supports_max_tokens_flag?, true) do
        cmd = @client.send(:build_claude_command, max_tokens: 123)
        max_tokens_idx = cmd.index("--max-tokens")

        refute_nil max_tokens_idx
        assert_equal "123", cmd[max_tokens_idx + 1]
      end
    end

    it "omits max tokens when the installed claude CLI does not support the flag" do
      @client.stub(:supports_max_tokens_flag?, false) do
        cmd = @client.send(:build_claude_command, max_tokens: 123)

        refute_includes cmd, "--max-tokens"
      end
    end

    it "preserves explicit empty tool list values from cli_args arrays" do
      cmd = client_with_probe_guard.send(:build_claude_command, cli_args: ["--tools", ""])
      tools_idx = cmd.index("--tools")

      refute_nil tools_idx
      assert_equal "", cmd[tools_idx + 1]
    end

    it "preserves explicit tool allowlists from cli_args arrays" do
      cmd = client_with_probe_guard.send(:build_claude_command, cli_args: ["--tools", "Bash,Read"])
      tools_idx = cmd.index("--tools")

      refute_nil tools_idx
      assert_equal "Bash,Read", cmd[tools_idx + 1]
    end

    it "filters forwarded max tokens cli args when the installed claude CLI does not support the flag" do
      @client.stub(:supports_max_tokens_flag?, false) do
        cmd = @client.send(:build_claude_command, cli_args: "--max-tokens 123 --tools Bash")

        refute_includes cmd, "--max-tokens"
        assert_includes cmd, "--tools"
        assert_includes cmd, "Bash"
      end
    end

    it "preserves forwarded max tokens cli args when the installed claude CLI supports the flag" do
      @client.stub(:supports_max_tokens_flag?, true) do
        cmd = @client.send(:build_claude_command, cli_args: "--max-tokens 123")
        max_tokens_idx = cmd.rindex("--max-tokens")

        refute_nil max_tokens_idx
        assert_equal "123", cmd[max_tokens_idx + 1]
      end
    end

    it "does not probe claude help when max tokens handling is unused" do
      cmd = client_with_probe_guard.send(:build_claude_command, cli_args: "--tools Bash")

      assert_includes cmd, "--tools"
      assert_includes cmd, "Bash"
    end
  end

  describe "build_interactive_invocation" do
    it "builds interactive claude command without print mode" do
      @client.stub(:validate_claude_availability!, nil) do
        invocation = @client.build_interactive_invocation([{role: "user", content: "/as-assign-drive abc123@010"}])
        assert_equal "claude", invocation[:command][0]
        refute_includes invocation[:command], "-p"
        refute_includes invocation[:command], "--print"
        assert_includes invocation[:command].join(" "), "/as-assign-drive abc123@010"
      end
    end
  end

  describe "supports_max_tokens_flag?" do
    def status(success)
      Object.new.tap do |obj|
        obj.define_singleton_method(:success?) { success }
      end
    end

    it "detects support from claude help output" do
      capture = proc do |*cmd|
        case cmd
        when [{"CLAUDECODE" => nil}, "claude", "-p", "--help"]
          ["usage: claude -p [options]\n  --max-tokens <n>", "", status(true)]
        else
          flunk "unexpected command: #{cmd.inspect}"
        end
      end

      Open3.stub(:capture3, capture) do
        assert @client.send(:supports_max_tokens_flag?)
      end
    end

    it "falls back to top-level help when prompt help lacks the flag" do
      capture = proc do |*cmd|
        case cmd
        when [{"CLAUDECODE" => nil}, "claude", "-p", "--help"]
          ["usage: claude -p [options]", "", status(true)]
        when [{"CLAUDECODE" => nil}, "claude", "--help"]
          ["global options include --max-tokens", "", status(true)]
        else
          flunk "unexpected command: #{cmd.inspect}"
        end
      end

      Open3.stub(:capture3, capture) do
        assert @client.send(:supports_max_tokens_flag?)
      end
    end

    it "returns false when help output does not advertise the flag" do
      capture = proc do |*cmd|
        case cmd
        when [{"CLAUDECODE" => nil}, "claude", "-p", "--help"], [{"CLAUDECODE" => nil}, "claude", "--help"]
          ["usage: claude", "", status(true)]
        else
          flunk "unexpected command: #{cmd.inspect}"
        end
      end

      Open3.stub(:capture3, capture) do
        refute @client.send(:supports_max_tokens_flag?)
      end
    end

    it "clears CLAUDECODE during help probes" do
      captured_env = nil
      capture = proc do |env, *cmd|
        captured_env = env
        ["usage: claude", "", status(true)]
      end

      Open3.stub(:capture3, capture) do
        @client.send(:command_help_supports_flag?, "--max-tokens")
      end

      assert_equal({"CLAUDECODE" => nil}, captured_env)
    end
  end

  describe "execute_claude_command" do
    def run_with_captured_env(&block)
      captured_env = nil
      captured_chdir = nil
      fake_capture = lambda { |*_args, **kwargs|
        captured_env = kwargs[:env]
        captured_chdir = kwargs[:chdir]
        mock_status = Object.new
        mock_status.define_singleton_method(:success?) { true }
        mock_status.define_singleton_method(:exitstatus) { 0 }
        ['{"result":"ok"}', "", mock_status]
      }

      Ace::LLM::Providers::CLI::Molecules::SafeCapture.stub(:call, fake_capture) do
        block.call
      end
      [captured_env, captured_chdir]
    end

    it "passes CLAUDECODE nil by default" do
      env, chdir = run_with_captured_env do
        @client.send(:execute_claude_command, ["claude", "-p"], "hello")
      end

      assert_includes env.keys, "CLAUDECODE"
      assert_nil env["CLAUDECODE"]
      assert_nil chdir
    end

    it "merges subprocess_env into env" do
      env, _chdir = run_with_captured_env do
        @client.send(:execute_claude_command, ["claude", "-p"], "hello",
          subprocess_env: {"ACE_TMUX_SESSION" => "TS-TEST-001-e2e", "FOO" => "bar"})
      end

      assert_nil env["CLAUDECODE"]
      assert_equal "TS-TEST-001-e2e", env["ACE_TMUX_SESSION"]
      assert_equal "bar", env["FOO"]
    end

    it "does not modify env when subprocess_env is nil" do
      env, _chdir = run_with_captured_env do
        @client.send(:execute_claude_command, ["claude", "-p"], "hello", subprocess_env: nil)
      end

      assert_equal({"CLAUDECODE" => nil}, env)
    end

    it "passes working_dir as subprocess chdir" do
      _env, chdir = run_with_captured_env do
        @client.send(:execute_claude_command, ["claude", "-p"], "hello", working_dir: "/tmp/e2e-sandbox")
      end

      assert_equal "/tmp/e2e-sandbox", chdir
    end
  end

  describe "generate passes subprocess_env through" do
    it "forwards subprocess_env from options to execute_claude_command" do
      captured_subprocess_env = :not_called
      captured_command_prefix = :not_called
      messages = [{role: "user", content: "hello"}]

      @client.stub(:validate_claude_availability!, nil) do
        @client.define_singleton_method(:execute_claude_command) do |cmd, prompt, subprocess_env: nil, working_dir: nil,
          subprocess_command_prefix: nil|
          captured_subprocess_env = subprocess_env
          captured_command_prefix = subprocess_command_prefix
          mock_status = Object.new
          mock_status.define_singleton_method(:success?) { true }
          mock_status.define_singleton_method(:exitstatus) { 0 }
          ['{"result":"ok"}', "", mock_status]
        end

        @client.generate(
          messages,
          subprocess_env: {"ACE_TMUX_SESSION" => "test-session"},
          subprocess_command_prefix: ["bwrap", "--"]
        )
      end

      assert_equal({"ACE_TMUX_SESSION" => "test-session"}, captured_subprocess_env)
      assert_equal ["bwrap", "--"], captured_command_prefix
    end
  end

  describe "parse_claude_response" do
    def success_status
      status = Object.new
      status.define_singleton_method(:success?) { true }
      status.define_singleton_method(:exitstatus) { 0 }
      status
    end

    it "includes structured details when response text is empty" do
      stdout = {
        "type" => "result",
        "subtype" => "success",
        "stop_reason" => "end_turn",
        "session_id" => "sess-123",
        "duration_ms" => 1234
      }.to_json

      error = assert_raises(Ace::LLM::ProviderError) do
        @client.send(:parse_claude_response, stdout, "", success_status, "prompt", {})
      end

      assert_includes error.message, "empty response"
      assert_includes error.message, "type=result"
      assert_includes error.message, "session_id=sess-123"
    end

    it "extracts text from nested Claude result content" do
      stdout = {
        "result" => {
          "content" => [
            {
              "type" => "text",
              "text" => "Nested response content"
            }
          ]
        }
      }.to_json

      result = @client.send(
        :parse_claude_response,
        stdout,
        "",
        success_status,
        "prompt",
        {}
      )

      assert_equal "Nested response content", result[:text]
    end

    it "surfaces provider error payload details when response is marked as error" do
      stdout = {
        "type" => "result",
        "subtype" => "success",
        "is_error" => true,
        "result" => "Model overloaded",
        "stop_reason" => "stop_sequence",
        "session_id" => "sess-456"
      }.to_json

      error = assert_raises(Ace::LLM::ProviderError) do
        @client.send(:parse_claude_response, stdout, "", success_status, "prompt", {})
      end

      assert_includes error.message, "error payload"
      assert_includes error.message, "Model overloaded"
      assert_includes error.message, "is_error=true"
    end
  end
end
