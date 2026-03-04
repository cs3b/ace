# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"
require "stringio"

class TaskPlanCommandTest < AceTaskTestCase
  FakeGenerator = Struct.new(:model) do
    def prompt_paths
      nil
    end

    def generate(task:, context_files:, cache_dir: nil)
      <<~PLAN
        # Plan for #{task.id}
        model: #{model}
        context-count: #{context_files.size}
      PLAN
    end
  end

  def setup
    @tmpdir = Dir.mktmpdir("task-plan-cmd-test")
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)

    @tasks_dir = File.join(@tmpdir, ".ace-tasks")
    create_task_fixture(@tasks_dir, id: "8pp.t.q7w", slug: "plan-me", status: "pending")
    @task_file = File.join(@tasks_dir, "8pp.t.q7w-plan-me", "8pp.t.q7w-plan-me.s.md")
    inject_bundle_files(@task_file, ["README.md"])
    File.write("README.md", "# context\n")

    @original_generator = Ace::Task::CLI::Commands::Plan.generator_class
    Ace::Task::CLI::Commands::Plan.generator_class = FakeGenerator
  end

  def teardown
    Ace::Task::CLI::Commands::Plan.generator_class = @original_generator
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_generates_plan_and_prints_path
    result = run_cli(%w[plan q7w])

    assert_equal 0, result[:exit_code], result[:stderr]
    assert_match(%r{/.cache/ace-task/8pp\.t\.q7w/.+-plan\.md$}, result[:stdout].strip)
    assert File.exist?(result[:stdout].strip)
  end

  def test_reuses_fresh_plan_without_regeneration
    first = run_cli(%w[plan q7w])
    second = run_cli(%w[plan q7w])

    assert_equal first[:stdout].strip, second[:stdout].strip
    assert_equal 0, second[:exit_code], second[:stderr]
  end

  def test_refresh_forces_regeneration
    first = run_cli(%w[plan q7w]).fetch(:stdout).strip
    second = run_cli(%w[plan q7w --refresh]).fetch(:stdout).strip

    refute_equal first, second
  end

  def test_content_prints_plan_body
    run_cli(%w[plan q7w])
    result = run_cli(%w[plan q7w --content])

    assert_equal 0, result[:exit_code], result[:stderr]
    assert_includes result[:stdout], "# Plan for 8pp.t.q7w"
  end

  def test_errors_when_task_not_found
    result = run_cli(%w[plan zzz])

    assert_equal 1, result[:exit_code]
    assert_includes result[:stderr], "not found"
  end

  def test_backend_failure_is_reported
    failing_class = Class.new do
      def initialize(model:); end

      def prompt_paths
        nil
      end

      def generate(task:, context_files:, cache_dir: nil)
        raise Ace::Core::CLI::Error.new("Plan generation backend unavailable")
      end
    end
    Ace::Task::CLI::Commands::Plan.generator_class = failing_class

    result = run_cli(%w[plan q7w --refresh])

    assert_equal 1, result[:exit_code]
    assert_includes result[:stderr], "backend unavailable"
  end

  private

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

  def inject_bundle_files(task_file, files)
    content = File.read(task_file)
    frontmatter, body = Ace::Support::Items::Atoms::FrontmatterParser.parse(content)
    frontmatter["bundle"] = { "files" => files }

    File.write(task_file, "#{frontmatter.to_yaml}---\n\n#{body}")
  end
end
