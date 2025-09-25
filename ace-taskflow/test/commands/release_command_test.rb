# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/commands/release_command"

class ReleaseCommandTest < AceTaskflowTestCase
  def setup
    @command = Ace::Taskflow::Commands::ReleaseCommand.new
  end

  def test_show_active_release
    with_test_project do |dir|
      # Create active release marker
      File.write(File.join(dir, "v.0.9.0", ".active"), "")

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute
        end

        assert_match(/v\.0\.9\.0/, output)
        assert_match(/Active Release/, output)
      end
    end
  end

  def test_no_active_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute
        end

        assert_match(/No active release/, output)
      end
    end
  end

  def test_show_release_with_path_flag
    with_test_project do |dir|
      File.write(File.join(dir, "v.0.9.0", ".active"), "")

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--path"])
        end

        assert_match(%r{v\.0\.9\.0}, output)
        refute_match(/Active Release/, output)
      end
    end
  end

  def test_show_specific_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["v.0.8.0"])
        end

        assert_match(/v\.0\.8\.0/, output)
        assert_match(/Release Information/, output)
      end
    end
  end

  def test_create_new_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["create", "v.0.10.0", "New Features"])
        end

        assert_match(/Created release/, output)
        assert_match(/v\.0\.10\.0/, output)

        # Verify directory structure
        assert Dir.exist?(File.join(dir, "v.0.10.0"))
        assert Dir.exist?(File.join(dir, "v.0.10.0", "t"))
        assert Dir.exist?(File.join(dir, "v.0.10.0", "i"))
        assert Dir.exist?(File.join(dir, "v.0.10.0", "docs"))

        # Verify release file
        release_file = File.join(dir, "v.0.10.0", "release.md")
        assert File.exist?(release_file)
        content = File.read(release_file)
        assert_match(/New Features/, content)
      end
    end
  end

  def test_create_release_with_invalid_version
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["create", "invalid-version"])
        end

        assert_match(/Invalid version format/, output)
      end
    end
  end

  def test_create_duplicate_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["create", "v.0.9.0"])
        end

        assert_match(/already exists/, output)
      end
    end
  end

  def test_promote_release_from_backlog
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["promote", "v.0.11.0", "Promoted Release"])
        end

        assert_match(/Promoted release/, output)
        assert_match(/v\.0\.11\.0/, output)

        # Verify it became active
        assert File.exist?(File.join(dir, "v.0.11.0", ".active"))

        # Verify some tasks were moved from backlog
        promoted_tasks = Dir.glob(File.join(dir, "v.0.11.0", "t", "*", "*.md"))
        assert promoted_tasks.length > 0
      end
    end
  end

  def test_activate_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["activate", "v.0.8.0"])
        end

        assert_match(/Activated release/, output)
        assert_match(/v\.0\.8\.0/, output)

        # Verify active marker
        assert File.exist?(File.join(dir, "v.0.8.0", ".active"))

        # Verify previous active was deactivated
        refute File.exist?(File.join(dir, "v.0.9.0", ".active"))
      end
    end
  end

  def test_deactivate_release
    with_test_project do |dir|
      File.write(File.join(dir, "v.0.9.0", ".active"), "")

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["deactivate"])
        end

        assert_match(/Deactivated release/, output)
        refute File.exist?(File.join(dir, "v.0.9.0", ".active"))
      end
    end
  end

  def test_release_statistics
    with_test_project do |dir|
      File.write(File.join(dir, "v.0.9.0", ".active"), "")

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--stats"])
        end

        assert_match(/Release Statistics/, output)
        assert_match(/Tasks:/, output)
        assert_match(/Done:/, output)
        assert_match(/In Progress:/, output)
        assert_match(/Pending:/, output)
        assert_match(/Ideas:/, output)
      end
    end
  end

  def test_release_with_detailed_flag
    with_test_project do |dir|
      File.write(File.join(dir, "v.0.9.0", ".active"), "")

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--detailed"])
        end

        # Should show task list
        assert_match(/v\.0\.9\.0\+task\.001/, output)
        assert_match(/v\.0\.9\.0\+task\.002/, output)
        assert_match(/Ideas:/, output)
      end
    end
  end

  def test_invalid_release_reference
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["v.99.99.99"])
        end

        assert_match(/Release not found/, output)
      end
    end
  end

  def test_archive_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["archive", "v.0.8.0"])
        end

        assert_match(/Archived release/, output)

        # Verify moved to done directory
        assert Dir.exist?(File.join(dir, "done", "v.0.8.0"))
        refute Dir.exist?(File.join(dir, "v.0.8.0"))
      end
    end
  end
end