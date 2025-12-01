# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "ace/taskflow"
require "ace/taskflow/organisms/task_manager"
require "ace/taskflow/molecules/task_arg_parser"
require "ace/taskflow/commands/tasks_command"

# Integration tests for hierarchical task CLI features
# Tests complete workflow: create orchestrator, create subtasks, display hierarchy
class HierarchicalTaskCliIntegrationTest < AceTaskflowTestCase
  def setup
    super
    @temp_dir = Dir.mktmpdir
    @project_root = File.join(@temp_dir, "test-project")
    FileUtils.mkdir_p(@project_root)

    # Save and set PROJECT_ROOT_PATH to temp directory
    @original_project_root = ENV["PROJECT_ROOT_PATH"]
    ENV["PROJECT_ROOT_PATH"] = @project_root

    # Setup ace-taskflow project structure
    taskflow_root = File.join(@project_root, ".ace-taskflow")
    config_dir = File.join(@project_root, ".ace", "taskflow")
    t_dir = File.join(taskflow_root, "v.0.9.0", "t")
    FileUtils.mkdir_p([taskflow_root, config_dir, t_dir])

    # Create config
    File.write(File.join(config_dir, "config.yml"), <<~YAML)
      taskflow:
        root: .ace-taskflow
        task_dir: t
      YAML

    # Create active release
    release_dir = File.join(taskflow_root, "v.0.9.0")
    File.write(File.join(release_dir, ".active"), "")

    Dir.chdir(@project_root) do
      Ace::Taskflow.reset_configuration!
    end
  end

  def teardown
    # Restore original PROJECT_ROOT_PATH
    if @original_project_root
      ENV["PROJECT_ROOT_PATH"] = @original_project_root
    else
      ENV.delete("PROJECT_ROOT_PATH")
    end
    FileUtils.rm_rf(@temp_dir)
    super
  end

  def test_cli_create_and_display_hierarchy
    skip "Pending full implementation of hierarchical task display feature"
    Dir.chdir(@project_root) do
      # Create an orchestrator task
      manager = Ace::Taskflow::Organisms::TaskManager.new
      result = manager.create_task("Test Orchestrator", release: "v.0.9.0")
      assert result[:success]
      orchestrator_id = result[:task_id]

      # Mark it as orchestrator by adding .00 file
      orchestrator_task = Dir.glob(File.join(@project_root, ".ace-taskflow/v.0.9.0/t", "#{result[:task_number]}-*")).first
      orchestrator_file = File.join(orchestrator_task, "#{result[:task_number]}.00-orchestrator.s.md")
      FileUtils.cp(Dir.glob(File.join(orchestrator_task, "*.s.md")).first, orchestrator_file)

      # Update orchestrator file to have subtasks frontmatter
      content = File.read(orchestrator_file)
      content = content.gsub(/id: v\.0\.9\.0\+task\.001/, "id: #{orchestrator_id}")
      content = content.sub(/---\n\n# /, "---\nsubtasks: []\n\n# ")
      File.write(orchestrator_file, content)

      # Create subtasks using --child-of flag
      subtask1_result = manager.create_subtask(result[:task_number].to_s, "First Subtask", metadata: {})
      assert subtask1_result[:success]

      subtask2_result = manager.create_subtask(result[:task_number].to_s, "Second Subtask", metadata: {})
      assert subtask2_result[:success]

      # Test hierarchical display (--subtasks)
      tasks_command = Ace::Taskflow::Commands::TasksCommand.new
      output = capture_stdout do
        tasks_command.execute(["--subtasks"])
      end

      # Verify hierarchical output
      assert_match(/Test Orchestrator/, output)
      assert_output_has_tree_node(output, "First Subtask")
      assert_output_has_tree_node(output, "Second Subtask")

      # Test flat display (--flat)
      output = capture_stdout do
        tasks_command.execute(["--flat"])
      end

      # Verify flat output (no hierarchy)
      assert_match(/Test Orchestrator/, output)
      assert_match(/First Subtask/, output)
      assert_match(/Second Subtask/, output)
      # Should not have tree characters
      refute_match(/[├│└]/, output)

      # Test no-subtasks display
      output = capture_stdout do
        tasks_command.execute(["--no-subtasks"])
      end

      # Verify orchestrator only (no subtasks shown)
      assert_match(/Test Orchestrator/, output)
      refute_match(/First Subtask/, output)
      refute_match(/Second Subtask/, output)
    end
  end

  def test_cli_child_of_with_qualified_references
    skip "Pending full implementation of hierarchical task display feature"
    Dir.chdir(@project_root) do
      # Create parent orchestrator
      manager = Ace::Taskflow::Organisms::TaskManager.new
      orchestrator_result = manager.create_task("Parent Orchestrator", release: "v.0.9.0")
      assert orchestrator_result[:success]

      # Mark as orchestrator
      orchestrator_task = Dir.glob(File.join(@project_root, ".ace-taskflow/v.0.9.0/t", "#{orchestrator_result[:task_number]}-*")).first
      orchestrator_file = File.join(orchestrator_task, "#{orchestrator_result[:task_number]}.00-orchestrator.s.md")
      FileUtils.cp(Dir.glob(File.join(orchestrator_task, "*.s.md")).first, orchestrator_file)

      # Create subtask with qualified parent reference
      task_arg_parser = Ace::Taskflow::Molecules::TaskArgParser.new
      args = ["Child Subtask", "--child-of", orchestrator_result[:task_id]]
      parsed = task_arg_parser.parse(args)

      # Test task creation with qualified reference
      create_result = manager.create_subtask(orchestrator_result[:task_id], "Child Subtask", metadata: {})
      assert create_result[:success]

      # Verify subtask has correct parent
      subtask = manager.show_task(create_result[:task_id])
      assert_equal orchestrator_result[:task_id], subtask[:parent_id]
    end
  end

  private

  def capture_stdout
    original_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = original_stdout
  end
end