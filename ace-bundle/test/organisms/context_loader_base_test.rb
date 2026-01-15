# frozen_string_literal: true

require_relative "../test_helper"

class ContextLoaderBaseTest < AceTestCase
  def setup
    @env = Ace::TestSupport::TestEnvironment.new("context_base")
    @env.setup
    create_base_files
    create_test_presets
  end

  def teardown
    @env.teardown
  end

  def test_base_field_detection_and_loading
    Dir.chdir(@env.project_dir) do
      context = Ace::Bundle.load_preset("with-base")

      # Verify base content was loaded
      refute_nil context.content
      assert context.content.include?("Base System Content")
      assert context.content.include?("This is the primary document")

      # Verify metadata tracks base info
      assert_equal "./test/base/system.md", context.metadata[:base_ref]
      assert context.metadata[:base_path]
    end
  end

  def test_base_content_ordering_before_sections
    Dir.chdir(@env.project_dir) do
      context = Ace::Bundle.load_preset("base-with-sections")

      # Base content should appear in the formatted output
      assert context.content.include?("Base System Content")

      # Sections should be processed and present
      refute_empty context.sections
      assert context.sections.key?(:test_section) || context.sections.key?('test_section')

      # Full formatted output should have section title
      assert context.content.include?("Test Section"), "Output should include section title. Got: #{context.content[0..500]}"

      # Base should come before section
      base_position = context.content.index("Base System Content")
      section_position = context.content.index("Test Section")

      assert base_position, "Base content should be in output"
      assert section_position, "Section title should be in output"
      assert base_position < section_position, "Base should come before sections"
    end
  end

  def test_missing_base_field_backward_compatibility
    Dir.chdir(@env.project_dir) do
      context = Ace::Bundle.load_preset("without-base")

      # Should work normally without base field
      refute_nil context
      assert_nil context.metadata[:base_error]

      # Sections should still be processed
      refute_empty context.sections
    end
  end

  def test_invalid_base_protocol_graceful_error
    Dir.chdir(@env.project_dir) do
      context = Ace::Bundle.load_preset("invalid-base-protocol")

      # Should have error in metadata
      assert context.metadata[:base_error]
      assert context.metadata[:base_error].include?("Failed to resolve")

      # Should still process sections (graceful degradation)
      refute_empty context.sections
    end
  end

  def test_base_file_not_found_graceful_error
    Dir.chdir(@env.project_dir) do
      context = Ace::Bundle.load_preset("missing-base-file")

      # Should have error in metadata
      assert context.metadata[:base_error]
      assert context.metadata[:base_error].include?("not found")

      # Should still process sections
      refute_empty context.sections
    end
  end

  def test_empty_base_content_warning
    Dir.chdir(@env.project_dir) do
      # This should log warning but not fail
      context = Ace::Bundle.load_preset("empty-base")

      # Content will be empty, formatted output includes metadata header
      assert context.content.include?("base_ref")
      assert context.content.include?("./test/base/empty.md")

      # Should still have metadata
      assert_equal "./test/base/empty.md", context.metadata[:base_ref]
    end
  end

  def test_base_only_no_sections
    Dir.chdir(@env.project_dir) do
      context = Ace::Bundle.load_preset("base-only")

      # Should have base content in the output
      assert context.content.include?("Base System Content")

      # Should have no sections
      assert_empty context.sections
    end
  end

  def test_extension_less_file_resolution
    Dir.chdir(@env.project_dir) do
      context = Ace::Bundle.load_preset("extensionless-base")

      # Should load file content, not treat filename as inline content
      assert context.content.include?("README content for testing"),
             "Should include README file content"

      # Verify it was loaded as file, not inline
      assert_equal 'file', context.metadata[:base_type],
                   "Should be loaded as file type, not inline"
      assert context.metadata[:base_path], "Should have base_path metadata"
      assert_equal "README", context.metadata[:base_ref]
    end
  end

  def test_inline_base_content
    Dir.chdir(@env.project_dir) do
      context = Ace::Bundle.load_preset("inline-base")

      # Should use the literal string as content
      assert_equal "This is inline base content", context.content.strip

      # Verify it was treated as inline
      assert_equal 'inline', context.metadata[:base_type]
      assert_equal "This is inline base content", context.metadata[:base_ref]
      refute context.metadata[:base_path], "Inline content should not have base_path"
    end
  end

  private

  def create_base_files
    # Create a test base file that can be resolved via protocol
    base_dir = File.join(@env.project_dir, "test", "base")
    FileUtils.mkdir_p(base_dir)

    File.write(File.join(base_dir, "system.md"), <<~BASE)
      # Base System Content

      This is the primary document that should appear first.

      It contains core instructions and guidelines.
    BASE

    # Create empty base file for testing
    File.write(File.join(base_dir, "empty.md"), "")

    # Create extension-less file for testing (like README, CONTEXT, etc.)
    File.write(File.join(@env.project_dir, "README"), <<~README)
      # README content for testing

      This file has no extension but should be resolved as a file, not inline content.
    README

    # Create sample section content
    sections_dir = File.join(@env.project_dir, "test", "sections")
    FileUtils.mkdir_p(sections_dir)
    File.write(File.join(sections_dir, "sample.md"), "Sample section content")
  end

  def create_test_presets
    presets_dir = File.join(@env.project_dir, ".ace/bundle/presets")
    FileUtils.mkdir_p(presets_dir)

    # Preset with base field
    File.write(File.join(presets_dir, "with-base.md"), <<~PRESET)
      ---
      description: "Preset with base field"
      context:
        base: "./test/base/system.md"
      ---
    PRESET

    # Preset with base and sections
    File.write(File.join(presets_dir, "base-with-sections.md"), <<~PRESET)
      ---
      description: "Preset with base and sections"
      context:
        base: "./test/base/system.md"
        sections:
          test_section:
            title: "Test Section"
            files:
              - "test/sections/sample.md"
      ---
    PRESET

    # Preset without base (backward compatibility)
    File.write(File.join(presets_dir, "without-base.md"), <<~PRESET)
      ---
      description: "Preset without base field"
      context:
        sections:
          test_section:
            title: "Test Section"
            files:
              - "test/sections/sample.md"
      ---
    PRESET

    # Preset with invalid protocol
    File.write(File.join(presets_dir, "invalid-base-protocol.md"), <<~PRESET)
      ---
      description: "Preset with invalid base protocol"
      context:
        base: "invalid://nonexistent/path"
        sections:
          test_section:
            title: "Test Section"
            files:
              - "test/sections/sample.md"
      ---
    PRESET

    # Preset with missing base file
    File.write(File.join(presets_dir, "missing-base-file.md"), <<~PRESET)
      ---
      description: "Preset with missing base file"
      context:
        base: "./nonexistent/file.md"
        sections:
          test_section:
            title: "Test Section"
            files:
              - "test/sections/sample.md"
      ---
    PRESET

    # Preset with empty base file
    File.write(File.join(presets_dir, "empty-base.md"), <<~PRESET)
      ---
      description: "Preset with empty base file"
      context:
        base: "./test/base/empty.md"
      ---
    PRESET

    # Preset with base only, no sections
    File.write(File.join(presets_dir, "base-only.md"), <<~PRESET)
      ---
      description: "Preset with base only"
      context:
        base: "./test/base/system.md"
      ---
    PRESET

    # Preset with extension-less file (README, CONTEXT, etc.)
    File.write(File.join(presets_dir, "extensionless-base.md"), <<~PRESET)
      ---
      description: "Preset with extension-less base file"
      context:
        base: "README"
      ---
    PRESET

    # Preset with inline base content
    File.write(File.join(presets_dir, "inline-base.md"), <<~PRESET)
      ---
      description: "Preset with inline base content"
      context:
        base: "This is inline base content"
      ---
    PRESET
  end
end
