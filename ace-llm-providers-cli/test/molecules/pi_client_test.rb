# frozen_string_literal: true

require_relative "../test_helper"

describe "PiClient" do
  before do
    @client = Ace::LLM::Providers::CLI::PiClient.new
  end

  it "initializes with default model" do
    model = @client.instance_variable_get(:@model)
    assert_equal "zai/glm-4.7", model
  end

  it "can be initialized with custom model" do
    client = Ace::LLM::Providers::CLI::PiClient.new(model: "anthropic/claude-opus-4-6")
    model = client.instance_variable_get(:@model)
    assert_equal "anthropic/claude-opus-4-6", model
  end

  it "needs_credentials? returns false" do
    refute @client.needs_credentials?
  end

  it "provider_name is 'pi'" do
    assert_equal "pi", Ace::LLM::Providers::CLI::PiClient.provider_name
  end

  it "can list models" do
    models = @client.list_models
    assert_kind_of Array, models
    assert models.any? { |m| m[:id] == "zai/glm-4.7" }
    assert models.any? { |m| m[:id] == "anthropic/claude-opus-4-6" }
    assert models.any? { |m| m[:id] == "google-gemini-cli/gemini-2.5-pro" }
  end

  it "formats string prompts correctly" do
    prompt = "Just a string"
    formatted = @client.send(:format_messages_as_prompt, prompt)
    assert_equal "Just a string", formatted
  end

  it "formats message array with roles" do
    messages = [
      { role: "system", content: "You are helpful" },
      { role: "user", content: "Hello" }
    ]

    formatted = @client.send(:format_messages_as_prompt, messages)
    assert_includes formatted, "System: You are helpful"
    assert_includes formatted, "User: Hello"
  end

  it "formats multi-turn conversations" do
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

  describe "build_pi_command" do
    it "builds command with default flags" do
      cmd = @client.send(:build_pi_command, "Test prompt", {})

      assert_equal "pi", cmd[0]
      assert_includes cmd, "-p"
      assert_includes cmd, "--no-session"
      assert_includes cmd, "--no-skills"
      assert cmd.any? { |arg| arg == "Test prompt" }
    end

    it "includes provider and model flags from model string" do
      client = Ace::LLM::Providers::CLI::PiClient.new(model: "anthropic/claude-opus-4-6")
      cmd = client.send(:build_pi_command, "Test", {})

      assert_includes cmd, "--provider"
      assert_includes cmd, "anthropic"
      assert_includes cmd, "--model"
      assert_includes cmd, "claude-opus-4-6"
    end

    it "includes system prompt flag when system_prompt provided" do
      cmd = @client.send(:build_pi_command, "Test", {}, system_prompt: "Be helpful")

      assert_includes cmd, "--system-prompt"
      assert_includes cmd, "Be helpful"
    end

    it "does not include system prompt flag when none provided" do
      cmd = @client.send(:build_pi_command, "Test", {})

      refute_includes cmd, "--system-prompt"
    end
  end

  describe "split_provider_model" do
    it "splits provider/model correctly" do
      provider, model = @client.send(:split_provider_model, "anthropic/claude-opus-4-6")
      assert_equal "anthropic", provider
      assert_equal "claude-opus-4-6", model
    end

    it "handles multi-segment provider names" do
      provider, model = @client.send(:split_provider_model, "google-gemini-cli/gemini-2.5-pro")
      assert_equal "google-gemini-cli", provider
      assert_equal "gemini-2.5-pro", model
    end

    it "returns nil pair for nil input" do
      provider, model = @client.send(:split_provider_model, nil)
      assert_nil provider
      assert_nil model
    end

    it "returns nil pair for string without slash" do
      provider, model = @client.send(:split_provider_model, "no-slash")
      assert_nil provider
      assert_nil model
    end

    it "handles nested provider with colon (openrouter:openai/model)" do
      provider, model = @client.send(:split_provider_model, "openrouter:openai/gpt-oss-120b")
      assert_equal "openrouter", provider
      assert_equal "openai/gpt-oss-120b", model
    end

    it "handles standard format even when colon is present elsewhere" do
      # Ensure we don't break standard provider/model format
      provider, model = @client.send(:split_provider_model, "anthropic/claude-opus-4-6")
      assert_equal "anthropic", provider
      assert_equal "claude-opus-4-6", model
    end
  end

  describe "availability validation" do
    it "raises ProviderError when pi CLI is not available" do
      @client.stub :pi_available?, false do
        error = assert_raises(Ace::LLM::ProviderError) do
          @client.send(:validate_pi_availability!)
        end
        assert_match(/not found/, error.message)
      end
    end

    it "does not raise when pi is available" do
      @client.stub :pi_available?, true do
        @client.send(:validate_pi_availability!)
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

    it "parses NDJSON response correctly" do
      # Default mode is plain text, but we detect NDJSON (starts with {"type":")
      ndjson_response = <<~NDJSON
        {"type":"message_end","message":{"content":[{"type":"text","text":"Hello from Pi!"}],"usage":{"input":10,"output":5}}}
      NDJSON

      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: ndjson_response) do
            result = @client.generate("Hi")
            assert_equal "Hello from Pi!", result[:text]
            assert_equal 10, result[:metadata][:input_tokens]
            assert_equal 5, result[:metadata][:output_tokens]
            assert_equal "pi", result[:metadata][:provider]
            assert_equal "zai/glm-4.7", result[:metadata][:model]
          end
        end
      end
    end

    it "falls back to raw text when JSON parsing fails" do
      raw_text = "This is plain text output"

      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: raw_text) do
            result = @client.generate("Hi")
            assert_equal "This is plain text output", result[:text]
            assert_kind_of Integer, result[:metadata][:total_tokens]
          end
        end
      end
    end

    it "raises ProviderError on CLI failure" do
      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: "", stderr: "CLI error", success: false) do
            error = assert_raises(Ace::LLM::ProviderError) do
              @client.generate("Hi")
            end
            assert_match(/Pi CLI failed/, error.message)
          end
        end
      end
    end

    it "raises AuthenticationError on 401" do
      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: "", stderr: "401 Unauthorized", success: false) do
            error = assert_raises(Ace::LLM::AuthenticationError) do
              @client.generate("Hi")
            end
            assert_match(/authentication failed/, error.message)
          end
        end
      end
    end

    it "builds synthetic metadata for plain text response" do
      plain_text = "Test response"

      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: plain_text) do
            result = @client.generate("Hi")
            assert_equal "Test response", result[:text]
            assert_kind_of Integer, result[:metadata][:total_tokens]
          end
        end
      end
    end

    it "parses NDJSON message_end events" do
      ndjson_output = <<~NDJSON
        {"type":"message_start","message":{"id":"msg-123","type":"message","role":"assistant","content":[]}}
        {"type":"content_block_delta","delta":{"type":"text","text":"Hello"}}
        {"type":"content_block_delta","delta":{"type":"text","text":" from Pi!"}}
        {"type":"message_end","message":{"content":[{"type":"text","text":"Hello from Pi!"}],"usage":{"input":10,"output":5}}}
      NDJSON

      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: ndjson_output) do
            result = @client.generate("Hi")
            assert_equal "Hello from Pi!", result[:text]
            assert_equal 10, result[:metadata][:input_tokens]
            assert_equal 5, result[:metadata][:output_tokens]
          end
        end
      end
    end

    it "parses NDJSON agent_end fallback" do
      ndjson_output = <<~NDJSON
        {"type":"agent_start","agent_id":"agent-123"}
        {"type":"agent_end","messages":[{"content":[{"type":"text","text":"Response text"}],"usage":{"input":8,"output":3}}]}
      NDJSON

      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: ndjson_output) do
            result = @client.generate("Hi")
            assert_equal "Response text", result[:text]
            assert_equal 8, result[:metadata][:input_tokens]
            assert_equal 3, result[:metadata][:output_tokens]
          end
        end
      end
    end

    it "extracts usage from NDJSON with normalized field names" do
      ndjson_output = <<~NDJSON
        {"type":"message_end","message":{"content":[{"type":"text","text":"Text"}],"usage":{"input":15,"output":7}}}
      NDJSON

      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: ndjson_output) do
            result = @client.generate("Hi")
            assert_equal "Text", result[:text]
            # Normalize input->input_tokens, output->output_tokens
            assert_equal 15, result[:metadata][:input_tokens]
            assert_equal 7, result[:metadata][:output_tokens]
          end
        end
      end
    end

    it "falls back to plain text for non-NDJSON output" do
      plain_text = "This is plain text output\nNot NDJSON"

      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: plain_text) do
            result = @client.generate("Hi")
            assert_equal "This is plain text output\nNot NDJSON", result[:text]
          end
        end
      end
    end

    it "handles NDJSON parse errors gracefully" do
      invalid_ndjson = '{"type":"message_end"\nInvalid JSON line'

      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: invalid_ndjson) do
            result = @client.generate("Hi")
            # Falls back to treating as plain text
            assert_equal invalid_ndjson.strip, result[:text]
          end
        end
      end
    end
  end

  describe "parse_ndjson" do
    it "extracts text from message_end event" do
      ndjson = <<~NDJSON
        {"type":"message_end","message":{"content":[{"type":"text","text":"Hello"}]}}
      NDJSON

      text, usage = @client.send(:parse_ndjson, ndjson)
      assert_equal "Hello", text
      assert_equal({}, usage)
    end

    it "extracts usage from message_end event" do
      ndjson = <<~NDJSON
        {"type":"message_end","message":{"content":[],"usage":{"input":5,"output":2}}}
      NDJSON

      text, usage = @client.send(:parse_ndjson, ndjson)
      assert_equal "", text
      assert_equal({"input" => 5, "output" => 2}, usage)
    end

    it "extracts text from agent_end fallback" do
      ndjson = <<~NDJSON
        {"type":"agent_end","messages":[{"content":[{"type":"text","text":"Fallback text"}]}]}
      NDJSON

      text, usage = @client.send(:parse_ndjson, ndjson)
      assert_equal "Fallback text", text
    end

    it "returns plain text on JSON parse error" do
      text, usage = @client.send(:parse_ndjson, "Not JSON at all")
      assert_equal "Not JSON at all", text
      assert_equal({}, usage)
    end
  end

  describe "normalize_usage" do
    it "normalizes Pi field names to standard format" do
      usage = { "input" => 10, "output" => 5 }
      result = @client.send(:normalize_usage, usage)
      assert_equal({ "input_tokens" => 10, "output_tokens" => 5 }, result)
    end

    it "passes through already-normalized field names" do
      usage = { "input_tokens" => 10, "output_tokens" => 5 }
      result = @client.send(:normalize_usage, usage)
      assert_equal({ "input_tokens" => 10, "output_tokens" => 5 }, result)
    end

    it "returns empty hash for nil usage" do
      result = @client.send(:normalize_usage, nil)
      assert_equal({}, result)
    end
  end

  describe "skill command rewriting" do
    it "rewrites skill commands when skills_dir exists" do
      # Create a temporary skills directory with a SKILL.md
      Dir.mktmpdir do |tmpdir|
        skill_dir = File.join(tmpdir, "test_skill")
        Dir.mkdir(skill_dir)
        File.write(File.join(skill_dir, "SKILL.md"), "---\nname: test-skill\n---\nContent")

        client = Ace::LLM::Providers::CLI::PiClient.new(skills_dir: tmpdir)
        result = client.send(:rewrite_skill_commands, "/test-skill please")
        assert_equal "/skill:test-skill please", result
      end
    end

    it "returns prompt unchanged when no skills_dir" do
      client = Ace::LLM::Providers::CLI::PiClient.new(skills_dir: "/nonexistent/path")
      result = client.send(:rewrite_skill_commands, "/onboard please")
      assert_equal "/onboard please", result
    end
  end

  describe "resolve_skills_dir" do
    it "returns configured dir if it exists" do
      Dir.mktmpdir do |tmpdir|
        client = Ace::LLM::Providers::CLI::PiClient.new(skills_dir: tmpdir)
        result = client.send(:resolve_skills_dir)
        assert_equal tmpdir, result
      end
    end

    it "returns nil for nonexistent configured dir" do
      client = Ace::LLM::Providers::CLI::PiClient.new(skills_dir: "/nonexistent/path")
      result = client.send(:resolve_skills_dir)
      assert_nil result
    end

    it "prefers provider-specific .pi/skills fallback dir" do
      Dir.mktmpdir do |tmpdir|
        default_skills = File.join(tmpdir, ".pi", "skills")
        FileUtils.mkdir_p(default_skills)

        Dir.chdir(tmpdir) do
          client = Ace::LLM::Providers::CLI::PiClient.new
          result = client.send(:resolve_skills_dir)
          expected = File.join(Dir.pwd, ".pi", "skills")
          assert_equal expected, result
        end
      end
    end

    it "returns nil when provider-specific dir is missing" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          client = Ace::LLM::Providers::CLI::PiClient.new
          result = client.send(:resolve_skills_dir)
          assert_nil result
        end
      end
    end
  end
end
