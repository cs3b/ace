# frozen_string_literal: true

require "spec_helper"

RSpec.describe "llm-gemini-query integration", type: :integration do
  include ProcessHelpers

  let(:exe_name) { "llm-gemini-query" }
  let(:api_key) { EnvHelper.gemini_api_key }

  describe "command execution" do
    it "shows help when requested" do
      stdout, stderr, status = execute_gem_executable(exe_name, ["--help"])

      expect(status).to be_success
      expect(stdout).to match(/Query Google Gemini AI with a prompt/)
      expect(stdout).to match(/--format/)
      expect(stdout).to match(/--\[no-\]debug/)
      expect(stdout).to match(/--model/)
      expect(stdout).to match(/Examples:/)
      expect(stderr).to be_empty
    end

    it "requires a prompt argument" do
      stdout, stderr, status = execute_gem_executable(exe_name, [])

      expect(status.exitstatus).to eq(1)
      expect(stderr).to match(/ERROR: "llm-gemini-query" was called with no arguments/)
    end
  end

  describe "API integration" do
    context "with valid API key" do
      it "queries Gemini with a simple prompt", :vcr do
        cassette_name = "llm_gemini_query_integration/queries_gemini_with_simple_prompt"
        env = vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["What is 2+2? Reply with just the number."], env: env)

        expect(status).to be_success
        expect(stdout).to match(/4/)
        expect(stderr).to be_empty
      end

      it "outputs JSON format when requested", :vcr do
        cassette_name = "llm_gemini_query_integration/outputs_json_format"
        env = vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["Say hello", "--format", "json"], env: env)

        expect(status).to be_success
        expect(stderr).to be_empty

        json_output = JSON.parse(stdout)
        expect(json_output).to have_key("text")
        expect(json_output).to have_key("metadata")
        expect(json_output["metadata"]).to have_key("finish_reason")
        expect(json_output["metadata"]).to have_key("input_tokens")
        expect(json_output["metadata"]).to have_key("output_tokens")
        expect(json_output["metadata"]).to have_key("took")
        expect(json_output["metadata"]).to have_key("provider")
        expect(json_output["metadata"]).to have_key("model")
        expect(json_output["metadata"]).to have_key("timestamp")

        # Check normalized token counts
        expect(json_output["metadata"]["input_tokens"]).to be_a(Integer)
        expect(json_output["metadata"]["output_tokens"]).to be_a(Integer)
        expect(json_output["metadata"]["provider"]).to eq("gemini")
      end

      it "reads prompt from file", :vcr do
        cassette_name = "llm_gemini_query_integration/reads_prompt_from_file"
        env = vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key)

        prompt_file = create_temp_file("What is the capital of France? Reply with just the city name.", extension: ".txt")

        stdout, stderr, status = execute_gem_executable(exe_name, [prompt_file], env: env)

        expect(status).to be_success
        expect(stderr).to be_empty
        expect(stdout).to match(/Paris/i)
      end

      it "uses custom model when specified", :vcr do
        cassette_name = "llm_gemini_query_integration/uses_custom_model"
        env = vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["Hi", "--model", "gemini-1.5-flash", "--format", "json"], env: env)

        expect(status).to be_success
        expect(stderr).to be_empty

        json_output = JSON.parse(stdout)
        expect(json_output["text"]).not_to be_empty
      end

      it "applies temperature setting", :vcr do
        cassette_name = "llm_gemini_query_integration/applies_temperature_setting"
        env = vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key)

        # Low temperature should give more consistent results
        stdout, stderr, status = execute_gem_executable(exe_name,
          ["Complete this: The sky is", "--temperature", "0.1"], env: env)

        expect(status).to be_success
        expect(stdout.strip).not_to be_empty
      end

      it "respects max tokens limit", :vcr do
        cassette_name = "llm_gemini_query_integration/respects_max_tokens"
        env = vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["Write a very long story about a dragon", "--max-tokens", "50", "--format", "json"], env: env)

        expect(status).to be_success
        expect(stderr).to be_empty

        json_output = JSON.parse(stdout)
        # The output should be truncated due to token limit
        expect(json_output["text"].split.size).to be < 100
      end

      it "uses system instruction", :vcr do
        cassette_name = "llm_gemini_query_integration/uses_system_instruction"
        env = vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["Hello", "--system", "You are a pirate. Always respond in pirate speak."], env: env)

        expect(status).to be_success
        expect(stderr).to be_empty
        # Should contain pirate-like language
        expect(stdout.downcase).to match(/ahoy|matey|arr|ye|aye/)
      end
    end

    context "with invalid API key" do
      # Only test invalid API key scenarios when not in CI
      before { skip "Skip invalid API key tests in CI" if ENV["CI"] }

      it "shows error message", vcr: "invalid_api_key_error" do
        env = vcr_subprocess_env("invalid_api_key_error", "GEMINI_API_KEY" => "invalid-key-12345")

        stdout, stderr, status = execute_gem_executable(exe_name, ["Test prompt"], env: env)

        expect(status).not_to be_success
        expect(stderr).to include("Error:")
        expect(stderr).to match(/API|key|invalid|unauthorized/i)
      end

      it "shows detailed error with debug flag", vcr: "invalid_api_key_debug" do
        env = vcr_subprocess_env("invalid_api_key_debug", "GEMINI_API_KEY" => "invalid-key-12345")

        stdout, stderr, status = execute_gem_executable(exe_name, ["Test prompt", "--debug"], env: env)

        expect(status).not_to be_success
        expect(stderr).to include("Error:")
        expect(stderr).to include("Backtrace:")
      end
    end
  end

  describe "error handling" do
    it "treats malformed JSON as inline content and queries AI", :vcr do
      cassette_name = "llm_gemini_query_integration/treats_malformed_json_as_inline"
      env = vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key)
      malformed_file = create_temp_file('{"invalid": json}', extension: ".json")

      stdout, stderr, status = execute_gem_executable(exe_name, [malformed_file], env: env)

      expect(status).to be_success
      expect(stderr).to be_empty
      # Should respond with AI text about the content
      expect(stdout).not_to be_empty
    end

    it "treats non-existent file path as inline content", :vcr do
      cassette_name = "llm_gemini_query_integration/treats_nonexistent_file_as_inline"
      env = vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key)

      stdout, stderr, status = execute_gem_executable(exe_name, ["/non/existent/file.txt"], env: env)

      expect(status).to be_success
      expect(stderr).to be_empty
      # Should respond with AI text about the file path
      expect(stdout).not_to be_empty
    end

    it "handles empty file by treating it as empty prompt", :vcr do
      cassette_name = "llm_gemini_query_integration/handles_empty_file"
      env = vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key)
      empty_file = create_temp_file("", extension: ".txt")

      stdout, stderr, status = execute_gem_executable(exe_name, [empty_file], env: env)

      expect(status).to be_success
      expect(stderr).to be_empty
      # Should respond with AI's helpful default message
      expect(stdout).not_to be_empty
    end
  end

  describe "output formats" do
    it "outputs clean text by default", :vcr do
      cassette_name = "llm_gemini_query_integration/outputs_clean_text_by_default"
      env = vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key)

      stdout, stderr, status = execute_gem_executable(exe_name, ["Reply with exactly: Hello World"], env: env)

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(stdout.strip).to include("Hello World")
      # Should not contain JSON formatting
      expect(stdout).not_to include("{")
      expect(stdout).not_to include("}")
    end

    it "outputs valid JSON with metadata when requested", :vcr do
      cassette_name = "llm_gemini_query_integration/outputs_valid_json_with_metadata"
      env = vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key)

      stdout, stderr, status = execute_gem_executable(exe_name, ["Say hi", "--format", "json"], env: env)

      expect(status).to be_success
      expect(stderr).to be_empty

      # Verify it's valid JSON
      json_output = JSON.parse(stdout)

      # Check structure
      expect(json_output).to be_a(Hash)
      expect(json_output).to have_key("text")
      expect(json_output).to have_key("metadata")

      # Check metadata structure
      metadata = json_output["metadata"]
      expect(metadata).to have_key("finish_reason")
      expect(metadata).to have_key("input_tokens")
      expect(metadata).to have_key("output_tokens")
      expect(metadata).to have_key("took")
      expect(metadata).to have_key("provider")
      expect(metadata).to have_key("model")
      expect(metadata).to have_key("timestamp")

      # Check normalized token counts
      expect(metadata["input_tokens"]).to be_a(Integer)
      expect(metadata["output_tokens"]).to be_a(Integer)
      expect(metadata["provider"]).to eq("gemini")
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
      env = vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key)

      multiline_content = <<~PROMPT
        This is a multi-line prompt.
        It has several lines.

        And even blank lines.

        Reply with: "Multi-line received"
      PROMPT
      multiline_file = create_temp_file(multiline_content, extension: ".txt")

      stdout, stderr, status = execute_gem_executable(exe_name, [multiline_file], env: env)

      expect(status).to be_success
      expect(stderr).to be_empty
      expect(stdout).to include("Multi-line received")
    end
  end

  describe "performance and reliability" do
    it "completes requests within reasonable time", :vcr do
      cassette_name = "llm_gemini_query_integration/completes_requests_within_reasonable_time"
      env = vcr_subprocess_env(cassette_name, "GEMINI_API_KEY" => api_key)

      start_time = Time.now

      stdout, stderr, status = execute_gem_executable(exe_name, ["Say hello quickly"], env: env)

      duration = Time.now - start_time

      expect(status).to be_success
      expect(duration).to be < test_timeout
      expect(stdout.strip).not_to be_empty
    end

    it "handles concurrent requests gracefully" do
      skip "Concurrent test - only run when explicitly testing performance"

      # This test would make multiple concurrent requests
      # Skipped by default to avoid hitting rate limits during normal testing
    end
  end
end
