# frozen_string_literal: true

require "test_helper"

class IdeaManagerTest < AceIdeaTestCase
  def test_create_and_show_roundtrip
    with_ideas_dir do |root|
      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)

      idea = manager.create("Dark mode would be great",
                            title: "Dark mode",
                            tags: ["ux"])

      refute_nil idea
      id = idea.id

      # Show by full ID
      loaded = manager.show(id)
      refute_nil loaded
      assert_equal id, loaded.id
      assert_equal "Dark mode", loaded.title

      # Show by shortcut (last 3 chars)
      shortcut = id[-3..]
      loaded_by_shortcut = manager.show(shortcut)
      refute_nil loaded_by_shortcut
      assert_equal id, loaded_by_shortcut.id
    end
  end

  def test_list_all_ideas
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "8ppq7w", slug: "idea-one", status: "pending")
      create_idea_fixture(root, id: "9xzr1k", slug: "idea-two", status: "done")

      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)
      ideas = manager.list

      assert_equal 2, ideas.length
    end
  end

  def test_list_filter_by_status
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "8ppq7w", slug: "pending-idea", status: "pending")
      create_idea_fixture(root, id: "9xzr1k", slug: "done-idea", status: "done")

      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)
      pending_ideas = manager.list(status: "pending")

      assert_equal 1, pending_ideas.length
      assert_equal "8ppq7w", pending_ideas.first.id
    end
  end

  def test_list_filter_by_folder
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "8ppq7w", slug: "active-idea")
      create_idea_fixture(root, id: "9xzr1k", slug: "maybe-idea", special_folder: "_maybe")

      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)
      maybe_ideas = manager.list(in_folder: "_maybe")

      assert_equal 1, maybe_ideas.length
      assert_equal "9xzr1k", maybe_ideas.first.id
    end
  end

  def test_list_filter_by_tags
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "8ppq7w", slug: "ux-idea", tags: ["ux", "design"])
      create_idea_fixture(root, id: "9xzr1k", slug: "backend-idea", tags: ["backend"])

      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)
      ux_ideas = manager.list(tags: ["ux"])

      assert_equal 1, ux_ideas.length
      assert_equal "8ppq7w", ux_ideas.first.id
    end
  end

  def test_update_status
    with_ideas_dir do |root|
      idea_dir = create_idea_fixture(root, id: "8ppq7w", slug: "dark-mode")

      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)
      updated = manager.update("q7w", set: { "status" => "in-progress" })

      refute_nil updated
      assert_equal "in-progress", updated.status
    end
  end

  def test_update_add_tags
    with_ideas_dir do |root|
      idea_dir = create_idea_fixture(root, id: "8ppq7w", slug: "dark-mode", tags: ["ux"])

      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)
      updated = manager.update("q7w", add: { "tags" => "design" })

      refute_nil updated
      assert_includes updated.tags, "ux"
      assert_includes updated.tags, "design"
    end
  end

  def test_update_move_to_special_folder
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "8ppq7w", slug: "dark-mode")

      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)
      moved = manager.update("q7w", move_to: "archive")

      refute_nil moved
      assert_equal "_archive", moved.special_folder
    end
  end

  def test_show_returns_nil_for_nonexistent
    with_ideas_dir do |root|
      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)
      result = manager.show("zzz")
      assert_nil result
    end
  end

  def test_create_with_move_to
    with_ideas_dir do |root|
      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)
      idea = manager.create("Some future idea", move_to: "maybe")

      assert_equal "_maybe", idea.special_folder
    end
  end

  def test_root_dir_is_created_on_first_use
    Dir.mktmpdir("ace-idea-root-test") do |tmpdir|
      new_root = File.join(tmpdir, "new-ideas-dir")
      refute Dir.exist?(new_root)

      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: new_root)
      manager.create("Test idea to create dir")

      assert Dir.exist?(new_root)
    end
  end

  def test_list_root_path_traversal_rejected
    with_ideas_dir do |root|
      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)

      assert_raises(ArgumentError) do
        manager.list(root: "../../etc")
      end
    end
  end

  def test_list_root_relative_subpath_allowed
    with_ideas_dir do |root|
      create_idea_fixture(root, id: "8ppq7w", slug: "dark-mode", special_folder: "_maybe")
      manager = Ace::Idea::Organisms::IdeaManager.new(root_dir: root)

      # Valid subpath within root should work without raising
      result = manager.list(root: "_maybe")
      assert_kind_of Array, result
    end
  end
end
