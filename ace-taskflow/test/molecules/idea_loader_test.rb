# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/idea_loader"

class IdeaLoaderTest < AceTaskflowTestCase
  def setup
    @loader = nil # Will create in test context
  end

  # Tests using Base36 compact ID format (6 alphanumeric characters)

  def test_load_ideas_from_release
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create test idea in .ace-taskflow/v.0.9.0/ideas using Base36 ID
        idea_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "ideas")
        FileUtils.mkdir_p(idea_dir)
        idea_subdir = File.join(idea_dir, "abc123-test-idea")
        FileUtils.mkdir_p(idea_subdir)
        File.write(File.join(idea_subdir, "test-idea.idea.s.md"), "# Test Idea\n\nContent here")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "v.0.9.0")

        assert_equal 1, ideas.length
        assert_equal "abc123", ideas.first[:id]
        assert_match(/test idea/i, ideas.first[:title])
      end
    end
  end

  def test_load_ideas_from_backlog
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create test idea in .ace-taskflow/_backlog/ideas using Base36 ID
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        idea_subdir = File.join(idea_dir, "def456-backlog-idea")
        FileUtils.mkdir_p(idea_subdir)
        File.write(File.join(idea_subdir, "backlog-idea.idea.s.md"), "# Backlog Idea")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "backlog")

        assert_equal 1, ideas.length
        assert_equal "def456", ideas.first[:id]
      end
    end
  end

  def test_load_all_ideas
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create ideas in multiple locations using Base36 IDs
        v090_ideas = File.join(dir, ".ace-taskflow", "v.0.9.0", "ideas")
        backlog_ideas = File.join(dir, ".ace-taskflow", "_backlog", "ideas")
        FileUtils.mkdir_p(v090_ideas)
        FileUtils.mkdir_p(backlog_ideas)

        idea1_dir = File.join(v090_ideas, "abc123-idea-one")
        FileUtils.mkdir_p(idea1_dir)
        File.write(File.join(idea1_dir, "idea-one.idea.s.md"), "# Idea One")

        idea2_dir = File.join(backlog_ideas, "xyz789-idea-two")
        FileUtils.mkdir_p(idea2_dir)
        File.write(File.join(idea2_dir, "idea-two.idea.s.md"), "# Idea Two")

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
        # Use Base36 IDs that sort correctly (earlier ID first)
        first_dir = File.join(idea_dir, "aaa111-first")
        FileUtils.mkdir_p(first_dir)
        File.write(File.join(first_dir, "first.idea.s.md"), "# First")

        second_dir = File.join(idea_dir, "zzz999-second")
        FileUtils.mkdir_p(second_dir)
        File.write(File.join(second_dir, "second.idea.s.md"), "# Second")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        next_idea = @loader.find_next(release: "backlog")

        assert next_idea
        assert_equal "aaa111", next_idea[:id]
      end
    end
  end

  def test_find_by_partial_name
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        dark_dir = File.join(idea_dir, "abc123-dark-mode-feature")
        FileUtils.mkdir_p(dark_dir)
        File.write(File.join(dark_dir, "dark-mode-feature.idea.s.md"), "# Dark Mode")
        light_dir = File.join(idea_dir, "def456-light-theme")
        FileUtils.mkdir_p(light_dir)
        File.write(File.join(light_dir, "light-theme.idea.s.md"), "# Light Theme")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        idea = @loader.find_by_partial_name("dark", release: "backlog")

        assert idea
        assert_match(/dark/i, idea[:filename])
      end
    end
  end

  def test_load_idea_with_content
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        idea_subdir = File.join(idea_dir, "abc123-test")
        FileUtils.mkdir_p(idea_subdir)
        idea_path = File.join(idea_subdir, "test.idea.s.md")
        File.write(idea_path, "# My Idea\n\nThis is the content")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        idea = @loader.load_idea(idea_subdir, include_content: true)

        assert idea
        assert_equal "abc123", idea[:id]
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
        idea_subdir = File.join(idea_dir, "abc123-test")
        FileUtils.mkdir_p(idea_subdir)
        File.write(File.join(idea_subdir, "test.idea.s.md"), "# Test\n\nLong content here")

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
        idea_subdir = File.join(idea_dir, "abc123-add-dark-mode-feature")
        FileUtils.mkdir_p(idea_subdir)
        File.write(File.join(idea_subdir, "add-dark-mode-feature.idea.s.md"), "Content")

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
        idea_subdir = File.join(idea_dir, "abc123-UPPERCASE-IDEA")
        FileUtils.mkdir_p(idea_subdir)
        File.write(File.join(idea_subdir, "uppercase-idea.idea.s.md"), "# Test")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        idea = @loader.find_by_partial_name("uppercase", release: "backlog")

        assert idea
        assert_match(/UPPERCASE/i, idea[:filename])
      end
    end
  end

  # Tests for Base36 compact ID format

  def test_load_idea_with_compact_id_format
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas")
        FileUtils.mkdir_p(idea_dir)
        # Use a valid 6-char Base36 ID
        idea_subdir = File.join(idea_dir, "abc123-compact-idea")
        FileUtils.mkdir_p(idea_subdir)
        File.write(File.join(idea_subdir, "compact-idea.idea.s.md"), "# Compact Idea\n\nContent here")

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
        File.write(File.join(idea_dir, "directory-idea.idea.s.md"), "# Directory Idea\n\nContent")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "backlog")

        assert_equal 1, ideas.length
        assert_equal "xyz789", ideas.first[:id]
        assert ideas.first[:is_directory]
      end
    end
  end

  def test_find_by_reference_with_compact_id
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create v.0.9.0 as active release and add idea there
        release_dir = File.join(dir, ".ace-taskflow", "v.0.9.0", "ideas")
        FileUtils.mkdir_p(release_dir)
        idea_dir = File.join(release_dir, "abc123-test-idea")
        FileUtils.mkdir_p(idea_dir)
        File.write(File.join(idea_dir, "test-idea.idea.s.md"), "# Test Idea\n\nContent")

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
        idea_subdir = File.join(idea_dir, "abc123-idea")
        FileUtils.mkdir_p(idea_subdir)
        File.write(File.join(idea_subdir, "idea.idea.s.md"), "# Test")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "backlog")

        # Should have a created_at time (decoded from compact ID or fallback)
        assert ideas.first[:created_at].is_a?(Time)
      end
    end
  end

  # Tests for new .idea.s.md format (Task 182)

  def test_load_idea_directory_with_idea_s_md_format
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas", "xyz789-new-format")
        FileUtils.mkdir_p(idea_dir)
        # New format: {slug}.idea.s.md
        File.write(File.join(idea_dir, "new-format.idea.s.md"), "# New Format Idea\n\nContent")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "backlog")

        assert_equal 1, ideas.length
        assert_equal "xyz789", ideas.first[:id]
        assert ideas.first[:is_directory]
      end
    end
  end

  # Tests for file_path resolution (Task 182)

  def test_file_path_resolution
    with_test_project do |dir|
      Dir.chdir(dir) do
        idea_dir = File.join(dir, ".ace-taskflow", "_backlog", "ideas", "xyz789-test")
        FileUtils.mkdir_p(idea_dir)
        expected_path = File.join(idea_dir, "test.idea.s.md")
        File.write(expected_path, "# Test Format")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "backlog")

        assert_equal 1, ideas.length
        assert_equal expected_path, ideas.first[:file_path]
      end
    end
  end

  def test_legacy_formats_not_supported
    with_test_project do |dir|
      Dir.chdir(dir) do
        # Create legacy format files - should be ignored
        ideas_base = File.join(dir, ".ace-taskflow", "_backlog", "ideas")

        # Legacy idea.s.md format
        legacy_dir = File.join(ideas_base, "abc123-legacy")
        FileUtils.mkdir_p(legacy_dir)
        File.write(File.join(legacy_dir, "idea.s.md"), "# Legacy Idea")

        # Alternative .s.md format
        File.write(File.join(ideas_base, "def456-alternative.s.md"), "# Alternative Idea")

        @loader = Ace::Taskflow::Molecules::IdeaLoader.new(File.join(dir, ".ace-taskflow"))
        ideas = @loader.load_all(release: "backlog")

        # Neither format should be loaded
        assert_equal 0, ideas.length
      end
    end
  end
end
