# frozen_string_literal: true

require "spec_helper"

RSpec.describe "llm-google-query integration", type: :integration do
  include ProcessHelpers

  let(:exe_name) { "llm-google-query" }
  let(:api_key) { EnvHelper.google_api_key }

  describe "command execution" do
    it "shows help when requested" do
      stdout, stderr, status = execute_gem_executable(exe_name, ["--help"])

      expect(status).to be_success
      expect(stdout).to match(/Query Google AI with a prompt/)
      expect(stdout).to match(/--format/)
      expect(stdout).to match(/--\[no-\]debug/)
      expect(stdout).to match(/--model/)
      expect(stdout).to match(/Examples:/)
      expect(stderr).to be_empty
    end

    it "requires a prompt argument" do
      _, stderr, status = execute_gem_executable(exe_name, [])

      expect(status.exitstatus).to eq(1)
      expect(stderr).to match(/ERROR: "llm-google-query" was called with no arguments/)
    end
  end

  describe "API integration" do
    context "with valid API key" do
      it "queries Google with a simple prompt", :vcr do
        cassette_name = "llm_google_query_integration/queries_google_with_simple_prompt"
        env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["What is 2+2? Reply with just the number."], env: env)

        expect(status).to be_success
        expect(stdout).to match(/4/)
        expect(stderr).to be_empty
      end

      it "outputs JSON format when requested", :vcr do
        cassette_name = "llm_google_query_integration/outputs_json_format"
        env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

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
        expect(json_output["metadata"]["provider"]).to eq("google")
      end

      it "reads prompt from file", :vcr do
        cassette_name = "llm_google_query_integration/reads_prompt_from_file"
        env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

        prompt_file = create_temp_file("What is the capital of France? Reply with just the city name.", extension: ".txt")

        stdout, stderr, status = execute_gem_executable(exe_name, [prompt_file], env: env)

        expect(status).to be_success
        expect(stdout).to match(/Paris/i)
        expect(stderr).to be_empty
      end

      it "supports custom model selection", :vcr do
        cassette_name = "llm_google_query_integration/supports_custom_model"
        env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["Count from 1 to 3", "--model", "gemini-1.5-flash"], env: env)

        expect(status).to be_success
        expect(stdout).to match(/1.*2.*3/m)
        expect(stderr).to be_empty
      end

      it "supports custom temperature", :vcr do
        cassette_name = "llm_google_query_integration/supports_custom_temperature"
        env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["What is 1+1? Answer with just the number.", "--temperature", "0.0"], env: env)

        expect(status).to be_success
        expect(stdout).to match(/2/)
        expect(stderr).to be_empty
      end

      it "supports max tokens", :vcr do
        cassette_name = "llm_google_query_integration/supports_max_tokens"
        env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["Write a long essay about artificial intelligence.", "--max-tokens", "50"], env: env)

        expect(status).to be_success
        expect(stdout).not_to be_empty
        expect(stderr).to be_empty
      end

      it "supports output to file", :vcr do
        cassette_name = "llm_google_query_integration/supports_output_to_file"
        env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

        output_file = create_temp_file("", extension: ".json")

        _, stderr, status = execute_gem_executable(exe_name,
          ["Say hello world", "--output", output_file], env: env)

        expect(status).to be_success
        expect(stderr).to be_empty

        output_content = File.read(output_file)
        expect(output_content).not_to be_empty

        # Should be JSON format inferred from extension
        parsed = JSON.parse(output_content)
        expect(parsed).to have_key("text")
        expect(parsed).to have_key("metadata")
        expect(parsed["text"]).to match(/hello.*world/i)
      end

      it "supports system instruction", :vcr do
        cassette_name = "llm_google_query_integration/supports_system_instruction"
        env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["What is 2+2?", "--system", "You are a calculator. Only respond with numbers."], env: env)

        expect(status).to be_success
        expect(stdout).to match(/4/)
        expect(stderr).to be_empty
      end

      it "handles unicode prompts", :vcr do
        cassette_name = "llm_google_query_integration/handles_unicode_prompts"
        env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["What does 'Hëllö Wörld' mean?"], env: env)

        expect(status).to be_success
        expect(stdout).not_to be_empty
        expect(stderr).to be_empty
      end

      it "handles prompts with special characters", :vcr do
        cassette_name = "llm_google_query_integration/handles_special_characters"
        env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["What does 'Hello, World!' mean in programming?"], env: env)

        expect(status).to be_success
        expect(stdout).not_to be_empty
        expect(stderr).to be_empty
      end

      it "handles multiline prompts from file", :vcr do
        cassette_name = "llm_google_query_integration/handles_multiline_prompts"
        env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

        multiline_content = "Explain the following concepts:\n1. Quantum entanglement\n2. Superposition"
        prompt_file = create_temp_file(multiline_content, extension: ".txt")

        stdout, stderr, status = execute_gem_executable(exe_name, [prompt_file], env: env)

        expect(status).to be_success
        expect(stdout).not_to be_empty
        expect(stderr).to be_empty
      end

      it "completes requests within reasonable time", :vcr do
        cassette_name = "llm_google_query_integration/completes_within_time"
        env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

        start_time = Time.now

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["What is 2+2?"], env: env)

        end_time = Time.now
        duration = end_time - start_time

        expect(status).to be_success
        expect(stdout).not_to be_empty
        expect(stderr).to be_empty
        expect(duration).to be < 30  # Should complete within 30 seconds
      end
    end

    context "with invalid API key" do
      it "shows authentication error" do
        env = vcr_subprocess_env("llm_google_query_integration/invalid_api_key", "GOOGLE_API_KEY" => "invalid-key")

        _, stderr, status = execute_gem_executable(exe_name, ["Hello"], env: env)

        expect(status.exitstatus).to eq(1)
        expect(stderr).to match(/Error.*API.*key|Error.*Failed to query Google/i)
      end
    end

    context "with missing API key" do
      it "shows API key error" do
        env = vcr_subprocess_env("llm_google_query_integration/missing_api_key", "GOOGLE_API_KEY" => "")

        _, stderr, status = execute_gem_executable(exe_name, ["Hello"], env: env)

        expect(status.exitstatus).to eq(1)
        expect(stderr).to match(/Error.*API key not found/i)
      end
    end
  end

  describe "input validation" do
    it "handles empty file", :vcr do
      empty_file = create_temp_file("", extension: ".txt")
      cassette_name = "llm_google_query_integration/empty_file"
      env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

      stdout, stderr, status = execute_gem_executable(exe_name, [empty_file], env: env)

      # Google API accepts empty prompts, so this should succeed
      expect(status).to be_success
      expect(stdout).not_to be_empty
      expect(stderr).to be_empty
    end

    it "treats nonexistent file as inline prompt", :vcr do
      cassette_name = "llm_google_query_integration/nonexistent_file_as_prompt"
      env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

      stdout, stderr, status = execute_gem_executable(exe_name,
        ["nonexistent_file.txt"], env: env)

      expect(status).to be_success
      expect(stdout).not_to be_empty
      expect(stderr).to be_empty
    end
  end

  describe "error handling" do
    it "handles invalid arguments gracefully" do
      _, stderr, status = execute_gem_executable(exe_name, ["--invalid-option"])

      expect(status.exitstatus).to eq(1)
      expect(stderr).not_to be_empty
    end

    it "handles malformed JSON as inline prompt", :vcr do
      cassette_name = "llm_google_query_integration/malformed_json_as_prompt"
      env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

      malformed_json = '{"incomplete": '
      stdout, stderr, status = execute_gem_executable(exe_name, [malformed_json], env: env)

      expect(status).to be_success
      expect(stdout).not_to be_empty
      expect(stderr).to be_empty
    end
  end

  describe "structured output requests" do
    it "handles prompts requesting structured output", :vcr do
      cassette_name = "llm_google_query_integration/structured_output_request"
      env = vcr_subprocess_env(cassette_name, "GOOGLE_API_KEY" => api_key)

      prompt = "List 3 programming languages in JSON format with name and year fields"
      stdout, stderr, status = execute_gem_executable(exe_name, [prompt], env: env)

      expect(status).to be_success
      expect(stdout).not_to be_empty
      expect(stderr).to be_empty
    end
  end
end
