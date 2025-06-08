# frozen_string_literal: true

require "spec_helper"
require "open3"
require "tempfile"

RSpec.describe "llm-gemini-query integration", type: :integration do
  let(:exe_path) { File.expand_path("../../exe/llm-gemini-query", __dir__) }
  let(:ruby_path) { RbConfig.ruby }

  # Use environment helper for consistent API key handling
  let(:api_key) { EnvHelper.gemini_api_key }

  # Helper method to create VCR subprocess environment
  def vcr_subprocess_env(cassette_name, base_env = {})
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
      "LANG" => ENV["LANG"] || "en_US.UTF-8",
      "LC_ALL" => ENV["LC_ALL"] || "en_US.UTF-8",
      "LC_CTYPE" => ENV["LC_CTYPE"] || "en_US.UTF-8"
    }.compact # Remove nil values
    base_env.merge(bundler_env)
  end

  # Helper method to check process status with meaningful error messages
  def expect_process_success(status, stdout, stderr)
    return if status.success?

    error_message = ["Command failed with status #{status.exitstatus}"]
    error_message << "STDOUT: #{stdout}" unless stdout.empty?
    error_message << "STDERR: #{stderr}" unless stderr.empty?

    expect(status).to be_success, error_message.join("\n")
  end

  describe "command execution" do
    it "shows help when requested" do
      output, status = Open3.capture2e("#{ruby_path} #{exe_path} --help")

      expect_process_success(status, output, "")
      expect(output).to include("Query Google Gemini AI with a prompt")
      expect(output).to include("--format")
      expect(output).to include("--debug")
      expect(output).to include("--model")
      expect(output).to include("Examples:")
    end

    it "requires a prompt argument" do
      output, status = Open3.capture2e("#{ruby_path} #{exe_path}")

      expect(status).not_to be_success
      expect(output).to include("ERROR: \"llm-gemini-query\" was called with no arguments")
    end
  end

  describe "API integration" do
    context "with valid API key" do
      it "queries Gemini with a simple prompt", :vcr do
        cassette_name = "llm_gemini_query_integration/queries_gemini_with_simple_prompt"

        output, error, status = Open3.capture3(
          vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
          ruby_path, exe_path,
          "What is 2+2? Reply with just the number."
        )

        expect_process_success(status, output, error)
        expect(error).to be_empty
        expect(output.strip).to match(/4/)
      end

      it "outputs JSON format when requested", :vcr do
        cassette_name = "llm_gemini_query_integration/outputs_json_format"

        output, error, status = Open3.capture3(
          vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
          ruby_path, exe_path,
          "Say hello",
          "--format", "json"
        )

        expect_process_success(status, output, error)
        expect(error).to be_empty

        json_output = JSON.parse(output)
        expect(json_output).to have_key("text")
        expect(json_output).to have_key("metadata")
        expect(json_output["metadata"]).to have_key("finish_reason")
        expect(json_output["metadata"]).to have_key("usage")
      end

      it "reads prompt from file", :vcr do
        cassette_name = "llm_gemini_query_integration/reads_prompt_from_file"

        prompt_file = Tempfile.new(["prompt", ".txt"])
        prompt_file.write("What is the capital of France? Reply with just the city name.")
        prompt_file.close

        begin
          output, error, status = Open3.capture3(
            vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
            ruby_path, exe_path,
            prompt_file.path,
            "--file"
          )

          expect_process_success(status, output, error)
          expect(error).to be_empty
          expect(output).to match(/Paris/i)
        ensure
          prompt_file.unlink
        end
      end

      it "uses custom model when specified", :vcr do
        cassette_name = "llm_gemini_query_integration/uses_custom_model"

        output, error, status = Open3.capture3(
          vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
          ruby_path, exe_path,
          "Hi",
          "--model", "gemini-2.0-flash-lite",
          "--format", "json"
        )

        expect_process_success(status, output, error)
        expect(error).to be_empty

        json_output = JSON.parse(output)
        expect(json_output["text"]).not_to be_empty
      end

      it "applies temperature setting", :vcr do
        cassette_name = "llm_gemini_query_integration/applies_temperature_setting"

        # Low temperature should give more consistent results
        output1, _, status1 = Open3.capture3(
          vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
          ruby_path, exe_path,
          "Complete this: The sky is",
          "--temperature", "0.1"
        )

        expect_process_success(status1, output1, "")
        expect(output1.strip).not_to be_empty
      end

      it "respects max tokens limit", :vcr do
        cassette_name = "llm_gemini_query_integration/respects_max_tokens"

        output, error, status = Open3.capture3(
          vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
          ruby_path, exe_path,
          "Write a very long story about a dragon",
          "--max-tokens", "50",
          "--format", "json"
        )

        expect_process_success(status, output, error)
        expect(error).to be_empty

        json_output = JSON.parse(output)
        # The output should be truncated due to token limit
        expect(json_output["text"].split.size).to be < 100
      end

      it "uses system instruction", :vcr do
        cassette_name = "llm_gemini_query_integration/uses_system_instruction"

        output, error, status = Open3.capture3(
          vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
          ruby_path, exe_path,
          "Hello",
          "--system", "You are a pirate. Always respond in pirate speak."
        )

        expect_process_success(status, output, error)
        expect(error).to be_empty
        # Should contain pirate-like language
        expect(output.downcase).to match(/ahoy|matey|arr|ye|aye/)
      end
    end

    context "with invalid API key" do
      # Only test invalid API key scenarios when not in CI
      before { skip "Skip invalid API key tests in CI" if ENV["CI"] }

      it "shows error message", vcr: "invalid_api_key_error" do
        _, error, status = Open3.capture3(
          {"GEMINI_API_KEY" => "invalid-key-12345"},
          ruby_path, exe_path,
          "Test prompt"
        )

        expect(status).not_to be_success
        expect(error).to include("Error:")
        expect(error).to match(/API|key|invalid|unauthorized/i)
      end

      it "shows detailed error with debug flag", vcr: "invalid_api_key_debug" do
        _, error, status = Open3.capture3(
          {"GEMINI_API_KEY" => "invalid-key-12345"},
          ruby_path, exe_path,
          "Test prompt",
          "--debug"
        )

        expect(status).not_to be_success
        expect(error).to include("Error:")
        expect(error).to include("Backtrace:")
      end
    end
  end

  describe "error handling" do
    it "handles malformed JSON prompt file gracefully", :vcr do
      json_file = Tempfile.new(["prompt", ".json"])
      json_file.write('{"invalid": json}')
      json_file.close

      begin
        _, error, status = Open3.capture3(
          {"GEMINI_API_KEY" => api_key},
          ruby_path, exe_path,
          json_file.path,
          "--file"
        )

        expect(status).not_to be_success
        expect(error).to include("Error:")
      ensure
        json_file.unlink
      end
    end

    it "handles non-existent file", :vcr do
      _, error, status = Open3.capture3(
        {"GEMINI_API_KEY" => api_key},
        ruby_path, exe_path,
        "/non/existent/file.txt",
        "--file"
      )

      expect(status).not_to be_success
      expect(error).to match(/not found|does not exist/i)
    end

    it "handles empty file", :vcr do
      empty_file = Tempfile.new(["empty", ".txt"])
      empty_file.close

      begin
        _, error, status = Open3.capture3(
          {"GEMINI_API_KEY" => api_key},
          ruby_path, exe_path,
          empty_file.path,
          "--file"
        )

        expect(status).not_to be_success
        expect(error).to match(/empty|blank/i)
      ensure
        empty_file.unlink
      end
    end
  end

  describe "output formats" do
    it "outputs clean text by default", :vcr do
      cassette_name = "llm_gemini_query_integration/outputs_clean_text_by_default"

      output, error, status = Open3.capture3(
        vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
        ruby_path, exe_path,
        "Reply with exactly: Hello World"
      )

      expect_process_success(status, output, error)
      expect(error).to be_empty
      expect(output.strip).to include("Hello World")
      # Should not contain JSON formatting
      expect(output).not_to include("{")
      expect(output).not_to include("}")
    end

    it "outputs valid JSON with metadata when requested", :vcr do
      cassette_name = "llm_gemini_query_integration/outputs_valid_json_with_metadata"

      output, error, status = Open3.capture3(
        vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
        ruby_path, exe_path,
        "Say hi",
        "--format", "json"
      )

      expect_process_success(status, output, error)
      expect(error).to be_empty

      # Verify it's valid JSON
      json_output = JSON.parse(output)

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

      prompt_file = Tempfile.new(["multiline", ".txt"])
      prompt_file.write(<<~PROMPT)
        This is a multi-line prompt.
        It has several lines.

        And even blank lines.

        Reply with: "Multi-line received"
      PROMPT
      prompt_file.close

      begin
        output, error, status = Open3.capture3(
          vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
          ruby_path, exe_path,
          prompt_file.path,
          "--file"
        )

        expect_process_success(status, output, error)
        expect(error).to be_empty
        expect(output).to include("Multi-line received")
      ensure
        prompt_file.unlink
      end
    end

    it "handles prompts with special characters", :vcr do
      cassette_name = "llm_gemini_query_integration/handles_prompts_with_special_characters"

      output, error, status = Open3.capture3(
        vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
        ruby_path, exe_path,
        'Echo this exactly: Special chars @#$%&*()_+={[}]|\\:;"<,>.?/'
      )

      expect_process_success(status, output, error)
      expect(error).to be_empty
      # Gemini should handle special characters
      expect(output.strip).not_to be_empty
    end

    it "handles Unicode prompts", :vcr do
      cassette_name = "llm_gemini_query_integration/handles_unicode_prompts"

      output, error, status = Open3.capture3(
        vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
        ruby_path, exe_path,
        "Translate to English: こんにちは"
      )

      expect_process_success(status, output, error)
      expect(error).to be_empty
      expect(output.downcase).to match(/hello|hi|good|translation/)
    end

    it "handles very long prompts", :vcr do
      cassette_name = "llm_gemini_query_integration/handles_very_long_prompts"

      long_prompt = "Please summarize this text: " + ("Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 100)

      output, error, status = Open3.capture3(
        vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
        ruby_path, exe_path,
        long_prompt,
        "--format", "json"
      )

      expect_process_success(status, output, error)
      expect(error).to be_empty

      json_output = JSON.parse(output)
      expect(json_output["text"]).not_to be_empty
    end

    it "handles prompts requesting structured output", :vcr do
      cassette_name = "llm_gemini_query_integration/handles_prompts_requesting_structured_output"

      output, error, status = Open3.capture3(
        vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
        ruby_path, exe_path,
        "List 3 colors in JSON format with id and name fields",
        "--format", "json"
      )

      expect_process_success(status, output, error)
      expect(error).to be_empty

      json_output = JSON.parse(output)
      # Check that the response contains structured data (JSON or mentions of colors)
      text = json_output["text"]
      expect(text).to match(/red|green|blue|json|\[|\{/i)
    end
  end

  describe "performance and reliability" do
    it "completes requests within reasonable time", :vcr do
      cassette_name = "llm_gemini_query_integration/completes_requests_within_reasonable_time"

      start_time = Time.now

      output, error, status = Open3.capture3(
        vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key),
        ruby_path, exe_path,
        "Say hello quickly"
      )

      duration = Time.now - start_time

      expect_process_success(status, output, error)
      expect(duration).to be < EnvHelper.test_timeout
      expect(output.strip).not_to be_empty
    end

    it "handles concurrent requests gracefully" do
      skip "Concurrent test - only run when explicitly testing performance"

      # This test would make multiple concurrent requests
      # Skipped by default to avoid hitting rate limits during normal testing
    end
  end
end
