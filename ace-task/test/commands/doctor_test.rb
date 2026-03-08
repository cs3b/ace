# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"
require "stringio"

# CLI integration tests for ace-task doctor command.
class TaskDoctorCliTest < AceTaskTestCase
  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def run_cli(args)
    old_stdout = $stdout
    old_stderr = $stderr
    $stdout = StringIO.new
    $stderr = StringIO.new

    exit_code = 0

    begin
      Ace::Task::TaskCLI.start(args)
    rescue Ace::Core::CLI::Error => e
      $stderr.puts e.message
      exit_code = e.exit_code
    rescue SystemExit => e
      exit_code = e.status
    end

    { stdout: $stdout.string, stderr: $stderr.string, exit_code: exit_code }
  ensure
    $stdout = old_stdout
    $stderr = old_stderr
  end

  def with_cli_root(root_dir)
    loader = Ace::Task::Molecules::TaskConfigLoader
    original_load = loader.method(:load)
    original_root = loader.method(:root_dir)

    loader.define_singleton_method(:load) do |**_opts|
      { "task" => { "root_dir" => root_dir } }
    end
    loader.define_singleton_method(:root_dir) do |_config = nil|
      root_dir
    end
    yield
  ensure
    loader = Ace::Task::Molecules::TaskConfigLoader
    loader.define_singleton_method(:load) { |**opts| original_load.call(**opts) }
    loader.define_singleton_method(:root_dir) { |config = nil| original_root.call(config) }
  end

  # ---------------------------------------------------------------------------
  # basic doctor
  # ---------------------------------------------------------------------------

  def test_doctor_healthy
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "good-task", status: "pending", tags: ["test"])
      with_cli_root(root) do
        result = run_cli(["doctor"])
        assert_equal 0, result[:exit_code], "Expected exit 0: #{result[:stderr]}"
        assert_includes result[:stdout], "Task Health Check"
        assert_includes result[:stdout], "100/100"
      end
    end
  end

  def test_doctor_with_issues
    with_tasks_dir do |root|
      dir = File.join(root, "8pp.t.q7w-broken")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "8pp.t.q7w-broken.s.md"), <<~CONTENT)
        ---
        status: invalid
        title: Broken task
        ---
      CONTENT

      with_cli_root(root) do
        result = run_cli(["doctor"])
        assert_equal 1, result[:exit_code]
        assert_includes result[:stdout], "Issues Found"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # --json
  # ---------------------------------------------------------------------------

  def test_doctor_json_output
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "test-task", status: "pending", tags: ["test"])
      with_cli_root(root) do
        result = run_cli(["doctor", "--json"])
        assert_equal 0, result[:exit_code], result[:stderr]

        parsed = JSON.parse(result[:stdout])
        assert_equal 100, parsed["health_score"]
        assert parsed["valid"]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # --quiet
  # ---------------------------------------------------------------------------

  def test_doctor_quiet_healthy
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "good", status: "pending", tags: ["test"])
      with_cli_root(root) do
        result = run_cli(["doctor", "--quiet"])
        assert_equal 0, result[:exit_code]
        assert_empty result[:stdout].strip
      end
    end
  end

  def test_doctor_quiet_unhealthy
    with_tasks_dir do |root|
      dir = File.join(root, "8pp.t.q7w-bad")
      FileUtils.mkdir_p(dir)
      File.write(File.join(dir, "8pp.t.q7w-bad.s.md"), "---\nstatus: invalid\n---\n")

      with_cli_root(root) do
        result = run_cli(["doctor", "--quiet"])
        assert_equal 1, result[:exit_code]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # --check
  # ---------------------------------------------------------------------------

  def test_doctor_check_frontmatter
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "test", status: "pending", tags: ["test"])
      with_cli_root(root) do
        result = run_cli(["doctor", "--check", "frontmatter"])
        assert_equal 0, result[:exit_code], result[:stderr]
      end
    end
  end

  def test_doctor_check_structure
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "test", status: "pending", tags: ["test"])
      with_cli_root(root) do
        result = run_cli(["doctor", "--check", "structure"])
        assert_equal 0, result[:exit_code], result[:stderr]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # --errors-only
  # ---------------------------------------------------------------------------

  def test_doctor_errors_only
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "test", status: "done")
      with_cli_root(root) do
        result = run_cli(["doctor", "--errors-only"])
        assert_equal 0, result[:exit_code]
      end
    end
  end

  # ---------------------------------------------------------------------------
  # --auto-fix --dry-run
  # ---------------------------------------------------------------------------

  def test_doctor_auto_fix_dry_run
    with_tasks_dir do |root|
      backup = File.join(root, "old.backup.md")
      File.write(backup, "stale backup content")
      create_task_fixture(root, id: "8pp.t.q7w", slug: "test", status: "pending", tags: ["test"])

      with_cli_root(root) do
        result = run_cli(["doctor", "--auto-fix", "--dry-run"])
        assert File.exist?(backup)
        assert_includes result[:stdout], "DRY RUN"
      end
    end
  end

  # ---------------------------------------------------------------------------
  # --no-color
  # ---------------------------------------------------------------------------

  def test_doctor_no_color
    with_tasks_dir do |root|
      create_task_fixture(root, id: "8pp.t.q7w", slug: "test", status: "pending", tags: ["test"])
      with_cli_root(root) do
        result = run_cli(["doctor", "--no-color"])
        assert_equal 0, result[:exit_code]
        refute_match(/\e\[/, result[:stdout])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # help shows doctor
  # ---------------------------------------------------------------------------

  def test_help_lists_doctor_command
    result = run_cli(["help"])
    assert_includes result[:stdout], "doctor"
  end

  # ---------------------------------------------------------------------------
  # nonexistent root
  # ---------------------------------------------------------------------------

  def test_doctor_nonexistent_root
    with_cli_root("/tmp/nonexistent-tasks-#{rand(99999)}") do
      result = run_cli(["doctor"])
      assert_equal 1, result[:exit_code]
      assert_includes result[:stderr], "not found"
    end
  end

end
