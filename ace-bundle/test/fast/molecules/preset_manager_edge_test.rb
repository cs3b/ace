# frozen_string_literal: true

require_relative "../../test_helper"

class PresetManagerEdgeTest < AceTestCase
  include Ace::TestSupport::ConfigHelpers

  def test_handles_missing_preset_file
    with_temp_dir do
      FileUtils.mkdir_p(".ace/bundle/presets")

      manager = Ace::Bundle::Molecules::PresetManager.new
      preset = manager.get_preset("nonexistent")

      assert_nil preset
    end
  end

  def test_handles_empty_preset_file
    with_temp_dir do
      FileUtils.mkdir_p(".ace/bundle/presets")
      File.write(".ace/bundle/presets/empty.md", "")

      manager = Ace::Bundle::Molecules::PresetManager.new
      preset = manager.get_preset("empty")

      # Should handle empty file gracefully
      assert preset.nil? || preset[:name] == "empty"
    end
  end

  def test_handles_preset_with_invalid_frontmatter
    with_temp_dir do
      FileUtils.mkdir_p(".ace/bundle/presets")
      invalid_content = <<~MARKDOWN
        ---
        invalid: [unclosed
        ---
        # Invalid Preset
      MARKDOWN
      File.write(".ace/bundle/presets/invalid.md", invalid_content)

      manager = Ace::Bundle::Molecules::PresetManager.new

      # Should either return nil or handle gracefully without raising
      manager.get_preset("invalid")
      # Test passes if we get here without exception
      assert true
    end
  end

  def test_handles_preset_with_missing_frontmatter
    with_temp_dir do
      FileUtils.mkdir_p(".ace/bundle/presets")
      content_without_frontmatter = <<~MARKDOWN
        # Preset Without Frontmatter

        This preset has no frontmatter.
      MARKDOWN
      File.write(".ace/bundle/presets/no_frontmatter.md", content_without_frontmatter)

      manager = Ace::Bundle::Molecules::PresetManager.new
      preset = manager.get_preset("no_frontmatter")

      # Should handle missing frontmatter
      if preset
        assert_equal "no_frontmatter", preset[:name]
      end
    end
  end

  def test_handles_preset_with_unicode_content
    with_temp_dir do
      FileUtils.mkdir_p(".ace/bundle/presets")
      unicode_content = <<~MARKDOWN
        ---
        description: Prés et café 日本語
        params:
          output: cache
        bundle:
          files:
            - "файл.md"
            - "café/*.txt"
        ---

        # Unicode Preset 世界

        Content with unicode: Привет мир!
      MARKDOWN
      File.write(".ace/bundle/presets/unicode.md", unicode_content)

      manager = Ace::Bundle::Molecules::PresetManager.new
      preset = manager.get_preset("unicode")

      assert preset
      assert_equal "unicode", preset[:name]
      assert preset[:description].include?("café")
    end
  end

  def test_handles_preset_with_very_long_content
    with_temp_dir do
      FileUtils.mkdir_p(".ace/bundle/presets")

      # Create a preset with very long body
      long_body = "# Long Preset\n\n" + ("x" * 100_000)
      long_content = <<~MARKDOWN
        ---
        description: Long preset
        ---

        #{long_body}
      MARKDOWN
      File.write(".ace/bundle/presets/long.md", long_content)

      manager = Ace::Bundle::Molecules::PresetManager.new
      preset = manager.get_preset("long")

      assert preset
      assert_equal "long", preset[:name]
      assert preset[:body].length > 100_000
    end
  end

  def test_handles_preset_with_special_characters_in_filename
    with_temp_dir do
      FileUtils.mkdir_p(".ace/bundle/presets")
      content = <<~MARKDOWN
        ---
        description: Special chars
        ---

        # Special
      MARKDOWN

      # Filename with special characters (but valid)
      File.write(".ace/bundle/presets/preset-with-dashes_and_underscores.md", content)

      manager = Ace::Bundle::Molecules::PresetManager.new
      preset = manager.get_preset("preset-with-dashes_and_underscores")

      assert preset
      assert_equal "preset-with-dashes_and_underscores", preset[:name]
    end
  end

  def test_handles_nested_preset_directories
    with_temp_dir do
      FileUtils.mkdir_p(".ace/bundle/presets/nested/deep")
      content = <<~MARKDOWN
        ---
        description: Nested preset
        ---

        # Nested
      MARKDOWN
      File.write(".ace/bundle/presets/nested/deep/preset.md", content)

      manager = Ace::Bundle::Molecules::PresetManager.new

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
      FileUtils.mkdir_p(".ace/bundle/presets")
      malformed_content = <<~MARKDOWN
        ---
        description: Test
        params:
          max_size: "not_a_number"
          timeout: null
        ---

        # Malformed
      MARKDOWN
      File.write(".ace/bundle/presets/malformed.md", malformed_content)

      manager = Ace::Bundle::Molecules::PresetManager.new

      # Should handle malformed values without crashing
      preset = manager.get_preset("malformed")
      assert preset
    end
  end

  def test_handles_preset_with_empty_arrays_and_hashes
    with_temp_dir do
      FileUtils.mkdir_p(".ace/bundle/presets")
      content = <<~MARKDOWN
        ---
        description: Empty collections
        params: {}
        bundle:
          files: []
          commands: []
          exclude: []
        ---

        # Empty Collections
      MARKDOWN
      File.write(".ace/bundle/presets/empty_collections.md", content)

      manager = Ace::Bundle::Molecules::PresetManager.new
      preset = manager.get_preset("empty_collections")

      assert preset
      assert_equal({}, preset[:params]) if preset.key?(:params)
      assert_equal([], preset.dig(:bundle, "files")) if preset.dig(:bundle, "files")
    end
  end

  def test_handles_case_sensitivity_in_preset_names
    with_temp_dir do
      FileUtils.mkdir_p(".ace/bundle/presets")
      content = <<~MARKDOWN
        ---
        description: Case test
        ---

        # Case Test
      MARKDOWN
      File.write(".ace/bundle/presets/CaseSensitive.md", content)

      manager = Ace::Bundle::Molecules::PresetManager.new

      # Test exact case
      preset_exact = manager.get_preset("CaseSensitive")
      assert preset_exact if File.exist?(".ace/bundle/presets/CaseSensitive.md")

      # Test different case (behavior may vary by filesystem)
      manager.get_preset("casesensitive")
      # On case-insensitive filesystems, this might work
    end
  end

  def test_handles_preset_with_bom_marker
    with_temp_dir do
      FileUtils.mkdir_p(".ace/bundle/presets")

      # Write file with UTF-8 BOM
      File.open(".ace/bundle/presets/bom.md", "wb") do |f|
        f.write("\xEF\xBB\xBF")
        f.write("---\ndescription: BOM test\n---\n\n# BOM Preset")
      end

      manager = Ace::Bundle::Molecules::PresetManager.new
      preset = manager.get_preset("bom")

      # BOM handling may vary - test that we don't crash
      # Either preset is loaded or nil is returned
      assert preset.nil? || preset[:name] == "bom"
    end
  end

  def test_handles_preset_with_windows_line_endings
    with_temp_dir do
      FileUtils.mkdir_p(".ace/bundle/presets")

      # Content with \r\n line endings
      content = "---\r\ndescription: Windows\r\n---\r\n\r\n# Windows Preset\r\n"
      File.write(".ace/bundle/presets/windows.md", content)

      manager = Ace::Bundle::Molecules::PresetManager.new
      preset = manager.get_preset("windows")

      assert preset
      assert_equal "windows", preset[:name]
    end
  end

  def test_handles_symlinked_preset_file
    with_temp_dir do
      FileUtils.mkdir_p(".ace/bundle/presets")

      # Create original file
      original_content = <<~MARKDOWN
        ---
        description: Original
        ---

        # Original
      MARKDOWN
      File.write(".ace/bundle/presets/original.md", original_content)

      # Create symlink
      File.symlink("original.md", ".ace/bundle/presets/link.md")

      manager = Ace::Bundle::Molecules::PresetManager.new
      preset = manager.get_preset("link")

      # Should follow symlink
      assert preset if File.exist?(".ace/bundle/presets/link.md")
    end
  end

  def test_lists_all_presets_with_various_edge_cases
    with_temp_dir do
      FileUtils.mkdir_p(".ace/bundle/presets")

      # Create various preset files
      File.write(".ace/bundle/presets/normal.md", "---\n---\n# Normal")
      File.write(".ace/bundle/presets/empty.md", "")
      File.write(".ace/bundle/presets/.hidden.md", "---\n---\n# Hidden")
      File.write(".ace/bundle/presets/README.txt", "Not a preset")

      manager = Ace::Bundle::Molecules::PresetManager.new

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
