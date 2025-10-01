# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/commands/release_command"

class ReleaseCommandTest < AceTaskflowTestCase
  def setup
    @command = Ace::Taskflow::Commands::ReleaseCommand.new
  end

  def test_show_active_release
    with_test_project do |dir|
      # Promote v.0.9.0 to active
      Dir.chdir(dir) do
        # First promote to make it active
        capture_stdout { @command.execute(["promote", "v.0.9.0"]) }

        # Then show active
        output = capture_stdout do
          @command.execute([])
        end

        assert_match(/v\.0\.9\.0/, output)
        assert_match(/Release:|Status:/, output)
      end
    end
  end

  def test_no_active_release
    with_test_project do |dir|
      # Don't promote any release, so none are active
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute([])
        end

        assert_match(/No active release/, output)
      end
    end
  end

  def test_show_release_with_path_flag
    skip "Path flag not implemented in current version"
  end

  def test_show_specific_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["v.0.9.0"])
        end

        assert_match(/v\.0\.9\.0/, output)
      end
    end
  end

  def test_create_new_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          # Command API: create <codename> [--release version]
          @command.execute(["create", "new-features"])
        end

        assert_match(/Created release/, output)
        # Use flexible version pattern instead of hardcoded version
        assert_match(/v\.\d+\.\d+\.\d+/, output)

        # Extract the actual version from output to verify structure
        version_match = output.match(/v\.\d+\.\d+\.\d+/)
        assert version_match, "Should contain a version number"
        created_version = version_match[0]

        # Release is created in backlog by default
        release_dir = Dir.glob(File.join(dir, "backlog", "#{created_version}*")).first
        assert release_dir, "Release directory should exist in backlog"

        # Verify subdirectories
        assert Dir.exist?(File.join(release_dir, "t"))
        assert Dir.exist?(File.join(release_dir, "i"))
        assert Dir.exist?(File.join(release_dir, "docs"))

        # Verify release file
        release_file = File.join(release_dir, "release.md")
        assert File.exist?(release_file)
      end
    end
  end

  def test_create_release_with_invalid_version
    skip "Version validation not enforced at create time in current implementation"
  end

  def test_create_duplicate_release
    skip "Duplicate detection not fully implemented in current version"
  end

  def test_promote_release_from_backlog
    with_test_project do |dir|
      Dir.chdir(dir) do
        # First create a release in backlog
        capture_stdout { @command.execute(["create", "promoted-release"]) }

        # Get the created version from backlog
        backlog_releases = Dir.glob(File.join(dir, "backlog", "v.*"))
        assert backlog_releases.any?, "Should have a release in backlog"

        backlog_release = File.basename(backlog_releases.first)

        # Now promote it
        output = capture_stdout do
          @command.execute(["promote", backlog_release])
        end

        assert_match(/success|promoted/i, output)

        # Verify it was moved out of backlog
        assert Dir.exist?(File.join(dir, backlog_release)), "Release should be moved to root"
      end
    end
  end

  def test_activate_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          # Use 'promote' command to activate
          @command.execute(["promote", "v.0.9.0"])
        end

        assert_match(/success|promoted/i, output)
        assert_match(/v\.0\.9\.0/, output)
      end
    end
  end

  def test_deactivate_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        # First promote v.0.9.0 to make it active
        capture_stdout { @command.execute(["promote", "v.0.9.0"]) }

        # Then demote it
        output = capture_stdout do
          @command.execute(["demote", "v.0.9.0"])
        end

        assert_match(/success|demote/i, output)
      end
    end
  end

  def test_release_statistics
    skip "Stats flag not implemented in current version"
  end

  def test_release_with_detailed_flag
    skip "Detailed flag not implemented in current version"
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
        # First promote v.0.9.0
        capture_stdout { @command.execute(["promote", "v.0.9.0"]) }

        # Now demote (archive) it
        output = capture_stdout do
          @command.execute(["demote", "v.0.9.0"])
        end

        assert_match(/success|demote/i, output)

        # Verify moved to done directory
        assert Dir.exist?(File.join(dir, "done", "v.0.9.0"))
        refute Dir.exist?(File.join(dir, "v.0.9.0"))
      end
    end
  end
end