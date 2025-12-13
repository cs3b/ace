# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/commands/migrate_command"

class MigrateCommandTest < AceTaskflowTestCase
  def test_migrate_help_flag
    with_test_project do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::MigrateCommand.new

        output = capture_stdout do
          exit_code = command.execute(["--help"])
          assert_equal 0, exit_code
        end

        assert_match(/Usage: ace-taskflow migrate/, output)
        assert_match(/--dry-run/, output)
        assert_match(/--verbose/, output)
        assert_match(/--no-git/, output)
      end
    end
  end

  def test_migrate_executes_successfully
    with_test_project do |dir|
      taskflow_root = File.join(dir, ".ace-taskflow")

      # Create old "done" folder
      done_dir = File.join(taskflow_root, "done")
      FileUtils.mkdir_p(done_dir)
      File.write(File.join(done_dir, "test.txt"), "test content")

      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::MigrateCommand.new

        output = capture_stdout do
          exit_code = command.execute([])
          assert_equal 0, exit_code
        end

        assert_match(/Migrating folder structure/, output)
        assert_match(/Successfully migrated: 1/, output)
        assert_match(/done.*→.*_archive/, output)

        # Verify folder was actually migrated
        archive_dir = File.join(taskflow_root, "_archive")
        assert Dir.exist?(archive_dir)
        refute Dir.exist?(done_dir)
      end
    end
  end

  def test_migrate_dry_run_does_not_modify
    with_test_project do |dir|
      taskflow_root = File.join(dir, ".ace-taskflow")

      # Create old "done" folder
      done_dir = File.join(taskflow_root, "done")
      FileUtils.mkdir_p(done_dir)
      File.write(File.join(done_dir, "test.txt"), "test content")

      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::MigrateCommand.new

        output = capture_stdout do
          exit_code = command.execute(["--dry-run"])
          assert_equal 0, exit_code
        end

        assert_match(/DRY RUN MODE/, output)
        assert_match(/Successfully migrated: 1/, output)

        # Verify folder was NOT migrated
        archive_dir = File.join(taskflow_root, "_archive")
        refute Dir.exist?(archive_dir)
        assert Dir.exist?(done_dir)
      end
    end
  end

  def test_migrate_verbose_shows_skipped
    with_test_project do |dir|
      taskflow_root = File.join(dir, ".ace-taskflow")

      # Create both old and new folders (will be skipped)
      done_dir = File.join(taskflow_root, "done")
      archive_dir = File.join(taskflow_root, "_archive")
      FileUtils.mkdir_p(done_dir)
      FileUtils.mkdir_p(archive_dir)

      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::MigrateCommand.new

        output = capture_stdout do
          exit_code = command.execute(["--verbose"])
          assert_equal 0, exit_code
        end

        assert_match(/Skipped: 1/, output)
        assert_match(/Skipped Folders:/, output)
        assert_match(/Target already exists/, output)
      end
    end
  end

  def test_migrate_no_folders_to_migrate
    with_test_project do |dir|
      taskflow_root = File.join(dir, ".ace-taskflow")

      # Create only new-style folders
      FileUtils.mkdir_p(File.join(taskflow_root, "_archive"))
      FileUtils.mkdir_p(File.join(taskflow_root, "_backlog"))

      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::MigrateCommand.new

        output = capture_stdout do
          exit_code = command.execute([])
          assert_equal 0, exit_code
        end

        assert_match(/Total folders found: 0/, output)
        assert_match(/No folders need migration/, output)
      end
    end
  end

  def test_migrate_returns_error_when_not_in_taskflow_project
    Dir.mktmpdir do |dir|
      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::MigrateCommand.new

        output = capture_stdout do
          exit_code = command.execute([])
          assert_equal 2, exit_code
        end

        assert_match(/No \.ace-taskflow directory found/, output)
      end
    end
  end

  def test_migrate_detects_git_repository
    with_test_project do |dir|
      Dir.chdir(dir) do
        taskflow_root = File.join(dir, ".ace-taskflow")

        # Initialize git repo
        system("git", "init", "-q", dir)
        system("git", "config", "user.email", "test@example.com")
        system("git", "config", "user.name", "Test User")

        # Create old "done" folder
        done_dir = File.join(taskflow_root, "done")
        FileUtils.mkdir_p(done_dir)
        File.write(File.join(done_dir, "test.txt"), "test content")

        # Add to git
        system("git", "add", "-A")
        system("git", "commit", "-q", "-m", "Initial commit")

        command = Ace::Taskflow::Commands::MigrateCommand.new

        output = capture_stdout do
          exit_code = command.execute([])
          # May succeed or fail depending on git state, we just check detection
          assert [0, 1, 2].include?(exit_code)
        end

        assert_match(/Git repository detected/, output)
      ensure
        # Cleanup git repo
        FileUtils.rm_rf(File.join(dir, ".git")) if File.exist?(File.join(dir, ".git"))
      end
    end
  end

  def test_migrate_with_no_git_flag
    with_test_project do |dir|
      taskflow_root = File.join(dir, ".ace-taskflow")

      # Initialize git repo
      system("git", "init", "-q", dir)

      # Create old "done" folder
      done_dir = File.join(taskflow_root, "done")
      FileUtils.mkdir_p(done_dir)
      File.write(File.join(done_dir, "test.txt"), "test content")

      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::MigrateCommand.new

        output = capture_stdout do
          exit_code = command.execute(["--no-git"])
          assert_equal 0, exit_code
        end

        # Should not mention git when --no-git is used
        refute_match(/Git repository detected/, output)
        assert_match(/Successfully migrated: 1/, output)
      ensure
        # Cleanup git repo
        FileUtils.rm_rf(File.join(dir, ".git")) if File.exist?(File.join(dir, ".git"))
      end
    end
  end

  def test_migrate_multiple_folders
    with_test_project do |dir|
      taskflow_root = File.join(dir, ".ace-taskflow")

      # Create multiple old folders
      done_dir = File.join(taskflow_root, "done")
      backlog_dir = File.join(taskflow_root, "backlog")
      FileUtils.mkdir_p(done_dir)
      FileUtils.mkdir_p(backlog_dir)

      # Create nested done folders
      release_dir = File.join(taskflow_root, "v.0.9.0")
      tasks_done = File.join(release_dir, "tasks", "done")
      FileUtils.mkdir_p(tasks_done)

      Dir.chdir(dir) do
        command = Ace::Taskflow::Commands::MigrateCommand.new

        output = capture_stdout do
          exit_code = command.execute([])
          assert_equal 0, exit_code
        end

        assert_match(/Total folders found: 3/, output)
        assert_match(/Successfully migrated: 3/, output)
        assert_match(/done.*→.*_archive/, output)
        assert_match(/backlog.*→.*_backlog/, output)
      end
    end
  end

  private

  def capture_stdout
    old_stdout = $stdout
    $stdout = StringIO.new
    yield
    $stdout.string
  ensure
    $stdout = old_stdout
  end
end
