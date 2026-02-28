# frozen_string_literal: true

require "test_helper"

class IdeaMoverTest < AceIdeaTestCase
  def test_moves_idea_to_special_folder
    with_ideas_dir do |root|
      idea_dir = create_idea_fixture(root, id: "8ppq7w", slug: "dark-mode")

      loader = Ace::Idea::Molecules::IdeaLoader.new
      idea = loader.load(idea_dir, id: "8ppq7w")

      mover = Ace::Idea::Molecules::IdeaMover.new(root)
      new_path = mover.move(idea, to: "maybe")

      refute Dir.exist?(idea_dir), "Original directory should be gone"
      assert Dir.exist?(new_path), "New directory should exist"
      assert_includes new_path, "_maybe"
    end
  end

  def test_moves_idea_to_root
    with_ideas_dir do |root|
      idea_dir = create_idea_fixture(root, id: "8ppq7w", slug: "dark-mode",
                                     special_folder: "_maybe")

      loader = Ace::Idea::Molecules::IdeaLoader.new
      idea = loader.load(idea_dir, id: "8ppq7w", special_folder: "_maybe")

      mover = Ace::Idea::Molecules::IdeaMover.new(root)
      new_path = mover.move_to_root(idea)

      assert Dir.exist?(new_path)
      assert_equal root, File.dirname(new_path)
    end
  end

  def test_raises_if_destination_exists
    with_ideas_dir do |root|
      idea_dir = create_idea_fixture(root, id: "8ppq7w", slug: "dark-mode")
      # Pre-create destination
      dest = File.join(root, "_archive", "8ppq7w-dark-mode")
      FileUtils.mkdir_p(dest)

      loader = Ace::Idea::Molecules::IdeaLoader.new
      idea = loader.load(idea_dir, id: "8ppq7w")

      mover = Ace::Idea::Molecules::IdeaMover.new(root)

      assert_raises(ArgumentError) do
        mover.move(idea, to: "archive")
      end
    end
  end

  def test_move_to_same_location_is_noop
    with_ideas_dir do |root|
      idea_dir = create_idea_fixture(root, id: "8ppq7w", slug: "dark-mode")

      loader = Ace::Idea::Molecules::IdeaLoader.new
      idea = loader.load(idea_dir, id: "8ppq7w")

      mover = Ace::Idea::Molecules::IdeaMover.new(root)
      # Moving to root when already in root should return same path
      result = mover.move_to_root(idea)

      assert_equal idea.path, result
      assert Dir.exist?(idea_dir), "Original directory should still exist"
    end
  end
end
