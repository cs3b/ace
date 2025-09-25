# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/commands/releases_command"

class ReleasesCommandTest < AceTaskflowTestCase
  def setup
    @command = Ace::Taskflow::Commands::ReleasesCommand.new
  end

  def test_list_all_releases
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute
        end

        # Should list all releases
        assert_match(/v\.0\.9\.0/, output)
        assert_match(/v\.0\.8\.0/, output)
        assert_match(/backlog/, output)

        # Should show task counts
        assert_match(/tasks/, output)
      end
    end
  end

  def test_list_releases_with_statistics
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--stats"])
        end

        # Should show aggregated statistics
        assert_match(/Total Releases:/, output)
        assert_match(/Active Releases:/, output)
        assert_match(/Total Tasks:/, output)
        assert_match(/Completed Tasks:/, output)
        assert_match(/In Progress Tasks:/, output)
        assert_match(/Pending Tasks:/, output)
      end
    end
  end

  def test_list_active_releases_only
    with_test_project do |dir|
      # Mark v.0.9.0 as active
      File.write(File.join(dir, "v.0.9.0", ".active"), "")

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--active"])
        end

        # Should only show active release
        assert_match(/v\.0\.9\.0/, output)
        refute_match(/v\.0\.8\.0/, output)
        refute_match(/backlog/, output)
      end
    end
  end

  def test_list_completed_releases
    with_test_project do |dir|
      # Create a done release
      done_dir = File.join(dir, "done", "v.0.7.0")
      FileUtils.mkdir_p(done_dir)
      File.write(File.join(done_dir, "release.md"), "# v.0.7.0\n\nCompleted release")

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--done"])
        end

        # Should show completed releases
        assert_match(/v\.0\.7\.0/, output)
        refute_match(/v\.0\.9\.0/, output)
      end
    end
  end

  def test_list_releases_sorted_by_version
    with_test_project do |dir|
      # Create additional releases
      FileUtils.mkdir_p(File.join(dir, "v.0.10.0"))
      FileUtils.mkdir_p(File.join(dir, "v.0.7.0"))

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--sort", "version"])
        end

        lines = output.lines
        v10_index = lines.index { |l| l.include?("v.0.10.0") }
        v9_index = lines.index { |l| l.include?("v.0.9.0") }
        v8_index = lines.index { |l| l.include?("v.0.8.0") }
        v7_index = lines.index { |l| l.include?("v.0.7.0") }

        # Should be sorted by version (descending)
        assert v10_index < v9_index if v10_index && v9_index
        assert v9_index < v8_index if v9_index && v8_index
        assert v8_index < v7_index if v8_index && v7_index
      end
    end
  end

  def test_list_releases_sorted_by_task_count
    with_test_project do |dir|
      # Add more tasks to v.0.8.0
      5.times do |i|
        task_num = sprintf("%03d", i + 4)
        task_dir = File.join(dir, "v.0.8.0", "t", task_num)
        FileUtils.mkdir_p(task_dir)
        File.write(File.join(task_dir, "task.md"), TestFactory.sample_task_content)
      end

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--sort", "tasks"])
        end

        lines = output.lines
        backlog_index = lines.index { |l| l.include?("backlog") }
        v8_index = lines.index { |l| l.include?("v.0.8.0") }
        v9_index = lines.index { |l| l.include?("v.0.9.0") }

        # backlog has 10, v.0.8.0 has 8, v.0.9.0 has 5
        assert backlog_index < v8_index if backlog_index && v8_index
        assert v8_index < v9_index if v8_index && v9_index
      end
    end
  end

  def test_releases_with_verbose_output
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--verbose"])
        end

        # Should include detailed information
        assert_match(/Created:/, output)
        assert_match(/Modified:/, output)
        assert_match(/Ideas:/, output)
        assert_match(/Documents:/, output)
      end
    end
  end

  def test_releases_timeline_view
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--timeline"])
        end

        # Should show timeline format
        assert_match(/Timeline/, output)
        assert_match(/═/, output) # Timeline graphics
      end
    end
  end

  def test_releases_export_to_json
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--format", "json"])
        end

        # Should output valid JSON
        require "json"
        data = JSON.parse(output)
        assert data.is_a?(Array)
        assert data.first.key?("version")
        assert data.first.key?("task_count")
        assert data.first.key?("status")
      end
    end
  end

  def test_releases_summary
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--summary"])
        end

        # Should show summary only
        assert_match(/v\.0\.9\.0.*5 tasks/, output)
        assert_match(/v\.0\.8\.0.*3 tasks/, output)
        assert_match(/backlog.*10 tasks/, output)

        # Should not show detailed task lists
        refute_match(/task\.001/, output)
      end
    end
  end

  def test_no_releases_message
    with_test_project do |dir|
      # Remove all releases
      FileUtils.rm_rf(Dir.glob(File.join(dir, "v.*")))
      FileUtils.rm_rf(File.join(dir, "backlog"))

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute
        end

        assert_match(/No releases found/, output)
      end
    end
  end

  def test_releases_health_check
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--health"])
        end

        # Should show health indicators
        assert_match(/Health Check/, output)
        assert_match(/Stale tasks/, output)
        assert_match(/Blocked tasks/, output)
        assert_match(/Overdue releases/, output)
      end
    end
  end

  def test_filter_releases_by_pattern
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--filter", "0.8"])
        end

        # Should only show matching releases
        assert_match(/v\.0\.8\.0/, output)
        refute_match(/v\.0\.9\.0/, output)
      end
    end
  end
end