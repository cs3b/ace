# frozen_string_literal: true

require "test_helper"

class ContextComposerTest < AceReviewTest
  def setup
    @base_instructions = "Review the following code for quality and best practices."
    @temp_dir = Dir.mktmpdir
  end

  def teardown
    FileUtils.rm_rf(@temp_dir) if @temp_dir && Dir.exist?(@temp_dir)
  end

  def test_create_context_md_with_minimal_config
    context_config = {}

    result = Ace::Review::Molecules::ContextComposer.create_context_md(
      @base_instructions,
      context_config
    )

    # Should contain YAML frontmatter with context section
    assert_match(/^---\nbundle:/, result)
    assert_match(/params:\s*\n\s*format: markdown-xml/, result)
    assert_match(/embed_document_source: true/, result)
    assert_match(/^---\n\n#{@base_instructions}/m, result)
  end

  def test_create_context_md_with_presets
    context_config = {
      "presets" => ["project", "testing"]
    }

    result = Ace::Review::Molecules::ContextComposer.create_context_md(
      @base_instructions,
      context_config
    )

    assert_match(/presets:\s*\n\s*- project\s*\n\s*- testing/, result)
    assert_match(/#{@base_instructions}/, result)
  end

  def test_create_context_md_with_files_and_diffs
    context_config = {
      "files" => ["src/main.rb", "README.md"],
      "diffs" => ["changes.diff"]
    }

    result = Ace::Review::Molecules::ContextComposer.create_context_md(
      @base_instructions,
      context_config
    )

    assert_match(/files:\s*\n\s*- src\/main\.rb\s*\n\s*- README\.md/, result)
    assert_match(/diffs:\s*\n\s*- changes\.diff/, result)
  end

  def test_create_context_md_with_subject_config
    context_config = {"presets" => ["project"]}
    subject_config = {"files" => ["src/test.rb"]}

    result = Ace::Review::Molecules::ContextComposer.create_context_md(
      @base_instructions,
      context_config,
      subject_config
    )

    assert_match(/## Review Scope/, result)
    assert_match(/\*\*Subject of review\*\*:/, result)
    assert_match(/File: `src\/test\.rb`/, result)
  end

  def test_create_context_md_with_multiple_files_subject
    context_config = {}
    subject_config = {
      "files" => ["src/main.rb", "src/helper.rb", "test/test_main.rb"]
    }

    result = Ace::Review::Molecules::ContextComposer.create_context_md(
      @base_instructions,
      context_config,
      subject_config
    )

    assert_match(/Files: `src\/main\.rb`, `src\/helper\.rb`, `test\/test_main\.rb`/, result)
  end

  def test_create_context_md_with_diff_subject
    context_config = {}
    subject_config = {"diff" => "some diff content"}

    result = Ace::Review::Molecules::ContextComposer.create_context_md(
      @base_instructions,
      context_config,
      subject_config
    )

    assert_match(/- Git diff changes/, result)
  end

  def test_create_context_md_with_content_subject
    context_config = {}
    subject_config = {"content" => "some inline content"}

    result = Ace::Review::Molecules::ContextComposer.create_context_md(
      @base_instructions,
      context_config,
      subject_config
    )

    assert_match(/- Inline content/, result)
  end

  def test_save_context_md
    context_md = "# Context\n\nThis is test content."

    file_path = Ace::Review::Molecules::ContextComposer.save_context_md(
      context_md,
      @temp_dir
    )

    assert_equal File.join(@temp_dir, "context.md"), file_path
    assert File.exist?(file_path)

    saved_content = File.read(file_path)
    assert_equal context_md, saved_content
  end

  def test_load_context_via_ace_bundle_missing_file
    non_existent_file = File.join(@temp_dir, "nonexistent.md")

    # ace-bundle now handles missing files gracefully by returning empty content
    result = Ace::Review::Molecules::ContextComposer.load_context_via_ace_bundle(non_existent_file)
    assert_equal "", result
  end

  def test_load_context_via_ace_bundle_with_existing_file
    # Test that it successfully loads an existing context file
    context_file = File.join(@temp_dir, "context.md")
    File.write(context_file, <<~MD)
      ---
      bundle:
        files:
          - README.md
      ---

      Test context content
    MD

    result = Ace::Review::Molecules::ContextComposer.load_context_via_ace_bundle(context_file)
    # ace-bundle processes the file and returns content
    refute_empty result
  end

  def test_normalize_context_config_merges_defaults
    config = {
      "presets" => ["project"],
      "commands" => ["git log"]
    }

    result = Ace::Review::Molecules::ContextComposer.send(:normalize_context_config, config)

    assert_equal "markdown-xml", result.dig("params", "format")
    assert_equal true, result["embed_document_source"]
    assert_equal ["project"], result["presets"]
    assert_equal [], result["files"]
    assert_equal [], result["diffs"]
    assert_equal ["git log"], result["commands"]
  end

  def test_normalize_context_config_initializes_arrays
    config = {}

    result = Ace::Review::Molecules::ContextComposer.send(:normalize_context_config, config)

    assert_equal [], result["presets"]
    assert_equal [], result["files"]
    assert_equal [], result["diffs"]
    assert_equal [], result["commands"]
  end

  def test_extract_subject_description_single_file
    subject_config = {"files" => "src/main.rb"}

    result = Ace::Review::Molecules::ContextComposer.send(:extract_subject_description, subject_config)

    assert_equal "- File: `src/main.rb`", result
  end

  def test_extract_subject_description_multiple_files
    subject_config = {
      "files" => ["src/main.rb", "test/test_main.rb"]
    }

    result = Ace::Review::Molecules::ContextComposer.send(:extract_subject_description, subject_config)

    assert_equal "- Files: `src/main.rb`, `test/test_main.rb`", result
  end

  def test_extract_subject_description_fallback
    subject_config = {}

    result = Ace::Review::Molecules::ContextComposer.send(:extract_subject_description, subject_config)

    assert_equal "- Repository changes", result
  end
end
