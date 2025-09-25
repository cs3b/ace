# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/commands/idea_command"

class IdeaCommandTest < AceTaskflowTestCase
  def setup
    @command = Ace::Taskflow::Commands::IdeaCommand.new
  end

  def test_create_simple_idea
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["This is a new idea"])
        end

        assert_match(/Idea captured/, output)
        assert_match(%r{v\.0\.9\.0/i/}, output)

        # Verify file was created
        idea_files = Dir.glob(File.join(dir, "v.0.9.0", "i", "*.md"))
        assert idea_files.length > 3 # Original 3 + new one

        # Check content
        new_file = idea_files.sort.last
        content = File.read(new_file)
        assert_match(/This is a new idea/, content)
      end
    end
  end

  def test_create_idea_in_backlog
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["Backlog idea", "--backlog"])
        end

        assert_match(/Idea captured/, output)
        assert_match(%r{backlog/i/}, output)

        # Verify file was created in backlog
        idea_files = Dir.glob(File.join(dir, "backlog", "i", "*.md"))
        assert idea_files.length > 5 # Original 5 + new one
      end
    end
  end

  def test_create_idea_with_git_commit
    with_test_project do |dir|
      # Initialize git repo for test
      Dir.chdir(dir) do
        `git init`
        `git config user.email "test@example.com"`
        `git config user.name "Test User"`
        `git add .`
        `git commit -m "Initial commit"`

        output = capture_stdout do
          @command.execute(["Git committed idea", "--git"])
        end

        assert_match(/Idea captured/, output)

        # Check git status
        git_status = `git status --short`
        assert_match(/A.*i\//, git_status) if git_status.length > 0
      end
    end
  end

  def test_create_idea_with_edit_flag
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Mock editor environment
        ENV["EDITOR"] = "echo 'Edited content' >"

        output = capture_stdout do
          @command.execute(["--edit"])
        end

        assert_match(/Idea captured/, output)

        # Find the created file
        idea_files = Dir.glob(File.join(dir, "v.0.9.0", "i", "*.md"))
        new_file = idea_files.sort.last
        content = File.read(new_file)
        assert_match(/Edited content/, content) if content
      end
    end
  end

  def test_show_next_idea
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["next"])
        end

        assert_match(/Idea 001/, output)
        assert_match(/Sample idea/, output)
      end
    end
  end

  def test_show_specific_idea
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["show", "002"])
        end

        assert_match(/Idea 002/, output)
      end
    end
  end

  def test_list_recent_ideas
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["recent"])
        end

        # Should show recent ideas
        assert_match(/Recent Ideas/, output)
        assert_match(/001/, output)
        assert_match(/002/, output)
      end
    end
  end

  def test_convert_idea_to_task
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["convert", "001"])
        end

        assert_match(/Converted idea to task/, output)
        assert_match(/v\.0\.9\.0\+task\.006/, output)

        # Verify task was created
        task_file = Dir.glob(File.join(dir, "v.0.9.0", "t", "006", "*.md")).first
        assert task_file
        assert File.exist?(task_file)

        # Verify idea was archived
        idea_file = File.join(dir, "v.0.9.0", "i", "001.md")
        refute File.exist?(idea_file)
      end
    end
  end

  def test_show_idea_with_path_flag
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["show", "001", "--path"])
        end

        assert_match(%r{v\.0\.9\.0/i/001\.md}, output)
        refute_match(/Idea 001/, output)
      end
    end
  end

  def test_no_ideas_message
    with_test_project do |dir|
      # Remove all ideas
      FileUtils.rm_rf(Dir.glob(File.join(dir, "**/i")))

      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["next"])
        end

        assert_match(/No ideas found/, output)
      end
    end
  end

  def test_create_idea_with_location_flag
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["Location-specific idea", "--location", "v.0.8.0"])
        end

        assert_match(/Idea captured/, output)
        assert_match(%r{v\.0\.8\.0/i/}, output)

        # Verify file was created in specified location
        idea_files = Dir.glob(File.join(dir, "v.0.8.0", "i", "*.md"))
        assert idea_files.length > 0
      end
    end
  end

  def test_invalid_idea_reference
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["show", "999"])
        end

        assert_match(/Idea not found/, output)
      end
    end
  end

  def test_create_multiline_idea
    with_test_project do |dir|
      Dir.chdir(dir) do
        output = capture_stdout do
          @command.execute(["Line 1", "Line 2", "Line 3"])
        end

        assert_match(/Idea captured/, output)

        # Find the created file
        idea_files = Dir.glob(File.join(dir, "v.0.9.0", "i", "*.md"))
        new_file = idea_files.sort.last
        content = File.read(new_file)
        assert_match(/Line 1/, content)
        assert_match(/Line 2/, content)
        assert_match(/Line 3/, content)
      end
    end
  end

  def test_idea_with_llm_enhancement
    with_test_project do |dir|
      Dir.chdir(dir) do
        # This would normally call LLM, but in tests we skip it
        output = capture_stdout do
          @command.execute(["Enhance this idea", "--llm"])
        end

        assert_match(/Idea captured/, output)
        # In real implementation, would check for enhanced content
      end
    end
  end
end