# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class FolderMoverTest < AceSupportItemsTestCase
  Mover = Ace::Support::Items::Molecules::FolderMover

  def setup
    @tmpdir = Dir.mktmpdir("folder-mover-test")
    @root_dir = File.join(@tmpdir, "items")
    FileUtils.mkdir_p(@root_dir)
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_move_to_special_folder_with_short_name
    item = create_item_folder("8pp.t.q7w-fix-login")
    mover = Mover.new(@root_dir)

    new_path = mover.move(item, to: "maybe")

    assert File.exist?(new_path)
    assert_includes new_path, "_maybe"
    refute File.exist?(item.path)
  end

  def test_move_to_special_folder_with_full_name
    item = create_item_folder("8pp.t.q7w-fix-login")
    mover = Mover.new(@root_dir)

    new_path = mover.move(item, to: "_anytime")

    assert File.exist?(new_path)
    assert_includes new_path, "_anytime"
  end

  def test_move_rejects_virtual_filter_target
    item = create_item_folder("8pp.t.q7w-fix-login")
    mover = Mover.new(@root_dir)

    assert_raises(ArgumentError) { mover.move(item, to: "next") }
    assert_raises(ArgumentError) { mover.move(item, to: "all") }
  end

  def test_move_to_archive_with_date_partition
    item = create_item_folder("8pp.t.q7w-fix-login")
    mover = Mover.new(@root_dir)

    new_path = mover.move(item, to: "archive", date: Time.utc(2026, 2, 15))

    assert File.exist?(new_path)
    assert_includes new_path, "_archive"
    # Should have partition subdirectory
    relative = new_path.sub(@root_dir + "/", "")
    parts = relative.split("/")
    assert_equal "_archive", parts[0]
    # partition has month/week structure
    assert parts.length >= 3, "Expected archive/month/week/folder structure, got: #{relative}"
  end

  def test_move_same_location_returns_original_path
    item = create_item_in_folder("8pp.t.q7w-fix-login", "_maybe")
    mover = Mover.new(@root_dir)

    result = mover.move(item, to: "maybe")

    assert_equal item.path, result
  end

  def test_move_to_root
    item = create_item_in_folder("8pp.t.q7w-fix-login", "_maybe")
    mover = Mover.new(@root_dir)

    new_path = mover.move_to_root(item)

    assert File.exist?(new_path)
    assert_equal File.join(@root_dir, "8pp.t.q7w-fix-login"), new_path
    refute File.exist?(item.path)
  end

  def test_move_to_root_same_location_returns_original
    item = create_item_folder("8pp.t.q7w-fix-login")
    mover = Mover.new(@root_dir)

    result = mover.move_to_root(item)

    assert_equal item.path, result
  end

  def test_move_creates_target_directory
    item = create_item_folder("8pp.t.q7w-fix-login")
    mover = Mover.new(@root_dir)

    new_path = mover.move(item, to: "_custom")

    assert File.exist?(new_path)
    assert File.directory?(File.join(@root_dir, "_custom"))
  end

  def test_move_raises_on_destination_exists
    create_item_folder("8pp.t.q7w-fix-login")
    # Create same folder in _maybe
    FileUtils.mkdir_p(File.join(@root_dir, "_maybe", "8pp.t.q7w-fix-login"))

    item = create_item_folder_obj(File.join(@root_dir, "8pp.t.q7w-fix-login"))
    mover = Mover.new(@root_dir)

    assert_raises(ArgumentError) do
      mover.move(item, to: "maybe")
    end
  end

  def test_move_rejects_path_traversal
    item = create_item_folder("8pp.t.q7w-fix-login")
    mover = Mover.new(@root_dir)

    assert_raises(ArgumentError) do
      mover.move(item, to: "../../etc")
    end
  end

  private

  ItemStub = Struct.new(:path, keyword_init: true)

  def create_item_folder(folder_name)
    path = File.join(@root_dir, folder_name)
    FileUtils.mkdir_p(path)
    File.write(File.join(path, "#{folder_name}.s.md"), "---\nid: test\n---\n")
    ItemStub.new(path: path)
  end

  def create_item_in_folder(folder_name, special_folder)
    parent = File.join(@root_dir, special_folder)
    FileUtils.mkdir_p(parent)
    path = File.join(parent, folder_name)
    FileUtils.mkdir_p(path)
    File.write(File.join(path, "#{folder_name}.s.md"), "---\nid: test\n---\n")
    ItemStub.new(path: path)
  end

  def create_item_folder_obj(path)
    ItemStub.new(path: path)
  end
end
