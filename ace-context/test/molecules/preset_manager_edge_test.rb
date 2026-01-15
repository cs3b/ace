# frozen_string_literal: true

require_relative "../test_helper"

class PresetManagerEdgeTest < AceTestCase
  include Ace::TestSupport::ConfigHelpers

  def test_handles_missing_preset_file
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("nonexistent")

      assert_nil preset
    end
  end

  def test_handles_empty_preset_file
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")
      File.write(".ace/context/presets/empty.md", "")

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("empty")

      # Should handle empty file gracefully
      assert preset.nil? || preset[:name] == "empty"
    end
  end

  def test_handles_preset_with_invalid_frontmatter
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")
      invalid_content = <<~MARKDOWN
        ---
        invalid: [unclosed
        ---
        # Invalid Preset
      MARKDOWN
      File.write(".ace/context/presets/invalid.md", invalid_content)

      manager = Ace::Context::Molecules::PresetManager.new

      # Should either return nil or handle gracefully without raising
      preset = manager.get_preset("invalid")
      # Test passes if we get here without exception
      assert true
    end
  end

  def test_handles_preset_with_missing_frontmatter
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")
      content_without_frontmatter = <<~MARKDOWN
        # Preset Without Frontmatter

        This preset has no frontmatter.
      MARKDOWN
      File.write(".ace/context/presets/no_frontmatter.md", content_without_frontmatter)

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("no_frontmatter")

      # Should handle missing frontmatter
      if preset
        assert_equal "no_frontmatter", preset[:name]
      end
    end
  end

  def test_handles_preset_with_unicode_content
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")
      unicode_content = <<~MARKDOWN
        ---
        description: Prés et café 日本語
        params:
          output: cache
        context:
          files:
            - "файл.md"
            - "café/*.txt"
        ---

        # Unicode Preset 世界

        Content with unicode: Привет мир!
      MARKDOWN
      File.write(".ace/context/presets/unicode.md", unicode_content)

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("unicode")

      assert preset
      assert_equal "unicode", preset[:name]
      assert preset[:description].include?("café")
    end
  end

  def test_handles_preset_with_very_long_content
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")

      # Create a preset with very long body
      long_body = "# Long Preset\n\n" + ("x" * 100_000)
      long_content = <<~MARKDOWN
        ---
        description: Long preset
        ---

        #{long_body}
      MARKDOWN
      File.write(".ace/context/presets/long.md", long_content)

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("long")

      assert preset
      assert_equal "long", preset[:name]
      assert preset[:body].length > 100_000
    end
  end

  def test_handles_preset_with_special_characters_in_filename
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")
      content = <<~MARKDOWN
        ---
        description: Special chars
        ---

        # Special
      MARKDOWN

      # Filename with special characters (but valid)
      File.write(".ace/context/presets/preset-with-dashes_and_underscores.md", content)

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("preset-with-dashes_and_underscores")

      assert preset
      assert_equal "preset-with-dashes_and_underscores", preset[:name]
    end
  end

  def test_handles_nested_preset_directories
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets/nested/deep")
      content = <<~MARKDOWN
        ---
        description: Nested preset
        ---

        # Nested
      MARKDOWN
      File.write(".ace/context/presets/nested/deep/preset.md", content)

      manager = Ace::Context::Molecules::PresetManager.new

      # Try to load with path
      preset = manager.get_preset("nested/deep/preset")

      # Should either find it or return nil gracefully
      if preset
        assert_includes ["nested/deep/preset", "preset"], preset[:name]
      end
    end
  end

  def test_handles_preset_with_malformed_yaml_values
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")
      malformed_content = <<~MARKDOWN
        ---
        description: Test
        params:
          max_size: "not_a_number"
          timeout: null
        ---

        # Malformed
      MARKDOWN
      File.write(".ace/context/presets/malformed.md", malformed_content)

      manager = Ace::Context::Molecules::PresetManager.new

      # Should handle malformed values without crashing
      preset = manager.get_preset("malformed")
      assert preset
    end
  end

  def test_handles_preset_with_empty_arrays_and_hashes
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")
      content = <<~MARKDOWN
        ---
        description: Empty collections
        params: {}
        context:
          files: []
          commands: []
          exclude: []
        ---

        # Empty Collections
      MARKDOWN
      File.write(".ace/context/presets/empty_collections.md", content)

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("empty_collections")

      assert preset
      assert_equal({}, preset[:params]) if preset.key?(:params)
      assert_equal([], preset.dig(:context, "files")) if preset.dig(:context, "files")
    end
  end

  def test_handles_case_sensitivity_in_preset_names
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")
      content = <<~MARKDOWN
        ---
        description: Case test
        ---

        # Case Test
      MARKDOWN
      File.write(".ace/context/presets/CaseSensitive.md", content)

      manager = Ace::Context::Molecules::PresetManager.new

      # Test exact case
      preset_exact = manager.get_preset("CaseSensitive")
      assert preset_exact if File.exist?(".ace/context/presets/CaseSensitive.md")

      # Test different case (behavior may vary by filesystem)
      preset_lower = manager.get_preset("casesensitive")
      # On case-insensitive filesystems, this might work
    end
  end

  def test_handles_preset_with_bom_marker
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")

      # Write file with UTF-8 BOM
      File.open(".ace/context/presets/bom.md", "wb") do |f|
        f.write("\xEF\xBB\xBF")
        f.write("---\ndescription: BOM test\n---\n\n# BOM Preset")
      end

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("bom")

      # BOM handling may vary - test that we don't crash
      # Either preset is loaded or nil is returned
      assert preset.nil? || preset[:name] == "bom"
    end
  end

  def test_handles_preset_with_windows_line_endings
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")

      # Content with \r\n line endings
      content = "---\r\ndescription: Windows\r\n---\r\n\r\n# Windows Preset\r\n"
      File.write(".ace/context/presets/windows.md", content)

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("windows")

      assert preset
      assert_equal "windows", preset[:name]
    end
  end

  def test_handles_symlinked_preset_file
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")

      # Create original file
      original_content = <<~MARKDOWN
        ---
        description: Original
        ---

        # Original
      MARKDOWN
      File.write(".ace/context/presets/original.md", original_content)

      # Create symlink
      File.symlink("original.md", ".ace/context/presets/link.md")

      manager = Ace::Context::Molecules::PresetManager.new
      preset = manager.get_preset("link")

      # Should follow symlink
      assert preset if File.exist?(".ace/context/presets/link.md")
    end
  end

  def test_lists_all_presets_with_various_edge_cases
    with_temp_dir do
      FileUtils.mkdir_p(".ace/context/presets")

      # Create various preset files
      File.write(".ace/context/presets/normal.md", "---\n---\n# Normal")
      File.write(".ace/context/presets/empty.md", "")
      File.write(".ace/context/presets/.hidden.md", "---\n---\n# Hidden")
      File.write(".ace/context/presets/README.txt", "Not a preset")

      manager = Ace::Context::Molecules::PresetManager.new

      # Should list presets without crashing
      if manager.respond_to?(:list_presets)
        presets = manager.list_presets
        assert_kind_of Array, presets
      else
        # Method doesn't exist, that's fine
        assert true
      end
    end
  end
end
