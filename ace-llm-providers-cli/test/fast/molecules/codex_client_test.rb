# frozen_string_literal: true

require_relative "../../test_helper"
require "fileutils"
require "tmpdir"
require "yaml"

describe "CodexClient" do
  before do
    @client = Ace::LLM::Providers::CLI::CodexClient.new
  end

  it "does not split a structured report at a filename containing codex" do
    report = JSON.pretty_generate({"files" => [".ace/llm/presets/codex/review.yml"], "complete" => true})
    status = Object.new
    status.define_singleton_method(:success?) { true }
    result = @client.send(:parse_codex_response, report, "", status, "Review", {})
    assert_equal report, result[:text]
  end

  it "keeps a standalone codex line in a report without a CLI banner" do
    report = "First finding\ncodex\nSecond finding"
    status = Object.new
    status.define_singleton_method(:success?) { true }
    result = @client.send(:parse_codex_response, report, "", status, "Review", {})
    assert_equal report, result[:text]
  end

  it "prefers Codex's last-message file over transcript markers" do
    Dir.mktmpdir do |dir|
      path = File.join(dir, "last.md")
      File.write(path, "First finding\ncodex\nSecond finding\n")
      status = Object.new
      status.define_singleton_method(:success?) { true }
      result = @client.send(:parse_codex_response, "OpenAI Codex v0.156.1\ncodex\ntranscript", "",
        status, "Review", {last_message_file: path})
      assert_equal "First finding\ncodex\nSecond finding", result[:text]
    end
  end

  it "rejects an empty or missing requested final message instead of accepting a transcript" do
    status = Object.new
    status.define_singleton_method(:success?) { true }
    Dir.mktmpdir do |dir|
      path = File.join(dir, "last.md")
      [path, File.join(dir, "missing.md")].each do |file|
        File.write(file, "  \n") if file == path
        assert_raises(Ace::LLM::ProviderError) do
          @client.send(:parse_codex_response, "OpenAI Codex v0.156.1\ncodex\nincomplete", "",
            status, "Review", {last_message_file: file})
        end
      end
    end
  end

  it "initializes with default model" do
    model = @client.instance_variable_get(:@model)
    assert_equal "gpt-5.6-terra", model
  end

  it "can be initialized with custom model" do
    client = Ace::LLM::Providers::CLI::CodexClient.new(model: "gpt-5.4-mini")
    model = client.instance_variable_get(:@model)
    assert_equal "gpt-5.4-mini", model
  end

  it "preserves exact models and reasoning arguments in both native command paths" do
    ids = %w[gpt-6-astra gpt-5.6-sol gpt-5.6-terra gpt-5.6-luna gpt-5.3-chat-latest
      gpt-5.3-codex gpt-5.3-codex-spark gpt-5.4 gpt-5.4-mini gpt-5.4-nano gpt-5.4-pro gpt-9]
    ids.each do |id|
      client = Ace::LLM::Providers::CLI::CodexClient.new(model: id)
      %i[build_codex_command build_codex_interactive_command].each do |method|
        cmd = client.send(method, "ping", {cli_args: ["-c", 'model_reasoning_effort="high"']})
        assert_equal id, cmd.fetch(cmd.index("--model") + 1)
        assert_includes cmd, "model_reasoning_effort=high"
      end
    end
  end

  it "rejects non-interactive model overrides in CLI args" do
    client = Ace::LLM::Providers::CLI::CodexClient.new(model: "gpt-6-sol")
    [["-c", "model=gpt-6-astra"], ["-mgpt-6-astra"],
      ["-cmodel=gpt-6-astra"], ["--config=model_provider=other"],
      ["--profile", "other"], ["-c", "profiles.review.model=gpt-6-astra"]].each do |args|
      assert_raises(Ace::LLM::ProviderError) do
        client.send(:build_codex_command, "ping", {cli_args: args})
      end
    end
  end

  it "describes a non-interactive CLI argument conflict accurately" do
    error = assert_raises(Ace::LLM::ProviderError) do
      @client.send(:build_codex_command, "ping", {cli_args: ["--model", "other"]})
    end
    refute_match(/interactive mode/, error.message)
  end

  it "rejects interactive model overrides in CLI args" do
    assert_raises(Ace::LLM::ProviderError) do
      @client.send(:build_codex_interactive_command, "ping", {cli_args: ["-c", "model=other"]})
    end
  end

  it "rejects a second non-interactive output-last-message destination" do
    assert_raises(Ace::LLM::ProviderError) do
      @client.send(:build_codex_command, "ping", {
        last_message_file: "/tmp/owned.md", cli_args: ["--output-last-message", "/tmp/other.md"]
      })
    end
  end

  it "uses configured local default and listing without invented limits" do
    registry = Ace::LLM::Molecules::ClientRegistry.new
    registry.stub(:models_for_provider, ["native-local", "gpt-5.4"]) do
      Ace::LLM::Molecules::ClientRegistry.stub(:new, registry) do
        client = Ace::LLM::Providers::CLI::CodexClient.new
        assert_equal "native-local", client.instance_variable_get(:@model)
        assert_equal [{id: "native-local", name: "native-local"}, {id: "gpt-5.4", name: "gpt-5.4"}], client.list_models
      end
    end
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
    assert models.any? { |m| m[:id] == "gpt-5.3-codex" }
    assert models.any? { |m| m[:id] == "gpt-5.3-codex-spark" }
    assert models.any? { |m| m[:id] == "gpt-5.4" }
    assert models.any? { |m| m[:id] == "gpt-5.4-mini" }
  end

  it "ships current codex aliases in provider defaults" do
    config = YAML.safe_load_file(
      File.expand_path("../../../.ace-defaults/llm/providers/codex.yml", __dir__),
      permitted_classes: [Date],
      aliases: true
    )

    assert_equal "gpt-5.6-terra", config.dig("aliases", "model", "gpt")
    assert_equal "gpt-5.6-terra", config.dig("aliases", "model", "codex")
    assert_equal "gpt-5.6-luna", config.dig("aliases", "model", "mini")
    refute_includes(config.fetch("models"), "gpt-5-mini")
    refute_includes(config.fetch("aliases").fetch("model").values, "gpt-5-mini")
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
      assert_includes cmd, "--model"
      assert_includes cmd, "gpt-5.6-terra"
    end

    it "includes model flag when non-default model specified" do
      client = Ace::LLM::Providers::CLI::CodexClient.new(model: "gpt-5.4-mini")
      cmd = client.send(:build_codex_command, "Test prompt", {})

      assert_includes cmd, "--model"
      assert_includes cmd, "gpt-5.4-mini"
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

  describe "build_interactive_invocation" do
    it "builds interactive codex command without exec and rewrites skills" do
      @client.stub(:codex_available?, true) do
        @client.stub(:codex_authenticated?, true) do
          @client.stub(:resolve_skills_dir, "/tmp/skills") do
            @client.instance_variable_get(:@skill_name_reader).stub(:call, ["as-assign-drive"]) do
              invocation = @client.build_interactive_invocation([{role: "user", content: "/as-assign-drive abc123@010"}])
              assert_equal "codex", invocation[:command][0]
              refute_includes invocation[:command], "exec"
              assert_includes invocation[:command].join(" "), "$as-assign-drive abc123@010"
            end
          end
        end
      end
    end

    it "trusts the working directory without changing HOME" do
      @client.stub(:codex_available?, true) do
        @client.stub(:codex_authenticated?, true) do
          invocation = @client.build_interactive_invocation(
            [{role: "user", content: "/as-assign-drive abc123@010"}],
            working_dir: "/tmp/demo-sandbox",
            subprocess_env: {"HOME" => "/home/tester"}
          )

          assert_equal "/home/tester", invocation[:env]["HOME"]
          assert_includes invocation[:command], "-C"
          assert_includes invocation[:command], "/tmp/demo-sandbox"
          assert_includes invocation[:command], "-c"
          assert_includes invocation[:command], 'projects."/tmp/demo-sandbox".trust_level="trusted"'
        end
      end
    end

    it "trusts the working directory outside tmux context" do
      @client.stub(:codex_available?, true) do
        @client.stub(:codex_authenticated?, true) do
          invocation = @client.build_interactive_invocation(
            [{role: "user", content: "/as-assign-drive abc123@010"}],
            working_dir: "/tmp/demo-sandbox",
            subprocess_env: {"ACE_TMUX_SESSION" => nil, "TMUX" => nil}
          )

          refute invocation[:env].key?("HOME")
          assert_includes invocation[:command], "-C"
          assert_includes invocation[:command], "/tmp/demo-sandbox"
          assert_includes invocation[:command], 'projects."/tmp/demo-sandbox".trust_level="trusted"'
        end
      end
    end

    it "escapes trust override paths" do
      @client.stub(:codex_available?, true) do
        @client.stub(:codex_authenticated?, true) do
          Dir.mktmpdir do |tmp_dir|
            trusted_path = File.join(tmp_dir, 'demo-"sandbox"')
            invocation = @client.build_interactive_invocation(
              [{role: "user", content: "/as-assign-drive abc123@010"}],
              working_dir: trusted_path,
              subprocess_env: {"ACE_TMUX_SESSION" => "fork-demo"}
            )

            assert_includes invocation[:command], %(projects."#{trusted_path.gsub("\\", "\\\\").gsub("\"", "\\\"")}".trust_level="trusted")
          end
        end
      end
    end

    it "rejects user-provided interactive cd cli args" do
      @client.stub(:codex_available?, true) do
        @client.stub(:codex_authenticated?, true) do
          ["--cd /tmp/other", "-C /tmp/other"].each do |cli_args|
            error = assert_raises(Ace::LLM::ProviderError) do
              @client.build_interactive_invocation(
                [{role: "user", content: "/as-assign-drive abc123@010"}],
                working_dir: "/tmp/demo-sandbox",
                cli_args: cli_args
              )
            end

            assert_match(/--cd|-C/, error.message)
          end
        end
      end
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
    def stub_capture3(stdout:, stderr: "", success: true, last_message: nil)
      mock_status = Object.new
      mock_status.define_singleton_method(:success?) { success }
      mock_status.define_singleton_method(:exitstatus) { success ? 0 : 1 }

      capture = lambda do |command, **_kwargs|
        if last_message && (index = command.index("--output-last-message"))
          File.write(command[index + 1], last_message)
        end
        [stdout, stderr, mock_status]
      end
      Ace::LLM::Providers::CLI::Molecules::SafeCapture.stub(:call, capture) do
        yield
      end
    end

    it "does not accept a stale caller-provided final message file" do
      Dir.mktmpdir do |dir|
        requested = File.join(dir, "last.md")
        File.write(requested, "old review")
        @client.stub(:codex_available?, true) do
          @client.stub(:codex_authenticated?, true) do
            @client.stub(:resolve_skills_dir, nil) do
              stub_capture3(stdout: "OpenAI Codex v0.156.1\ncodex\nincomplete") do
                assert_raises(Ace::LLM::ProviderError) do
                  @client.generate("Hi", last_message_file: requested)
                end
              end
            end
          end
        end
        refute File.exist?(requested)
      end
    end

    it "keeps an existing diagnostic when command validation rejects CLI args" do
      Dir.mktmpdir do |dir|
        requested = File.join(dir, "last.md")
        File.write(requested, "previous diagnostic")
        @client.stub(:codex_available?, true) do
          @client.stub(:codex_authenticated?, true) do
            @client.stub(:resolve_skills_dir, nil) do
              assert_raises(Ace::LLM::ProviderError) do
                @client.generate("Hi", last_message_file: requested, cli_args: ["--model", "other"])
              end
            end
          end
        end
        assert_equal "previous diagnostic", File.read(requested)
      end
    end

    it "falls back to a tempfile when a stale caller file cannot be removed" do
      Dir.mktmpdir do |dir|
        requested = File.join(dir, "last.md")
        File.write(requested, "stale review")
        original_delete = File.method(:delete)
        delete = lambda do |path|
          raise Errno::EPERM, path if path == requested
          original_delete.call(path)
        end
        capture = lambda do |_cmd, _prompt, options|
          refute_equal requested, options[:last_message_file]
          File.write(options[:last_message_file], "fresh review")
          status = Object.new
          status.define_singleton_method(:success?) { true }
          ["transcript", "", status]
        end
        @client.stub(:codex_available?, true) do
          @client.stub(:codex_authenticated?, true) do
            @client.stub(:resolve_skills_dir, nil) do
              File.stub(:delete, delete) do
                @client.stub(:execute_codex_command, capture) do
                  result = @client.generate("Hi", last_message_file: requested)
                  assert_equal "fresh review", result[:text]
                end
              end
            end
          end
        end
      end
    end

    it "captures directly to the caller path so partial output survives a hard kill" do
      Dir.mktmpdir do |dir|
        requested = File.join(dir, "last.md")
        File.write(requested, "stale")
        capture = lambda do |_cmd, _prompt, options|
          assert_equal requested, options[:last_message_file]
          refute File.exist?(requested)
          File.write(requested, "partial before hard kill")
          raise Ace::LLM::ProviderError, "child stopped"
        end
        @client.stub(:codex_available?, true) do
          @client.stub(:codex_authenticated?, true) do
            @client.stub(:resolve_skills_dir, nil) do
              @client.stub(:execute_codex_command, capture) do
                assert_raises(Ace::LLM::ProviderError) { @client.generate("Hi", last_message_file: requested) }
              end
            end
          end
        end
        assert_equal "partial before hard kill", File.read(requested)
      end
    end

    it "resolves a relative caller path against the Codex working directory" do
      Dir.mktmpdir do |dir|
        requested = File.join(dir, "last.md")
        @client.stub(:codex_available?, true) do
          @client.stub(:codex_authenticated?, true) do
            @client.stub(:resolve_skills_dir, nil) do
              stub_capture3(stdout: "transcript", last_message: "completed") do
                result = @client.generate("Hi", working_dir: dir, last_message_file: "last.md")
                assert_equal "completed", result[:text]
              end
            end
          end
        end
        assert_equal "completed", File.read(requested)
      end
    end

    it "rejects a directory as the last-message destination without writing inside it" do
      Dir.mktmpdir do |dir|
        @client.stub(:codex_available?, true) do
          @client.stub(:codex_authenticated?, true) do
            error = assert_raises(Ace::LLM::ProviderError) do
              @client.generate("Hi", last_message_file: dir)
            end
            assert_match(/must name a file/, error.message)
          end
        end
        assert_empty Dir.children(dir)
      end
    end

    it "keeps an old diagnostic if Codex is unavailable before execution" do
      Dir.mktmpdir do |dir|
        requested = File.join(dir, "last.md")
        File.write(requested, "prior diagnostic")
        @client.stub(:codex_available?, false) do
          assert_raises(Ace::LLM::ProviderError) { @client.generate("Hi", last_message_file: requested) }
        end
        assert_equal "prior diagnostic", File.read(requested)
      end
    end

    it "preserves a partial last message for stall diagnosis on timeout" do
      Dir.mktmpdir do |dir|
        requested = File.join(dir, "last.md")
        timeout = lambda do |_cmd, _prompt, options|
          File.write(options[:last_message_file], "partial diagnostic")
          raise Ace::LLM::ProviderError, "Codex CLI timed out"
        end
        @client.stub(:codex_available?, true) do
          @client.stub(:codex_authenticated?, true) do
            @client.stub(:resolve_skills_dir, nil) do
              @client.stub(:execute_codex_command, timeout) do
                assert_raises(Ace::LLM::ProviderError) do
                  @client.generate("Hi", last_message_file: requested)
                end
              end
            end
          end
        end
        assert_equal "partial diagnostic", File.read(requested)
      end
    end

    it "preserves the timeout error when the partial-message destination is unwritable" do
      Dir.mktmpdir do |dir|
        requested = File.join(dir, "missing", "last.md")
        timeout = lambda do |_cmd, _prompt, options|
          File.write(options[:last_message_file], "partial diagnostic")
          raise Ace::LLM::ProviderError, "Codex CLI timed out"
        end
        @client.stub(:codex_available?, true) do
          @client.stub(:codex_authenticated?, true) do
            @client.stub(:resolve_skills_dir, nil) do
              @client.stub(:execute_codex_command, timeout) do
                error = assert_raises(Ace::LLM::ProviderError) do
                  @client.generate("Hi", last_message_file: requested)
                end
                assert_match(/timed out/, error.message)
              end
            end
          end
        end
      end
    end

    it "keeps a completed response when its diagnostic destination is unwritable" do
      Dir.mktmpdir do |dir|
        requested = File.join(dir, "missing", "last.md")
        @client.stub(:codex_available?, true) do
          @client.stub(:codex_authenticated?, true) do
            @client.stub(:resolve_skills_dir, nil) do
              stub_capture3(stdout: "OpenAI Codex v0.156.1\ncodex\ntranscript", last_message: "Completed review") do
                result = @client.generate("Hi", last_message_file: requested)
                assert_equal "Completed review", result[:text]
                assert_match(/No such file or directory/, result[:metadata][:last_message_copy_error])
              end
            end
          end
        end
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
            stub_capture3(stdout: codex_response, last_message: "Hello from Codex!") do
              result = @client.generate("Hi")
              assert_equal "Hello from Codex!", result[:text]
              assert_equal "codex", result[:metadata][:provider]
              assert_equal "gpt-5.6-terra", result[:metadata][:model]
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
            stub_capture3(stdout: codex_response, last_message: "Test response") do
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
            stub_capture3(stdout: plain_text, last_message: plain_text) do
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
            Ace::LLM::Providers::CLI::Molecules::SafeCapture.stub(:call, lambda { |command, **kwargs|
              captured_kwargs = kwargs
              File.write(command[command.index("--output-last-message") + 1], "ok")
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
            Ace::LLM::Providers::CLI::Molecules::SafeCapture.stub(:call, lambda { |command, **kwargs|
              captured_kwargs = kwargs
              File.write(command[command.index("--output-last-message") + 1], "ok")
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
