# frozen_string_literal: true

require_relative "../test_helper"

class PresetManagerTest < AceTestCase
  include Ace::TestSupport::ConfigHelpers

  def setup
    @preset_content = <<~MARKDOWN
      ---
      description: Test preset
      context:
        params:
          output: cache
          max_size: 1048576
          timeout: 30
        embed_document_source: true
        files:
          - README.md
          - docs/*.md
        commands:
          - echo "test"
        exclude:
          - "**/node_modules/**"
      ---

      # Test Preset

      This is a test preset.
    MARKDOWN
  end

  def test_loads_preset_from_markdown_file
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")
      File.write(".ace/context/presets/test.md", @preset_content)

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("test")

      assert preset
      assert_equal "test", preset[:name]
      assert_equal "Test preset", preset[:description]
      assert_equal "cache", preset[:output]
    end
  end

  def test_parses_frontmatter_correctly
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")
      File.write(".ace/context/presets/test.md", @preset_content)

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("test")

      # Check params
      assert_equal "cache", preset.dig(:params, "output")
      assert_equal 1048576, preset.dig(:params, "max_size")
      assert_equal 30, preset.dig(:params, "timeout")

      # Check context
      assert_equal true, preset.dig(:context, "embed_document_source")
      assert_equal ["README.md", "docs/*.md"], preset.dig(:context, "files")
      assert_equal ["echo \"test\""], preset.dig(:context, "commands")
      assert_equal ["**/node_modules/**"], preset.dig(:context, "exclude")
    end
  end

  def test_extracts_body_content
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")
      File.write(".ace/context/presets/test.md", @preset_content)

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("test")

      assert preset[:body]
      assert preset[:body].include?("# Test Preset")
      assert preset[:body].include?("This is a test preset.")
    end
  end

  def test_lists_presets
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")
      File.write(".ace/context/presets/preset1.md", @preset_content)
      File.write(".ace/context/presets/preset2.md", @preset_content.sub("Test preset", "Second preset"))

      manager = Ace::Context::Molecules::PresetManager.new
      presets = manager.list_presets

      assert_equal 2, presets.size
      names = presets.map { |p| p[:name] }
      assert_includes names, "preset1"
      assert_includes names, "preset2"
    end
  end

  def test_preset_exists_check
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")
      File.write(".ace/context/presets/exists.md", @preset_content)

      manager = Ace::Context::Molecules::PresetManager.new

      assert manager.preset_exists?("exists")
      refute manager.preset_exists?("nonexistent")
    end
  end

  def test_handles_missing_presets_gracefully
    with_temp_dir do
      # No .ace/context directory
      manager = Ace::Context::Molecules::PresetManager.new

      preset = manager.get_preset("nonexistent")
      assert_nil preset

      presets = manager.list_presets
      assert_empty presets
    end
  end

  def test_handles_invalid_frontmatter
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")

      # Invalid YAML in frontmatter
      invalid_content = <<~MARKDOWN
        ---
        description: Test
        invalid yaml here [[[
        ---
        Content
      MARKDOWN

      File.write(".ace/context/presets/invalid.md", invalid_content)

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("invalid")

      # Should handle gracefully
      assert_nil preset
    end
  end

  def test_handles_missing_frontmatter
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")

      # No frontmatter at all
      no_frontmatter = "# Just Markdown\n\nNo frontmatter here."
      File.write(".ace/context/presets/nofm.md", no_frontmatter)

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("nofm")

      # Should handle gracefully
      assert_nil preset
    end
  end

  def test_default_values_for_missing_params
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")

      minimal_content = <<~MARKDOWN
        ---
        description: Minimal preset
        context:
          files:
            - README.md
        ---
        Minimal content
      MARKDOWN

      File.write(".ace/context/presets/minimal.md", minimal_content)

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("minimal")

      assert preset
      assert_equal "stdio", preset[:output]  # Default output
      assert_equal({}, preset[:params])  # Empty params hash
    end
  end

  def test_new_structure_with_nested_params
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")

      # NEW structure: context.params instead of top-level params
      new_structure_content = <<~MARKDOWN
        ---
        description: New structure preset
        context:
          params:
            output: cache
            max_size: 2097152
            timeout: 60
          embed_document_source: true
          files:
            - README.md
            - "docs/**/*.md"
          commands:
            - echo "new structure"
        ---
        # New Structure Preset
      MARKDOWN

      File.write(".ace/context/presets/new_structure.md", new_structure_content)

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("new_structure")

      assert preset
      assert_equal "new_structure", preset[:name]
      assert_equal "New structure preset", preset[:description]

      # Check params are read from context.params
      assert_equal "cache", preset.dig(:params, "output")
      assert_equal 2097152, preset.dig(:params, "max_size")
      assert_equal 60, preset.dig(:params, "timeout")

      # Check output is set correctly from nested params
      assert_equal "cache", preset[:output]
      assert_equal true, preset[:cache]

      # Check context config (embed_document_source is in context, NOT in params)
      assert_equal true, preset.dig(:context, "embed_document_source")
      assert_equal ["README.md", "docs/**/*.md"], preset.dig(:context, "files")
      assert_equal ["echo \"new structure\""], preset.dig(:context, "commands")
    end
  end

end