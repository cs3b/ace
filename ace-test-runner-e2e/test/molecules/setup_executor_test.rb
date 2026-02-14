# frozen_string_literal: true

require_relative "../test_helper"

class SetupExecutorTest < Minitest::Test
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
        setup_steps: [{ "run" => "echo hello > file.txt" }],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal "hello\n", File.read(File.join(sandbox, "file.txt"))
    end
  end

  def test_run_failure_raises
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [{ "run" => "false" }],
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
          { "env" => { "MY_VAR" => "hello_world" } },
          { "run" => "echo $MY_VAR > env_out.txt" }
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
        setup_steps: [{ "write-file" => { "path" => "config.yml", "content" => "key: value\n" } }],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal "key: value\n", File.read(File.join(sandbox, "config.yml"))
    end
  end

  def test_write_file_creates_parent_dirs
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [{ "write-file" => { "path" => "deep/nested/file.txt", "content" => "hello" } }],
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
          { "env" => { "GREETING" => "hi", "NAME" => "world" } },
          { "run" => "echo \"$GREETING $NAME\" > out.txt" }
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
          { "write-file" => { "path" => ".config/settings.yml", "content" => "verbose: true\n" } },
          { "run" => "git add -A && git commit -m 'initial' --quiet" }
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
          { "run" => "false" },
          { "run" => "echo should_not_run > marker.txt" }
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
          { "env" => { "FOO" => "bar", "BAZ" => "qux" } },
          { "run" => "echo ok" }
        ],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal({ "FOO" => "bar", "BAZ" => "qux" }, result[:env])
    end
  end

  def test_env_empty_when_no_env_steps
    Dir.mktmpdir do |sandbox|
      result = @executor.execute(
        setup_steps: [{ "run" => "echo ok" }],
        sandbox_dir: sandbox
      )

      assert result[:success]
      assert_equal({}, result[:env])
    end
  end
end
