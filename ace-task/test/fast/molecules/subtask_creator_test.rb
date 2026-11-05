# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "timeout"
require "json"
require "ace/task/molecules/task_reparenter"

class SubtaskCreatorTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("subtask-creator-test")
    @creator = Ace::Task::Molecules::TaskCreator.new(root_dir: @tmpdir)
    @parent = @creator.create("Fix login bug", time: Time.utc(2026, 2, 26, 12, 0, 0))
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_destination_paths_preview_the_created_paths
    subtask_creator = Ace::Task::Molecules::SubtaskCreator.new

    preview = subtask_creator.destination_paths(@parent, "Previewed subtask")
    subtask = subtask_creator.create(@parent, "Previewed subtask")

    assert_equal [subtask.path, subtask.file_path], preview
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

  def test_concurrent_processes_allocate_distinct_subtasks_without_overwriting
    assert_concurrent_allocations
  end

  def test_creators_and_demoters_share_parent_allocation_across_aliases
    assert_concurrent_allocations(demote: true)
  end

  def assert_concurrent_allocations(demote: false)
    skip "requires fork" unless Process.respond_to?(:fork)

    alias_path = File.join(@tmpdir, "parent-alias")
    File.symlink(@parent.path, alias_path)
    gate_read, gate_write = IO.pipe
    children = []
    # Hold the real read/write race window open, without replacing allocation.
    slow_creator = Class.new(Ace::Task::Molecules::SubtaskCreator) do
      private

      def destination_paths_for(parent, title)
        paths = super
        sleep 0.1
        paths
      end
    end
    slow_reparenter = Class.new(Ace::Task::Molecules::TaskReparenter) do
      private

      def demoted_paths(task, parent)
        paths = super
        sleep 0.1
        paths
      end
    end
    standalone = demote ? [2, 3].to_h do |index|
      [index, @creator.create("Move child #{index}", time: Time.utc(2026, 2, 26, 12, index, 0))]
    end : {}
    4.times do |index|
      children << fork do
        gate_write.close
        gate_read.read(1)
        parent = @parent.dup
        parent.path = alias_path if index.odd?
        child = if standalone[index]
          slow_reparenter.new(root_dir: @tmpdir).reparent(standalone[index],
            target: parent.id, resolve_ref: ->(_) { parent })
        else
          slow_creator.new.create(parent, "Concurrent child")
        end
        File.write(File.join(@tmpdir, "result-#{index}.json"), JSON.generate(id: child.id, path: child.file_path))
        exit! 0
      rescue StandardError
        exit! 1
      end
    end
    gate_read.close
    gate_write.write("go!!")
    gate_write.close
    Timeout.timeout(10) do
      children.each do |pid|
        _, status = Process.waitpid2(pid)
        assert status.success?, "child creation process failed"
      end
    end
    children.clear
    results = 4.times.map { |index| JSON.parse(File.read(File.join(@tmpdir, "result-#{index}.json"))) }
    assert_equal 4, results.map { |result| result.fetch("id") }.uniq.size
    assert_equal 4, results.map { |result| File.realpath(result.fetch("path")) }.uniq.size
    results.each do |result|
      assert_includes File.read(result.fetch("path")), "id: #{result.fetch('id')}"
    end
  ensure
    gate_read&.close unless gate_read&.closed?
    gate_write&.close unless gate_write&.closed?
    Array(children).each do |pid|
      begin
        Process.kill("KILL", pid)
        Process.waitpid(pid)
      rescue Errno::ESRCH, Errno::ECHILD
        nil
      end
    end
  end

  def test_process_death_releases_allocation_without_reusing_partial_child
    skip "requires fork" unless Process.respond_to?(:fork)

    ready_read, ready_write = IO.pipe
    pid = fork do
      ready_read.close
      Ace::Task::Molecules::SubtaskAllocationLock.synchronize(@parent.path) do
        Dir.mkdir(File.join(@parent.path, "0-interrupted"))
        ready_write.write("ready")
        ready_write.close
        sleep 30
      end
      exit! 0
    end
    ready_write.close
    assert_equal "ready", Timeout.timeout(5) { ready_read.read(5) }
    Process.kill("KILL", pid)
    Process.waitpid(pid)
    pid = nil
    child = Timeout.timeout(5) do
      Ace::Task::Molecules::SubtaskCreator.new.create(@parent, "After interrupted writer")
    end
    assert_equal "#{@parent.id}.1", child.id
    assert File.file?(child.file_path)
    assert Dir.exist?(File.join(@parent.path, "0-interrupted"))
  ensure
    ready_read&.close unless ready_read&.closed?
    ready_write&.close unless ready_write&.closed?
    if pid
      begin
        Process.kill("KILL", pid)
        Process.waitpid(pid)
      rescue Errno::ESRCH, Errno::ECHILD
        nil
      end
    end
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
