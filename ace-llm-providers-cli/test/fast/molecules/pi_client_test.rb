# frozen_string_literal: true

require_relative "../../test_helper"

describe "PiClient" do
  before do
    @client = Ace::LLM::Providers::CLI::PiClient.new
  end

  it "initializes with default model" do
    model = @client.instance_variable_get(:@model)
    assert_equal "zai/glm-5.3-flash", model
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
    assert models.any? { |m| m[:id] == "zai/glm-5.3" }
    assert models.any? { |m| m[:id] == "zai/glm-5.3-flash" }
    assert models.any? { |m| m[:id] == "zai/glm-5.3-highspeed" }
    assert models.none? { |m| m[:id].match?(/glm-(4\.|5\.1|5-turbo)/) }
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
      {role: "system", content: "You are helpful"},
      {role: "user", content: "Hello"}
    ]

    formatted = @client.send(:format_messages_as_prompt, messages)
    assert_includes formatted, "System: You are helpful"
    assert_includes formatted, "User: Hello"
  end

  it "formats multi-turn conversations" do
    messages = [
      {role: "user", content: "Hello"},
      {role: "assistant", content: "Hi there"},
      {role: "user", content: "How are you?"}
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
      assert_equal "json", cmd.fetch(cmd.index("--mode") + 1)
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

    it "preserves the resolved GLM model and max reasoning in native arguments" do
      client = Ace::LLM::Providers::CLI::PiClient.new(model: "zai/glm-5.3")
      cmd = client.send(:build_pi_command, "Review", {cli_args: ["--thinking", "max"]})
      assert_equal "zai", cmd.fetch(cmd.index("--provider") + 1)
      assert_equal "glm-5.3", cmd.fetch(cmd.index("--model") + 1)
      assert_equal "max", cmd.fetch(cmd.index("--thinking") + 1)
    end

    it "rejects CLI model overrides that would falsify execution identity" do
      client = Ace::LLM::Providers::CLI::PiClient.new(model: "zai/glm-5.3")
      ["--mode", "--model", "--models"].each do |flag|
        assert_raises(Ace::LLM::ProviderError) do
          client.send(:build_pi_command, "Review", {cli_args: [flag, "other"]})
        end
      end
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

    it "passes working_dir to SafeCapture chdir" do
      captured_kwargs = nil
      mock_status = Object.new
      mock_status.define_singleton_method(:success?) { true }
      mock_status.define_singleton_method(:exitstatus) { 0 }

      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          Ace::LLM::Providers::CLI::Molecules::SafeCapture.stub(:call, lambda { |*_args, **kwargs|
            captured_kwargs = kwargs
            ["{\"type\":\"agent_end\",\"messages\":[{\"content\":[{\"type\":\"text\",\"text\":\"ok\"}]}]}\n{\"type\":\"agent_settled\"}\n", "", mock_status]
          }) do
            @client.generate("Hi", working_dir: "/tmp/e2e-sandbox")
          end
        end
      end

      assert_equal "/tmp/e2e-sandbox", captured_kwargs[:chdir]
    end
  end

  describe "build_interactive_invocation" do
    it "rejects interactive provider and model overrides" do
      client = Ace::LLM::Providers::CLI::PiClient.new(model: "zai/glm-5.3")
      ["--provider", "--model", "--models"].each do |flag|
        assert_raises(Ace::LLM::ProviderError) do
          client.send(:build_pi_interactive_command, "Review", {cli_args: [flag, "other"]})
        end
      end
    end

    it "builds interactive pi command with translated skill syntax" do
      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, "/tmp/skills") do
          @client.instance_variable_get(:@skill_name_reader).stub(:call, ["as-assign-drive"]) do
            invocation = @client.build_interactive_invocation([{role: "user", content: "/as-assign-drive abc123@010"}])
            assert_equal "pi", invocation[:command][0]
            refute_includes invocation[:command], "-p"
            refute_includes invocation[:command], "--no-session"
            refute_includes invocation[:command], "--no-skills"
            assert_includes invocation[:command].join(" "), "/skill:as-assign-drive abc123@010"
          end
        end
      end
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

    it "rejects unresolved models instead of silently using the Pi default" do
      [nil, "glm5:max", "no-slash", "/model", "provider/", ":openai/gpt"].each do |model|
        assert_raises(Ace::LLM::ProviderError) { @client.send(:split_provider_model, model) }
      end
    end

    it "handles nested provider with colon (openrouter:openai/model)" do
      provider, model = @client.send(:split_provider_model, "openrouter:openai/gpt-oss-120b")
      assert_equal "openrouter", provider
      assert_equal "openai/gpt-oss-120b", model
    end

    it "rejects nested selectors with an empty provider or model component" do
      ["openrouter:/gpt", "openrouter:openai/"].each do |model|
        assert_raises(Ace::LLM::ProviderError) { @client.send(:split_provider_model, model) }
      end
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
        {"type":"agent_end","messages":[]}
        {"type":"agent_settled"}
      NDJSON

      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: ndjson_response) do
            result = @client.generate("Hi")
            assert_equal "Hello from Pi!", result[:text]
            assert_equal 10, result[:metadata][:input_tokens]
            assert_equal 5, result[:metadata][:output_tokens]
            assert_equal "pi", result[:metadata][:provider]
            assert_equal "zai/glm-5.3-flash", result[:metadata][:model]
          end
        end
      end
    end

    it "rejects raw text while JSON mode is required" do
      raw_text = "This is plain text output"

      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: raw_text) do
            assert_raises(Ace::LLM::ProviderError) { @client.generate("Hi") }
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

    it "rejects a non-JSON response despite subprocess success" do
      plain_text = "Test response"

      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: plain_text) do
            assert_raises(Ace::LLM::ProviderError) { @client.generate("Hi") }
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
        {"type":"agent_end","messages":[]}
        {"type":"agent_settled"}
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
        {"type":"agent_settled"}
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
        {"type":"agent_end","messages":[]}
        {"type":"agent_settled"}
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

    it "rejects a multiline non-NDJSON response" do
      plain_text = "This is plain text output\nNot NDJSON"

      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: plain_text) do
            assert_raises(Ace::LLM::ProviderError) { @client.generate("Hi") }
          end
        end
      end
    end

    it "rejects malformed NDJSON instead of accepting it as a complete report" do
      invalid_ndjson = '{"type":"message_end"\nInvalid JSON line'

      @client.stub(:pi_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: invalid_ndjson) do
            assert_raises(Ace::LLM::ProviderError) { @client.generate("Hi") }
          end
        end
      end
    end
  end

  describe "parse_ndjson" do
    it "keeps only the final assistant turn" do
      ndjson = <<~NDJSON
        {"type":"message_end","message":{"role":"assistant","content":[{"type":"text","text":"First turn"}]}}
        {"type":"message_end","message":{"role":"toolResult","content":[{"type":"text","text":"tool output"}]}}
        {"type":"message_end","message":{"role":"assistant","content":[{"type":"text","text":"Final turn"}]}}
        {"type":"agent_end","messages":[]}
        {"type":"agent_settled"}
      NDJSON
      text, = @client.send(:parse_ndjson, ndjson)
      assert_equal "Final turn", text
    end

    it "rejects a message_end without the terminal agent_end event" do
      ndjson = <<~NDJSON
        {"type":"message_end","message":{"content":[{"type":"text","text":"Hello"}]}}
      NDJSON

      assert_raises(Ace::LLM::ProviderError) { @client.send(:parse_ndjson, ndjson) }
    end

    it "rejects an agent_end without the final agent_settled event" do
      ndjson = <<~NDJSON
        {"type":"message_end","message":{"content":[{"type":"text","text":"Unsettled"}]}}
        {"type":"agent_end","messages":[]}
      NDJSON
      error = assert_raises(Ace::LLM::ProviderError) { @client.send(:parse_ndjson, ndjson) }
      assert_match(/agent_settled/, error.message)
    end

    it "accepts valid JSON with whitespace around the type separator" do
      ndjson = <<~NDJSON
        {"type": "message_end", "message": {"content": [{"type": "text", "text": "Complete"}]}}
        {"type": "agent_end", "messages": []}
        {"type": "agent_settled"}
      NDJSON
      status = Object.new
      status.define_singleton_method(:success?) { true }
      result = @client.send(:parse_pi_response, ndjson, "", status, "Review", {})
      assert_equal "Complete", result[:text]
    end

    it "extracts usage from message_end event" do
      ndjson = <<~NDJSON
        {"type":"message_end","message":{"content":[{"type":"text","text":"Answer"}],"usage":{"input":5,"output":2}}}
        {"type":"agent_end","messages":[]}
        {"type":"agent_settled"}
      NDJSON

      text, usage = @client.send(:parse_ndjson, ndjson)
      assert_equal "Answer", text
      assert_equal({"input" => 5, "output" => 2}, usage)
    end

    it "rejects a successful terminal event without assistant text" do
      assert_raises(Ace::LLM::ProviderError) do
        @client.send(:parse_ndjson, "{\"type\":\"agent_end\",\"messages\":[]}")
      end
    end

    it "extracts text from agent_end fallback" do
      ndjson = <<~NDJSON
        {"type":"agent_end","messages":[{"content":[{"type":"text","text":"Fallback text"}]}]}
        {"type":"agent_settled"}
      NDJSON

      text, _ = @client.send(:parse_ndjson, ndjson)
      assert_equal "Fallback text", text
    end

    it "propagates a terminal failure stop reason" do
      ndjson = <<~NDJSON
        {"type":"message_end","message":{"content":[{"type":"text","text":"Partial"}]}}
        {"type":"agent_end","messages":[{"role":"assistant","content":[{"type":"text","text":"Partial"}],"stopReason":"error"}]}
        {"type":"agent_settled"}
      NDJSON
      status = Object.new
      status.define_singleton_method(:success?) { true }
      result = @client.send(:parse_pi_response, ndjson, "", status, "Review", {})
      assert_equal "error", result[:metadata][:finish_reason]
    end

    it "propagates a message-level truncation despite an empty agent_end" do
      ndjson = <<~NDJSON
        {"type":"message_end","message":{"content":[{"type":"text","text":"Partial review"}],"stopReason":"length"}}
        {"type":"agent_end","messages":[]}
        {"type":"agent_settled"}
      NDJSON
      status = Object.new
      status.define_singleton_method(:success?) { true }
      result = @client.send(:parse_pi_response, ndjson, "", status, "Review", {})
      assert_equal "length", result[:metadata][:finish_reason]
    end

    it "keeps the final message_end reason when agent_end contains earlier text" do
      ndjson = <<~NDJSON
        {"type":"message_end","message":{"content":[{"type":"text","text":"Partial review"}],"stopReason":"length"}}
        {"type":"agent_end","messages":[{"role":"assistant","content":[{"type":"text","text":"Earlier turn"}],"stopReason":"stop"},{"role":"assistant","content":[]}]}
        {"type":"agent_settled"}
      NDJSON
      _, _, reason = @client.send(:parse_ndjson, ndjson)
      assert_equal "length", reason
    end

    it "prioritizes a terminal error over message-level truncation" do
      ndjson = <<~NDJSON
        {"type":"message_end","message":{"content":[{"type":"text","text":"Partial review"}],"stopReason":"length"}}
        {"type":"agent_end","messages":[{"role":"assistant","content":[{"type":"text","text":"Partial review"}],"stopReason":"error"}]}
        {"type":"agent_settled"}
      NDJSON
      _, _, reason = @client.send(:parse_ndjson, ndjson)
      assert_equal "error", reason
    end

    it "rejects an unfinished retry and keeps only the recovered run" do
      retry_event = <<~NDJSON
        {"type":"message_end","message":{"content":[{"type":"text","text":"Partial"}],"stopReason":"length"}}
        {"type":"agent_end","willRetry":true,"messages":[]}
      NDJSON
      assert_raises(Ace::LLM::ProviderError) { @client.send(:parse_ndjson, retry_event) }

      recovered = retry_event + <<~NDJSON
        {"type":"message_end","message":{"content":[{"type":"text","text":"Complete"}],"stopReason":"stop"}}
        {"type":"agent_end","willRetry":false,"messages":[]}
        {"type":"agent_settled"}
      NDJSON
      text, _, reason = @client.send(:parse_ndjson, recovered)
      assert_equal "Complete", text
      assert_equal "stop", reason
    end

    it "rejects invalid JSON events" do
      assert_raises(Ace::LLM::ProviderError) { @client.send(:parse_ndjson, "Not JSON at all") }
    end
  end

  it "rejects empty plain-text output despite a successful subprocess" do
    status = Object.new
    status.define_singleton_method(:success?) { true }
    assert_raises(Ace::LLM::ProviderError) do
      @client.send(:parse_pi_response, "  \n", "", status, "Review", {})
    end
  end

  describe "normalize_usage" do
    it "normalizes Pi field names to standard format" do
      usage = {"input" => 10, "output" => 5}
      result = @client.send(:normalize_usage, usage)
      assert_equal({"input_tokens" => 10, "output_tokens" => 5}, result)
    end

    it "passes through already-normalized field names" do
      usage = {"input_tokens" => 10, "output_tokens" => 5}
      result = @client.send(:normalize_usage, usage)
      assert_equal({"input_tokens" => 10, "output_tokens" => 5}, result)
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
