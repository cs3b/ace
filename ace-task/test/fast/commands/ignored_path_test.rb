# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"
require "ace/task/organisms/task_doctor"
require "ace/task/molecules/task_doctor_fixer"
require "open3"
require "tmpdir"

# ace-task is folder-name agnostic: behavior that must differ for a path that
# is not committed comes from Git's own ignore rules, never from a folder-name
# list. These tests use a neutral ignored folder that a lab prepares like any
# other directory, plus ordinary (tracked) folders for contrast.
class IgnoredPathTest < AceTaskTestCase
  IGNORED_FOLDER = "_scratch"

  def setup
    @tmpdir = Dir.mktmpdir("task-ignored-path-test")
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)
    init_git_repo
    # A lab prepares the folder itself; ace-task has no built-in knowledge of it.
    FileUtils.mkdir_p(File.join(@tmpdir, ".ace-tasks", IGNORED_FOLDER))
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_default_list_is_the_root_view_and_in_narrows_a_special_folder
    project_id = create_project_task("Project task")
    ignored_id = create_in_folder(IGNORED_FOLDER, "Ignored task")
    maybe_id = create_in_folder("maybe", "Maybe task")

    default_view = invoke("list")
    assert_includes default_view, project_id
    refute_includes default_view, ignored_id
    refute_includes default_view, maybe_id

    narrowed = invoke("list", "--in", IGNORED_FOLDER)
    assert_includes narrowed, ignored_id
    refute_includes narrowed, project_id

    assert_includes invoke("list", "--in", "all"), ignored_id
    assert_includes invoke("list", "--in", "all"), maybe_id
  end

  def test_show_update_subtasks_and_dependencies_work_for_ignored_tasks
    parent_id = create_in_folder(IGNORED_FOLDER, "Ignored objective")
    child_output = invoke("create", "Ignored subtask", "--child-of", parent_id)
    child_id = child_output[/Created task ([0-9a-z]{3}\.t\.[0-9a-z]{3}\.[0-9a-z])/, 1]
    refute_nil child_id

    assert_includes invoke("show", parent_id, "--content"), "Ignored objective"
    invoke("update", parent_id, "--set", "status=in-progress,next_action=dispatch")
    shown = invoke("show", parent_id, "--content")
    assert_includes shown, "status: in-progress"
    assert_includes shown, "next_action: dispatch"

    child = Ace::Task::Organisms::TaskManager.new.show(child_id)
    assert child.subtask?
    assert_includes child.path, IGNORED_FOLDER
    assert_includes invoke("show", parent_id, "--path"), IGNORED_FOLDER

    # Ordinary task features stay independent from Git tracking.
    manager = Ace::Task::Organisms::TaskManager.new
    dependent = manager.create("Project depends on ignored objective", dependencies: [parent_id])
    assert_equal [parent_id], dependent.dependencies
    assert_includes manager.list(in_folder: "all").map(&:id), parent_id
  end

  def test_git_commit_is_rejected_for_anything_in_an_ignored_path
    create_error = assert_raises(Ace::Support::Cli::Error) do
      invoke("create", "Ignored task", "--in", IGNORED_FOLDER, "--gc")
    end
    assert_match(/Git-ignored task path/, create_error.message)
    assert_empty Dir.children(File.join(@tmpdir, ".ace-tasks", IGNORED_FOLDER))

    parent_id = create_in_folder(IGNORED_FOLDER, "Ignored objective")
    child_error = assert_raises(Ace::Support::Cli::Error) do
      invoke("create", "Ignored subtask", "--child-of", parent_id, "--gc")
    end
    assert_match(/Git-ignored task path/, child_error.message)

    update_error = assert_raises(Ace::Support::Cli::Error) do
      invoke("update", parent_id, "--set", "status=done", "--gc")
    end
    assert_match(/Git-ignored task path/, update_error.message)

    project_id = create_project_task("Project task")
    move_error = assert_raises(Ace::Support::Cli::Error) do
      invoke("update", project_id, "--move-to", IGNORED_FOLDER, "--gc")
    end
    assert_match(/Git-ignored task path/, move_error.message)
    assert_nil Ace::Task::Organisms::TaskManager.new.show(project_id).special_folder
  end

  def test_terminal_ignored_family_is_not_auto_archived
    parent_id = create_in_folder(IGNORED_FOLDER, "Ignored objective")
    child_output = invoke("create", "Ignored subtask", "--child-of", parent_id)
    child_id = child_output[/Created task ([0-9a-z]{3}\.t\.[0-9a-z]{3}\.[0-9a-z])/, 1]
    refute_nil child_id

    invoke("update", child_id, "--set", "status=done")

    parent_path = invoke("show", parent_id, "--path").strip
    assert parent_path.start_with?(
      File.join(File.realpath(@tmpdir), ".ace-tasks", IGNORED_FOLDER) + File::SEPARATOR
    )
    refute_includes parent_path, "_archive"
    refute Dir.exist?(File.join(@tmpdir, ".ace-tasks", "_archive")),
      "a Git-ignored family must not trigger a repository archive relocation"
    refute Dir.exist?(File.join(@tmpdir, ".ace-tasks", IGNORED_FOLDER, "_archive")),
      "ace-task must not invent a private archive folder"
  end

  def test_terminal_tracked_family_still_auto_archives
    parent_id = create_project_task("Project objective")
    child_output = invoke("create", "Project subtask", "--child-of", parent_id)
    child_id = child_output[/Created task ([0-9a-z]{3}\.t\.[0-9a-z]{3}\.[0-9a-z])/, 1]
    refute_nil child_id

    invoke("update", child_id, "--set", "status=done")

    parent_path = invoke("show", parent_id, "--path").strip
    assert_includes parent_path, File.join("_archive", "")
    assert Dir.exist?(File.join(@tmpdir, ".ace-tasks", "_archive"))
  end

  def test_doctor_neither_requires_nor_performs_an_archive_move_for_ignored_tasks
    id = create_in_folder(IGNORED_FOLDER, "Ignored standalone")
    invoke("update", id, "--set", "status=done")

    tasks_root = File.join(@tmpdir, ".ace-tasks")
    doctor = Ace::Task::Organisms::TaskDoctor.new(tasks_root)
    results = doctor.run_diagnosis
    archive_warnings = results[:issues].select { |issue| issue[:message].include?("not in _archive") }
    assert_empty archive_warnings, "doctor must not demand archiving a Git-ignored task"

    fixer = Ace::Task::Molecules::TaskDoctorFixer.new(root_dir: tasks_root)
    fixer.fix_issues(results[:issues].select { |issue| doctor.auto_fixable?(issue) })

    path = invoke("show", id, "--path").strip
    assert path.start_with?(
      File.join(File.realpath(@tmpdir), ".ace-tasks", IGNORED_FOLDER) + File::SEPARATOR
    )
    refute Dir.exist?(File.join(tasks_root, "_archive")),
      "doctor --auto-fix must not move a Git-ignored task into the repository archive"
  end

  def test_ignored_path_detection_works_from_a_subdirectory
    ignored_id = create_in_folder(IGNORED_FOLDER, "Ignored task")

    subdir = File.join(@tmpdir, "nested", "deeper")
    FileUtils.mkdir_p(subdir)
    Dir.chdir(subdir) do
      error = assert_raises(Ace::Support::Cli::Error) do
        invoke("update", ignored_id, "--set", "status=done", "--gc")
      end
      assert_match(/Git-ignored task path/, error.message)
      assert_includes invoke("list", "--in", IGNORED_FOLDER), ignored_id
    end
  end

  def test_ignored_path_detection_works_with_a_custom_task_root
    FileUtils.mkdir_p(File.join(@tmpdir, ".ace", "task"))
    File.write(File.join(@tmpdir, ".ace", "task", "config.yml"), "task:\n  root_dir: tasks\n")
    File.open(File.join(@tmpdir, ".gitignore"), "a") { |file| file.puts "/tasks/#{IGNORED_FOLDER}/" }
    tasks_root = File.join(@tmpdir, "tasks")
    FileUtils.mkdir_p(File.join(tasks_root, IGNORED_FOLDER))

    output = invoke("create", "Ignored custom-root task", "--in", IGNORED_FOLDER)
    id = output[/Created task ([0-9a-z]{3}\.t\.[0-9a-z]{3})/, 1]
    refute_nil id
    path = invoke("show", id, "--path").strip
    assert path.start_with?(File.join(File.realpath(@tmpdir), "tasks", IGNORED_FOLDER) + File::SEPARATOR)

    error = assert_raises(Ace::Support::Cli::Error) do
      invoke("update", id, "--set", "status=done", "--gc")
    end
    assert_match(/Git-ignored task path/, error.message)

    subdir = File.join(@tmpdir, "nested")
    FileUtils.mkdir_p(subdir)
    Dir.chdir(subdir) do
      assert_includes invoke("list", "--in", IGNORED_FOLDER), id
    end
  end

  def test_list_from_subdirectory_resolves_project_root
    project_id = create_project_task("Project task")
    ignored_id = create_in_folder(IGNORED_FOLDER, "Ignored task")
    maybe_id = create_in_folder("maybe", "Maybe task")

    subdir = File.join(@tmpdir, "nested", "deeper")
    FileUtils.mkdir_p(subdir)
    Dir.chdir(subdir) do
      default_view = invoke("list")
      assert_includes default_view, project_id
      refute_includes default_view, ignored_id
      refute_includes default_view, maybe_id

      maybe = invoke("list", "--in", "_maybe")
      assert_includes maybe, maybe_id
      refute_includes maybe, project_id

      narrowed = invoke("list", "--in", IGNORED_FOLDER)
      assert_includes narrowed, ignored_id
      refute_includes narrowed, project_id
    end
  end

  def test_root_override_keeps_pre_existing_cwd_relative_behavior
    root = File.join(@tmpdir, "custom-queue")
    output = invoke("create", "Queued task", "--root", root)
    id = output[/Created task ([0-9a-z]{3}\.t\.[0-9a-z]{3})/, 1]
    refute_nil id

    subdir = File.join(@tmpdir, "nested")
    FileUtils.mkdir_p(subdir)
    Dir.chdir(subdir) do
      # --root is an explicit path override resolved from the current directory.
      assert_includes invoke("list", "--root", "../custom-queue"), id
    end
  end

  private

  def init_git_repo
    File.write(File.join(@tmpdir, ".gitignore"), "/.ace-tasks/#{IGNORED_FOLDER}/\n")
    assert system("git", "init", "-q", chdir: @tmpdir), "git init must succeed"
    system("git", "config", "user.email", "ignored-path@example.com", chdir: @tmpdir)
    system("git", "config", "user.name", "Ignored Path", chdir: @tmpdir)
  end

  def create_project_task(title)
    output = invoke("create", title)
    id = output[/Created task ([0-9a-z]{3}\.t\.[0-9a-z]{3})/, 1]
    refute_nil id
    id
  end

  def create_in_folder(folder, title)
    output = invoke("create", title, "--in", folder)
    id = output[/Created task ([0-9a-z]{3}\.t\.[0-9a-z]{3})/, 1]
    refute_nil id
    id
  end

  def invoke(*args)
    capture_io { Ace::Task::TaskCLI.start(args) }.first
  end
end
