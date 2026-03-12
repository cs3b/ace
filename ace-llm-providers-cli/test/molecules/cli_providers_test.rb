# frozen_string_literal: true

require_relative "../test_helper"
require "stringio"

describe "CLI Providers" do
  describe "ClaudeCodeClient" do
    before do
      @client = Ace::LLM::Providers::CLI::ClaudeCodeClient.new
    end

    it "initializes with default model" do
      assert @client.instance_variable_get(:@model)
    end

    it "can list models" do
      models = @client.list_models
      assert_kind_of Array, models
      assert models.any? { |m| m[:id].include?("opus") }
      assert models.any? { |m| m[:id].include?("sonnet") }
      assert models.any? { |m| m[:id].include?("haiku") }
    end

    it "formats messages correctly" do
      messages = [
        { role: "system", content: "You are helpful" },
        { role: "user", content: "Hello" }
      ]

      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "System: You are helpful"
      assert_includes formatted, "User: Hello"
    end

    it "handles string prompts" do
      prompt = "Just a string"
      formatted = @client.send(:format_messages_as_prompt, prompt)
      assert_equal "Just a string", formatted
    end

    it "passes cli_args into the subprocess command" do
      status = Struct.new(:success?).new(true)
      captured_cmd = nil

      @client.stub :validate_claude_availability!, true do
        @client.stub :execute_claude_command, lambda { |cmd, prompt, subprocess_env: nil, working_dir: nil|
          captured_cmd = cmd
          ['{"result":"ok","usage":{}}', "", status]
        } do
          @client.generate([{ role: "user", content: "hi" }], cli_args: "--verbose")
        end
      end

      assert_includes captured_cmd, "--verbose"
    end

    it "emits subprocess debug context when enabled" do
      status = Struct.new(:success?).new(true)
      old_env = ENV["ACE_LLM_DEBUG_SUBPROCESS"]
      old_stderr = $stderr
      stderr_io = StringIO.new
      ENV["ACE_LLM_DEBUG_SUBPROCESS"] = "1"
      $stderr = stderr_io

      @client.stub :validate_claude_availability!, true do
        Ace::LLM::Providers::CLI::Molecules::SafeCapture.stub :call, ['{"result":"ok","usage":{}}', "", status] do
          @client.generate([{ role: "user", content: "hi" }], cli_args: "--verbose")
        end
      end

      assert_includes stderr_io.string, "[ClaudeCodeClient] spawn timeout="
    ensure
      ENV["ACE_LLM_DEBUG_SUBPROCESS"] = old_env
      $stderr = old_stderr
    end
  end

  describe "CodexClient" do
    before do
      @client = Ace::LLM::Providers::CLI::CodexClient.new
    end

    it "initializes with default model" do
      model = @client.instance_variable_get(:@model)
      assert model # Just check it has a model
    end

    it "can list models" do
      models = @client.list_models
      assert_kind_of Array, models
      assert models.any? { |m| m[:id] == "gpt-5" }
      assert models.any? { |m| m[:id] == "gpt-5-mini" }
    end
  end

  describe "OpenCodeClient" do
    before do
      @client = Ace::LLM::Providers::CLI::OpenCodeClient.new
    end

    it "initializes with default model" do
      model = @client.instance_variable_get(:@model)
      assert model # Just check it has a model
    end

    it "provides models" do
      models = @client.list_models
      assert_kind_of Array, models
      assert models.size > 0
      assert models.any? { |m| m[:id].include?("gemini") }
    end
  end

  describe "CodexOaiClient" do
    before do
      @client = Ace::LLM::Providers::CLI::CodexOaiClient.new
    end

    it "initializes with default model" do
      model = @client.instance_variable_get(:@model)
      assert model # Just check it has a model
    end

    it "lists models" do
      models = @client.list_models
      assert_kind_of Array, models
      assert models.any? { |m| m[:id] == "zai/glm-5" }
    end
  end

  describe "ClaudeOaiClient" do
    before do
      @client = Ace::LLM::Providers::CLI::ClaudeOaiClient.new
    end

    it "initializes with default model" do
      model = @client.instance_variable_get(:@model)
      assert model # Just check it has a model
    end

    it "lists models" do
      models = @client.list_models
      assert_kind_of Array, models
      assert models.any? { |m| m[:id] == "zai/glm-5" }
    end
  end
end
