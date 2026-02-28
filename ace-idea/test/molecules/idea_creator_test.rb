# frozen_string_literal: true

require "test_helper"

class IdeaCreatorTest < AceIdeaTestCase
  def test_creates_idea_with_content
    with_ideas_dir do |root|
      creator = Ace::Idea::Molecules::IdeaCreator.new(root_dir: root)
      idea = creator.create("Dark mode would be great for night coding")

      refute_nil idea
      assert_equal 6, idea.id.length
      assert_match(/[0-9a-z]{6}/, idea.id)
      assert Dir.exist?(idea.path)
      assert File.exist?(idea.file_path)
    end
  end

  def test_creates_idea_with_explicit_title
    with_ideas_dir do |root|
      creator = Ace::Idea::Molecules::IdeaCreator.new(root_dir: root)
      idea = creator.create("Dark mode would be great", title: "Dark mode")

      assert_equal "Dark mode", idea.title
    end
  end

  def test_creates_idea_with_tags
    with_ideas_dir do |root|
      creator = Ace::Idea::Molecules::IdeaCreator.new(root_dir: root)
      idea = creator.create("Dark mode", tags: ["ux", "design"])

      assert_equal ["ux", "design"], idea.tags
    end
  end

  def test_creates_idea_in_move_to_folder
    with_ideas_dir do |root|
      creator = Ace::Idea::Molecules::IdeaCreator.new(root_dir: root)
      idea = creator.create("Dark mode", move_to: "maybe")

      assert_equal "_maybe", idea.special_folder
      assert_includes idea.path, "_maybe"
    end
  end

  def test_raises_without_content
    with_ideas_dir do |root|
      creator = Ace::Idea::Molecules::IdeaCreator.new(root_dir: root)

      assert_raises(ArgumentError) do
        creator.create(nil)
      end
    end
  end

  def test_creates_folder_structure
    with_ideas_dir do |root|
      creator = Ace::Idea::Molecules::IdeaCreator.new(root_dir: root)
      idea = creator.create("My idea for testing")

      # Verify folder structure: {id}-{slug}/
      folder_name = File.basename(idea.path)
      assert_match(/\A[0-9a-z]{6}-[a-z0-9-]+\z/, folder_name)

      # Verify spec file: {id}-{slug}.idea.s.md
      spec_filename = File.basename(idea.file_path)
      assert spec_filename.end_with?(".idea.s.md")
    end
  end

  def test_spec_file_has_valid_frontmatter
    with_ideas_dir do |root|
      creator = Ace::Idea::Molecules::IdeaCreator.new(root_dir: root)
      idea = creator.create("Test idea with frontmatter")

      content = File.read(idea.file_path)
      assert content.start_with?("---\n")

      # Parse frontmatter
      end_idx = content.index("\n---\n", 4)
      assert end_idx, "Frontmatter closing delimiter not found"

      yaml_str = content[4...end_idx]
      fm = YAML.safe_load(yaml_str, permitted_classes: [Date, Time, Symbol])

      assert_equal idea.id, fm["id"]
      assert_equal "pending", fm["status"]
    end
  end

  def test_llm_enhance_falls_back_to_original_when_llm_unavailable
    with_ideas_dir do |root|
      creator = Ace::Idea::Molecules::IdeaCreator.new(root_dir: root, config: {})

      # Stub LLM availability to force fallback path without real API calls
      enhancer = Ace::Idea::Molecules::IdeaLlmEnhancer.new(config: {})
      Ace::Idea::Molecules::IdeaLlmEnhancer.stub(:new, enhancer) do
        enhancer.stub(:llm_available?, false) do
          idea = creator.create("My idea", llm_enhance: true)

          refute_nil idea
          assert File.exist?(idea.file_path)
        end
      end
    end
  end

  def test_attachment_path_traversal_rejected
    with_ideas_dir do |root|
      creator = Ace::Idea::Molecules::IdeaCreator.new(root_dir: root)

      # Simulate attachment with path-traversal filename
      traversal_attachment = {
        filename: "../../../etc/malicious",
        data: "evil content"
      }

      # Use a fake clipboard result by stubbing gather_content
      creator_instance = Ace::Idea::Molecules::IdeaCreator.new(root_dir: root)
      creator_instance.define_singleton_method(:gather_content) do |content, clipboard: false|
        [content, [traversal_attachment]]
      end

      # Should not write any file outside root
      idea = creator_instance.create("Test path traversal defense")

      # Verify no file was written outside the idea directory
      refute File.exist?(File.join(root, "..", "..", "etc", "malicious")),
             "Path traversal should be rejected"
      assert Dir.exist?(idea.path), "Idea directory should still be created"
    end
  end

  def test_attachment_null_byte_filename_rejected
    with_ideas_dir do |root|
      null_byte_attachment = {
        filename: "safe\x00/etc/passwd",
        data: "evil"
      }

      creator = Ace::Idea::Molecules::IdeaCreator.new(root_dir: root)
      creator.define_singleton_method(:gather_content) do |content, clipboard: false|
        [content, [null_byte_attachment]]
      end

      # Should not raise, should skip the unsafe attachment
      idea = creator.create("Test null byte defense")
      assert Dir.exist?(idea.path)
    end
  end
end
