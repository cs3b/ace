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
        File.write(File.join(idea_dir, "20250101-120000-test-idea.s.md"), "# Test Idea\n\nContent here")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "v.0.9.0")

        assert_equal 1, ideas.length
        assert_equal "20250101-120000", ideas.first[:id]
        assert_match(/test idea/i, ideas.first[:title])
      end
    end
  end

  def test_load_ideas_from_backlog
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create test idea in .ace-taskflow/_backlog/ideas
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "20250102-130000-backlog-idea.s.md"), "# Backlog Idea")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "backlog")

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
        backlog_ideas = File.join(dir, ".ace-taskflow", "_backlog", "ideas")
        FileUtils.mkdir_p(v090_ideas)
        FileUtils.mkdir_p(backlog_ideas)

        File.write(File.join(v090_ideas, "20250101-100000-idea-one.s.md"), "# Idea One")
        File.write(File.join(backlog_ideas, "20250102-100000-idea-two.s.md"), "# Idea Two")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))

        # Load from v.0.9.0
        v090_result = @loader.load_all(release: "v.0.9.0")
        assert_equal 1, v090_result.length

        # Load from backlog
        backlog_result = @loader.load_all(release: "backlog")
        assert_equal 1, backlog_result.length
      end
    end
  end

  def test_find_next_idea
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "20250101-100000-first.s.md"), "# First")
        File.write(File.join(idea_dir, "20250102-100000-second.s.md"), "# Second")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        next_idea = @loader.find_next(release: "backlog")

        assert_equal "20250101-100000", next_idea[:id]
      end
    end
  end

  def test_find_by_partial_name
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "20250101-100000-dark-mode-feature.s.md"), "# Dark Mode")
        File.write(File.join(idea_dir, "20250102-100000-light-theme.s.md"), "# Light Theme")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        idea = @loader.find_by_partial_name("dark", release: "backlog")

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
        idea_path = File.join(idea_dir, "20250101-100000-test.s.md")
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
        ideas = @loader.load_all(release: "v.99.99.99")

        assert_equal [], ideas
      end
    end
  end

  def test_load_ideas_without_content
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "20250101-100000-test.s.md"), "# Test\n\nLong content here")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "backlog", include_content: false)

        assert_equal 1, ideas.length
        assert_nil ideas.first[:content]
      end
    end
  end

  def test_extract_title_from_filename
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "20250101-100000-add-dark-mode-feature.s.md"), "Content")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "backlog")

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
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "20250101-100000-UPPERCASE-IDEA.s.md"), "# Test")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        idea = @loader.find_by_partial_name("uppercase", release: "backlog")

        assert idea
        assert_match(/UPPERCASE/i, idea[:filename])
      end
    end
  end

  # Tests for Base36 compact ID format support
  def test_load_idea_with_compact_id_format
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        # Use a valid-looking 6-char Base36 ID
        File.write(File.join(idea_dir, "abc123-compact-idea.s.md"), "# Compact Idea\n\nContent here")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "backlog")

        assert_equal 1, ideas.length
        assert_equal "abc123", ideas.first[:id]
        assert_match(/compact idea/i, ideas.first[:title])
      end
    end
  end

  def test_load_idea_directory_with_compact_id
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas", "xyz789-directory-idea")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "idea.s.md"), "# Directory Idea\n\nContent")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "backlog")

        assert_equal 1, ideas.length
        assert_equal "xyz789", ideas.first[:id]
        assert ideas.first[:is_directory]
      end
    end
  end

  def test_mixed_timestamp_and_compact_ids
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        # Create both timestamp and compact ID ideas
        File.write(File.join(idea_dir, "20250101-100000-timestamp-idea.s.md"), "# Timestamp Idea")
        File.write(File.join(idea_dir, "abc123-compact-idea.s.md"), "# Compact Idea")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "backlog")

        assert_equal 2, ideas.length

        timestamp_idea = ideas.find { |i| i[:id] == "20250101-100000" }
        compact_idea = ideas.find { |i| i[:id] == "abc123" }

        assert timestamp_idea, "Should load timestamp format idea"
        assert compact_idea, "Should load compact format idea"
      end
    end
  end

  def test_find_by_reference_with_compact_id
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create v.0.9.0 as active release and add idea there
        release_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "ideas")
        FileUtils.mkdir_p(release_dir)
        File.write(File.join(release_dir, "abc123-test-idea.s.md"), "# Test Idea\n\nContent")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        idea = @loader.find_by_reference("abc123")

        assert idea
        assert_equal "abc123", idea[:id]
      end
    end
  end

  def test_extract_timestamp_from_compact_id
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "abc123-idea.s.md"), "# Test")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "backlog")

        # Should have a created_at time (decoded from compact ID or fallback)
        assert ideas.first[:created_at].is_a?(Time)
      end
    end
  end
end
