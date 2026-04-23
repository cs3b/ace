# frozen_string_literal: true

require_relative "../../test_helper"

class SetupExecutorTest < Minitest::Test
  FakeStatus = Struct.new(:exitstatus) do
    def success?
      exitstatus.zero?
    end
  end

  def setup
    @executor = Ace::Test::EndToEndRunner::Molecules::SetupExecutor.new
  end

  def test_git_init_creates_repo
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: ["git-init"],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert Dir.exist?(File.join(sandbox, ".git"))
    end
  end

  def test_git_init_sets_user_config
    Dir.mktmpdir do |sandbox|
      @executor.execute(setup_steps: ["git-init"], sandbox_dir: sandbox)

      name = `git -C #{sandbox} config user.name`.strip
      email = `git -C #{sandbox} config user.email`.strip
      assert_equal "Test User", name
      assert_equal "test@example.com", email
    end
  end

  def test_git_init_seeds_default_and_custom_git_excludes
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: ["git-init"],
        sandbox_dir: sandbox,
        git_excludes: ["ace-demo/", ".ace-handbook/"]
      )

      assert result[:success]

      exclude_path = File.join(sandbox, ".git", "info", "exclude")
      patterns = File.readlines(exclude_path, chomp: true)

      assert_includes patterns, ".ace-local/"
      assert_includes patterns, "reports/"
      assert_includes patterns, "results/"
      assert_includes patterns, "ace-demo/"
      assert_includes patterns, ".ace-handbook/"
    end
  end

  def test_git_excludes_keep_support_paths_out_of_fixture_commit
    Dir.mktmpdir do |sandbox|
      FileUtils.mkdir_p(File.join(sandbox, ".ace-local", "e2e-runtime"))
      FileUtils.mkdir_p(File.join(sandbox, "ace-demo"))
      FileUtils.mkdir_p(File.join(sandbox, "results", "tc", "01"))
      File.write(File.join(sandbox, ".ace-local", "e2e-runtime", "runtime.txt"), "runtime")
      File.write(File.join(sandbox, "ace-demo", "copied.txt"), "copied")
      File.write(File.join(sandbox, "results", "tc", "01", "artifact.txt"), "artifact")
      File.write(File.join(sandbox, "keep.txt"), "keep")

      result = @executor.execute(
        setup_steps: [
          "git-init",
          {"run" => "git add -A && git commit -m 'initial' --quiet"},
          {"run" => "git ls-files > tracked.txt"}
        ],
        sandbox_dir: sandbox,
        git_excludes: ["ace-demo/"]
      )

      assert result[:success]

      tracked = File.read(File.join(sandbox, "tracked.txt"))
      assert_includes tracked, "keep.txt"
      refute_includes tracked, ".ace-local/e2e-runtime/runtime.txt"
      refute_includes tracked, "ace-demo/copied.txt"
      refute_includes tracked, "results/tc/01/artifact.txt"
    end
  end

  def test_copy_fixtures
    Dir.mktmpdir do |tmpdir|
      sandbox = File.join(tmpdir, "sandbox")
      fixture_dir = File.join(tmpdir, "fixtures")
      FileUtils.mkdir_p(fixture_dir)
      File.write(File.join(fixture_dir, "test.rb"), "puts 'hello'")

      result = @executor.execute(
        setup_steps: ["copy-fixtures"],
        sandbox_dir: sandbox,
        fixture_source: fixture_dir
      )

      assert result[:success]
      assert File.exist?(File.join(sandbox, "test.rb"))
    end
  end

  def test_copy_fixtures_without_source_raises
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: ["copy-fixtures"],
        sandbox_dir: sandbox,
        fixture_source: nil
      )

      refute result[:success]
      assert_match(/No fixture source/, result[:error])
    end
  end

  def test_run_executes_command
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [{"run" => "echo hello > file.txt"}],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal "hello\n", File.read(File.join(sandbox, "file.txt"))
    end
  end

  def test_run_failure_raises
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [{"run" => "false"}],
        sandbox_dir: sandbox
      )

      refute result[:success]
      assert_match(/run.*failed/, result[:error])
    end
  end

  def test_run_uses_env_vars
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [
          {"agent-env" => {"MY_VAR" => "hello_world"}},
          {"run" => "echo $MY_VAR > env_out.txt"}
        ],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal "hello_world\n", File.read(File.join(sandbox, "env_out.txt"))
    end
  end

  def test_write_file_creates_file
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [{"write-file" => {"path" => "config.yml", "content" => "key: value\n"}}],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal "key: value\n", File.read(File.join(sandbox, "config.yml"))
    end
  end

  def test_write_file_creates_parent_dirs
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [{"write-file" => {"path" => "deep/nested/file.txt", "content" => "hello"}}],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal "hello", File.read(File.join(sandbox, "deep", "nested", "file.txt"))
    end
  end

  def test_env_propagates_to_run
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [
          {"agent-env" => {"GREETING" => "hi", "NAME" => "world"}},
          {"run" => "echo \"$GREETING $NAME\" > out.txt"}
        ],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal "hi world\n", File.read(File.join(sandbox, "out.txt"))
    end
  end

  def test_multi_step_sequence
    Dir.mktmpdir do |tmpdir|
      sandbox = File.join(tmpdir, "sandbox")
      fixture_dir = File.join(tmpdir, "fixtures")
      FileUtils.mkdir_p(fixture_dir)
      File.write(File.join(fixture_dir, "valid.rb"), "puts 'ok'")

      result = @executor.execute(
        setup_steps: [
          "git-init",
          "copy-fixtures",
          {"write-file" => {"path" => ".config/settings.yml", "content" => "verbose: true\n"}},
          {"run" => "git add -A && git commit -m 'initial' --quiet"}
        ],
        sandbox_dir: sandbox,
        fixture_source: fixture_dir
      )

      assert result[:success]
      assert_equal 4, result[:steps_completed]
      assert Dir.exist?(File.join(sandbox, ".git"))
      assert File.exist?(File.join(sandbox, "valid.rb"))
      assert File.exist?(File.join(sandbox, ".config", "settings.yml"))
      # Verify git commit was made
      log = `git -C #{sandbox} log --oneline`.strip
      refute_empty log
    end
  end

  def test_step_failure_stops_execution
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [
          {"run" => "false"},
          {"run" => "echo should_not_run > marker.txt"}
        ],
        sandbox_dir: sandbox
      )

      refute result[:success]
      assert_equal 0, result[:steps_completed]
      refute File.exist?(File.join(sandbox, "marker.txt"))
    end
  end

  def test_empty_steps_succeeds
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(setup_steps: [], sandbox_dir: sandbox)

      assert result[:success]
      assert_equal 0, result[:steps_completed]
      assert_nil result[:error]
    end
  end

  def test_env_returned_in_result
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [
          {"agent-env" => {"FOO" => "bar", "BAZ" => "qux"}},
          {"run" => "echo ok"}
        ],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal "bar", result[:env]["FOO"]
      assert_equal "qux", result[:env]["BAZ"]
      assert result[:env].key?("PATH")
    end
  end

  def test_reserved_env_keys_are_ignored
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [
          {"agent-env" => {
            "PROJECT_ROOT_PATH" => "/tmp/override",
            "PATH" => "/tmp/bin",
            "ACE_CONFIG_PATH" => "/tmp/config",
            "SAFE_VALUE" => "ok"
          }}
        ],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal "ok", result[:env]["SAFE_VALUE"]
      refute result[:env].key?("ACE_CONFIG_PATH")
      refute_equal "/tmp/bin", result[:env]["PATH"]
    end
  end

  def test_env_empty_when_no_env_steps
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [{"run" => "echo ok"}],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert result[:env].key?("PATH")
    end
  end

  def test_execute_returns_prepared_env_with_provider_credentials
    Dir.mktmpdir do |sandbox|
      old_google = ENV["GOOGLE_API_KEY"]
      old_gemini = ENV["GEMINI_API_KEY"]
      ENV["GOOGLE_API_KEY"] = "google-secret"
      ENV.delete("GEMINI_API_KEY")

      result = @executor.execute(
        setup_steps: [{"run" => "printf '%s' \"$GOOGLE_API_KEY\" > provider.txt"}],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal "google-secret", File.read(File.join(sandbox, "provider.txt"))
      assert_equal "google-secret", result[:env]["GOOGLE_API_KEY"]
    ensure
      old_google.nil? ? ENV.delete("GOOGLE_API_KEY") : ENV["GOOGLE_API_KEY"] = old_google
      old_gemini.nil? ? ENV.delete("GEMINI_API_KEY") : ENV["GEMINI_API_KEY"] = old_gemini
    end
  end

  def test_sandbox_backend_prepares_env_before_setup_steps
    sandbox_backend = Class.new do
      def prepared_env(base_env)
        base_env.merge(
          "HOME" => "/tmp/ace-home",
          "TMPDIR" => "/tmp/ace-tmp",
          "XDG_RUNTIME_DIR" => "/tmp/ace-runtime",
          "TMUX_TMPDIR" => "/tmp/ace-runtime"
        )
      end
    end.new

    executor = Ace::Test::EndToEndRunner::Molecules::SetupExecutor.new(sandbox_backend: sandbox_backend)

    Dir.mktmpdir do |sandbox|
      result = executor.execute(setup_steps: [], sandbox_dir: sandbox)

      assert result[:success]
      assert_equal "/tmp/ace-home", result[:env]["HOME"]
      assert_equal "/tmp/ace-runtime", result[:env]["TMUX_TMPDIR"]
    end
  end

  def test_tmux_session_uses_scenario_name_when_provided
    calls = []
    executor = build_tmux_executor(command_calls: calls)

    Dir.mktmpdir do |sandbox|
      result = executor.execute(
        setup_steps: ["tmux-session"],
        sandbox_dir: sandbox,
        scenario_name: "TS-TEST-001"
      )

      assert result[:success]
      assert_equal "TS-TEST-001-e2e", result[:tmux_session]
      assert_equal "TS-TEST-001-e2e", result[:env]["ACE_TMUX_SESSION"]
      assert_equal ["tmux", "new-session", "-d", "-s", "TS-TEST-001-e2e"], calls.first.drop(1)
    end
  end

  def test_tmux_session_uses_run_id_with_name_source_run_id
    calls = []
    executor = build_tmux_executor(command_calls: calls)

    Dir.mktmpdir do |sandbox|
      result = executor.execute(
        setup_steps: [{"tmux-session" => {"name-source" => "run-id"}}],
        sandbox_dir: sandbox,
        scenario_name: "TS-TEST-001",
        run_id: "8pny7t0"
      )

      assert result[:success]
      assert_equal "8pny7t0", result[:tmux_session]
      assert_equal "8pny7t0", result[:env]["ACE_TMUX_SESSION"]
      assert_equal ["tmux", "new-session", "-d", "-s", "8pny7t0"], calls.first.drop(1)
    end
  end

  def test_tmux_session_name_source_run_id_falls_back_when_run_id_missing
    calls = []
    executor = build_tmux_executor(command_calls: calls)

    Dir.mktmpdir do |sandbox|
      result = executor.execute(
        setup_steps: [{"tmux-session" => {"name-source" => "run-id"}}],
        sandbox_dir: sandbox,
        scenario_name: "TS-TEST-001"
      )

      assert result[:success]
      assert_equal "TS-TEST-001-e2e", result[:tmux_session]
      assert_equal "TS-TEST-001-e2e", result[:env]["ACE_TMUX_SESSION"]
      assert_equal ["tmux", "new-session", "-d", "-s", "TS-TEST-001-e2e"], calls.first.drop(1)
    end
  end

  def test_tmux_session_uses_fallback_name_without_scenario_name
    calls = []
    executor = build_tmux_executor(command_calls: calls, time_source: -> { 123_456 })

    Dir.mktmpdir do |sandbox|
      result = executor.execute(
        setup_steps: ["tmux-session"],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal "ace-e2e-123456", result[:tmux_session]
      assert_equal ["tmux", "new-session", "-d", "-s", "ace-e2e-123456"], calls.first.drop(1)
    end
  end

  def test_teardown_clears_tmux_session
    command_calls = []
    system_calls = []
    executor = build_tmux_executor(command_calls: command_calls, system_calls: system_calls)

    Dir.mktmpdir do |sandbox|
      result = executor.execute(
        setup_steps: ["tmux-session"],
        sandbox_dir: sandbox,
        scenario_name: "TS-TEARDOWN-001"
      )

      assert result[:success]
      assert_equal "TS-TEARDOWN-001-e2e", result[:tmux_session]

      executor.teardown

      assert_equal [["tmux", "kill-session", "-t", "TS-TEARDOWN-001-e2e"]], system_calls
      assert_equal ["tmux", "new-session", "-d", "-s", "TS-TEARDOWN-001-e2e"], command_calls.first.drop(1)
    end
  end

  def test_run_re_exports_env_vars_to_protect_against_mise_clobbering
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [
          {"run" => "echo $PROJECT_ROOT_PATH > prp_out.txt"}
        ],
        sandbox_dir: sandbox,
        initial_env: {"PROJECT_ROOT_PATH" => "/custom/path"}
      )

      assert result[:success]
      assert_equal "/custom/path\n", File.read(File.join(sandbox, "prp_out.txt"))
    end
  end

  def test_run_re_exports_process_env_vars_when_no_explicit_override
    Dir.mktmpdir do |sandbox|
      original = ENV["PROJECT_ROOT_PATH"]
      ENV["PROJECT_ROOT_PATH"] = "/from/process/env"

      result = @executor.execute(
        setup_steps: [
          {"run" => "echo $PROJECT_ROOT_PATH > prp_out.txt"}
        ],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal "/from/process/env\n", File.read(File.join(sandbox, "prp_out.txt"))
    ensure
      if original
        ENV["PROJECT_ROOT_PATH"] = original
      else
        ENV.delete("PROJECT_ROOT_PATH")
      end
    end
  end

  def test_merged_environment_strips_ambient_tmux_vars
    Dir.mktmpdir do |sandbox|
      original_tmux = ENV["TMUX"]
      original_tmux_pane = ENV["TMUX_PANE"]
      ENV["TMUX"] = "/tmp/tmux-socket,123,0"
      ENV["TMUX_PANE"] = "%9"

      result = @executor.execute(
        setup_steps: [
          {"run" => "printf '%s|%s' \"${TMUX-unset}\" \"${TMUX_PANE-unset}\" > tmux_env.txt"}
        ],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal "unset|unset", File.read(File.join(sandbox, "tmux_env.txt"))
    ensure
      original_tmux ? ENV["TMUX"] = original_tmux : ENV.delete("TMUX")
      original_tmux_pane ? ENV["TMUX_PANE"] = original_tmux_pane : ENV.delete("TMUX_PANE")
    end
  end

  private

  def build_tmux_executor(command_calls:, system_calls: [], time_source: -> { Time.now.to_i })
    Ace::Test::EndToEndRunner::Molecules::SetupExecutor.new(
      command_runner: lambda do |*args, **kwargs|
        command_calls << args
        ["", "", FakeStatus.new(0)]
      end,
      system_runner: lambda do |*args, **kwargs|
        system_calls << args
        true
      end,
      time_source: time_source
    )
  end
end
