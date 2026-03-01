# frozen_string_literal: true

require "test_helper"

class RetroCreatorTest < AceRetroTestCase
  def test_creates_retro_with_title
    with_retros_dir do |root|
      creator = Ace::Retro::Molecules::RetroCreator.new(root_dir: root)
      retro = creator.create("Sprint Review")

      refute_nil retro
      assert_equal 6, retro.id.length
      assert_match(/[0-9a-z]{6}/, retro.id)
      assert Dir.exist?(retro.path)
      assert File.exist?(retro.file_path)
    end
  end

  def test_creates_retro_with_type
    with_retros_dir do |root|
      creator = Ace::Retro::Molecules::RetroCreator.new(root_dir: root)
      retro = creator.create("Sprint Review", type: "conversation-analysis")

      assert_equal "conversation-analysis", retro.type
    end
  end

  def test_creates_retro_with_tags
    with_retros_dir do |root|
      creator = Ace::Retro::Molecules::RetroCreator.new(root_dir: root)
      retro = creator.create("Sprint Review", tags: ["sprint", "team"])

      assert_equal ["sprint", "team"], retro.tags
    end
  end

  def test_creates_retro_with_task_ref
    with_retros_dir do |root|
      creator = Ace::Retro::Molecules::RetroCreator.new(root_dir: root)
      retro = creator.create("Sprint Review", task_ref: "292.01")

      assert_equal "292.01", retro.task_ref
    end
  end

  def test_creates_retro_in_move_to_folder
    with_retros_dir do |root|
      creator = Ace::Retro::Molecules::RetroCreator.new(root_dir: root)
      retro = creator.create("Sprint Review", move_to: "archive")

      assert_equal "_archive", retro.special_folder
      assert_includes retro.path, "_archive"
    end
  end

  def test_raises_without_title
    with_retros_dir do |root|
      creator = Ace::Retro::Molecules::RetroCreator.new(root_dir: root)

      assert_raises(ArgumentError) do
        creator.create(nil)
      end
    end
  end

  def test_raises_with_empty_title
    with_retros_dir do |root|
      creator = Ace::Retro::Molecules::RetroCreator.new(root_dir: root)

      assert_raises(ArgumentError) do
        creator.create("  ")
      end
    end
  end

  def test_creates_folder_structure
    with_retros_dir do |root|
      creator = Ace::Retro::Molecules::RetroCreator.new(root_dir: root)
      retro = creator.create("My Sprint Review")

      folder_name = File.basename(retro.path)
      assert_match(/\A[0-9a-z]{6}-[a-z0-9-]+\z/, folder_name)

      retro_filename = File.basename(retro.file_path)
      assert retro_filename.end_with?(".retro.md")
    end
  end

  def test_retro_file_has_valid_frontmatter
    with_retros_dir do |root|
      creator = Ace::Retro::Molecules::RetroCreator.new(root_dir: root)
      retro = creator.create("Sprint Review", type: "standard", task_ref: "q7w")

      content = File.read(retro.file_path)
      assert content.start_with?("---\n")

      end_idx = content.index("\n---\n", 4)
      assert end_idx, "Frontmatter closing delimiter not found"

      yaml_str = content[4...end_idx]
      fm = YAML.safe_load(yaml_str, permitted_classes: [Date, Time, Symbol])

      assert_equal retro.id, fm["id"]
      assert_equal "active", fm["status"]
      assert_equal "standard", fm["type"]
      assert_equal "q7w", fm["task_ref"]
    end
  end

  def test_retro_file_has_template_body
    with_retros_dir do |root|
      creator = Ace::Retro::Molecules::RetroCreator.new(root_dir: root)
      retro = creator.create("Sprint Review")

      content = File.read(retro.file_path)
      assert_includes content, "## What Went Well"
      assert_includes content, "## What Could Be Improved"
      assert_includes content, "## Action Items"
    end
  end

  def test_conversation_analysis_template
    with_retros_dir do |root|
      creator = Ace::Retro::Molecules::RetroCreator.new(root_dir: root)
      retro = creator.create("Analysis", type: "conversation-analysis")

      content = File.read(retro.file_path)
      assert_includes content, "## Context"
      assert_includes content, "## Key Observations"
      assert_includes content, "## Patterns Identified"
    end
  end

  def test_self_review_template
    with_retros_dir do |root|
      creator = Ace::Retro::Molecules::RetroCreator.new(root_dir: root)
      retro = creator.create("Self Review", type: "self-review")

      content = File.read(retro.file_path)
      assert_includes content, "## What I Did Well"
      assert_includes content, "## What I Could Improve"
      assert_includes content, "## Key Learnings"
    end
  end

  def test_default_type_from_config
    with_retros_dir do |root|
      config = { "retro" => { "default_type" => "self-review" } }
      creator = Ace::Retro::Molecules::RetroCreator.new(root_dir: root, config: config)
      retro = creator.create("My Review")

      assert_equal "self-review", retro.type
    end
  end
end
