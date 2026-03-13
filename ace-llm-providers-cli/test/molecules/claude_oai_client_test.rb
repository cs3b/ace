# frozen_string_literal: true

require_relative "../test_helper"

describe "ClaudeOaiClient" do
  before do
    @backends = {
      "zai" => {
        "base_url" => "https://api.z.ai/api/anthropic",
        "env_key" => "ZAI_API_KEY",
        "model_tiers" => {
          "opus" => "glm-5",
          "sonnet" => "glm-5",
          "haiku" => "glm-4.7"
        }
      }
    }
    @client = Ace::LLM::Providers::CLI::ClaudeOaiClient.new(backends: @backends)
  end

  it "initializes with default model" do
    model = @client.instance_variable_get(:@model)
    assert_equal "zai/glm-5", model
  end

  it "can be initialized with custom model" do
    client = Ace::LLM::Providers::CLI::ClaudeOaiClient.new(model: "zai/glm-4.7", backends: @backends)
    model = client.instance_variable_get(:@model)
    assert_equal "zai/glm-4.7", model
  end

  it "needs_credentials? returns false" do
    refute @client.needs_credentials?
  end

  it "provider_name is 'claudeoai'" do
    assert_equal "claudeoai", Ace::LLM::Providers::CLI::ClaudeOaiClient.provider_name
  end

  it "can list models" do
    models = @client.list_models
    assert_kind_of Array, models
    assert models.any? { |m| m[:id] == "zai/glm-5" }
    assert models.any? { |m| m[:id] == "zai/glm-4.7" }
    assert models.any? { |m| m[:id] == "zai/glm-4.6" }
  end

  describe "split_backend_model" do
    it "splits backend/model format" do
      backend, model = @client.split_backend_model("zai/glm-5")
      assert_equal "zai", backend
      assert_equal "glm-5", model
    end

    it "returns nil pair for nil input" do
      backend, model = @client.split_backend_model(nil)
      assert_nil backend
      assert_nil model
    end

    it "returns nil pair for string without slash" do
      backend, model = @client.split_backend_model("glm-5")
      assert_nil backend
      assert_nil model
    end
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

  describe "build_claude_command" do
    it "builds command with claude -p and JSON output" do
      cmd = @client.send(:build_claude_command, {})

      assert_equal "claude", cmd[0]
      assert_includes cmd, "-p"
      assert_includes cmd, "--output-format"

      json_idx = cmd.index("--output-format")
      assert_equal "json", cmd[json_idx + 1]
    end

    it "uses a tier alias (not backend model name) for --model flag" do
      cmd = @client.send(:build_claude_command, {})

      m_index = cmd.index("--model")
      refute_nil m_index
      assert_equal "opus", cmd[m_index + 1]
    end

    it "does not pass unsupported temperature flag" do
      cmd = @client.send(:build_claude_command, temperature: 0.2)
      refute_includes cmd, "--temperature"
    end

    it "resolves haiku tier for glm-4.7" do
      client = Ace::LLM::Providers::CLI::ClaudeOaiClient.new(model: "zai/glm-4.7", backends: @backends)
      cmd = client.send(:build_claude_command, {})

      m_index = cmd.index("--model")
      assert_equal "haiku", cmd[m_index + 1]
    end

    it "falls back to sonnet for unknown model" do
      client = Ace::LLM::Providers::CLI::ClaudeOaiClient.new(model: "zai/glm-999", backends: @backends)
      cmd = client.send(:build_claude_command, {})

      m_index = cmd.index("--model")
      assert_equal "sonnet", cmd[m_index + 1]
    end
  end

  describe "backend_env_vars" do
    it "sets ANTHROPIC_BASE_URL from backend config" do
      env = @client.send(:backend_env_vars)
      assert_equal "https://api.z.ai/api/anthropic", env["ANTHROPIC_BASE_URL"]
    end

    it "reads ANTHROPIC_AUTH_TOKEN from env var specified by env_key" do
      old_val = ENV["ZAI_API_KEY"]
      ENV["ZAI_API_KEY"] = "test-zai-key-123"

      env = @client.send(:backend_env_vars)
      assert_equal "test-zai-key-123", env["ANTHROPIC_AUTH_TOKEN"]
    ensure
      ENV["ZAI_API_KEY"] = old_val
    end

    it "clears ANTHROPIC_API_KEY to prevent cached creds" do
      env = @client.send(:backend_env_vars)
      assert_equal "", env["ANTHROPIC_API_KEY"]
    end

    it "sets ANTHROPIC_DEFAULT_OPUS_MODEL for tier-mapped model" do
      env = @client.send(:backend_env_vars)
      assert_equal "glm-5", env["ANTHROPIC_DEFAULT_OPUS_MODEL"]
    end

    it "sets ANTHROPIC_DEFAULT_HAIKU_MODEL for haiku-tier model" do
      client = Ace::LLM::Providers::CLI::ClaudeOaiClient.new(model: "zai/glm-4.7", backends: @backends)
      env = client.send(:backend_env_vars)
      assert_equal "glm-4.7", env["ANTHROPIC_DEFAULT_HAIKU_MODEL"]
    end

    it "sets ANTHROPIC_DEFAULT_SONNET_MODEL for unknown model (fallback)" do
      client = Ace::LLM::Providers::CLI::ClaudeOaiClient.new(model: "zai/glm-999", backends: @backends)
      env = client.send(:backend_env_vars)
      assert_equal "glm-999", env["ANTHROPIC_DEFAULT_SONNET_MODEL"]
    end

    it "returns empty hash when no backend matches" do
      client = Ace::LLM::Providers::CLI::ClaudeOaiClient.new(model: "unknown/model", backends: @backends)
      env = client.send(:backend_env_vars)
      assert_equal({}, env)
    end
  end

  describe "execute_claude_command env injection" do
    def run_with_captured_env(&block)
      captured_env = nil
      captured_chdir = nil
      fake_capture = lambda { |*_args, **kwargs|
        captured_env = kwargs[:env]
        captured_chdir = kwargs[:chdir]
        mock_status = Object.new
        mock_status.define_singleton_method(:success?) { true }
        mock_status.define_singleton_method(:exitstatus) { 0 }
        ['{"result":"ok"}', "", mock_status]
      }

      Ace::LLM::Providers::CLI::Molecules::SafeCapture.stub(:call, fake_capture) do
        block.call
      end
      [captured_env, captured_chdir]
    end

    it "injects backend env vars into subprocess" do
      old_val = ENV["ZAI_API_KEY"]
      ENV["ZAI_API_KEY"] = "injected-key"

      env, _chdir = run_with_captured_env do
        @client.send(:execute_claude_command, ["claude", "-p"], "hello")
      end

      assert_nil env["CLAUDECODE"]
      assert_equal "https://api.z.ai/api/anthropic", env["ANTHROPIC_BASE_URL"]
      assert_equal "injected-key", env["ANTHROPIC_AUTH_TOKEN"]
      assert_equal "", env["ANTHROPIC_API_KEY"]
    ensure
      ENV["ZAI_API_KEY"] = old_val
    end

    it "merges subprocess_env on top of backend env" do
      env, _chdir = run_with_captured_env do
        @client.send(:execute_claude_command, ["claude", "-p"], "hello",
                     subprocess_env: {"ACE_TMUX_SESSION" => "TS-TEST-001-e2e"})
      end

      assert_equal "TS-TEST-001-e2e", env["ACE_TMUX_SESSION"]
      assert_equal "https://api.z.ai/api/anthropic", env["ANTHROPIC_BASE_URL"]
    end

    it "passes working_dir as subprocess chdir" do
      _env, chdir = run_with_captured_env do
        @client.send(:execute_claude_command, ["claude", "-p"], "hello", working_dir: "/tmp/e2e-sandbox")
      end

      assert_equal "/tmp/e2e-sandbox", chdir
    end
  end

  describe "availability validation" do
    it "raises ProviderError when claude CLI is not available" do
      @client.stub :claude_available?, false do
        error = assert_raises(Ace::LLM::ProviderError) do
          @client.send(:validate_claude_availability!)
        end
        assert_match(/not found/, error.message)
      end
    end

    it "does not raise when claude is available" do
      @client.stub :claude_available?, true do
        @client.send(:validate_claude_availability!)
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

    it "parses claude JSON response correctly" do
      claude_response = '{"result":"Hello from Claude OAI!","usage":{"input_tokens":10,"output_tokens":5}}'

      @client.stub(:claude_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: claude_response) do
            result = @client.generate("Hi")
            assert_equal "Hello from Claude OAI!", result[:text]
            assert_equal "claudeoai", result[:metadata][:provider]
            assert_equal "zai/glm-5", result[:metadata][:model]
            assert_equal 10, result[:metadata][:input_tokens]
            assert_equal 5, result[:metadata][:output_tokens]
          end
        end
      end
    end

    it "raises ProviderError on CLI failure" do
      @client.stub(:claude_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: "", stderr: "CLI error", success: false) do
            error = assert_raises(Ace::LLM::ProviderError) do
              @client.generate("Hi")
            end
            assert_match(/Claude OAI CLI failed/, error.message)
          end
        end
      end
    end

    it "raises ProviderError on invalid JSON" do
      @client.stub(:claude_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: "not json at all") do
            error = assert_raises(Ace::LLM::ProviderError) do
              @client.generate("Hi")
            end
            assert_match(/Failed to parse/, error.message)
          end
        end
      end
    end
  end
end
