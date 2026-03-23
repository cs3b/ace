# frozen_string_literal: true

require_relative "../test_helper"

describe "CodexOaiClient" do
  before do
    @backends = {
      "zai" => {
        "name" => "Z.ai GLM",
        "base_url" => "https://api.z.ai/api/coding/paas/v4",
        "env_key" => "ZAI_API_KEY"
      }
    }
    @client = Ace::LLM::Providers::CLI::CodexOaiClient.new(backends: @backends)
  end

  it "initializes with default model" do
    model = @client.instance_variable_get(:@model)
    assert_equal "zai/glm-5", model
  end

  it "can be initialized with custom model" do
    client = Ace::LLM::Providers::CLI::CodexOaiClient.new(model: "zai/glm-4.7", backends: @backends)
    model = client.instance_variable_get(:@model)
    assert_equal "zai/glm-4.7", model
  end

  it "needs_credentials? returns false" do
    refute @client.needs_credentials?
  end

  it "provider_name is 'codexoai'" do
    assert_equal "codexoai", Ace::LLM::Providers::CLI::CodexOaiClient.provider_name
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
      {role: "system", content: "You are helpful"},
      {role: "user", content: "Hello"}
    ]

    formatted = @client.send(:format_messages_as_prompt, messages)
    assert_includes formatted, "System: You are helpful"
    assert_includes formatted, "User: Hello"
  end

  describe "build_codex_oai_command" do
    it "builds command with backend config overrides" do
      cmd = @client.send(:build_codex_oai_command, "Test prompt", {})

      assert_equal "codex", cmd[0]
      assert_includes cmd, "exec"

      # Should have -c overrides for the backend
      assert_includes cmd, "-c"
      assert cmd.any? { |arg| arg.include?("model_provider=") }
      assert cmd.any? { |arg| arg.include?("model_providers.zai.name=") }
      assert cmd.any? { |arg| arg.include?("model_providers.zai.base_url=") }
      assert cmd.any? { |arg| arg.include?("model_providers.zai.env_key=") }

      # Should have -m with just the model name (not backend/model)
      m_index = cmd.index("-m")
      refute_nil m_index
      assert_equal "glm-5", cmd[m_index + 1]
    end

    it "includes correct base_url in config override" do
      cmd = @client.send(:build_codex_oai_command, "Test prompt", {})
      base_url_arg = cmd.find { |arg| arg.include?("base_url=") }
      assert_includes base_url_arg, "https://api.z.ai/api/coding/paas/v4"
    end

    it "includes correct env_key in config override" do
      cmd = @client.send(:build_codex_oai_command, "Test prompt", {})
      env_key_arg = cmd.find { |arg| arg.include?("env_key=") }
      assert_includes env_key_arg, "ZAI_API_KEY"
    end

    it "includes provider name in config override" do
      cmd = @client.send(:build_codex_oai_command, "Test prompt", {})
      name_arg = cmd.find { |arg| arg.include?("model_providers.zai.name=") }
      assert_includes name_arg, "Z.ai GLM"
    end

    it "falls back to backend key as name when name not configured" do
      backends = {"deepseek" => {"base_url" => "https://api.deepseek.com/v1", "env_key" => "DEEPSEEK_API_KEY"}}
      client = Ace::LLM::Providers::CLI::CodexOaiClient.new(model: "deepseek/deepseek-chat", backends: backends)
      cmd = client.send(:build_codex_oai_command, "Test prompt", {})
      name_arg = cmd.find { |arg| arg.include?("model_providers.deepseek.name=") }
      assert_includes name_arg, "deepseek"
    end

    it "uses different backend model" do
      client = Ace::LLM::Providers::CLI::CodexOaiClient.new(model: "zai/glm-4.7", backends: @backends)
      cmd = client.send(:build_codex_oai_command, "Test prompt", {})

      m_index = cmd.index("-m")
      assert_equal "glm-4.7", cmd[m_index + 1]
    end
  end

  describe "availability validation" do
    it "raises ProviderError when codex CLI is not available" do
      @client.stub :codex_available?, false do
        error = assert_raises(Ace::LLM::ProviderError) do
          @client.send(:validate_codex_availability!)
        end
        assert_match(/not found/, error.message)
      end
    end

    it "does not raise when codex is available" do
      @client.stub :codex_available?, true do
        @client.send(:validate_codex_availability!)
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

    it "parses codex response correctly" do
      codex_response = <<~OUTPUT
        codex
        Hello from Codex OAI!
        42 tokens used
      OUTPUT

      @client.stub(:codex_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: codex_response) do
            result = @client.generate("Hi")
            assert_equal "Hello from Codex OAI!", result[:text]
            assert_equal "codexoai", result[:metadata][:provider]
            assert_equal "zai/glm-5", result[:metadata][:model]
          end
        end
      end
    end

    it "raises ProviderError on CLI failure" do
      @client.stub(:codex_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: "", stderr: "CLI error", success: false) do
            error = assert_raises(Ace::LLM::ProviderError) do
              @client.generate("Hi")
            end
            assert_match(/Codex OAI CLI failed/, error.message)
          end
        end
      end
    end

    it "builds synthetic metadata for response" do
      codex_response = "codex\nTest response\n100 tokens used"

      @client.stub(:codex_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: codex_response) do
            result = @client.generate("Hi")
            assert_equal "Test response", result[:text]
            assert_kind_of Integer, result[:metadata][:total_tokens]
            assert_equal "codexoai", result[:metadata][:provider]
          end
        end
      end
    end

    it "handles response without codex header line" do
      plain_text = "Just plain text"

      @client.stub(:codex_available?, true) do
        @client.stub(:resolve_skills_dir, nil) do
          stub_capture3(stdout: plain_text) do
            result = @client.generate("Hi")
            assert_equal "Just plain text", result[:text]
          end
        end
      end
    end
  end
end
