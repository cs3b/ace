# frozen_string_literal: true

require "test_helper"
require "ace/task/cli"
require "open3"
require "tmpdir"

class StoreInCommandTest < AceTaskTestCase
  STORE_ROOT = File.join(".ace-local", "overseer", "tasks")

  def setup
    @tmpdir = Dir.mktmpdir("task-store-cmd-test")
    @original_dir = Dir.pwd
    Dir.chdir(@tmpdir)
    init_git_repo
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@tmpdir)
  end

  def test_create_in_overseer_store_writes_untracked_isolated_task
    id = create_in_store("Private overseer task")
    path = invoke("show", id, "--in", "_overseer", "--path").strip

    assert path.start_with?(File.join(File.realpath(@tmpdir), STORE_ROOT) + File::SEPARATOR)
    assert Dir.exist?(File.join(@tmpdir, STORE_ROOT))
    refute Dir.exist?(File.join(@tmpdir, ".ace-tasks"))

    # Project listing and the project scanner never see the private store.
    refute_includes invoke("list"), "Private overseer task"
    refute_includes invoke("list", "--in", "all"), "Private overseer task"
    assert_empty Ace::Task::Molecules::TaskScanner.new(File.join(@tmpdir, ".ace-tasks")).scan

    # The store is untracked: .ace-local/ is ignored and git sees no new files.
    assert_git_ignored(STORE_ROOT)
    status_output, = Open3.capture3("git", "status", "--porcelain", "--untracked-files=all", chdir: @tmpdir)
    refute_includes status_output, STORE_ROOT
  end

  def test_show_list_and_update_resolve_the_store
    id = create_in_store("Queue item")

    list_output = invoke("list", "--in", "_overseer")
    assert_includes list_output, "Queue item"
    refute_includes invoke("list"), "Queue item"

    assert_includes invoke("show", id, "--in", "_overseer", "--content"), "Queue item"

    invoke("update", id, "--in", "_overseer", "--set", "status=in-progress,next_action=dispatch")
    shown = invoke("show", id, "--in", "_overseer", "--content")
    assert_includes shown, "status: in-progress"
    assert_includes shown, "next_action: dispatch"

    # The project scope cannot resolve the private task even by exact ID.
    error = assert_raises(Ace::Support::Cli::Error) { invoke("show", id) }
    assert_match(/not found/, error.message)
  end

  def test_store_manager_lists_only_store_tasks
    create_in_store("Queued")
    create_project_task("Project task")

    store_tasks = Ace::Task::Organisms::TaskManager.new(
      root_dir: File.join(@tmpdir, STORE_ROOT)
    ).list(in_folder: "all")
    project_tasks = Ace::Task::Organisms::TaskManager.new.list(in_folder: "all")

    assert_equal ["Queued"], store_tasks.map(&:title)
    assert_equal ["Project task"], project_tasks.map(&:title)
  end

  def test_create_with_store_and_root_is_rejected
    error = assert_raises(Ace::Support::Cli::Error) do
      invoke("create", "Conflicting task", "--in", "_overseer", "--root", File.join(@tmpdir, "queue"))
    end

    assert_match(/--root/, error.message)
    refute Dir.exist?(File.join(@tmpdir, STORE_ROOT))
  end

  def test_store_create_and_update_reject_git_commit
    create_error = assert_raises(Ace::Support::Cli::Error) do
      invoke("create", "Private task", "--in", "_overseer", "--git-commit")
    end
    assert_match(/untracked/, create_error.message)

    id = create_in_store("Private task")
    update_error = assert_raises(Ace::Support::Cli::Error) do
      invoke("update", id, "--in", "_overseer", "--set", "status=done", "--git-commit")
    end
    assert_match(/untracked/, update_error.message)
  end

  def test_unknown_store_is_rejected_for_show_and_update
    show_error = assert_raises(Ace::Support::Cli::Error) { invoke("show", "abc.t.xyz", "--in", "_unknown") }
    assert_match(/Unknown task store '_unknown'/, show_error.message)

    update_error = assert_raises(Ace::Support::Cli::Error) do
      invoke("update", "abc.t.xyz", "--in", "_unknown", "--set", "status=done")
    end
    assert_match(/Unknown task store '_unknown'/, update_error.message)
  end

  def test_list_rejects_unknown_private_store_name
    error = assert_raises(Ace::Support::Cli::Error) { invoke("list", "--in", "_unknown") }

    assert_match(/Unknown task store '_unknown'/, error.message)
  end

  def test_list_with_root_allows_underscore_folder_under_override
    root = File.join(@tmpdir, "queue-root")
    FileUtils.mkdir_p(File.join(root, "_custom"))

    output = invoke("list", "--root", root, "--in", "_custom")

    refute_nil output
  end

  def test_dry_run_does_not_create_store_root
    output = invoke("create", "Preview", "--in", "_overseer", "--dry-run")

    assert_includes output, "Store:"
    refute Dir.exist?(File.join(@tmpdir, STORE_ROOT))
  end

  private

  def init_git_repo
    File.write(File.join(@tmpdir, ".gitignore"), "/.ace-local/\n")
    assert system("git", "init", "-q", chdir: @tmpdir), "git init must succeed"
    system("git", "config", "user.email", "store-test@example.com", chdir: @tmpdir)
    system("git", "config", "user.name", "Store Test", chdir: @tmpdir)
  end

  def create_in_store(title)
    output = invoke("create", title, "--in", "_overseer")
    id = output[/Created task ([0-9a-z]{3}\.t\.[0-9a-z]{3})/, 1]
    refute_nil id
    id
  end

  def create_project_task(title)
    output = invoke("create", title)
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
