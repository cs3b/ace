# frozen_string_literal: true

require "test_helper"

class RetroManagerTest < AceRetroTestCase
  def test_create_and_show
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      retro = manager.create("Sprint Review", type: "standard", tags: ["sprint"])

      refute_nil retro
      assert_equal "Sprint Review", retro.title
      assert_equal "standard", retro.type
      assert_equal ["sprint"], retro.tags
      assert_equal "active", retro.status

      # Show by full ID
      found = manager.show(retro.id)
      refute_nil found
      assert_equal retro.id, found.id
    end
  end

  def test_show_by_shortcut
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      retro = manager.create("Sprint Review")

      found = manager.show(retro.shortcut)
      refute_nil found
      assert_equal retro.id, found.id
    end
  end

  def test_show_returns_nil_for_unknown
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      assert_nil manager.show("zzz")
    end
  end

  def test_list_returns_all_retros
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      manager.create("First")
      manager.create("Second")

      retros = manager.list
      assert_equal 2, retros.length
    end
  end

  def test_list_filters_by_status
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      manager.create("Active Retro")
      retro2 = manager.create("Done Retro")
      manager.update(retro2.id, set: { "status" => "done" })

      active_retros = manager.list(status: "active")
      assert_equal 1, active_retros.length
      assert_equal "active", active_retros.first.status
    end
  end

  def test_list_filters_by_type
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      manager.create("Standard", type: "standard")
      manager.create("Self Review", type: "self-review")

      standard_retros = manager.list(type: "standard")
      assert_equal 1, standard_retros.length
      assert_equal "standard", standard_retros.first.type
    end
  end

  def test_list_filters_by_tags
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      manager.create("Sprint Retro", tags: ["sprint"])
      manager.create("Personal Retro", tags: ["personal"])

      sprint_retros = manager.list(tags: ["sprint"])
      assert_equal 1, sprint_retros.length
      assert_includes sprint_retros.first.tags, "sprint"
    end
  end

  def test_update_set
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      retro = manager.create("Sprint Review")

      updated = manager.update(retro.id, set: { "status" => "done" })
      refute_nil updated
      assert_equal "done", updated.status
    end
  end

  def test_update_add_tags
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      retro = manager.create("Sprint Review", tags: ["sprint"])

      updated = manager.update(retro.id, add: { "tags" => "reviewed" })
      refute_nil updated
      assert_includes updated.tags, "sprint"
      assert_includes updated.tags, "reviewed"
    end
  end

  def test_update_remove_tags
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      retro = manager.create("Sprint Review", tags: ["sprint", "team"])

      updated = manager.update(retro.id, remove: { "tags" => "team" })
      refute_nil updated
      assert_includes updated.tags, "sprint"
      refute_includes updated.tags, "team"
    end
  end

  def test_update_returns_nil_for_unknown
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      assert_nil manager.update("zzz", set: { "status" => "done" })
    end
  end

  def test_update_move_to_archive
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      retro = manager.create("Sprint Review")

      moved = manager.update(retro.id, move_to: "archive")
      refute_nil moved
      assert_equal "_archive", moved.special_folder
      assert_includes moved.path, "_archive"
    end
  end

  def test_update_move_to_root
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      retro = manager.create("Sprint Review", move_to: "archive")

      moved = manager.update(retro.id, move_to: "root")
      refute_nil moved
      assert_nil moved.special_folder
    end
  end

  def test_update_move_to_returns_nil_for_unknown
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      assert_nil manager.update("zzz", move_to: "archive")
    end
  end

  def test_create_with_move_to
    with_retros_dir do |root|
      manager = Ace::Retro::Organisms::RetroManager.new(root_dir: root)
      retro = manager.create("Archived Retro", move_to: "archive")

      assert_equal "_archive", retro.special_folder
    end
  end
end
