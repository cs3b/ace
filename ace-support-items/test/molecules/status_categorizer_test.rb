# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class StatusCategorizerTest < AceSupportItemsTestCase
  Item = Struct.new(:id, :status, :special_folder, :file_path, keyword_init: true)

  def setup
    @tmpdir = Dir.mktmpdir("status-categorizer-test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  def test_up_next_selects_pending_root_items_sorted_by_id
    items = [
      make_item(id: "8pp.t.z9z", status: "pending"),
      make_item(id: "8pp.t.a1a", status: "pending"),
      make_item(id: "8pp.t.m5m", status: "pending")
    ]

    result = categorize(items, up_next_limit: 2, recently_done_limit: 0)

    assert_equal 2, result[:up_next].length
    assert_equal "8pp.t.a1a", result[:up_next][0].id
    assert_equal "8pp.t.m5m", result[:up_next][1].id
  end

  def test_up_next_excludes_special_folder_items
    items = [
      make_item(id: "8pp.t.a1a", status: "pending"),
      make_item(id: "8pp.t.b2b", status: "pending", special_folder: "_maybe")
    ]

    result = categorize(items, up_next_limit: 10, recently_done_limit: 0)

    assert_equal 1, result[:up_next].length
    assert_equal "8pp.t.a1a", result[:up_next][0].id
  end

  def test_up_next_excludes_non_pending_statuses
    items = [
      make_item(id: "8pp.t.a1a", status: "pending"),
      make_item(id: "8pp.t.b2b", status: "done"),
      make_item(id: "8pp.t.c3c", status: "in-progress")
    ]

    result = categorize(items, up_next_limit: 10, recently_done_limit: 0)

    assert_equal 1, result[:up_next].length
    assert_equal "8pp.t.a1a", result[:up_next][0].id
  end

  def test_up_next_disabled_when_limit_zero
    items = [make_item(id: "8pp.t.a1a", status: "pending")]

    result = categorize(items, up_next_limit: 0, recently_done_limit: 0)

    assert_empty result[:up_next]
  end

  def test_recently_done_sorted_by_mtime_desc
    older_file = make_item(id: "8pp.t.a1a", status: "done")
    sleep 0.05
    newer_file = make_item(id: "8pp.t.b2b", status: "done")

    result = categorize([older_file, newer_file], up_next_limit: 0, recently_done_limit: 10)

    assert_equal 2, result[:recently_done].length
    assert_equal "8pp.t.b2b", result[:recently_done][0][:item].id
    assert_equal "8pp.t.a1a", result[:recently_done][1][:item].id
  end

  def test_recently_done_includes_completed_at
    item = make_item(id: "8pp.t.a1a", status: "done")

    result = categorize([item], up_next_limit: 0, recently_done_limit: 1)

    entry = result[:recently_done].first
    assert_instance_of Time, entry[:completed_at]
  end

  def test_recently_done_respects_limit
    items = 5.times.map { |i| make_item(id: "8pp.t.a#{i}a", status: "done") }

    result = categorize(items, up_next_limit: 0, recently_done_limit: 3)

    assert_equal 3, result[:recently_done].length
  end

  def test_recently_done_disabled_when_limit_zero
    items = [make_item(id: "8pp.t.a1a", status: "done")]

    result = categorize(items, up_next_limit: 0, recently_done_limit: 0)

    assert_empty result[:recently_done]
  end

  def test_recently_done_includes_special_folder_items
    items = [
      make_item(id: "8pp.t.a1a", status: "done"),
      make_item(id: "8pp.t.b2b", status: "done", special_folder: "_archive")
    ]

    result = categorize(items, up_next_limit: 0, recently_done_limit: 10)

    assert_equal 2, result[:recently_done].length
  end

  def test_custom_pending_statuses
    items = [
      make_item(id: "8pp.t.a1a", status: "pending"),
      make_item(id: "8pp.t.b2b", status: "draft")
    ]

    result = Ace::Support::Items::Molecules::StatusCategorizer.categorize(
      items,
      up_next_limit: 10,
      recently_done_limit: 0,
      pending_statuses: %w[pending draft]
    )

    assert_equal 2, result[:up_next].length
  end

  def test_empty_items_returns_empty_buckets
    result = categorize([], up_next_limit: 5, recently_done_limit: 5)

    assert_empty result[:up_next]
    assert_empty result[:recently_done]
  end

  private

  def categorize(items, **opts)
    Ace::Support::Items::Molecules::StatusCategorizer.categorize(items, **opts)
  end

  def make_item(id:, status:, special_folder: nil)
    path = File.join(@tmpdir, "#{id}.md")
    File.write(path, "# test")
    Item.new(id: id, status: status, special_folder: special_folder, file_path: path)
  end
end
