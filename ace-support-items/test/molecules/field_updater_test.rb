# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class FieldUpdaterTest < AceSupportItemsTestCase
  Updater = Ace::Support::Items::Molecules::FieldUpdater

  def setup
    @tmpdir = Dir.mktmpdir("field-updater-test")
  end

  def teardown
    FileUtils.rm_rf(@tmpdir)
  end

  # --- set operations ---

  def test_set_replaces_scalar_field
    file = create_spec_file("status" => "pending")
    fm = Updater.update(file, set: { "status" => "done" })
    assert_equal "done", fm["status"]
  end

  def test_set_creates_new_field
    file = create_spec_file("status" => "pending")
    fm = Updater.update(file, set: { "priority" => "high" })
    assert_equal "high", fm["priority"]
  end

  def test_set_handles_nested_dot_key
    file = create_spec_file_raw("---\nupdate:\n  frequency: weekly\n---\n")
    fm = Updater.update(file, set: { "update.last-updated" => "2026-03-01" })
    assert_equal "2026-03-01", fm["update"]["last-updated"]
    assert_equal "weekly", fm["update"]["frequency"]
  end

  def test_set_creates_intermediate_hashes_for_nested_key
    file = create_spec_file("status" => "pending")
    fm = Updater.update(file, set: { "meta.source.name" => "agent" })
    assert_equal "agent", fm["meta"]["source"]["name"]
  end

  # --- add operations ---

  def test_add_appends_to_existing_array
    file = create_spec_file("tags" => ["auth"])
    fm = Updater.update(file, add: { "tags" => "ui" })
    assert_equal ["auth", "ui"], fm["tags"]
  end

  def test_add_creates_array_from_nil
    file = create_spec_file("status" => "pending")
    fm = Updater.update(file, add: { "tags" => "new" })
    assert_equal ["new"], fm["tags"]
  end

  def test_add_coerces_scalar_to_array
    file = create_spec_file("tags" => "existing")
    fm = Updater.update(file, add: { "tags" => "new" })
    assert_equal ["existing", "new"], fm["tags"]
  end

  def test_add_deduplicates_values
    file = create_spec_file("tags" => ["auth"])
    fm = Updater.update(file, add: { "tags" => "auth" })
    assert_equal ["auth"], fm["tags"]
  end

  def test_add_multiple_values
    file = create_spec_file("tags" => [])
    fm = Updater.update(file, add: { "tags" => ["a", "b"] })
    assert_equal ["a", "b"], fm["tags"]
  end

  # --- remove operations ---

  def test_remove_from_array
    file = create_spec_file("tags" => ["auth", "ui", "api"])
    fm = Updater.update(file, remove: { "tags" => "ui" })
    assert_equal ["auth", "api"], fm["tags"]
  end

  def test_remove_multiple_from_array
    file = create_spec_file("tags" => ["a", "b", "c"])
    fm = Updater.update(file, remove: { "tags" => ["a", "c"] })
    assert_equal ["b"], fm["tags"]
  end

  def test_remove_skips_nil_field
    file = create_spec_file("status" => "pending")
    fm = Updater.update(file, remove: { "tags" => "missing" })
    assert_nil fm["tags"]
  end

  def test_remove_raises_for_non_array
    file = create_spec_file("status" => "pending")
    assert_raises(ArgumentError) do
      Updater.update(file, remove: { "status" => "pending" })
    end
  end

  # --- combined operations ---

  def test_combined_set_and_add
    file = create_spec_file("status" => "pending", "tags" => ["auth"])
    fm = Updater.update(file, set: { "status" => "done" }, add: { "tags" => "shipped" })
    assert_equal "done", fm["status"]
    assert_equal ["auth", "shipped"], fm["tags"]
  end

  # --- file persistence ---

  def test_changes_persisted_to_file
    file = create_spec_file("status" => "pending")
    Updater.update(file, set: { "status" => "done" })

    content = File.read(file)
    assert_includes content, "status: done"
  end

  def test_body_preserved_after_update
    file = create_spec_file_with_body("status" => "pending")
    Updater.update(file, set: { "status" => "done" })

    content = File.read(file)
    assert_includes content, "# Test Task"
    assert_includes content, "Some body content"
  end

  private

  def create_spec_file(frontmatter)
    path = File.join(@tmpdir, "test.s.md")
    content = Ace::Support::Items::Atoms::FrontmatterSerializer.serialize(frontmatter)
    File.write(path, "#{content}\n")
    path
  end

  def create_spec_file_with_body(frontmatter)
    path = File.join(@tmpdir, "test.s.md")
    fm = Ace::Support::Items::Atoms::FrontmatterSerializer.serialize(frontmatter)
    File.write(path, "#{fm}\n\n# Test Task\n\nSome body content\n")
    path
  end

  def create_spec_file_raw(content)
    path = File.join(@tmpdir, "test.s.md")
    File.write(path, content)
    path
  end
end
