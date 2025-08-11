# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"
require "json"
require "yaml"
require_relative "../support/env_helper"

RSpec.describe "LLM File I/O Integration", type: :integration do
  include CliHelpers

  let(:temp_dir) { Dir.mktmpdir("llm_integration_test") }
  let(:prompt_file) { File.join(temp_dir, "test_prompt.txt") }
  let(:system_file) { File.join(temp_dir, "system_prompt.md") }
  let(:output_file) { File.join(temp_dir, "output") }

  before do
    # Create test prompt file
    File.write(prompt_file, "What is the capital of France?")

    # Create test system file
    File.write(system_file, "You are a helpful geography assistant.")
  end

  after do
    safe_directory_cleanup(temp_dir) if Dir.exist?(temp_dir)
  end

  # Use VCR for predictable API responses
  let(:api_key) { EnvHelper.google_api_key }

  describe "Google query command" do
    context "with file input and output" do
      it "reads prompt from file and writes JSON output", :vcr do
        json_output = "#{output_file}.json"

        cassette_name = "llm_file_io_integration/google_query_command/with_file_input_and_output/reads_prompt_from_file_and_writes_JSON_output"
        env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
        _, stderr, status = execute_gem_executable("llm-query", ["google", prompt_file, "--output", json_output], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        expect(File.exist?(json_output)).to be true

        content = File.read(json_output)
        parsed = JSON.parse(content)

        expect(parsed["text"]).to be_a(String)
        expect(parsed["metadata"]).to include(
          "provider" => "google"
        )
        expect(parsed["metadata"]["input_tokens"]).to be_a(Integer)
        expect(parsed["metadata"]["output_tokens"]).to be_a(Integer)
      end

      xit "reads prompt from file and writes Markdown output", :vcr do
        md_output = "#{output_file}.md"

        cassette_name = "llm_file_io_integration/google_query_command/with_file_input_and_output/reads_prompt_from_file_and_writes_Markdown_output"
        env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
        _, stderr, status = execute_gem_executable("llm-query", ["google", prompt_file, "--output", md_output], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        expect(File.exist?(md_output)).to be true

        content = File.read(md_output)

        expect(content).to include("---")
        expect(content).to be_a(String)

        # Parse YAML front matter
        lines = content.split("\n")
        yaml_end = lines[1..].index("---")
        expect(yaml_end).not_to be_nil, "Expected YAML front matter closing '---' not found"

        yaml_content = lines[1...yaml_end + 1].join("\n")
        metadata = YAML.safe_load(yaml_content)
        expect(metadata).not_to be_nil, "YAML metadata should not be nil"

        expect(metadata["provider"]).to eq("google")
        expect(metadata["input_tokens"]).to be_a(Integer)
      end

      it "reads prompt from file and writes text output", :vcr do
        txt_output = "#{output_file}.txt"

        cassette_name = "llm_file_io_integration/google_query_command/with_file_input_and_output/reads_prompt_from_file_and_writes_text_output"
        env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
        _, stderr, status = execute_gem_executable("llm-query", ["google", prompt_file, "--output", txt_output], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        expect(File.exist?(txt_output)).to be true

        content = File.read(txt_output)
        expect(content.strip).to be_a(String)
        expect(content.strip).not_to be_empty
      end

      it "uses format flag to override file extension", :vcr do
        txt_output = "#{output_file}.txt"

        cassette_name = "llm_file_io_integration/google_query_command/with_file_input_and_output/uses_format_flag_to_override_file_extension"
        env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
        _, stderr, status = execute_gem_executable("llm-query", ["google", prompt_file, "--output", txt_output, "--format", "json"], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        expect(File.exist?(txt_output)).to be true

        content = File.read(txt_output)
        parsed = JSON.parse(content)

        expect(parsed["text"]).to be_a(String)
        expect(parsed["metadata"]["provider"]).to eq("google")
      end

      it "reads both prompt and system from files", :vcr do
        json_output = "#{output_file}.json"

        cassette_name = "llm_file_io_integration/google_query_command/with_file_input_and_output/reads_both_prompt_and_system_from_files"
        env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
        _, stderr, status = execute_gem_executable("llm-query", ["google", prompt_file, "--system", system_file, "--output", json_output], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        expect(File.exist?(json_output)).to be true

        content = File.read(json_output)
        parsed = JSON.parse(content)

        expect(parsed["text"]).to be_a(String)
        expect(parsed["metadata"]["provider"]).to eq("google")
      end
    end

    context "with inline content" do
      it "processes inline prompt and writes to file", :vcr do
        json_output = "#{output_file}.json"

        cassette_name = "llm_file_io_integration/google_query_command/with_inline_content/processes_inline_prompt_and_writes_to_file"
        env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
        _, stderr, status = execute_gem_executable("llm-query", ["google", "What is 2+2?", "--output", json_output], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        expect(File.exist?(json_output)).to be true

        content = File.read(json_output)
        parsed = JSON.parse(content)

        expect(parsed["text"]).to be_a(String)
        expect(parsed["metadata"]["provider"]).to eq("google")
      end

      it "processes inline prompt with inline system instruction", :vcr do
        json_output = "#{output_file}.json"

        cassette_name = "llm_file_io_integration/google_query_command/with_inline_content/processes_inline_prompt_with_inline_system_instruction"
        env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
        _, stderr, status = execute_gem_executable("llm-query", ["google", "What is 2+2?", "--system", "Be concise", "--output", json_output], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        expect(File.exist?(json_output)).to be true
      end
    end

    context "with mixed file and inline content" do
      it "reads prompt from file and uses inline system instruction", :vcr do
        json_output = "#{output_file}.json"

        cassette_name = "llm_file_io_integration/google_query_command/with_mixed_file_and_inline_content/reads_prompt_from_file_and_uses_inline_system_instruction"
        env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
        _, stderr, status = execute_gem_executable("llm-query", ["google", prompt_file, "--system", "Be very detailed", "--output", json_output], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        expect(File.exist?(json_output)).to be true
      end

      it "uses inline prompt and reads system from file", :vcr do
        json_output = "#{output_file}.json"

        cassette_name = "llm_file_io_integration/google_query_command/with_mixed_file_and_inline_content/uses_inline_prompt_and_reads_system_from_file"
        env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
        _, stderr, status = execute_gem_executable("llm-query", ["google", "Quick question", "--system", system_file, "--output", json_output], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        expect(File.exist?(json_output)).to be true
      end
    end

    context "with stdout output" do
      it "outputs JSON format to stdout", :vcr do
        cassette_name = "llm_file_io_integration/google_query_command/with_stdout_output/outputs_JSON_format_to_stdout"
        env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
        stdout, stderr, status = execute_gem_executable("llm-query", ["google", "Test prompt", "--format", "json"], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        parsed = JSON.parse(stdout)
        expect(parsed["text"]).to be_a(String)
        expect(parsed["metadata"]["provider"]).to eq("google")
      end

      it "outputs text format to stdout by default", :vcr do
        cassette_name = "llm_file_io_integration/google_query_command/with_stdout_output/outputs_text_format_to_stdout_by_default"
        env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
        stdout, stderr, status = execute_gem_executable("llm-query", ["google", "Test prompt"], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        expect(stdout.strip).to be_a(String)
        expect(stdout.strip).not_to be_empty
      end
    end
  end

  describe "LMStudio query command" do
    context "with file input and output" do
      it "reads prompt from file and writes JSON output", :vcr do
        json_output = "#{output_file}.json"

        cassette_name = "llm_file_io_integration/lmstudio/reads_prompt_file_writes_json"
        env = vcr_subprocess_env(cassette_name)
        _, stderr, status = execute_gem_executable("llm-query", ["lmstudio", prompt_file, "--output", json_output], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        expect(File.exist?(json_output)).to be true

        content = File.read(json_output)
        parsed = JSON.parse(content)

        expect(parsed["text"]).to be_a(String)
        expect(parsed["metadata"]).to include(
          "provider" => "lmstudio"
        )
        expect(parsed["metadata"]["input_tokens"]).to be_a(Integer)
        expect(parsed["metadata"]["output_tokens"]).to be_a(Integer)
      end

      xit "reads prompt from file and writes Markdown output", :vcr do
        md_output = "#{output_file}.md"

        cassette_name = "llm_file_io_integration/lmstudio/reads_prompt_file_writes_markdown"
        env = vcr_subprocess_env(cassette_name)
        _, stderr, status = execute_gem_executable("llm-query", ["lmstudio", prompt_file, "--output", md_output], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        expect(File.exist?(md_output)).to be true

        content = File.read(md_output)

        expect(content).to include("---")
        expect(content).to be_a(String)

        # Parse YAML front matter
        lines = content.split("\n")
        yaml_end = lines[1..].index("---")
        expect(yaml_end).not_to be_nil, "Expected YAML front matter closing '---' not found"

        yaml_content = lines[1...yaml_end + 1].join("\n")
        metadata = YAML.safe_load(yaml_content)
        expect(metadata).not_to be_nil, "YAML metadata should not be nil"

        expect(metadata["provider"]).to eq("lmstudio")
        expect(metadata["input_tokens"]).to be_a(Integer)
      end
    end

    context "with stdout output" do
      it "outputs JSON format to stdout", :vcr do
        cassette_name = "llm_file_io_integration/lmstudio/outputs_json_to_stdout"
        env = vcr_subprocess_env(cassette_name)
        stdout, stderr, status = execute_gem_executable("llm-query", ["lmstudio", "Test prompt", "--format", "json"], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        parsed = JSON.parse(stdout)
        expect(parsed["text"]).to be_a(String)
        expect(parsed["metadata"]["provider"]).to eq("lmstudio")
      end

      it "outputs text format to stdout by default", :vcr do
        cassette_name = "llm_file_io_integration/lmstudio/outputs_text_to_stdout"
        env = vcr_subprocess_env(cassette_name)
        stdout, stderr, status = execute_gem_executable("llm-query", ["lmstudio", "Test prompt"], env: env)

        expect(status).to be_success, "Command failed: #{stderr}"
        expect(stdout.strip).to be_a(String)
        expect(stdout.strip).not_to be_empty
      end
    end
  end

  describe "Error handling" do
    it "handles non-existent input files gracefully", :vcr do
      non_existent = "/tmp/does_not_exist_test_file.txt"
      json_output = "#{output_file}.json"

      # Non-existent files should be treated as inline content
      cassette_name = "llm_file_io_integration/error_handling/handles_non-existent_input_files_gracefully"
      env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
      _, stderr, status = execute_gem_executable("llm-query", ["google", non_existent, "--output", json_output], env: env)

      expect(status).to be_success, "Command failed: #{stderr}"
      expect(File.exist?(json_output)).to be true
    end

    it "creates output directories automatically", :vcr do
      nested_output = File.join(temp_dir, "nested", "deep", "output.json")

      cassette_name = "llm_file_io_integration/error_handling/creates_output_directories_automatically"
      env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
      _, stderr, status = execute_gem_executable("llm-query", ["google", "Test", "--output", nested_output], env: env)

      expect(status).to be_success, "Command failed: #{stderr}"
      expect(File.exist?(nested_output)).to be true
    end

    it "handles invalid format gracefully" do
      env = {"GOOGLE_API_KEY" => api_key}
      result = execute_cli_command("llm-query", ["google", "Test", "--format", "invalid"], env: env)

      expect(result).not_to be_success, "Command should have failed"
      combined_output = "#{result.stdout}#{result.stderr}"
      expect(combined_output).to include("ERROR")
    end
  end

  describe "Format inference" do
    it "infers JSON format from .json extension", :vcr do
      json_output = "#{output_file}.json"

      cassette_name = "llm_file_io_integration/format_inference/infers_JSON_format_from_json_extension"
      env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
      _, stderr, status = execute_gem_executable("llm-query", ["google", "Test", "--output", json_output], env: env)

      expect(status).to be_success, "Command failed: #{stderr}"
      content = File.read(json_output)
      expect { JSON.parse(content) }.not_to raise_error
    end

    it "infers Markdown format from .md extension", :vcr do
      md_output = "#{output_file}.md"

      cassette_name = "llm_file_io_integration/format_inference/infers_Markdown_format_from_md_extension"
      env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
      _, stderr, status = execute_gem_executable("llm-query", ["google", "Test", "--output", md_output], env: env)

      expect(status).to be_success, "Command failed: #{stderr}"
      content = File.read(md_output)
      expect(content).to include("---") # YAML front matter
    end

    it "defaults to text format for unknown extensions", :vcr do
      unknown_output = "#{output_file}.xyz"

      cassette_name = "llm_file_io_integration/format_inference/defaults_to_text_format_for_unknown_extensions"
      env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
      _, stderr, status = execute_gem_executable("llm-query", ["google", "Test", "--output", unknown_output], env: env)

      expect(status).to be_success, "Command failed: #{stderr}"
      content = File.read(unknown_output)
      expect(content.strip).to be_a(String)
      expect(content.strip).not_to be_empty
    end
  end

  describe "Metadata normalization" do
    it "normalizes Google metadata correctly", :vcr do
      json_output = "#{output_file}.json"

      cassette_name = "llm_file_io_integration/metadata_normalization/normalizes_Google_metadata_correctly"
      env = vcr_subprocess_env(cassette_name, {"GOOGLE_API_KEY" => api_key})
      _, stderr, status = execute_gem_executable("llm-query", ["google", "Test", "--output", json_output], env: env)

      expect(status).to be_success, "Command failed: #{stderr}"
      content = File.read(json_output)
      parsed = JSON.parse(content)
      metadata = parsed["metadata"]

      expect(metadata).to include(
        "provider" => "google"
      )
      expect(metadata["finish_reason"]).to be_a(String)
      expect(metadata["input_tokens"]).to be_a(Integer)
      expect(metadata["output_tokens"]).to be_a(Integer)
      expect(metadata["total_tokens"]).to be_a(Integer)
      expect(metadata["took"]).to be_a(Numeric)
      expect(metadata["timestamp"]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end

    it "normalizes LMStudio metadata correctly", :vcr do
      json_output = "#{output_file}.json"

      cassette_name = "llm_file_io_integration/lmstudio/normalizes_metadata"
      env = vcr_subprocess_env(cassette_name)
      _, stderr, status = execute_gem_executable("llm-query", ["lmstudio", "Test", "--output", json_output], env: env)

      expect(status).to be_success, "Command failed: #{stderr}"
      content = File.read(json_output)
      parsed = JSON.parse(content)
      metadata = parsed["metadata"]

      expect(metadata).to include(
        "provider" => "lmstudio"
      )
      expect(metadata["finish_reason"]).to be_a(String)
      expect(metadata["input_tokens"]).to be_a(Integer)
      expect(metadata["output_tokens"]).to be_a(Integer)
      expect(metadata["total_tokens"]).to be_a(Integer)
      expect(metadata["took"]).to be_a(Numeric)
      expect(metadata["timestamp"]).to match(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z/)
    end
  end
end
