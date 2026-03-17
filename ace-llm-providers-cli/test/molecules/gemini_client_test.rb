# frozen_string_literal: true

require_relative "../test_helper"

describe "GeminiClient" do
  before do
    @client = Ace::LLM::Providers::CLI::GeminiClient.new
  end

  it "initializes with default model" do
    model = @client.instance_variable_get(:@model)
    assert_equal "gemini-2.5-flash", model
  end

  it "can be initialized with custom model" do
    client = Ace::LLM::Providers::CLI::GeminiClient.new(model: "gemini-2.5-pro")
    model = client.instance_variable_get(:@model)
    assert_equal "gemini-2.5-pro", model
  end

  it "needs_credentials? returns false" do
    refute @client.needs_credentials?
  end

  it "can list models matching gem defaults" do
    models = @client.list_models
    assert_kind_of Array, models
    assert_equal 4, models.size, "Should match .ace-defaults/llm/providers/gemini.yml"
    assert models.any? { |m| m[:id] == "gemini-2.5-flash" }
    assert models.any? { |m| m[:id] == "gemini-2.5-pro" }
    assert models.any? { |m| m[:id] == "gemini-2.0-flash" }
    assert models.any? { |m| m[:id] == "gemini-1.5-pro-latest" }
  end

  it "formats string prompts correctly" do
    prompt = "Just a string"
    formatted = @client.send(:format_messages_as_prompt, prompt)
    assert_equal "Just a string", formatted
  end

  it "formats message array without system prompt correctly" do
    messages = [
      { role: "user", content: "Hello" }
    ]

    formatted = @client.send(:format_messages_as_prompt, messages)
    assert_includes formatted, "User: Hello"
  end

  it "formats message array with system prompt correctly" do
    messages = [
      { role: "system", content: "You are helpful" },
      { role: "user", content: "Hello" }
    ]

    formatted = @client.send(:format_messages_as_prompt, messages)
    assert_includes formatted, "System: You are helpful"
    assert_includes formatted, "User: Hello"
  end

  it "formats multi-turn conversations correctly" do
    messages = [
      { role: "user", content: "Hello" },
      { role: "assistant", content: "Hi there" },
      { role: "user", content: "How are you?" }
    ]

    formatted = @client.send(:format_messages_as_prompt, messages)
    assert_includes formatted, "User: Hello"
    assert_includes formatted, "Assistant: Hi there"
    assert_includes formatted, "User: How are you?"
  end

  it "formats messages with system prompt at the beginning" do
    messages = [
      { role: "system", content: "You are helpful" },
      { role: "user", content: "Hello" },
      { role: "assistant", content: "Hi" },
      { role: "user", content: "Thanks" }
    ]

    formatted = @client.send(:format_messages_as_prompt, messages)
    assert_match(/^System: You are helpful/, formatted)
    assert_includes formatted, "User: Hello"
  end

  it "builds command with default model" do
    prompt = "Test prompt"
    cmd = @client.send(:build_gemini_command, prompt, {})

    assert_includes cmd, "gemini"
    refute_includes cmd, "--prompt"  # Uses positional argument, not --prompt flag
    refute_includes cmd, "-i"        # No interactive flag
    assert_includes cmd, "--output-format"
    assert_includes cmd, "json"
    refute_includes cmd, "--model"
    # Prompt should be in the command (as positional argument)
    assert cmd.any? { |arg| arg.include?("Test prompt") }
  end

  it "builds command with custom model" do
    client = Ace::LLM::Providers::CLI::GeminiClient.new(model: "gemini-2.5-pro")
    prompt = "Test prompt"
    cmd = client.send(:build_gemini_command, prompt, {})

    assert_includes cmd, "gemini"
    refute_includes cmd, "--prompt"  # Uses positional argument
    refute_includes cmd, "-i"        # No interactive flag
    assert_includes cmd, "--output-format"
    assert_includes cmd, "json"
    assert_includes cmd, "--model"
    assert_includes cmd, "gemini-2.5-pro"
    # Prompt should be in the command (as positional argument)
    assert cmd.any? { |arg| arg.include?("Test prompt") }
  end

  it "provider_name is 'gemini'" do
    assert_equal "gemini", Ace::LLM::Providers::CLI::GeminiClient.provider_name
  end

  describe "availability validation" do
    it "raises ProviderError when gemini CLI is not available" do
      # Stub gemini_available? to return false
      @client.stub :gemini_available?, false do
        error = assert_raises(Ace::LLM::ProviderError) do
          @client.send(:validate_gemini_availability!)
        end
        assert_match(/not found/, error.message)
        assert_match(/npm install/, error.message)
      end
    end

    it "does not raise when gemini is available" do
      # Stub availability check to return true
      @client.stub :gemini_available?, true do
        @client.send(:validate_gemini_availability!)
      end
    end
  end

  describe "generate method" do
    def stub_capture3(stdout:, stderr: "", success: true)
      mock_status = Object.new
      mock_status.define_singleton_method(:success?) { success }
      mock_status.define_singleton_method(:exitstatus) { success ? 0 : 1 }

      Ace::LLM::Providers::CLI::Molecules::SafeCapture.stub(:call, lambda { |*_args, **_kwargs| [stdout, stderr, mock_status] }) do
        yield
      end
    end

    it "parses JSON response correctly" do
      json_response = {
        "response" => "Hello, world!",
        "stats" => {
          "tokens" => {
            "promptTokens" => 10,
            "candidatesTokens" => 5
          }
        }
      }.to_json

      @client.stub(:gemini_available?, true) do
        stub_capture3(stdout: json_response) do
          result = @client.generate("Hi")
          assert_equal "Hello, world!", result[:text]
          assert_equal 10, result[:metadata][:input_tokens]
          assert_equal 5, result[:metadata][:output_tokens]
          assert_equal "gemini-2.5-flash", result[:metadata][:model]
        end
      end
    end

    it "falls back to raw text when JSON parsing fails" do
      raw_text = "This is plain text output"

      @client.stub(:gemini_available?, true) do
        stub_capture3(stdout: raw_text) do
          result = @client.generate("Hi")
          assert_equal "This is plain text output", result[:text]
          assert_kind_of Integer, result[:metadata][:total_tokens]
        end
      end
    end

    it "raises ProviderError on CLI failure" do
      @client.stub(:gemini_available?, true) do
        stub_capture3(stdout: "", stderr: "CLI error", success: false) do
          error = assert_raises(Ace::LLM::ProviderError) do
            @client.generate("Hi")
          end
          assert_match(/CLI failed/, error.message)
        end
      end
    end

    it "builds synthetic metadata when tokens not in JSON" do
      json_response = {
        "response" => "Test response"
      }.to_json

      @client.stub(:gemini_available?, true) do
        stub_capture3(stdout: json_response) do
          result = @client.generate("Hi")
          assert_equal "Test response", result[:text]
          assert_kind_of Integer, result[:metadata][:total_tokens]
        end
      end
    end

    it "builds command with file references for large prompts" do
      # Create a client with system_prompt to trigger large prompt path
      client = Ace::LLM::Providers::CLI::GeminiClient.new(
        generation_config: { system_prompt: "x" * 50_000 }
      )

      # Stub file operations to avoid polluting .cache/ during tests
      client.stub(:create_prompt_cache_dir, "/tmp/stubbed-cache") do
        File.stub(:write, nil) do
          # With additional 60K prompt, total > 100K triggers file reference path
          cmd = client.send(:build_gemini_command, "y" * 60_000, {})

          assert_includes cmd, "gemini"
          refute_includes cmd, "-i"              # No interactive flag (conflicts with stdin)
          refute_includes cmd, "-y"              # No yolo mode
          assert_includes cmd, "--output-format"
          assert_includes cmd, "json"
          refute_includes cmd, "--allowed-tools"
          # Prompt should contain file reading instructions
          assert cmd.any? { |arg| arg.include?("Read") && arg.include?("instruction") }
        end
      end
    end

    it "respects custom timeout option" do
      custom_timeout_client = Ace::LLM::Providers::CLI::GeminiClient.new(timeout: 60)

      timeout_value = custom_timeout_client.instance_variable_get(:@options)[:timeout]
      assert_equal 60, timeout_value
    end

    it "uses working_dir when creating prompt cache dir" do
      Dir.mktmpdir do |tmpdir|
        cache_dir = @client.send(:create_prompt_cache_dir, tmpdir)
        assert_equal File.join(tmpdir, ".ace-local", "llm", "prompts"), cache_dir
      end
    end

    it "passes resolved project root as subprocess chdir" do
      captured_kwargs = nil
      mock_status = Object.new
      mock_status.define_singleton_method(:success?) { true }
      mock_status.define_singleton_method(:exitstatus) { 0 }

      @client.stub(:gemini_available?, true) do
        Ace::LLM::Providers::CLI::Molecules::SafeCapture.stub(:call, lambda { |*_args, **kwargs|
          captured_kwargs = kwargs
          ['{"response":"ok"}', "", mock_status]
        }) do
          @client.generate("Hi", working_dir: "/tmp/e2e-sandbox")
        end
      end

      assert_equal "/tmp/e2e-sandbox", captured_kwargs[:chdir]
    end

    it "builds command with pre-existing files when system_file and prompt_file provided" do
      # Test the code path used by ace-review to avoid double-writing files
      cmd = @client.send(:build_gemini_command, "ignored prompt", {
        system_file: "/path/to/system.md",
        prompt_file: "/path/to/user.md"
      })

      assert_includes cmd, "gemini"
      assert_includes cmd, "--output-format"
      assert_includes cmd, "json"
      refute_includes cmd, "--allowed-tools"
      # Should contain file reading instructions
      assert cmd.any? { |arg| arg.include?("Read the system instructions") && arg.include?("/path/to/system.md") }
      assert cmd.any? { |arg| arg.include?("Read the user context") && arg.include?("/path/to/user.md") }
      # Original prompt should NOT be in the command (file paths take precedence)
      refute cmd.any? { |arg| arg.include?("ignored prompt") }
    end
  end
end
