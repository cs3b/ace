# frozen_string_literal: true

require_relative "../test_helper"

describe "CLI Execution Edge Cases" do
  describe "ClaudeCodeClient Error Handling" do
    before do
      @client = Ace::LLM::Providers::CLI::ClaudeCodeClient.new
    end

    it "handles command not found gracefully" do
      # Mock the claude_available? method to return false
      @client.define_singleton_method(:claude_available?) { false }

      err = assert_raises(Ace::LLM::Error) do
        @client.generate([{ role: "user", content: "test" }])
      end

      assert_match(/claude.*not.*found/i, err.message)
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
      messages = [{ role: "user", content: long_prompt }]

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
        { role: "user", content: "Hello 世界 café résumé مرحبا" }
      ]

      # Should format messages without error
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "世界"
      assert_includes formatted, "café"
    end

    it "handles special characters in prompt" do
      messages = [
        { role: "user", content: "Test $VAR `command` $(subshell) & | > <" }
      ]

      # Should format messages without error
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "$VAR"
    end

    it "handles malformed message array" do
      # Missing required fields
      messages = [
        { content: "no role specified" }
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
        { role: "system", content: "You are helpful" },
        { role: "user", content: "Hello" },
        { role: "assistant", content: "Hi there" },
        { role: "user", content: "How are you?" }
      ]

      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "System:"
      assert_includes formatted, "User:"
      assert_includes formatted, "Assistant:"
    end

    it "handles messages with newlines" do
      messages = [
        { role: "user", content: "Line 1\nLine 2\nLine 3" }
      ]

      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "Line 1"
      assert_includes formatted, "Line 2"
    end

    it "handles messages with quotes" do
      messages = [
        { role: "user", content: 'Single \'quotes\' and "double" quotes' }
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
      # Mock the aider_available? method to return false
      @client.define_singleton_method(:aider_available?) { false }

      err = assert_raises(Ace::LLM::Error) do
        @client.generate([{ role: "user", content: "test" }])
      end

      assert_match(/aider.*not.*found/i, err.message)
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
        { role: "user", content: "Code with unicode: café.js 文件" }
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
      # Mock the windsurf_available? method to return false
      @client.define_singleton_method(:windsurf_available?) { false }

      err = assert_raises(Ace::LLM::Error) do
        @client.generate([{ role: "user", content: "test" }])
      end

      assert_match(/opencode.*not.*found/i, err.message)
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

  describe "CodexOSSClient Error Handling" do
    before do
      @client = Ace::LLM::Providers::CLI::CodexOSSClient.new
    end

    it "handles command not found gracefully" do
      # Mock the cursor_available? method to return false
      @client.define_singleton_method(:cursor_available?) { false }

      err = assert_raises(Ace::LLM::Error) do
        @client.generate([{ role: "user", content: "test" }])
      end

      assert_match(/codex.*not.*found/i, err.message)
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
      messages = [{ role: "user", content: "   \n\t   " }]
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert formatted
    end

    it "handles message with control characters" do
      messages = [{ role: "user", content: "Test\x00\x01\x02" }]
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert formatted
    end

    it "handles message with emoji" do
      messages = [{ role: "user", content: "Hello 👋 world 🌍" }]
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "👋"
    end

    it "handles mixed string and symbol keys" do
      messages = [
        { "role" => "user", "content" => "String keys" },
        { role: "user", content: "Symbol keys" }
      ]
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "String keys"
      assert_includes formatted, "Symbol keys"
    end

    it "handles unknown role" do
      messages = [{ role: "unknown", content: "Unknown role message" }]
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert_includes formatted, "Unknown role message"
    end

    it "handles deeply nested JSON-like content" do
      content = { nested: { deeply: { value: "test" } } }.to_s
      messages = [{ role: "user", content: content }]
      formatted = @client.send(:format_messages_as_prompt, messages)
      assert formatted
    end
  end
end
