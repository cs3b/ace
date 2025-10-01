# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/idea_loader"

class IdeaLoaderTest < AceTaskflowTestCase
  def setup
    @loader = nil # Will create in test context
  end

  def test_load_ideas_from_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create test idea in .ace-taskflow/v.0.9.0/ideas (not v.0.9.0/ideas)
        idea_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "ideas")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "20250101-120000-test-idea.md"), "# Test Idea\n\nContent here")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(context: "v.0.9.0")

        assert_equal 1, ideas.length
        assert_equal "20250101-120000", ideas.first[:id]
        assert_match(/test idea/i, ideas.first[:title])
      end
    end
  end

  def test_load_ideas_from_backlog
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create test idea in .ace-taskflow/backlog/ideas
        idea_dir = File.join(dir, ".ace-taskflow", "backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "20250102-130000-backlog-idea.md"), "# Backlog Idea")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(context: "backlog")

        assert_equal 1, ideas.length
        assert_equal "20250102-130000", ideas.first[:id]
      end
    end
  end

  def test_load_all_ideas
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create ideas in multiple locations
        v090_ideas = File.join(dir, ".ace-taskflow", "v.0.9.0", "ideas")
        backlog_ideas = File.join(dir, ".ace-taskflow", "backlog", "ideas")
        FileUtils.mkdir_p(v090_ideas)
        FileUtils.mkdir_p(backlog_ideas)

        File.write(File.join(v090_ideas, "20250101-100000-idea-one.md"), "# Idea One")
        File.write(File.join(backlog_ideas, "20250102-100000-idea-two.md"), "# Idea Two")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))

        # Load from v.0.9.0
        v090_result = @loader.load_all(context: "v.0.9.0")
        assert_equal 1, v090_result.length

        # Load from backlog
        backlog_result = @loader.load_all(context: "backlog")
        assert_equal 1, backlog_result.length
      end
    end
  end

  def test_find_next_idea
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "20250101-100000-first.md"), "# First")
        File.write(File.join(idea_dir, "20250102-100000-second.md"), "# Second")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        next_idea = @loader.find_next(context: "backlog")

        assert_equal "20250101-100000", next_idea[:id]
      end
    end
  end

  def test_find_by_partial_name
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "20250101-100000-dark-mode-feature.md"), "# Dark Mode")
        File.write(File.join(idea_dir, "20250102-100000-light-theme.md"), "# Light Theme")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        idea = @loader.find_by_partial_name("dark", context: "backlog")

        assert idea
        assert_match(/dark/i, idea[:filename])
      end
    end
  end

  def test_find_by_reference_with_timestamp
    skip "Requires active release configuration - tested in integration tests"
  end

  def test_load_idea_with_content
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        idea_path = File.join(idea_dir, "20250101-100000-test.md")
        File.write(idea_path, "# My Idea\n\nThis is the content")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        idea = @loader.load_idea(idea_path, include_content: true)

        assert idea
        assert_equal "20250101-100000", idea[:id]
        assert_includes idea[:content], "This is the content"
      end
    end
  end

  def test_handle_missing_idea_directory
    with_test_project do |dir|
      Dir.chdir(dir) do
        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(context: "v.99.99.99")

        assert_equal [], ideas
      end
    end
  end

  def test_load_ideas_without_content
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "20250101-100000-test.md"), "# Test\n\nLong content here")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(context: "backlog", include_content: false)

        assert_equal 1, ideas.length
        assert_nil ideas.first[:content]
      end
    end
  end

  def test_extract_title_from_filename
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "20250101-100000-add-dark-mode-feature.md"), "Content")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(context: "backlog")

        assert_equal 1, ideas.length
        assert_match(/add dark mode feature/i, ideas.first[:title])
      end
    end
  end

  def test_load_nonexistent_idea
    with_test_project do |dir|
      Dir.chdir(dir) do
        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        idea = @loader.load_idea("/nonexistent/path.md")

        assert_nil idea
      end
    end
  end

  def test_find_by_partial_name_case_insensitive
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "20250101-100000-UPPERCASE-IDEA.md"), "# Test")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        idea = @loader.find_by_partial_name("uppercase", context: "backlog")

        assert idea
        assert_match(/UPPERCASE/i, idea[:filename])
      end
    end
  end
end
