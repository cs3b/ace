# frozen_string_literal: true

require_relative "../test_helper"

describe "ClaudeCodeClient" do
  before do
    @client = Ace::LLM::Providers::CLI::ClaudeCodeClient.new
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
      cmd = @client.send(:build_claude_command, temperature: 0.2)
      refute_includes cmd, "--temperature"
    end

    it "preserves explicit empty tool list values from cli_args arrays" do
      cmd = @client.send(:build_claude_command, cli_args: ["--tools", ""])
      tools_idx = cmd.index("--tools")

      refute_nil tools_idx
      assert_equal "", cmd[tools_idx + 1]
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
      messages = [{ role: "user", content: "hello" }]

      @client.stub(:validate_claude_availability!, nil) do
        @client.define_singleton_method(:execute_claude_command) do |cmd, prompt, subprocess_env: nil, working_dir: nil|
          captured_subprocess_env = subprocess_env
          mock_status = Object.new
          mock_status.define_singleton_method(:success?) { true }
          mock_status.define_singleton_method(:exitstatus) { 0 }
          ['{"result":"ok"}', "", mock_status]
        end

        @client.generate(messages, subprocess_env: {"ACE_TMUX_SESSION" => "test-session"})
      end

      assert_equal({"ACE_TMUX_SESSION" => "test-session"}, captured_subprocess_env)
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
