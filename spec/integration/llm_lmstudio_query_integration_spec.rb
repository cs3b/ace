# frozen_string_literal: true

require "spec_helper"
require "aruba/rspec"

RSpec.describe "llm-lmstudio-query integration", type: :aruba do
  include ProcessHelpers
  let(:exe_path) { File.expand_path("../../exe/llm-lmstudio-query", __dir__) }
  let(:ruby_path) { RbConfig.ruby }

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

  # VCR-wrapped helper to check LM Studio availability
  def lm_studio_available?
    VCR.use_cassette("lm_studio_availability_check", record: :once) do
      require "net/http"
      uri = URI("http://localhost:1234/v1/models")
      response = Net::HTTP.get_response(uri)
      response.code == "200"
    end
  rescue
    false
  end

  describe "command execution" do
    it "shows help when requested" do
      run_command("#{ruby_path} #{exe_path} --help")

      expect(last_command_started).to have_exit_status(0)
      expect(last_command_started).to have_output(/Query LM Studio AI with a prompt/)
      expect(last_command_started).to have_output(/--format/)
      expect(last_command_started).to have_output(/--\[no-\]debug/)
      expect(last_command_started).to have_output(/--model/)
      expect(last_command_started).to have_output(/Examples:/)
    end

    it "requires a prompt argument" do
      run_command("#{ruby_path} #{exe_path}")

      expect(last_command_started).to have_exit_status(1)
      expect(last_command_started).to have_output(/ERROR: "llm-lmstudio-query" was called with no arguments/)
    end
  end

  describe "API integration" do
    context "with LM Studio server available" do
      # Skip these tests if LM Studio server is not running
      before do
        skip "LM Studio server not available at localhost:1234" unless lm_studio_available?
      end

      it "queries LM Studio with a simple prompt", :vcr do
        cassette_name = "llm_lmstudio_query_integration/queries_lm_studio_with_simple_prompt"
        setup_vcr_env(cassette_name)

        run_command("#{ruby_path} #{exe_path} 'What is 2+2? Reply with just the number.'")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started).to have_output(/4/)
        expect(last_command_started.stderr).to be_empty
      end

      it "outputs JSON format when requested", :vcr do
        cassette_name = "llm_lmstudio_query_integration/outputs_json_format"
        setup_vcr_env(cassette_name)

        run_command("#{ruby_path} #{exe_path} 'Say hello' --format json")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty

        json_output = JSON.parse(last_command_started.stdout)
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
        expect(json_output["metadata"]["provider"]).to eq("lmstudio")
      end

      it "reads prompt from file", :vcr do
        cassette_name = "llm_lmstudio_query_integration/reads_prompt_from_file"
        setup_vcr_env(cassette_name)

        write_file("prompt.txt", "What is the capital of France? Reply with just the city name.")

        run_command("#{ruby_path} #{exe_path} prompt.txt")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty
        expect(last_command_started).to have_output(/Paris/i)
      end

      it "uses custom model when specified", :vcr do
        cassette_name = "llm_lmstudio_query_integration/uses_custom_model"
        setup_vcr_env(cassette_name)

        # Use default model for testing model override
        run_command("#{ruby_path} #{exe_path} 'Hi' --model mistralai/devstral-small-2505 --format json")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty

        json_output = JSON.parse(last_command_started.stdout)
        expect(json_output["text"]).not_to be_empty
      end

      it "applies temperature setting", :vcr do
        cassette_name = "llm_lmstudio_query_integration/applies_temperature_setting"
        setup_vcr_env(cassette_name)

        # Low temperature should give more consistent results
        run_command("#{ruby_path} #{exe_path} 'Complete this: The sky is' --temperature 0.1")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stdout.strip).not_to be_empty
      end

      it "respects max tokens limit", :vcr do
        cassette_name = "llm_lmstudio_query_integration/respects_max_tokens"
        setup_vcr_env(cassette_name)

        run_command("#{ruby_path} #{exe_path} 'Write a very long story about a dragon' --max-tokens 50 --format json")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty

        json_output = JSON.parse(last_command_started.stdout)
        # The output should be truncated due to token limit
        expect(json_output["text"].split.size).to be < 100
      end

      it "uses system instruction", :vcr do
        cassette_name = "llm_lmstudio_query_integration/uses_system_instruction"
        setup_vcr_env(cassette_name)

        run_command("#{ruby_path} #{exe_path} 'Hello' --system 'You are a helpful assistant. Always respond with enthusiasm.'")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty
        # Should contain enthusiastic language
        expect(last_command_started.stdout).not_to be_empty
      end
    end

    context "with LM Studio server unavailable" do
      it "shows error message when server is not running" do
        # Mock the server check to return false
        run_command("#{ruby_path} -e \"
          require 'webmock'
          WebMock.enable!
          WebMock.stub_request(:get, 'http://localhost:1234/v1/models').to_raise(Errno::ECONNREFUSED)
          load '#{exe_path}'
        \" 'Test prompt'")

        expect(last_command_started).not_to have_exit_status(0)
        expect(last_command_started.stderr).to include("Error:")
        expect(last_command_started.stderr).to match(/LM Studio server.*not available/i)
      end

      it "shows detailed error with debug flag when server unavailable" do
        # Mock the server check to return connection refused
        run_command("#{ruby_path} -e \"
          require 'webmock'
          WebMock.enable!
          WebMock.stub_request(:get, 'http://localhost:1234/v1/models').to_raise(Errno::ECONNREFUSED)
          load '#{exe_path}'
        \" 'Test prompt' --debug")

        expect(last_command_started).not_to have_exit_status(0)
        expect(last_command_started.stderr).to include("Error:")
        expect(last_command_started.stderr).to include("Backtrace:")
      end
    end
  end

  describe "error handling" do
    it "treats malformed JSON as inline content and queries AI", :vcr do
      temp_dir = Dir.mktmpdir("lmstudio_test")
      malformed_file = File.join(temp_dir, "malformed.json")
      File.write(malformed_file, '{"invalid": json}')

      env = vcr_subprocess_env("llm-lmstudio-query integration/error handling/treats malformed JSON as inline content and queries AI")
      stdout, stderr, status = execute_gem_executable("llm-lmstudio-query", [malformed_file], env: env)

      expect(status).to be_success, "Command failed: #{stderr}"
      expect(stderr).to be_empty
      # Should respond with AI text about the content
      expect(stdout).not_to be_empty
    ensure
      FileUtils.remove_entry(temp_dir) if temp_dir && Dir.exist?(temp_dir)
    end

    it "treats non-existent file path as inline content", :vcr do
      env = vcr_subprocess_env("llm-lmstudio-query integration/error handling/treats non-existent file path as inline content")
      stdout, stderr, status = execute_gem_executable("llm-lmstudio-query", ["/non/existent/file.txt"], env: env)

      expect(status).to be_success, "Command failed: #{stderr}"
      expect(stderr).to be_empty
      # Should respond with AI text about the file path
      expect(stdout).not_to be_empty
    end

    it "handles empty file by treating it as empty prompt", :vcr do
      temp_dir = Dir.mktmpdir("lmstudio_test")
      empty_file = File.join(temp_dir, "empty.txt")
      File.write(empty_file, "")

      env = vcr_subprocess_env("llm-lmstudio-query integration/error handling/handles empty file by treating it as empty prompt")
      stdout, stderr, status = execute_gem_executable("llm-lmstudio-query", [empty_file], env: env)

      expect(status).to be_success, "Command failed: #{stderr}"
      expect(stderr).to be_empty
      # Should respond with AI's helpful default message
      expect(stdout).not_to be_empty
    ensure
      FileUtils.remove_entry(temp_dir) if temp_dir && Dir.exist?(temp_dir)
    end
  end

  describe "output formats" do
    context "with LM Studio available" do
      before do
        skip "LM Studio server not available" unless lm_studio_available?
      end

      it "outputs clean text by default", :vcr do
        cassette_name = "llm_lmstudio_query_integration/outputs_clean_text_by_default"
        setup_vcr_env(cassette_name)

        run_command("#{ruby_path} #{exe_path} 'Reply with exactly: Hello World'")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty
        expect(last_command_started.stdout.strip).to include("Hello World")
        # Should not contain JSON formatting
        expect(last_command_started.stdout).not_to include("{")
        expect(last_command_started.stdout).not_to include("}")
      end

      it "outputs valid JSON with metadata when requested", :vcr do
        cassette_name = "llm_lmstudio_query_integration/outputs_valid_json_with_metadata"
        setup_vcr_env(cassette_name)

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
        expect(metadata).to have_key("input_tokens")
        expect(metadata).to have_key("output_tokens")
        expect(metadata).to have_key("took")
        expect(metadata).to have_key("provider")
        expect(metadata).to have_key("model")
        expect(metadata).to have_key("timestamp")

        # Check normalized token counts
        expect(metadata["input_tokens"]).to be_a(Integer)
        expect(metadata["output_tokens"]).to be_a(Integer)
        expect(metadata["provider"]).to eq("lmstudio")
      end
    end
  end

  describe "complex prompts" do
    context "with LM Studio available" do
      before do
        skip "LM Studio server not available" unless lm_studio_available?
      end

      it "handles multi-line prompts from file", :vcr do
        cassette_name = "llm_lmstudio_query_integration/handles_multiline_prompts_from_file"
        setup_vcr_env(cassette_name)

        write_file("multiline.txt", <<~PROMPT)
          This is a multi-line prompt.
          It has several lines.

          And even blank lines.

          Reply with: "Multi-line received"
        PROMPT

        run_command("#{ruby_path} #{exe_path} multiline.txt")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty
        expect(last_command_started.stdout).to include("Multi-line received")
      end

      it "handles prompts with special characters", :vcr do
        cassette_name = "llm_lmstudio_query_integration/handles_prompts_with_special_characters"
        setup_vcr_env(cassette_name)

        run_command("#{ruby_path} #{exe_path} 'Echo this exactly: Special chars @#$%&*()_+={[}]|\\:;\"<,>.?/'")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty
        # LM Studio should handle special characters
        expect(last_command_started.stdout.strip).not_to be_empty
      end

      it "handles Unicode prompts", :vcr do
        cassette_name = "llm_lmstudio_query_integration/handles_unicode_prompts"
        setup_vcr_env(cassette_name)

        run_command("#{ruby_path} #{exe_path} 'Translate to English: こんにちは'")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty
        expect(last_command_started.stdout.downcase).to match(/hello|hi|good|translation/)
      end

      it "handles very long prompts", :vcr do
        cassette_name = "llm_lmstudio_query_integration/handles_very_long_prompts"
        setup_vcr_env(cassette_name)

        long_prompt = "Please summarize this text: " + ("Lorem ipsum dolor sit amet, consectetur adipiscing elit. " * 50)

        run_command("#{ruby_path} #{exe_path} '#{long_prompt}' --format json")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stderr).to be_empty

        json_output = JSON.parse(last_command_started.stdout)
        expect(json_output["text"]).not_to be_empty
      end
    end
  end

  describe "performance and reliability" do
    context "with LM Studio available" do
      before do
        skip "LM Studio server not available" unless lm_studio_available?
      end

      it "completes requests within reasonable time", :vcr do
        cassette_name = "llm_lmstudio_query_integration/completes_requests_within_reasonable_time"
        setup_vcr_env(cassette_name)

        start_time = Time.now

        run_command("#{ruby_path} #{exe_path} 'Say hello quickly'")

        duration = Time.now - start_time

        expect(last_command_started).to have_exit_status(0)
        expect(duration).to be < 180 # 3 minute timeout for local model inference
        expect(last_command_started.stdout.strip).not_to be_empty
      end
    end
  end

  describe "model management" do
    context "with LM Studio available" do
      before do
        skip "LM Studio server not available" unless lm_studio_available?
      end

      it "works with default model", :vcr do
        cassette_name = "llm_lmstudio_query_integration/works_with_default_model"
        setup_vcr_env(cassette_name)

        run_command("#{ruby_path} #{exe_path} 'Test default model'")

        expect(last_command_started).to have_exit_status(0)
        expect(last_command_started.stdout.strip).not_to be_empty
      end
    end
  end
end
