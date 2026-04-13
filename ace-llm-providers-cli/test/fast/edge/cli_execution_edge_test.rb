# frozen_string_literal: true

require_relative "../../test_helper"

# Helper module for CLI execution edge tests
module CLIExecutionTestHelpers
  # Create a mock status object for subprocess results
  # @param success [Boolean] Whether the command succeeded
  # @return [Object] Mock status object responding to success? and exitstatus
  def mock_success_status(success: true)
    status = Object.new
    status.define_singleton_method(:success?) { success }
    status.define_singleton_method(:exitstatus) { success ? 0 : 1 }
    status
  end
end

describe "CLI Execution Edge Cases" do
  include CLIExecutionTestHelpers

  describe "ClaudeCodeClient Error Handling" do
    before do
      @client = Ace::LLM::Providers::CLI::ClaudeCodeClient.new
    end

    it "handles command not found gracefully" do
      # Use stub pattern for thread-safe mocking
      @client.stub :claude_available?, false do
        err = assert_raises(Ace::LLM::Error) do
          @client.generate([{role: "user", content: "test"}])
        end

        assert_match(/claude.*not.*found/i, err.message, "Should report claude CLI not found")
      end
    end

    it "handles empty prompt" do
      skip "This test requires mocking or actual claude CLI"
      # Empty string prompt
      result = @client.generate("")
      assert result
    end

    it "handles very long prompt" do
      skip "This test requires mocking or actual claude CLI"
      # Create a very long prompt (100k characters)
      long_prompt = "test " * 20_000
      messages = [{role: "user", content: long_prompt}]

      # Should either succeed or fail gracefully
      begin
        result = @client.generate(messages)
        assert result
      rescue Ace::LLM::Error => e
        # Expected for very long prompts
        assert_match(/too.*long|limit|size/i, e.message)
      end
    end

    it "handles unicode in prompt" do
      messages = [
        {role: "user", content: "Hello 世界 café résumé مرحبا"}
      ]

      # Should format messages without error
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "世界"
      assert_includes formatted, "café"
    end

    it "handles special characters in prompt" do
      messages = [
        {role: "user", content: "Test $VAR `command` $(subshell) & | > <"}
      ]

      # Should format messages without error
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "$VAR"
    end

    it "handles malformed message array" do
      # Missing required fields
      messages = [
        {content: "no role specified"}
      ]

      # Should handle gracefully
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert formatted
    end

    it "handles nil messages gracefully" do
      # Should raise or handle nil appropriately
      assert_raises(NoMethodError, TypeError) do
        @client.send(:format_messages_as_prompt, nil)
      end
    end

    it "handles string prompt directly" do
      prompt = "Just a plain string prompt"
      formatted = @client.send(:format_messages_as_prompt, prompt)
      assert_equal prompt, formatted
    end

    it "handles empty message array" do
      messages = []
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_equal "", formatted
    end

    it "handles multiple roles in conversation" do
      messages = [
        {role: "system", content: "You are helpful"},
        {role: "user", content: "Hello"},
        {role: "assistant", content: "Hi there"},
        {role: "user", content: "How are you?"}
      ]

      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "System:"
      assert_includes formatted, "User:"
      assert_includes formatted, "Assistant:"
    end

    it "handles messages with newlines" do
      messages = [
        {role: "user", content: "Line 1\nLine 2\nLine 3"}
      ]

      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "Line 1"
      assert_includes formatted, "Line 2"
    end

    it "handles messages with quotes" do
      messages = [
        {role: "user", content: 'Single \'quotes\' and "double" quotes'}
      ]

      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "Single"
      assert_includes formatted, "quotes"
    end

    it "lists models without CLI available" do
      # list_models doesn't require CLI to be available
      models = @client.list_models

      assert_kind_of Array, models
      assert models.size > 0
      assert models.all? { |m| m.key?(:id) }
      assert models.all? { |m| m.key?(:name) }
    end

    it "indicates no credentials needed" do
      refute @client.needs_credentials?
    end
  end

  describe "CodexClient Error Handling" do
    before do
      @client = Ace::LLM::Providers::CLI::CodexClient.new
    end

    it "handles command not found gracefully" do
      skip "CodexClient has different error handling behavior"
      # Use stub pattern for thread-safe mocking
      @client.stub :aider_available?, false do
        err = assert_raises(Ace::LLM::Error) do
          @client.generate([{role: "user", content: "test"}])
        end

        assert_match(/aider.*not.*found/i, err.message, "Should report aider CLI not found")
      end
    end

    it "lists models without CLI available" do
      models = @client.list_models

      assert_kind_of Array, models
      assert models.size > 0
    end

    it "indicates no credentials needed" do
      refute @client.needs_credentials?
    end

    it "handles unicode in messages" do
      messages = [
        {role: "user", content: "Code with unicode: café.js 文件"}
      ]

      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "café"
    end
  end

  describe "OpenCodeClient Error Handling" do
    before do
      @client = Ace::LLM::Providers::CLI::OpenCodeClient.new
    end

    it "handles command not found gracefully" do
      # Use stub pattern for thread-safe mocking
      @client.stub :opencode_available?, false do
        err = assert_raises(Ace::LLM::Error) do
          @client.generate([{role: "user", content: "test"}])
        end

        assert_match(/opencode.*not.*found/i, err.message, "Should report opencode CLI not found")
      end
    end

    it "lists models without CLI available" do
      models = @client.list_models

      assert_kind_of Array, models
      assert models.size > 0
    end

    it "indicates no credentials needed" do
      refute @client.needs_credentials?
    end

    it "builds correct opencode command with run subcommand" do
      cmd = @client.send(:build_opencode_command, "test prompt", {})
      assert_equal "opencode", cmd[0]
      assert_equal "run", cmd[1]
      refute_includes cmd, "generate"
    end

    it "builds correct opencode command with model flag" do
      cmd = @client.send(:build_opencode_command, "test prompt", {})
      assert_includes cmd, "--model"
      model_idx = cmd.index("--model")
      assert_equal "google/gemini-2.5-flash", cmd[model_idx + 1]
    end

    it "builds correct opencode command with positional prompt argument" do
      prompt = "test prompt"
      cmd = @client.send(:build_opencode_command, prompt, {})
      refute_includes cmd, "--prompt"
      # Prompt should be at the end as positional argument
      assert_equal prompt, cmd.last
    end

    it "builds opencode command without unsupported flags" do
      cmd = @client.send(:build_opencode_command, "test prompt",
        temperature: 0.7, max_tokens: 1000, format: "json")
      refute_includes cmd, "--temperature"
      refute_includes cmd, "--max-tokens"
      # --format json is now added automatically for structured output
      assert_includes cmd, "--format"
      assert_equal "json", cmd[cmd.index("--format") + 1]
      refute_includes cmd, "--system"
    end

    it "builds opencode command with system prompt prepended" do
      prompt = "main prompt"
      system = "You are helpful"
      cmd = @client.send(:build_opencode_command, prompt, system: system)
      # System prompt should be prepended to main prompt
      expected_prompt = "System: #{system}\n\n#{prompt}"
      assert_equal expected_prompt, cmd.last
      refute_includes cmd, "--system"
    end

    it "builds full prompt without system instruction when not provided" do
      prompt = "test prompt"
      full_prompt = @client.send(:build_full_prompt, prompt, {})
      assert_equal prompt, full_prompt
    end

    it "builds full prompt with system instruction from various sources" do
      prompt = "main prompt"
      system = "You are helpful"

      # Test system_instruction option
      full_prompt = @client.send(:build_full_prompt, prompt, system_instruction: system)
      assert_equal "System: #{system}\n\n#{prompt}", full_prompt

      # Test system option
      full_prompt = @client.send(:build_full_prompt, prompt, system: system)
      assert_equal "System: #{system}\n\n#{prompt}", full_prompt

      # Test system_prompt option
      full_prompt = @client.send(:build_full_prompt, prompt, system_prompt: system)
      assert_equal "System: #{system}\n\n#{prompt}", full_prompt
    end

    it "builds full prompt with system instruction from generation_config" do
      # Create client with system_prompt in generation_config
      client = Ace::LLM::Providers::CLI::OpenCodeClient.new(
        generation_config: {system_prompt: "You are helpful"}
      )

      prompt = "main prompt"
      full_prompt = client.send(:build_full_prompt, prompt, {})

      assert_equal "System: You are helpful\n\n#{prompt}", full_prompt
    end

    it "prioritizes explicit options over generation_config for system prompt" do
      # Create client with system_prompt in generation_config
      client = Ace::LLM::Providers::CLI::OpenCodeClient.new(
        generation_config: {system_prompt: "Config system prompt"}
      )

      prompt = "main prompt"
      # Explicit system option should override generation_config
      full_prompt = client.send(:build_full_prompt, prompt, system: "Explicit system prompt")

      assert_equal "System: Explicit system prompt\n\n#{prompt}", full_prompt,
        "Explicit :system option should take precedence over generation_config"
    end

    it "avoids double system prefix when messages already contain system role" do
      # Simulate prompt that already has System: prefix from format_messages_as_prompt
      prompt_with_system = "System: You are helpful\n\nUser: Hello"

      # Even with system option provided, should not prepend another System: prefix
      full_prompt = @client.send(:build_full_prompt, prompt_with_system, system: "Another system prompt")

      # Should return original prompt unchanged to avoid duplication
      assert_equal prompt_with_system, full_prompt,
        "Should not prepend System: when prompt already starts with System:"
      refute full_prompt.start_with?("System: Another system prompt"),
        "Should not add duplicate system instruction"
    end

    it "uses explicit model over default when provided" do
      # Create client with explicit model
      client = Ace::LLM::Providers::CLI::OpenCodeClient.new(
        model: "anthropic/claude-3-5-sonnet"
      )

      cmd = client.send(:build_opencode_command_with_prompt, "test prompt", {})
      model_idx = cmd.index("--model")

      assert_equal "anthropic/claude-3-5-sonnet", cmd[model_idx + 1],
        "Should use explicit model when provided"
    end

    it "uses default model when no model specified" do
      # Create client without explicit model - constructor uses DEFAULT_MODEL
      client = Ace::LLM::Providers::CLI::OpenCodeClient.new

      cmd = client.send(:build_opencode_command_with_prompt, "test prompt", {})
      model_idx = cmd.index("--model")

      assert_equal "google/gemini-2.5-flash", cmd[model_idx + 1],
        "Should use default model when no model specified"
    end

    it "parses plain text output when JSON parsing fails" do
      # Simulate non-JSON stdout from OpenCode CLI
      stdout = "This is plain text output from the CLI"
      stderr = ""
      status = mock_success_status

      result = @client.send(:parse_opencode_response, stdout, stderr, status, "test prompt", {})

      assert_equal "This is plain text output from the CLI", result[:text],
        "Should extract plain text as response text"
      assert_equal "opencode", result[:metadata][:provider],
        "Should set provider to opencode"
      assert_equal "google/gemini-2.5-flash", result[:metadata][:model],
        "Should use default model"
      assert result[:metadata][:input_tokens] > 0,
        "Should estimate positive input tokens"
      assert result[:metadata][:output_tokens] > 0,
        "Should estimate positive output tokens"
    end

    it "parses JSON output when available" do
      # Simulate JSON stdout from OpenCode CLI
      stdout = '{"result": "Generated response", "usage": {"input_tokens": 10, "output_tokens": 20}}'
      stderr = ""
      status = mock_success_status

      result = @client.send(:parse_opencode_response, stdout, stderr, status, "test prompt", {})

      assert_equal "Generated response", result[:text],
        "Should extract result from JSON response"
      assert_equal 10, result[:metadata][:input_tokens],
        "Should use input_tokens from usage metadata"
      assert_equal 20, result[:metadata][:output_tokens],
        "Should use output_tokens from usage metadata"
    end

    it "handles empty plain text output gracefully" do
      # Simulate empty output from OpenCode CLI
      stdout = ""
      stderr = ""
      status = mock_success_status

      result = @client.send(:parse_opencode_response, stdout, stderr, status, "test prompt", {})

      assert_equal "", result[:text],
        "Should handle empty output without error"
      assert_equal "success", result[:metadata][:finish_reason],
        "Should set finish_reason to success"
    end

    it "handles nil prompt gracefully with string coercion" do
      # Test that nil prompt is converted to empty string via .to_s
      cmd = @client.send(:build_opencode_command, nil, {})

      # Prompt should be at the end as positional argument
      # nil.to_s returns ""
      assert_equal "", cmd.last
    end

    it "handles non-string prompt with string coercion" do
      # Test that non-string prompts are converted to string via .to_s
      cmd = @client.send(:build_opencode_command, 12345, {})

      # 12345.to_s returns "12345"
      assert_equal "12345", cmd.last
    end

    it "exercises public generate API with simple prompt" do
      # Test the public API path (not private methods via send)
      # This verifies the full flow works with string input
      # We can't test actual CLI execution without opencode installed,
      # but we can verify it doesn't crash on input

      # Use stub pattern for thread-safe mocking
      @client.stub :opencode_available?, false do
        prompt = "test prompt"
        messages = [{role: "user", content: prompt}]

        # This will fail with opencode availability error (expected)
        # but validates the type handling works up to that point
        err = assert_raises(Ace::LLM::ProviderError) do
          @client.generate(messages)
        end

        # Should fail on availability check, not on type errors
        assert_match(/opencode.*not.*found/i, err.message,
          "Should fail on availability check, not type errors")
      end
    end
  end

  describe "CodexOaiClient Error Handling" do
    before do
      @client = Ace::LLM::Providers::CLI::CodexOaiClient.new
    end

    it "handles command not found gracefully" do
      # Use stub pattern for thread-safe mocking
      @client.stub :codex_available?, false do
        err = assert_raises(Ace::LLM::Error) do
          @client.generate([{role: "user", content: "test"}])
        end

        assert_match(/codex.*not.*found/i, err.message, "Should report codex CLI not found")
      end
    end

    it "lists models without CLI available" do
      models = @client.list_models

      assert_kind_of Array, models
      assert models.size > 0
    end

    it "indicates no credentials needed" do
      refute @client.needs_credentials?
    end
  end

  describe "Process Execution Edge Cases" do
    it "handles subprocess timeout" do
      skip "Requires mocking subprocess execution with timeout"
      # This would test timeout handling in execute_claude_command
      # Implementation would depend on actual timeout mechanisms
    end

    it "handles subprocess killed" do
      skip "Requires mocking subprocess being killed"
      # This would test handling of killed processes
    end

    it "handles subprocess crash" do
      skip "Requires mocking subprocess crash"
      # This would test handling of subprocess non-zero exit
    end

    it "handles stdout and stderr simultaneously" do
      skip "Requires actual CLI execution or mocking"
      # This would test parsing both stdout and stderr
    end

    it "handles very large output" do
      skip "Requires actual CLI execution or mocking"
      # This would test handling of large subprocess output
    end

    it "handles binary output" do
      skip "Requires actual CLI execution or mocking"
      # This would test handling of non-text output
    end

    it "handles signal interruption" do
      skip "Requires signal handling setup"
      # This would test SIGINT/SIGTERM handling
    end
  end

  describe "Message Formatting Edge Cases" do
    before do
      @client = Ace::LLM::Providers::CLI::ClaudeCodeClient.new
    end

    it "handles message with only whitespace" do
      messages = [{role: "user", content: "   \n\t   "}]
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert formatted
    end

    it "handles message with control characters" do
      messages = [{role: "user", content: "Test\x00\x01\x02"}]
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert formatted
    end

    it "handles message with emoji" do
      messages = [{role: "user", content: "Hello 👋 world 🌍"}]
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "👋"
    end

    it "handles mixed string and symbol keys" do
      messages = [
        {"role" => "user", "content" => "String keys"},
        {role: "user", content: "Symbol keys"}
      ]
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "String keys"
      assert_includes formatted, "Symbol keys"
    end

    it "handles unknown role" do
      messages = [{role: "unknown", content: "Unknown role message"}]
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "Unknown role message"
    end

    it "handles deeply nested JSON-like content" do
      content = {nested: {deeply: {value: "test"}}}.to_s
      messages = [{role: "user", content: content}]
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert formatted
    end
  end
end
