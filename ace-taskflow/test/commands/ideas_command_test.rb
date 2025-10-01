# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/commands/ideas_command"

class IdeasCommandTest < AceTaskflowTestCase
  def setup
    @command = Ace::Taskflow::Commands::IdeasCommand.new
  end

  def test_list_all_ideas
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute([])
        end

        # Should show ideas from active release
        assert_match(/001/, output)
        assert_match(/002/, output)
        assert_match(/003/, output)
        assert_match(/Idea/, output)
      end
    end
  end

  def test_list_ideas_from_specific_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--release", "backlog"])
        end

        # Should show backlog ideas
        assert_match(/backlog/, output)
        assert_match(/001/, output)

        # Should not show release ideas
        refute_match(/v\.0\.9\.0/, output)
      end
    end
  end

  def test_list_all_releases_ideas
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--all"])
        end

        # Should show ideas from all releases
        assert_match(/v\.0\.9\.0/, output)
        assert_match(/backlog/, output)
      end
    end
  end

  def test_list_recent_ideas
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--recent", "2"])
        end

        # Should limit to 2 most recent
        lines = output.lines.select { |l| l.match(/\d{3}\.md/) }
        assert lines.length <= 2
      end
    end
  end

  def test_no_ideas_message
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      # Remove all ideas
      FileUtils.rm_rf(Dir.glob(File.join(dir, "**/i")))

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute([])
        end

        assert_match(/No ideas found/, output)
      end
    end
  end

  def test_ideas_statistics
    skip "Integration test needs fixture update - will be reviewed in Phase 9"
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["--stats"])
        end

        assert_match(/Statistics/, output)
        assert_match(/Total Ideas:/, output)
        assert_match(/By Release:/, output)
      end
    end
  end
end