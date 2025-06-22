# frozen_string_literal: true

require "spec_helper"

RSpec.describe "llm-openai-query integration", type: :integration do
  include ProcessHelpers

  let(:exe_name) { "llm-openai-query" }
  let(:api_key) { EnvHelper.openai_api_key }

  describe "command execution" do
    it "shows help when requested" do
      stdout, stderr, status = execute_gem_executable(exe_name, ["--help"])

      expect(status).to be_success
      expect(stdout).to match(/Query OpenAI API with a prompt/)
      expect(stdout).to match(/--format/)
      expect(stdout).to match(/--\[no-\]debug/)
      expect(stdout).to match(/--model/)
      expect(stdout).to match(/Examples:/)
      expect(stderr).to be_empty
    end

    it "requires a prompt argument" do
      stdout, stderr, status = execute_gem_executable(exe_name, [])

      expect(status.exitstatus).to eq(1)
      expect(stderr).to match(/ERROR: "llm-openai-query" was called with no arguments/)
    end
  end

  describe "API integration" do
    context "with valid API key" do
      it "queries OpenAI with a simple prompt", :vcr do
        cassette_name = "llm_openai_query_integration/queries_openai_with_simple_prompt"
        env = vcr_subprocess_env(cassette_name, "OPENAI_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["What is 2+2? Reply with just the number."], env: env)

        expect(status).to be_success
        expect(stdout).to match(/4/)
        expect(stderr).to be_empty
      end

      it "outputs JSON format when requested", :vcr do
        cassette_name = "llm_openai_query_integration/outputs_json_format"
        env = vcr_subprocess_env(cassette_name, "OPENAI_API_KEY" => api_key)

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
        expect(json_output["metadata"]["provider"]).to eq("openai")
      end

      it "reads prompt from file", :vcr do
        cassette_name = "llm_openai_query_integration/reads_prompt_from_file"
        env = vcr_subprocess_env(cassette_name, "OPENAI_API_KEY" => api_key)

        prompt_file = create_temp_file("What is the capital of France? Reply with just the city name.", extension: ".txt")

        stdout, stderr, status = execute_gem_executable(exe_name, [prompt_file], env: env)

        expect(status).to be_success
        expect(stdout).to match(/Paris/i)
        expect(stderr).to be_empty
      end

      it "supports custom model selection", :vcr do
        cassette_name = "llm_openai_query_integration/supports_custom_model"
        env = vcr_subprocess_env(cassette_name, "OPENAI_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["Count from 1 to 3", "--model", "gpt-4o-mini"], env: env)

        expect(status).to be_success
        expect(stdout).to match(/1.*2.*3/m)
        expect(stderr).to be_empty
      end

      it "supports custom temperature", :vcr do
        cassette_name = "llm_openai_query_integration/supports_custom_temperature"
        env = vcr_subprocess_env(cassette_name, "OPENAI_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["What is 1+1? Answer with just the number.", "--temperature", "0.0"], env: env)

        expect(status).to be_success
        expect(stdout).to match(/2/)
        expect(stderr).to be_empty
      end

      it "supports output to file", :vcr do
        cassette_name = "llm_openai_query_integration/supports_output_to_file"
        env = vcr_subprocess_env(cassette_name, "OPENAI_API_KEY" => api_key)

        output_file = create_temp_file("", extension: ".txt")

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["Say hello world", "--output", output_file], env: env)

        expect(status).to be_success
        expect(stderr).to be_empty

        output_content = File.read(output_file)
        expect(output_content).to match(/hello.*world/i)
      end

      it "supports system instruction", :vcr do
        cassette_name = "llm_openai_query_integration/supports_system_instruction"
        env = vcr_subprocess_env(cassette_name, "OPENAI_API_KEY" => api_key)

        stdout, stderr, status = execute_gem_executable(exe_name,
          ["What is 2+2?", "--system", "You are a calculator. Only respond with numbers."], env: env)

        expect(status).to be_success
        expect(stdout).to match(/4/)
        expect(stderr).to be_empty
      end
    end

    context "with invalid API key" do
      it "shows authentication error" do
        env = vcr_subprocess_env("llm_openai_query_integration/invalid_api_key", "OPENAI_API_KEY" => "invalid-key")

        stdout, stderr, status = execute_gem_executable(exe_name, ["Hello"], env: env)

        expect(status.exitstatus).to eq(1)
        expect(stderr).to match(/Error.*API.*[Aa]uth|[Ii]nvalid.*key|[Uu]nauthorized/i)
      end
    end
  end
end
