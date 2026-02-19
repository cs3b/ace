# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/organisms/task_manager"

# Tests for task reorganization methods: promote_to_standalone, demote_to_subtask, convert_to_orchestrator
class TaskManagerReorganizationTest < AceTaskflowTestCase
  # Helper: Create orchestrator project with subtasks for promotion tests
  def with_subtask_project
    Dir.mktmpdir do |dir|
      TestFactory.with_stubbed_project_root(dir) do
        setup_orchestrator_with_subtasks(dir)
        yield dir
      end
    end
  end

  # Helper: Create standalone task project for demotion tests
  def with_standalone_and_orchestrator_project
    Dir.mktmpdir do |dir|
      TestFactory.with_stubbed_project_root(dir) do
        setup_standalone_and_orchestrator(dir)
        yield dir
      end
    end
  end

  # Helper: Create standalone task project for convert-to-orchestrator tests
  def with_standalone_task_project
    Dir.mktmpdir do |dir|
      TestFactory.with_stubbed_project_root(dir) do
        setup_standalone_task(dir)
        yield dir
      end
    end
  end

  # ============== promote_to_standalone tests ==============

  def test_promote_to_standalone_success
    with_subtask_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new

        # Stub LLM slug generation
        stub_llm_slug_generation do
          result = manager.promote_to_standalone("121.01")

          assert result[:success], "Should successfully promote subtask: #{result[:message]}"
          assert_match(/Promoted subtask.*121\.01.*standalone/, result[:message])
          assert result[:new_reference], "Should return new reference"
          assert result[:new_path], "Should return new path"

          # Verify new file exists
          assert File.exist?(result[:new_path]), "New standalone task file should exist"

          # Verify content updated - no parent field
          content = File.read(result[:new_path])
          refute_match(/^parent:/, content, "Should not have parent field")

          # Verify original subtask removed
          original_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "121-orchestrator", "121.01-subtask-one.s.md")
          refute File.exist?(original_file), "Original subtask file should be deleted"
        end
      end
    end
  end

  def test_promote_to_standalone_not_a_subtask
    with_standalone_task_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.promote_to_standalone("125")

        refute result[:success], "Should fail for non-subtask"
        assert_match(/not a subtask/, result[:message])
      end
    end
  end

  def test_promote_to_standalone_task_not_found
    with_subtask_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.promote_to_standalone("999.01")

        refute result[:success], "Should fail for non-existent subtask"
        assert_match(/not found/, result[:message])
      end
    end
  end

  def test_promote_to_standalone_dry_run
    with_subtask_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new

        stub_llm_slug_generation do
          result = manager.promote_to_standalone("121.01", dry_run: true)

          assert result[:success], "Dry-run should succeed: #{result[:message]}"
          assert result[:dry_run], "Should indicate dry-run mode"
          assert_match(/DRY-RUN/, result[:message])
          assert result[:operations], "Should list operations"
          assert result[:operations].any? { |op| op.include?("Create directory") }
          assert result[:operations].any? { |op| op.include?("Copy file") }
          assert result[:operations].any? { |op| op.include?("Delete original") }

          # Verify nothing was actually changed
          original_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "121-orchestrator", "121.01-subtask-one.s.md")
          assert File.exist?(original_file), "Original file should still exist after dry-run"
        end
      end
    end
  end

  # ============== demote_to_subtask tests ==============

  def test_demote_to_subtask_success
    with_standalone_and_orchestrator_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new

        stub_llm_slug_generation do
          result = manager.demote_to_subtask("125", "121")

          assert result[:success], "Should successfully demote task: #{result[:message]}"
          assert_match(/Demoted task.*125.*subtask/, result[:message])
          assert result[:new_reference], "Should return new reference"
          assert_match(/121\.\d+/, result[:new_reference])
          assert result[:new_path], "Should return new path"

          # Verify new file exists in parent directory
          assert File.exist?(result[:new_path]), "New subtask file should exist"

          # Verify content has parent field
          content = File.read(result[:new_path])
          assert_match(/^parent: v\.0\.9\.0\+task\.121/, content, "Should have parent field")

          # Verify original directory removed
          original_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "125-standalone-task")
          refute Dir.exist?(original_dir), "Original task directory should be deleted"
        end
      end
    end
  end

  def test_demote_to_subtask_already_subtask
    with_subtask_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.demote_to_subtask("121.01", "121")

        refute result[:success], "Should fail for already-subtask"
        assert_match(/already a subtask/, result[:message])
      end
    end
  end

  def test_demote_to_subtask_parent_not_orchestrator
    with_standalone_and_orchestrator_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        # Create a non-orchestrator task to use as parent
        release_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "126-regular-task")
        FileUtils.mkdir_p(release_dir)
        regular_content = <<~CONTENT
---
id: v.0.9.0+task.126
status: pending
priority: medium
estimate: 4h
dependencies: []
---

# 126 - Regular Task (not orchestrator)
        CONTENT
        File.write(File.join(release_dir, "126-regular-task.s.md"), regular_content)

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.demote_to_subtask("125", "126")

        refute result[:success], "Should fail when parent is not orchestrator"
        assert_match(/not an orchestrator/, result[:message])
      end
    end
  end

  def test_demote_to_subtask_parent_not_found
    with_standalone_task_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.demote_to_subtask("125", "999")

        refute result[:success], "Should fail when parent not found"
        assert_match(/not found/, result[:message])
      end
    end
  end

  def test_demote_to_subtask_task_not_found
    with_standalone_and_orchestrator_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.demote_to_subtask("999", "121")

        refute result[:success], "Should fail when task not found"
        assert_match(/not found/, result[:message])
      end
    end
  end

  def test_demote_to_subtask_dry_run
    with_standalone_and_orchestrator_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new

        stub_llm_slug_generation do
          result = manager.demote_to_subtask("125", "121", dry_run: true)

          assert result[:success], "Dry-run should succeed: #{result[:message]}"
          assert result[:dry_run], "Should indicate dry-run mode"
          assert_match(/DRY-RUN/, result[:message])
          assert result[:operations], "Should list operations"
          assert result[:operations].any? { |op| op.include?("Copy file") }
          assert result[:operations].any? { |op| op.include?("Update ID") }
          assert result[:operations].any? { |op| op.include?("Add parent field") }
          assert result[:operations].any? { |op| op.include?("Delete original") }

          # Verify nothing was actually changed
          original_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "125-standalone-task")
          assert Dir.exist?(original_dir), "Original directory should still exist after dry-run"
        end
      end
    end
  end

  # ============== convert_to_orchestrator tests ==============

  def test_convert_to_orchestrator_success
    with_standalone_task_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.convert_to_orchestrator("125")

        assert result[:success], "Should successfully convert to orchestrator: #{result[:message]}"
        assert_match(/Converted task.*125.*orchestrator.*subtask/, result[:message])
        assert result[:orchestrator_path], "Should return orchestrator path"
        assert result[:subtask_path], "Should return subtask path"
        assert_match(/125-orchestrator\.s\.md/, result[:orchestrator_path])
        assert_match(/125\.01-.*\.s\.md/, result[:subtask_path])

        # Verify both files created
        assert File.exist?(result[:orchestrator_path]), "New orchestrator file should exist"
        assert File.exist?(result[:subtask_path]), "New subtask file should exist"

        # Verify original file removed
        original_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "125-standalone-task", "125-standalone-task.s.md")
        refute File.exist?(original_file), "Original file should be removed"

        # Verify orchestrator content
        orchestrator_content = File.read(result[:orchestrator_path])
        assert_match(/id:\s*v\.0\.9\.0\+task\.125/, orchestrator_content)
        assert_match(/## Overview/, orchestrator_content)
        assert_match(/## Subtasks/, orchestrator_content)

        # Verify subtask has parent field
        subtask_content = File.read(result[:subtask_path])
        assert_match(/parent:\s*v\.0\.9\.0\+task\.125/, subtask_content)
        assert_match(/id:\s*v\.0\.9\.0\+task\.125\.01/, subtask_content)
      end
    end
  end

  def test_convert_to_orchestrator_already_orchestrator
    with_subtask_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.convert_to_orchestrator("121")

        refute result[:success], "Should fail for already-orchestrator"
        assert_match(/already an orchestrator/, result[:message])
      end
    end
  end

  def test_convert_to_orchestrator_is_subtask
    with_subtask_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.convert_to_orchestrator("121.01")

        refute result[:success], "Should fail for subtask"
        assert_match(/subtask.*Cannot convert/, result[:message])
      end
    end
  end

  def test_convert_to_orchestrator_task_not_found
    with_standalone_task_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.convert_to_orchestrator("999")

        refute result[:success], "Should fail for non-existent task"
        assert_match(/not found/, result[:message])
      end
    end
  end

  def test_convert_to_orchestrator_dry_run
    with_standalone_task_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.convert_to_orchestrator("125", dry_run: true)

        assert result[:success], "Dry-run should succeed: #{result[:message]}"
        assert result[:dry_run], "Should indicate dry-run mode"
        assert_match(/DRY-RUN/, result[:message])
        assert result[:operations], "Should list operations"
        assert result[:operations].any? { |op| op.include?("Create orchestrator") }
        assert result[:operations].any? { |op| op.include?("Move original to subtask") }
        assert result[:orchestrator_path], "Should return orchestrator path"
        assert result[:subtask_path], "Should return subtask path"

        # Verify nothing was actually changed
        original_file = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "125-standalone-task", "125-standalone-task.s.md")
        assert File.exist?(original_file), "Original file should still exist after dry-run"
      end
    end
  end

  # ============== Auxiliary file preservation tests ==============

  def test_demote_to_subtask_preserves_auxiliary_files
    with_standalone_and_orchestrator_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        # Add auxiliary files to the standalone task directory
        task_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "125-standalone-task")
        docs_dir = File.join(task_dir, "docs")
        FileUtils.mkdir_p(docs_dir)
        File.write(File.join(docs_dir, "notes.md"), "# Notes\n\nSome notes for this task")
        File.write(File.join(task_dir, "extra.txt"), "Extra file content")

        manager = Ace::Taskflow::Organisms::TaskManager.new

        stub_llm_slug_generation do
          result = manager.demote_to_subtask("125", "121")

          assert result[:success], "Should successfully demote task: #{result[:message]}"

          # Verify auxiliary files were copied to parent orchestrator directory
          parent_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "121-orchestrator")
          assert File.exist?(File.join(parent_dir, "docs", "notes.md")), "docs/notes.md should be preserved"
          assert File.exist?(File.join(parent_dir, "extra.txt")), "extra.txt should be preserved"

          # Verify content is correct
          notes_content = File.read(File.join(parent_dir, "docs", "notes.md"))
          assert_match(/Some notes for this task/, notes_content)
        end
      end
    end
  end

  # ============== Subtask limit boundary tests ==============

  def test_demote_to_subtask_respects_99_limit
    with_standalone_and_orchestrator_project do |dir|
      Dir.chdir(dir) do
        Ace::Taskflow.reset_configuration!

        # Create 99 existing subtasks to hit the limit
        parent_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "t", "121-orchestrator")
        (1..99).each do |i|
          formatted = i.to_s.rjust(2, '0')
          File.write(File.join(parent_dir, "121.#{formatted}-subtask-#{i}.s.md"), <<~CONTENT)
            ---
            id: v.0.9.0+task.121.#{formatted}
            status: pending
            ---
            # Subtask #{i}
          CONTENT
        end

        manager = Ace::Taskflow::Organisms::TaskManager.new
        result = manager.demote_to_subtask("125", "121")

        refute result[:success], "Should fail when 99 subtasks already exist"
        assert_match(/Maximum subtask limit.*99/, result[:message])
      end
    end
  end

  private

  # Setup helpers

  def setup_base_structure(dir)
    taskflow_root = File.join(dir, ".ace-taskflow")
    config_dir = File.join(dir, ".ace", "taskflow")
    FileUtils.mkdir_p(config_dir)
    File.write(File.join(config_dir, "config.yml"), "taskflow:\n  root: .ace-taskflow\n")

    release_dir = File.join(taskflow_root, "v.0.9.0")
    FileUtils.mkdir_p(release_dir)
    File.write(File.join(release_dir, ".active"), "")

    [taskflow_root, release_dir]
  end

  def setup_orchestrator_with_subtasks(dir)
    taskflow_root, release_dir = setup_base_structure(dir)

    # Create orchestrator directory with subtasks
    task_dir = File.join(release_dir, "t", "121-orchestrator")
    FileUtils.mkdir_p(task_dir)

    # Orchestrator file - note: heredoc content must not be indented
    orchestrator_content = <<~CONTENT
---
id: v.0.9.0+task.121
status: in-progress
priority: high
estimate: 8h
dependencies: []
subtasks:
  - v.0.9.0+task.121.01
  - v.0.9.0+task.121.02
---

# 121 - Orchestrator Task
    CONTENT
    File.write(File.join(task_dir, "121-orchestrator.s.md"), orchestrator_content)

    # Subtask 01
    subtask01_content = <<~CONTENT
---
id: v.0.9.0+task.121.01
status: pending
priority: high
estimate: 2h
dependencies: []
parent: v.0.9.0+task.121
---

# 121.01 - First Subtask
    CONTENT
    File.write(File.join(task_dir, "121.01-subtask-one.s.md"), subtask01_content)

    # Subtask 02
    subtask02_content = <<~CONTENT
---
id: v.0.9.0+task.121.02
status: pending
priority: medium
estimate: 3h
dependencies:
  - v.0.9.0+task.121.01
parent: v.0.9.0+task.121
---

# 121.02 - Second Subtask
    CONTENT
    File.write(File.join(task_dir, "121.02-subtask-two.s.md"), subtask02_content)
  end

  def setup_standalone_and_orchestrator(dir)
    # First setup orchestrator
    setup_orchestrator_with_subtasks(dir)

    # Then add standalone task
    release_dir = File.join(dir, ".ace-taskflow", "v.0.9.0")
    task_dir = File.join(release_dir, "t", "125-standalone-task")
    FileUtils.mkdir_p(task_dir)

    standalone_content = <<~CONTENT
---
id: v.0.9.0+task.125
status: pending
priority: medium
estimate: 4h
dependencies: []
---

# 125 - Standalone Task

This task can be demoted to a subtask.
    CONTENT
    File.write(File.join(task_dir, "125-standalone-task.s.md"), standalone_content)
  end

  def setup_standalone_task(dir)
    taskflow_root, release_dir = setup_base_structure(dir)

    task_dir = File.join(release_dir, "t", "125-standalone-task")
    FileUtils.mkdir_p(task_dir)

    standalone_content = <<~CONTENT
---
id: v.0.9.0+task.125
status: pending
priority: medium
estimate: 4h
dependencies: []
---

# 125 - Standalone Task

This task can be converted to an orchestrator.
    CONTENT
    File.write(File.join(task_dir, "125-standalone-task.s.md"), standalone_content)
  end

  # Stub LLM slug generation to return deterministic slugs
  # Uses instance-level stubbing via the protected create_slug_generator factory method
  # for better parallel-safety than global class method modification
  def stub_llm_slug_generation(&block)
    require_relative "../../lib/ace/taskflow/molecules/llm_slug_generator"

    # Create stub instance that returns deterministic slugs
    stub_generator = Object.new
    stub_generator.define_singleton_method(:generate_task_slugs) do |_title, _metadata = {}|
      { folder_slug: "test-slug", file_slug: "test-slug" }
    end

    # Stub new to return our stub generator
    # Note: We still use class-level stubbing here because TaskManager.new creates
    # internal instances. A future improvement would be to inject the generator via config.
    original_new = Ace::Taskflow::Molecules::LlmSlugGenerator.method(:new)
    Ace::Taskflow::Molecules::LlmSlugGenerator.define_singleton_method(:new) do |**_opts|
      stub_generator
    end

    begin
      yield
    ensure
      Ace::Taskflow::Molecules::LlmSlugGenerator.define_singleton_method(:new, original_new)
    end
  end
end
