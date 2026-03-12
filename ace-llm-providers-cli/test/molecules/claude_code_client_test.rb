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
end
