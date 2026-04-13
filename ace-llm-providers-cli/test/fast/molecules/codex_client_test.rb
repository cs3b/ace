# frozen_string_literal: true

require_relative "../../test_helper"

describe "CodexClient" do
  before do
    @client = Ace::LLM::Providers::CLI::CodexClient.new
  end

  it "initializes with default model" do
    model = @client.instance_variable_get(:@model)
    assert_equal "gpt-5", model
  end

  it "can be initialized with custom model" do
    client = Ace::LLM::Providers::CLI::CodexClient.new(model: "gpt-5-mini")
    model = client.instance_variable_get(:@model)
    assert_equal "gpt-5-mini", model
  end

  it "needs_credentials? returns false" do
    refute @client.needs_credentials?
  end

  it "provider_name is 'codex'" do
    assert_equal "codex", Ace::LLM::Providers::CLI::CodexClient.provider_name
  end

  it "can list models" do
    models = @client.list_models
    assert_kind_of Array, models
    assert models.any? { |m| m[:id] == "gpt-5" }
    assert models.any? { |m| m[:id] == "gpt-5-mini" }
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

  describe "build_codex_command" do
    it "builds command with default flags" do
      cmd = @client.send(:build_codex_command, "Test prompt", {})

      assert_equal "codex", cmd[0]
      assert_includes cmd, "exec"
      # Default model doesn't add --model flag
      refute_includes cmd, "--model"
    end

    it "includes model flag when non-default model specified" do
      client = Ace::LLM::Providers::CLI::CodexClient.new(model: "gpt-5-mini")
      cmd = client.send(:build_codex_command, "Test prompt", {})

      assert_includes cmd, "--model"
      assert_includes cmd, "gpt-5-mini"
    end

    it "includes --add-dir when in a git worktree" do
      fake_git_dir = "/home/user/repo/.git"
      captured_working_dir = nil
      Ace::LLM::Providers::CLI::Atoms::WorktreeDirResolver.stub(:call, lambda { |working_dir: Dir.pwd|
        captured_working_dir = working_dir
        fake_git_dir
      }) do
        cmd = @client.send(:build_codex_command, "Test prompt", {}, working_dir: "/tmp/e2e-sandbox")
        add_dir_idx = cmd.index("--add-dir")
        refute_nil add_dir_idx, "expected --add-dir in command"
        assert_equal fake_git_dir, cmd[add_dir_idx + 1]
      end
      assert_equal "/tmp/e2e-sandbox", captured_working_dir
    end

    it "omits --add-dir when not in a git worktree" do
      Ace::LLM::Providers::CLI::Atoms::WorktreeDirResolver.stub(:call, nil) do
        cmd = @client.send(:build_codex_command, "Test prompt", {})
        refute_includes cmd, "--add-dir"
      end
    end

    it "includes --output-last-message when last_message_file option provided" do
      cmd = @client.send(:build_codex_command, "Test prompt", {last_message_file: "/tmp/last-msg.md"})

      idx = cmd.index("--output-last-message")
      refute_nil idx, "expected --output-last-message in command"
      assert_equal "/tmp/last-msg.md", cmd[idx + 1]
    end

    it "omits --output-last-message when last_message_file option not provided" do
      cmd = @client.send(:build_codex_command, "Test prompt", {})

      refute_includes cmd, "--output-last-message"
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

    it "raises AuthenticationError when codex not authenticated" do
      @client.stub :codex_available?, true do
        @client.stub :codex_authenticated?, false do
          error = assert_raises(Ace::LLM::AuthenticationError) do
            @client.send(:validate_codex_availability!)
          end
          assert_match(/authentication required/, error.message)
        end
      end
    end

    it "does not raise when codex is available and authenticated" do
      @client.stub :codex_available?, true do
        @client.stub :codex_authenticated?, true do
          @client.send(:validate_codex_availability!)
        end
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
        Hello from Codex!
        42 tokens used
      OUTPUT

      @client.stub(:codex_available?, true) do
        @client.stub(:codex_authenticated?, true) do
          @client.stub(:resolve_skills_dir, nil) do
            stub_capture3(stdout: codex_response) do
              result = @client.generate("Hi")
              assert_equal "Hello from Codex!", result[:text]
              assert_equal "codex", result[:metadata][:provider]
              assert_equal "gpt-5", result[:metadata][:model]
            end
          end
        end
      end
    end

    it "raises ProviderError on CLI failure" do
      @client.stub(:codex_available?, true) do
        @client.stub(:codex_authenticated?, true) do
          @client.stub(:resolve_skills_dir, nil) do
            stub_capture3(stdout: "", stderr: "CLI error", success: false) do
              error = assert_raises(Ace::LLM::ProviderError) do
                @client.generate("Hi")
              end
              assert_match(/Codex CLI failed/, error.message)
            end
          end
        end
      end
    end

    it "builds synthetic metadata for response" do
      codex_response = "codex\nTest response\n100 tokens used"

      @client.stub(:codex_available?, true) do
        @client.stub(:codex_authenticated?, true) do
          @client.stub(:resolve_skills_dir, nil) do
            stub_capture3(stdout: codex_response) do
              result = @client.generate("Hi")
              assert_equal "Test response", result[:text]
              assert_kind_of Integer, result[:metadata][:total_tokens]
              assert_equal "codex", result[:metadata][:provider]
            end
          end
        end
      end
    end

    it "handles response without codex header line" do
      plain_text = "Just plain text"

      @client.stub(:codex_available?, true) do
        @client.stub(:codex_authenticated?, true) do
          @client.stub(:resolve_skills_dir, nil) do
            stub_capture3(stdout: plain_text) do
              result = @client.generate("Hi")
              assert_equal "Just plain text", result[:text]
            end
          end
        end
      end
    end

    it "passes working_dir to SafeCapture chdir" do
      captured_kwargs = nil
      mock_status = Object.new
      mock_status.define_singleton_method(:success?) { true }
      mock_status.define_singleton_method(:exitstatus) { 0 }

      @client.stub(:codex_available?, true) do
        @client.stub(:codex_authenticated?, true) do
          @client.stub(:resolve_skills_dir, nil) do
            Ace::LLM::Providers::CLI::Molecules::SafeCapture.stub(:call, lambda { |*_args, **kwargs|
              captured_kwargs = kwargs
              ["codex\nok\n", "", mock_status]
            }) do
              @client.generate("Hi", working_dir: "/tmp/e2e-sandbox")
            end
          end
        end
      end

      assert_equal "/tmp/e2e-sandbox", captured_kwargs[:chdir]
    end

    it "passes subprocess_env to SafeCapture env" do
      captured_kwargs = nil
      mock_status = Object.new
      mock_status.define_singleton_method(:success?) { true }
      mock_status.define_singleton_method(:exitstatus) { 0 }

      @client.stub(:codex_available?, true) do
        @client.stub(:codex_authenticated?, true) do
          @client.stub(:resolve_skills_dir, nil) do
            Ace::LLM::Providers::CLI::Molecules::SafeCapture.stub(:call, lambda { |*_args, **kwargs|
              captured_kwargs = kwargs
              ["codex\nok\n", "", mock_status]
            }) do
              @client.generate("Hi", subprocess_env: {"PROJECT_ROOT_PATH" => "/tmp/e2e-sandbox"})
            end
          end
        end
      end

      assert_equal({"PROJECT_ROOT_PATH" => "/tmp/e2e-sandbox"}, captured_kwargs[:env])
    end
  end

  describe "skill command rewriting" do
    it "rewrites skill commands when skills_dir exists using Codex formatter" do
      # Create a temporary skills directory with a SKILL.md
      Dir.mktmpdir do |tmpdir|
        skill_dir = File.join(tmpdir, "test_skill")
        Dir.mkdir(skill_dir)
        File.write(File.join(skill_dir, "SKILL.md"), "---\nname: test-skill\n---\nContent")

        client = Ace::LLM::Providers::CLI::CodexClient.new(skills_dir: tmpdir)
        result = client.send(:rewrite_skill_commands, "/test-skill please")
        # Codex formatter: /name → $name
        assert_equal "$test-skill please", result
      end
    end

    it "rewrites underscore-prefixed skill names using Codex formatter" do
      Dir.mktmpdir do |tmpdir|
        skill_dir = File.join(tmpdir, "as-git-commit")
        Dir.mkdir(skill_dir)
        File.write(File.join(skill_dir, "SKILL.md"), "---\nname: as-git-commit\n---\nContent")

        client = Ace::LLM::Providers::CLI::CodexClient.new(skills_dir: tmpdir)
        result = client.send(:rewrite_skill_commands, "/as-git-commit please")
        # Codex formatter: /as-git-commit → $as-git-commit
        assert_equal "$as-git-commit please", result
      end
    end

    it "returns prompt unchanged when no skills_dir" do
      client = Ace::LLM::Providers::CLI::CodexClient.new(skills_dir: "/nonexistent/path")
      result = client.send(:rewrite_skill_commands, "/onboard please")
      assert_equal "/onboard please", result
    end

    it "rewrites multiple skill commands in same prompt" do
      Dir.mktmpdir do |tmpdir|
        skill1_dir = File.join(tmpdir, "skill1")
        skill2_dir = File.join(tmpdir, "skill2")
        Dir.mkdir(skill1_dir)
        Dir.mkdir(skill2_dir)
        File.write(File.join(skill1_dir, "SKILL.md"), "---\nname: onboard\n---\nContent")
        File.write(File.join(skill2_dir, "SKILL.md"), "---\nname: commit\n---\nContent")

        client = Ace::LLM::Providers::CLI::CodexClient.new(skills_dir: tmpdir)
        result = client.send(:rewrite_skill_commands, "Run /onboard then /commit")
        assert_equal "Run $onboard then $commit", result
      end
    end
  end

  describe "resolve_skills_dir" do
    it "returns configured dir if it exists" do
      Dir.mktmpdir do |tmpdir|
        client = Ace::LLM::Providers::CLI::CodexClient.new(skills_dir: tmpdir)
        result = client.send(:resolve_skills_dir)
        assert_equal tmpdir, result
      end
    end

    it "returns nil for nonexistent configured dir" do
      client = Ace::LLM::Providers::CLI::CodexClient.new(skills_dir: "/nonexistent/path")
      result = client.send(:resolve_skills_dir)
      assert_nil result
    end

    it "prefers provider-specific .codex/skills fallback dir" do
      Dir.mktmpdir do |tmpdir|
        default_skills = File.join(tmpdir, ".codex", "skills")
        FileUtils.mkdir_p(default_skills)

        Dir.chdir(tmpdir) do
          client = Ace::LLM::Providers::CLI::CodexClient.new
          result = client.send(:resolve_skills_dir)
          expected = File.join(Dir.pwd, ".codex", "skills")
          assert_equal expected, result
        end
      end
    end

    it "returns nil when provider-specific dir is missing" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          client = Ace::LLM::Providers::CLI::CodexClient.new
          result = client.send(:resolve_skills_dir)
          assert_nil result
        end
      end
    end

    it "returns nil when default dir does not exist" do
      Dir.mktmpdir do |tmpdir|
        Dir.chdir(tmpdir) do
          client = Ace::LLM::Providers::CLI::CodexClient.new
          result = client.send(:resolve_skills_dir)
          assert_nil result
        end
      end
    end
  end
end
