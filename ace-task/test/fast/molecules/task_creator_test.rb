# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class TaskCreatorTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-creator-test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_creates_task_with_correct_folder_structure
    creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    task = creator.create("Fix login bug")

    assert task.id.match?(/^[0-9a-z]{3}\.t\.[0-9a-z]{3}$/)
    assert_equal "pending", task.status
    assert_equal "Fix login bug", task.title
    assert File.exist?(task.file_path)
    assert task.file_path.end_with?(".s.md")
  end

  def test_creates_folder_with_folder_slug
    creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    task = creator.create("Fix login bug", time: Time.utc(2026, 1, 15, 12, 0, 0))

    folder_name = File.basename(task.path)
    # Folder uses folder_slug (up to 5 words)
    assert folder_name.match?(/^[0-9a-z]{3}\.t\.[0-9a-z]{3}-fix-login-bug$/), "folder: #{folder_name}"
  end

  def test_folder_slug_differs_from_file_slug_for_long_titles
    creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    task = creator.create("Plan repository naming and metadata updates for branding")

    folder_name = File.basename(task.path)
    file_name = File.basename(task.file_path)

    # Folder slug: 5 words max
    assert folder_name.match?(/plan-repository-naming-and-metadata$/), "folder: #{folder_name}"
    # File slug: 7 words max
    assert file_name.match?(/plan-repository-naming-and-metadata-updates-for\.s\.md$/), "file: #{file_name}"
  end

  def test_spec_file_has_frontmatter
    creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    task = creator.create("Test task")

    content = File.read(task.file_path)
    assert content.start_with?("---")
    assert content.include?("status: pending")
    assert content.include?(task.id)
    assert content.include?("# Test task")
  end

  def test_raises_for_empty_title
    creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)

    assert_raises(ArgumentError) { creator.create("") }
    assert_raises(ArgumentError) { creator.create(nil) }
  end

  def test_created_task_can_be_loaded_back
    creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    created = creator.create("Loadable task")

    loader = Ace::Task::Molecules::TaskLoader.new
    loaded = loader.load(created.path, id: created.id)

    assert_equal created.id, loaded.id
    assert_equal "Loadable task", loaded.title
    assert_equal "pending", loaded.status
  end

  def test_created_task_can_be_found_by_scanner
    creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    created = creator.create("Scannable task")

    scanner = Ace::Task::Molecules::TaskScanner.new(@tmpdir)
    results = scanner.scan

    assert_equal 1, results.length
    assert_equal created.id, results.first.id
  end

  def test_created_task_can_be_resolved_by_shortcut
    creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    created = creator.create("Resolvable task")

    scanner = Ace::Task::Molecules::TaskScanner.new(@tmpdir)
    results = scanner.scan
    resolver = Ace::Task::Molecules::TaskResolver.new(results)

    # Resolve by suffix (last 3 chars of the formatted ID)
    suffix = created.id[-3..]
    found = resolver.resolve(suffix)

    assert_equal created.id, found.id
  end

  def test_creates_task_with_priority_and_tags
    creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    task = creator.create("Auth task", priority: "high", tags: ["auth", "security"])

    assert_equal "high", task.priority
    assert_equal ["auth", "security"], task.tags
  end

  def test_creates_task_with_dependencies
    creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    task = creator.create("Dependent task", dependencies: ["8pp.t.abc"])

    assert_equal ["8pp.t.abc"], task.dependencies
  end

  def test_spec_file_has_full_frontmatter
    creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    task = creator.create("Full task", priority: "critical", tags: ["api"])

    content = File.read(task.file_path)
    assert_includes content, "priority: critical"
    assert_includes content, "tags: [api]"
    assert_includes content, "created_at:"
  end

  def test_raises_id_collision_when_generated_task_id_already_exists
    creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    colliding_id = "8pp.t.q7w"
    existing_dir = File.join(@tmpdir, "#{colliding_id}-existing-task")
    FileUtils.mkdir_p(existing_dir)
    File.write(
      File.join(existing_dir, "#{colliding_id}-existing-task.s.md"),
      "---\nid: #{colliding_id}\nstatus: pending\n---\n\n# Existing\n"
    )

    item_id = Struct.new(:formatted_id).new(colliding_id)
    Ace::Task::Atoms::TaskIdFormatter.stub(:generate, item_id) do
      assert_raises(Ace::Task::Molecules::TaskCreator::IdCollisionError) do
        creator.create("New task with colliding ID")
      end
    end
  end

  def test_raises_id_collision_when_id_reservation_is_already_held
    creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    colliding_id = "8pp.t.q7z"
    reservation = File.join(@tmpdir, ".ace-task-id-lock-#{colliding_id}")
    Dir.mkdir(reservation)

    item_id = Struct.new(:formatted_id).new(colliding_id)
    Ace::Task::Atoms::TaskIdFormatter.stub(:generate, item_id) do
      assert_raises(Ace::Task::Molecules::TaskCreator::IdCollisionError) do
        creator.create("New task while lock is held")
      end
    end

    assert Dir.exist?(reservation), "Expected existing reservation lock to remain untouched"
  ensure
    FileUtils.rm_rf(reservation) if reservation && Dir.exist?(reservation)
  end

  def test_cleans_up_partial_artifacts_when_create_fails_after_write
    creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    item_id = Struct.new(:formatted_id).new("8pp.t.q7x")
    failing_loader = Object.new
    failing_loader.define_singleton_method(:load) do |_path, id:|
      raise "simulated loader failure for #{id}"
    end

    Ace::Task::Atoms::TaskIdFormatter.stub(:generate, item_id) do
      Ace::Task::Molecules::TaskLoader.stub(:new, failing_loader) do
        assert_raises(RuntimeError) { creator.create("Task with failing load") }
      end
    end

    created_paths = Dir.glob(File.join(@tmpdir, "8pp.t.q7x-*"))
    assert_empty created_paths, "Expected partial task artifacts to be cleaned up"
  end
end
