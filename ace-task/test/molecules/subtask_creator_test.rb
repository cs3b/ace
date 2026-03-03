# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class SubtaskCreatorTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("subtask-creator-test")
    @creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    @parent = @creator.create("Fix login bug", time: Time.utc(2026, 2, 26, 12, 0, 0))
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_creates_subtask_with_correct_id
    subtask_creator = Ace::Task::Molecules::SubtaskCreator.new
    subtask = subtask_creator.create(@parent, "Setup database")

    assert_equal "#{@parent.id}.0", subtask.id
  end

  def test_creates_subtask_with_parent_id
    subtask_creator = Ace::Task::Molecules::SubtaskCreator.new
    subtask = subtask_creator.create(@parent, "Setup database")

    assert_equal @parent.id, subtask.parent_id
    assert subtask.subtask?
  end

  def test_creates_subtask_folder_inside_parent
    subtask_creator = Ace::Task::Molecules::SubtaskCreator.new
    subtask = subtask_creator.create(@parent, "Setup database")

    assert subtask.path.start_with?(@parent.path)
    assert File.exist?(subtask.file_path)
  end

  def test_sequential_allocation
    subtask_creator = Ace::Task::Molecules::SubtaskCreator.new

    first = subtask_creator.create(@parent, "First subtask")
    second = subtask_creator.create(@parent, "Second subtask")
    third = subtask_creator.create(@parent, "Third subtask")

    assert_equal "#{@parent.id}.0", first.id
    assert_equal "#{@parent.id}.1", second.id
    assert_equal "#{@parent.id}.2", third.id
  end

  def test_subtask_has_spec_file_with_frontmatter
    subtask_creator = Ace::Task::Molecules::SubtaskCreator.new
    subtask = subtask_creator.create(@parent, "Setup database", priority: "high", tags: ["db"])

    content = File.read(subtask.file_path)
    assert_includes content, "parent: #{@parent.id}"
    assert_includes content, "priority: high"
    assert_includes content, "tags: [db]"
    assert_includes content, "# Setup database"
  end

  def test_raises_for_empty_title
    subtask_creator = Ace::Task::Molecules::SubtaskCreator.new

    assert_raises(ArgumentError) { subtask_creator.create(@parent, "") }
    assert_raises(ArgumentError) { subtask_creator.create(@parent, nil) }
  end

  def test_raises_range_error_at_37th_subtask
    subtask_creator = Ace::Task::Molecules::SubtaskCreator.new

    # Create 36 subtask directories manually (a-z, 0-9) using short folder format
    chars = ("a".."z").to_a + ("0".."9").to_a
    chars.each do |char|
      folder = File.join(@parent.path, "#{char}-sub-#{char}")
      FileUtils.mkdir_p(folder)
      File.write(File.join(folder, "#{@parent.id}.#{char}-sub-#{char}.s.md"),
        "---\nid: #{@parent.id}.#{char}\nstatus: pending\nparent: #{@parent.id}\n---\n")
    end

    assert_raises(RangeError) do
      subtask_creator.create(@parent, "One too many")
    end
  end

  def test_dual_slug_folder_shorter_than_file_for_long_titles
    subtask_creator = Ace::Task::Molecules::SubtaskCreator.new
    subtask = subtask_creator.create(@parent, "Implement the new authentication flow for users")

    folder_name = File.basename(subtask.path)
    spec_name = File.basename(subtask.file_path, ".s.md")

    # Folder slug should be 5 words, file slug should be 7 words
    folder_slug = folder_name.sub(/^[0-9a-z.]+?-/, "")
    file_slug = spec_name.sub(/^[0-9a-z.]+?-/, "")

    assert folder_slug.split("-").length <= 5, "Folder slug should have at most 5 words: #{folder_slug}"
    assert file_slug.split("-").length <= 7, "File slug should have at most 7 words: #{file_slug}"
    assert file_slug.length > folder_slug.length, "File slug should be longer than folder slug for long titles"
  end

  def test_subtask_loadable_by_parent
    subtask_creator = Ace::Task::Molecules::SubtaskCreator.new
    subtask_creator.create(@parent, "Setup database")

    loader = Ace::Task::Molecules::TaskLoader.new
    reloaded = loader.load(@parent.path, id: @parent.id)

    assert reloaded.has_subtasks?
    assert_equal 1, reloaded.subtasks.length
    assert_equal "Setup database", reloaded.subtasks.first.title
  end
end
