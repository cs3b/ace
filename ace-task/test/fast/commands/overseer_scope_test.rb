# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"
require "open3"
require "tmpdir"

class OverseerScopeTest < AceTaskTestCase
  OVERSEER_DIR = File.join(".ace-tasks", "_overseer")

  def setup
    @tmpdir = Dir.mktmpdir("task-overseer-scope-test")
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)
    init_git_repo
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_create_in_overseer_creates_folder_and_untracked_task
    id = create_in_overseer("Overseer management task")
    path = invoke("show", id, "--path").strip

    overseer_root = File.join(File.realpath(@tmpdir), OVERSEER_DIR)
    assert Dir.exist?(overseer_root)
    assert path.start_with?(overseer_root + File::SEPARATOR)

    # The folder belongs to the untracked private scope.
    assert_git_ignored("#{OVERSEER_DIR}/")
    status_output, = Open3.capture3("git", "status", "--porcelain", "--untracked-files=all", chdir: @tmpdir)
    refute_includes status_output, "_overseer"
  end

  def test_shared_list_shows_project_and_overseer_and_in_narrows
    project_id = create_project_task("Project task")
    overseer_id = create_in_overseer("Overseer task")
    maybe_id = create_in_folder("maybe", "Maybe task")

    shared = invoke("list")
    assert_includes shared, project_id
    assert_includes shared, overseer_id
    refute_includes shared, maybe_id

    narrowed = invoke("list", "--in", "_overseer")
    assert_includes narrowed, overseer_id
    refute_includes narrowed, project_id

    assert_includes invoke("list", "--in", "all"), maybe_id
    assert_includes invoke("list", "--in", "next"), overseer_id
  end

  def test_show_update_move_and_status_work_for_overseer_tasks
    id = create_in_overseer("Overseer management task")

    assert_includes invoke("show", id, "--content"), "Overseer management task"

    invoke("update", id, "--set", "status=in-progress,next_action=dispatch")
    shown = invoke("show", id, "--content")
    assert_includes shown, "status: in-progress"
    assert_includes shown, "next_action: dispatch"

    invoke("update", id, "--set", "status=done")
    assert_includes invoke("status"), "Overseer management task"

    # Moving out of and back into the private folder is ordinary folder behavior.
    invoke("update", id, "--move-to", "next")
    refute_includes invoke("show", id, "--path"), OVERSEER_DIR
    invoke("update", id, "--move-to", "overseer")
    assert_includes invoke("show", id, "--path"), OVERSEER_DIR
  end

  def test_subtasks_and_dependencies_work_under_overseer
    parent_id = create_in_overseer("Management objective")
    child_output = invoke("create", "Management subtask", "--child-of", parent_id)
    child_id = child_output[/Created task ([0-9a-z]{3}\.t\.[0-9a-z]{3}\.[0-9a-z])/, 1]
    refute_nil child_id

    child = Ace::Task::Organisms::TaskManager.new.show(child_id)
    assert child.subtask?
    assert_equal "_overseer", child.special_folder
    assert_includes child.path, OVERSEER_DIR

    manager = Ace::Task::Organisms::TaskManager.new
    dependent = manager.create("Project depends on management", dependencies: [parent_id])
    assert_equal [parent_id], dependent.dependencies
    listed = manager.list.map(&:id)
    assert_includes listed, parent_id
    assert_includes listed, dependent.id
  end

  def test_git_commit_is_rejected_for_overseer_tasks
    create_error = assert_raises(Ace::Support::Cli::Error) do
      invoke("create", "Private task", "--in", "_overseer", "--gc")
    end
    assert_match(/untracked/, create_error.message)
    refute Dir.exist?(File.join(@tmpdir, OVERSEER_DIR))

    parent_id = create_in_overseer("Management objective")
    update_error = assert_raises(Ace::Support::Cli::Error) do
      invoke("update", parent_id, "--set", "status=done", "--gc")
    end
    assert_match(/untracked/, update_error.message)

    child_error = assert_raises(Ace::Support::Cli::Error) do
      invoke("create", "Management subtask", "--child-of", parent_id, "--gc")
    end
    assert_match(/untracked/, child_error.message)

    project_id = create_project_task("Project task")
    move_error = assert_raises(Ace::Support::Cli::Error) do
      invoke("update", project_id, "--move-to", "overseer", "--gc")
    end
    assert_match(/untracked/, move_error.message)
    assert_nil Ace::Task::Organisms::TaskManager.new.show(project_id).special_folder
  end

  def test_dry_run_does_not_create_overseer_folder
    invoke("create", "Preview", "--in", "_overseer", "--dry-run")

    refute Dir.exist?(File.join(@tmpdir, OVERSEER_DIR))
  end

  def test_list_from_subdirectory_resolves_project_root
    project_id = create_project_task("Project task")
    overseer_id = create_in_overseer("Overseer task")
    maybe_id = create_in_folder("maybe", "Maybe task")
    invoke("update", overseer_id, "--set", "status=done")

    subdir = File.join(@tmpdir, "nested", "deeper")
    FileUtils.mkdir_p(subdir)
    Dir.chdir(subdir) do
      shared = invoke("list")
      assert_includes shared, project_id
      assert_includes shared, overseer_id
      refute_includes shared, maybe_id

      maybe = invoke("list", "--in", "_maybe")
      assert_includes maybe, maybe_id
      refute_includes maybe, project_id

      narrowed = invoke("list", "--in", "_overseer")
      assert_includes narrowed, overseer_id
      refute_includes narrowed, project_id

      assert_includes invoke("status"), "Overseer task"
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

  def test_auto_archive_keeps_private_family_inside_overseer
    parent_id = create_in_overseer("Management objective")
    child_output = invoke("create", "Management subtask", "--child-of", parent_id)
    child_id = child_output[/Created task ([0-9a-z]{3}\.t\.[0-9a-z]{3}\.[0-9a-z])/, 1]
    refute_nil child_id

    invoke("update", child_id, "--set", "status=done")

    private_archive = File.join(File.realpath(@tmpdir), OVERSEER_DIR, "_archive")
    parent_path = invoke("show", parent_id, "--path").strip
    assert parent_path.start_with?(private_archive + File::SEPARATOR)
    refute Dir.exist?(File.join(@tmpdir, ".ace-tasks", "_archive")),
      "a private family must never be archived into the tracked task tree"

    # Classification stays _overseer: the family is still a private task.
    assert_equal "_overseer", Ace::Task::Organisms::TaskManager.new.show(parent_id).special_folder

    # The archived family stays inside the gitignored private scope.
    assert_git_ignored("#{OVERSEER_DIR}/_archive/")
    status_output, = Open3.capture3("git", "status", "--porcelain", "--untracked-files=all", chdir: @tmpdir)
    refute_includes status_output, "_overseer"

    # The default shared view hides archived private work; the private view
    # and `all` keep it reachable.
    refute_includes invoke("list"), parent_id
    assert_includes invoke("list", "--in", "_overseer"), parent_id
    assert_includes invoke("list", "--in", "all"), parent_id

    # Doctor accepts the privately archived family.
    diagnosis = Ace::Task::Organisms::TaskDoctor.new(File.join(@tmpdir, ".ace-tasks")).run_diagnosis
    assert diagnosis[:valid], diagnosis[:issues].inspect
  end

  def test_doctor_auto_fix_archives_standalone_private_task_inside_overseer
    id = create_in_overseer("Standalone management task")
    invoke("update", id, "--set", "status=done")

    tasks_root = File.join(@tmpdir, ".ace-tasks")
    doctor = Ace::Task::Organisms::TaskDoctor.new(tasks_root)
    results = doctor.run_diagnosis
    scope_warning = results[:issues].find { |issue| issue[:message].include?("not in _archive") }
    refute_nil scope_warning, "a terminal private task outside its archive must be reported"

    fixable = results[:issues].select { |issue| doctor.auto_fixable?(issue) }
    fixer = Ace::Task::Molecules::TaskDoctorFixer.new(root_dir: tasks_root)
    fixer.fix_issues(fixable)

    private_archive = File.join(File.realpath(@tmpdir), OVERSEER_DIR, "_archive")
    archived_path = invoke("show", id, "--path").strip
    assert archived_path.start_with?(private_archive + File::SEPARATOR)
    refute Dir.exist?(File.join(tasks_root, "_archive")),
      "doctor must not move private tasks into the tracked archive"
    assert_git_ignored("#{OVERSEER_DIR}/_archive/")
  end

  def test_explicit_archive_of_private_task_stays_inside_overseer
    id = create_in_overseer("Standalone management task")
    invoke("update", id, "--set", "status=done", "--move-to", "archive")

    private_archive = File.join(File.realpath(@tmpdir), OVERSEER_DIR, "_archive")
    archived_path = invoke("show", id, "--path").strip
    assert archived_path.start_with?(private_archive + File::SEPARATOR)
    refute Dir.exist?(File.join(@tmpdir, ".ace-tasks", "_archive")),
      "an explicit private archive must not enter the tracked task tree"

    # The archived private task is still a private management task.
    assert_equal "_overseer", Ace::Task::Organisms::TaskManager.new.show(id).special_folder
    refute_includes invoke("list"), id
    assert_includes invoke("list", "--in", "_overseer"), id
  end

  private

  def init_git_repo
    File.write(File.join(@tmpdir, ".gitignore"), "/.ace-tasks/_overseer/\n")
    assert system("git", "init", "-q", chdir: @tmpdir), "git init must succeed"
    system("git", "config", "user.email", "overseer-scope@example.com", chdir: @tmpdir)
    system("git", "config", "user.name", "Overseer Scope", chdir: @tmpdir)
  end

  def create_project_task(title)
    output = invoke("create", title)
    id = output[/Created task ([0-9a-z]{3}\.t\.[0-9a-z]{3})/, 1]
    refute_nil id
    id
  end

  def create_in_overseer(title)
    output = invoke("create", title, "--in", "_overseer")
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

  def assert_git_ignored(path)
    _out, _err, status = Open3.capture3("git", "check-ignore", "-q", path, chdir: @tmpdir)
    assert status.success?, "expected #{path} to be git-ignored"
  end

  def invoke(*args)
    capture_io { Ace::Task::TaskCLI.start(args) }.first
  end
end
