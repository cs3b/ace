# frozen_string_literal: true

require "spec_helper"
require "aruba/rspec"

RSpec.describe "llm-gemini-query integration", type: :aruba do
  let(:exe_path) { File.expand_path("../../exe/llm-gemini-query", __dir__) }
  let(:ruby_path) { RbConfig.ruby }

  # Use environment helper for consistent API key handling
  let(:api_key) { EnvHelper.gemini_api_key }

  # Helper method to setup VCR environment for Aruba
  def setup_vcr_env(cassette_name, base_env = {})
    vcr_setup_path = File.expand_path("../vcr_setup.rb", __dir__)
    # Include bundler environment to ensure subprocess has access to gems
    bundler_env = {
      "BUNDLE_GEMFILE" => ENV["BUNDLE_GEMFILE"],
      "BUNDLE_PATH" => ENV["BUNDLE_PATH"],
      "BUNDLE_BIN_PATH" => ENV["BUNDLE_BIN_PATH"],
      "RACK_ENV" => ENV["RACK_ENV"] || "test",
      "RUBYOPT" => "-rbundler/setup -r#{vcr_setup_path}",
      "VCR_CASSETTE_NAME" => cassette_name,
      # Ensure proper encoding for Unicode handling in CI
      "LANG" => ENV["LANG"].to_s.empty? ? "en_US.UTF-8" : ENV["LANG"],
      "LC_ALL" => ENV["LC_ALL"].to_s.empty? ? "en_US.UTF-8" : ENV["LC_ALL"],
      "LC_CTYPE" => ENV["LC_CTYPE"].to_s.empty? ? "en_US.UTF-8" : ENV["LC_CTYPE"]
    }.compact # Remove nil values

    env_vars = base_env.merge(bundler_env)
    env_vars.each { |key, value| set_environment_variable(key, value) }
  end

  describe "command execution" do
    it "shows help when requested" do
      run_command("#{ruby_path} #{exe_path} --help")

      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started).to have_output(/Query Google Gemini AI with a prompt/)
      expect(last_command_started).to have_output(/--format/)
      expect(last_command_started).to have_output(/--debug/)
      expect(last_command_started).to have_output(/--model/)
      expect(last_command_started).to have_output(/Examples:/)
    end

    it "requires a prompt argument" do
      run_command("#{ruby_path} #{exe_path}")

      expect(last_command_started).to have_exit_status(1)
      expect(last_command_started).to have_output(/ERROR: "llm-gemini-query" was called with no arguments/)
    end
  end

  describe "API integration" do
    context "with valid API key" do
      it "queries Gemini with a simple prompt", :vcr do
        cassette_name = "llm_gemini_query_integration/queries_gemini_with_simple_prompt"
        setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

        run_command("#{ruby_path} #{exe_path} 'What is 2+2? Reply with just the number.'")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started).to have_output(/4/)
        expect(last_command_started.stderr).to be_empty
      end

      it "outputs JSON format when requested", :vcr do
        cassette_name = "llm_gemini_query_integration/outputs_json_format"
        setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

        run_command("#{ruby_path} #{exe_path} 'Say hello' --format json")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty

        json_output = JSON.parse(last_command_started.stdout)
        expect(json_output).to have_key("text")
        expect(json_output).to have_key("metadata")
        expect(json_output["metadata"]).to have_key("finish_reason")
        expect(json_output["metadata"]).to have_key("usage")
      end

      it "reads prompt from file", :vcr do
        cassette_name = "llm_gemini_query_integration/reads_prompt_from_file"
        setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

        write_file("prompt.txt", "What is the capital of France? Reply with just the city name.")

        run_command("#{ruby_path} #{exe_path} prompt.txt --file")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty
        expect(last_command_started).to have_output(/Paris/i)
      end

      it "uses custom model when specified", :vcr do
        cassette_name = "llm_gemini_query_integration/uses_custom_model"
        setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

        run_command("#{ruby_path} #{exe_path} 'Hi' --model gemini-2.0-flash-lite --format json")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty

        json_output = JSON.parse(last_command_started.stdout)
        expect(json_output["text"]).not_to be_empty
      end

      it "applies temperature setting", :vcr do
        cassette_name = "llm_gemini_query_integration/applies_temperature_setting"
        setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

        # Low temperature should give more consistent results
        run_command("#{ruby_path} #{exe_path} 'Complete this: The sky is' --temperature 0.1")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stdout.strip).not_to be_empty
      end

      it "respects max tokens limit", :vcr do
        cassette_name = "llm_gemini_query_integration/respects_max_tokens"
        setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

        run_command("#{ruby_path} #{exe_path} 'Write a very long story about a dragon' --max-tokens 50 --format json")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty

        json_output = JSON.parse(last_command_started.stdout)
        # The output should be truncated due to token limit
        expect(json_output["text"].split.size).to be < 100
      end

      it "uses system instruction", :vcr do
        cassette_name = "llm_gemini_query_integration/uses_system_instruction"
        setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

        run_command("#{ruby_path} #{exe_path} 'Hello' --system 'You are a pirate. Always respond in pirate speak.'")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty
        # Should contain pirate-like language
        expect(last_command_started.stdout.downcase).to match(/ahoy|matey|arr|ye|aye/)
      end
    end

    context "with invalid API key" do
      # Only test invalid API key scenarios when not in CI
      before { skip "Skip invalid API key tests in CI" if ENV["CI"] }

      it "shows error message", vcr: "invalid_api_key_error" do
        set_environment_variable("GEMINI_API_KEY", "invalid-key-12345")

        run_command("#{ruby_path} #{exe_path} 'Test prompt'")

        expect(last_command_started).not_to have_exit_status(0)
        expect(last_command_started.stderr).to include("Error:")
        expect(last_command_started.stderr).to match(/API|key|invalid|unauthorized/i)
      end

      it "shows detailed error with debug flag", vcr: "invalid_api_key_debug" do
        set_environment_variable("GEMINI_API_KEY", "invalid-key-12345")

        run_command("#{ruby_path} #{exe_path} 'Test prompt' --debug")

        expect(last_command_started).not_to have_exit_status(0)
        expect(last_command_started.stderr).to include("Error:")
        expect(last_command_started.stderr).to include("Backtrace:")
      end
    end
  end

  describe "error handling" do
    it "handles malformed JSON prompt file gracefully", :vcr do
      set_environment_variable("GEMINI_API_KEY", api_key)
      write_file("malformed.json", '{"invalid": json}')

      run_command("#{ruby_path} #{exe_path} malformed.json --file")

      expect(last_command_started).not_to have_exit_status(0)
      expect(last_command_started.stderr).to include("Error:")
    end

    it "handles non-existent file", :vcr do
      set_environment_variable("GEMINI_API_KEY", api_key)

      run_command("#{ruby_path} #{exe_path} /non/existent/file.txt --file")

      expect(last_command_started).not_to have_exit_status(0)
      expect(last_command_started.stderr).to match(/not found|does not exist/i)
    end

    it "handles empty file", :vcr do
      set_environment_variable("GEMINI_API_KEY", api_key)
      write_file("empty.txt", "")

      run_command("#{ruby_path} #{exe_path} empty.txt --file")

      expect(last_command_started).not_to have_exit_status(0)
      expect(last_command_started.stderr).to match(/empty|blank/i)
    end
  end

  describe "output formats" do
    it "outputs clean text by default", :vcr do
      cassette_name = "llm_gemini_query_integration/outputs_clean_text_by_default"
      setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

      run_command("#{ruby_path} #{exe_path} 'Reply with exactly: Hello World'")

      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started.stderr).to be_empty
      expect(last_command_started.stdout.strip).to include("Hello World")
      # Should not contain JSON formatting
      expect(last_command_started.stdout).not_to include("{")
      expect(last_command_started.stdout).not_to include("}")
    end

    it "outputs valid JSON with metadata when requested", :vcr do
      cassette_name = "llm_gemini_query_integration/outputs_valid_json_with_metadata"
      setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

      run_command("#{ruby_path} #{exe_path} 'Say hi' --format json")

      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started.stderr).to be_empty

      # Verify it's valid JSON
      json_output = JSON.parse(last_command_started.stdout)

      # Check structure
      expect(json_output).to be_a(Hash)
      expect(json_output).to have_key("text")
      expect(json_output).to have_key("metadata")

      # Check metadata structure
      metadata = json_output["metadata"]
      expect(metadata).to have_key("finish_reason")
      expect(metadata).to have_key("safety_ratings")
      expect(metadata).to have_key("usage")

      # Usage should have token counts
      usage = metadata["usage"]
      expect(usage).to be_a(Hash)
      expect(usage.keys).to include("promptTokenCount") if usage.any?
    end
  end

  describe "rate limiting" do
    it "handles rate limit errors gracefully" do
      # This test would only trigger if we exceed rate limits
      # We'll simulate by making multiple rapid requests
      skip "Skipping rate limit test to avoid hitting actual limits"

      # If we wanted to test this:
      # 10.times do
      #   Open3.capture3(
      #     { "GEMINI_API_KEY" => ENV["GEMINI_API_KEY"] },
      #     ruby_path, exe_path,
      #     "Quick test"
      #   )
      # end
      #
      # The last request might hit rate limits and should show appropriate error
    end
  end

  describe "complex prompts" do
    it "handles multi-line prompts from file", :vcr do
      cassette_name = "llm_gemini_query_integration/handles_multiline_prompts_from_file"
      setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

      write_file("multiline.txt", <<~PROMPT)
        This is a multi-line prompt.
        It has several lines.

        And even blank lines.

        Reply with: "Multi-line received"
      PROMPT

      run_command("#{ruby_path} #{exe_path} multiline.txt --file")

      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started.stderr).to be_empty
      expect(last_command_started.stdout).to include("Multi-line received")
    end

    it "handles prompts with special characters", :vcr do
      cassette_name = "llm_gemini_query_integration/handles_prompts_with_special_characters"
      setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

      run_command("#{ruby_path} #{exe_path} 'Echo this exactly: Special chars @#$%&*()_+={[}]|\\:;\"<,>.?/'")

      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started.stderr).to be_empty
      # Gemini should handle special characters
      expect(last_command_started.stdout.strip).not_to be_empty
    end

    it "handles Unicode prompts", :vcr do
      cassette_name = "llm_gemini_query_integration/handles_unicode_prompts"
      setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

      run_command("#{ruby_path} #{exe_path} 'Translate to English: こんにちは'")

      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started.stderr).to be_empty
      expect(last_command_started.stdout.downcase).to match(/hello|hi|good|translation/)
    end

    it "handles very long prompts", :vcr do
      cassette_name = "llm_gemini_query_integration/handles_very_long_prompts"
      setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

      long_prompt = "Please summarize this text: " + ("Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 100)

      run_command("#{ruby_path} #{exe_path} '#{long_prompt}' --format json")

      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started.stderr).to be_empty

      json_output = JSON.parse(last_command_started.stdout)
      expect(json_output["text"]).not_to be_empty
    end

    it "handles prompts requesting structured output", :vcr do
      cassette_name = "llm_gemini_query_integration/handles_prompts_requesting_structured_output"
      setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

      run_command("#{ruby_path} #{exe_path} 'List 3 colors in JSON format with id and name fields' --format json")

      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started.stderr).to be_empty

      json_output = JSON.parse(last_command_started.stdout)
      # Check that the response contains structured data (JSON or mentions of colors)
      text = json_output["text"]
      expect(text).to match(/red|green|blue|json|\[|\{/i)
    end
  end

  describe "performance and reliability" do
    it "completes requests within reasonable time", :vcr do
      cassette_name = "llm_gemini_query_integration/completes_requests_within_reasonable_time"
      setup_vcr_env(cassette_name, "GEMINI_API_KEY" => api_key)

      start_time = Time.now

      run_command("#{ruby_path} #{exe_path} 'Say hello quickly'")

      duration = Time.now - start_time

      expect(last_command_started).to have_exit_status(0)
      expect(duration).to be < EnvHelper.test_timeout
      expect(last_command_started.stdout.strip).not_to be_empty
    end

    it "handles concurrent requests gracefully" do
      skip "Concurrent test - only run when explicitly testing performance"

      # This test would make multiple concurrent requests
      # Skipped by default to avoid hitting rate limits during normal testing
    end
  end
end
