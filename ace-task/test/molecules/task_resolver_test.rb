# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class TaskResolverTest < AceTaskTestCase
  def setup
    @tmpdir = Dir.mktmpdir("task-resolver-test")
    @task_dir = create_task_folder("8pp.t.q7w-fix-login")
    @scan_results = Ace::Task::Molecules::TaskScanner.new(@tmpdir).scan
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_resolve_by_full_id
    resolver = Ace::Task::Molecules::TaskResolver.new(@scan_results)
    result = resolver.resolve("8pp.t.q7w")

    assert_equal "8pp.t.q7w", result.id
  end

  def test_resolve_by_suffix
    resolver = Ace::Task::Molecules::TaskResolver.new(@scan_results)
    result = resolver.resolve("q7w")

    assert_equal "8pp.t.q7w", result.id
  end

  def test_resolve_by_short_ref
    resolver = Ace::Task::Molecules::TaskResolver.new(@scan_results)
    result = resolver.resolve("t.q7w")

    assert_equal "8pp.t.q7w", result.id
  end

  def test_resolve_returns_nil_for_unknown
    resolver = Ace::Task::Molecules::TaskResolver.new(@scan_results)
    result = resolver.resolve("zzz")

    assert_nil result
  end

  def test_resolve_returns_nil_for_nil
    resolver = Ace::Task::Molecules::TaskResolver.new(@scan_results)
    assert_nil resolver.resolve(nil)
  end

  def test_resolve_returns_nil_for_empty
    resolver = Ace::Task::Molecules::TaskResolver.new(@scan_results)
    assert_nil resolver.resolve("")
  end

  def test_resolve_subtask_reference
    # Create subtask folder inside parent
    subtask_dir = File.join(@task_dir, "8pp.t.q7w.a-setup-db")
    FileUtils.mkdir_p(subtask_dir)
    File.write(File.join(subtask_dir, "8pp.t.q7w.a-setup-db.s.md"),
      "---\nid: 8pp.t.q7w.a\nstatus: pending\nparent: 8pp.t.q7w\n---\n\n# Setup Database\n")

    resolver = Ace::Task::Molecules::TaskResolver.new(@scan_results)
    result = resolver.resolve("8pp.t.q7w.a")

    assert_equal "8pp.t.q7w.a", result.id
    assert_equal "setup-db", result.slug
    assert_includes result.dir_path, "8pp.t.q7w.a-setup-db"
  end

  def test_resolve_short_subtask_by_suffix
    # Create subtask folder inside parent
    subtask_dir = File.join(@task_dir, "8pp.t.q7w.a-setup-db")
    FileUtils.mkdir_p(subtask_dir)
    File.write(File.join(subtask_dir, "8pp.t.q7w.a-setup-db.s.md"),
      "---\nid: 8pp.t.q7w.a\nstatus: pending\nparent: 8pp.t.q7w\n---\n\n# Setup Database\n")

    resolver = Ace::Task::Molecules::TaskResolver.new(@scan_results)
    result = resolver.resolve("q7w.a")

    assert_equal "8pp.t.q7w.a", result.id
  end

  def test_resolve_short_subtask_with_marker_prefix
    # Create subtask folder inside parent
    subtask_dir = File.join(@task_dir, "8pp.t.q7w.a-setup-db")
    FileUtils.mkdir_p(subtask_dir)
    File.write(File.join(subtask_dir, "8pp.t.q7w.a-setup-db.s.md"),
      "---\nid: 8pp.t.q7w.a\nstatus: pending\nparent: 8pp.t.q7w\n---\n\n# Setup Database\n")

    resolver = Ace::Task::Molecules::TaskResolver.new(@scan_results)
    result = resolver.resolve("t.q7w.a")

    assert_equal "8pp.t.q7w.a", result.id
  end

  def test_resolve_short_subtask_returns_nil_for_unknown_parent
    resolver = Ace::Task::Molecules::TaskResolver.new(@scan_results)
    result = resolver.resolve("zzz.a")

    assert_nil result
  end

  def test_resolve_subtask_returns_nil_for_missing_subtask
    resolver = Ace::Task::Molecules::TaskResolver.new(@scan_results)
    result = resolver.resolve("8pp.t.q7w.z")

    assert_nil result
  end

  def test_resolve_subtask_returns_nil_for_missing_parent
    resolver = Ace::Task::Molecules::TaskResolver.new(@scan_results)
    result = resolver.resolve("abc.t.xyz.a")

    assert_nil result
  end

  private

  def create_task_folder(folder_name)
    path = File.join(@tmpdir, folder_name)
    FileUtils.mkdir_p(path)
    id = folder_name.split("-").first
    File.write(File.join(path, "#{folder_name}.s.md"),
      "---\nid: #{id}\nstatus: pending\n---\n\n# Fix Login\n")
    path
  end
end
