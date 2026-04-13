# frozen_string_literal: true

require_relative "../test_helper"
require "fileutils"
require "tmpdir"

# Tests for preset composition functionality
# Optimized to use API calls instead of subprocess for fast execution (~50ms vs ~2.4s)
# See PR #114 for performance optimization details
class CLIPresetCompositionTest < AceTestCase
  def setup
    # Create a temporary directory for test presets
    @test_dir = Dir.mktmpdir
    @presets_dir = File.join(@test_dir, ".ace", "bundle", "presets")
    FileUtils.mkdir_p(@presets_dir)

    @original_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    create_test_presets
    create_test_files
  end

  def teardown
    Dir.chdir(@original_pwd)
    FileUtils.rm_rf(@test_dir) if @test_dir && File.exist?(@test_dir)
  end

  def create_test_presets
    File.write(
      File.join(@presets_dir, "base.md"),
      <<~PRESET
        ---
        description: Base test preset
        bundle:
          params:
            timeout: 30
          files:
            - test1.md
          sections:
            main:
              files:
                - test1.md
        ---
        Base preset content
      PRESET
    )

    File.write(
      File.join(@presets_dir, "extended.md"),
      <<~PRESET
        ---
        description: Extended test preset
        bundle:
          presets:
            - base
          params:
            timeout: 60
          files:
            - test2.md
          sections:
            main:
              files:
                - test2.md
        ---
        Extended preset content
      PRESET
    )
  end

  def create_test_files
    File.write(File.join(@test_dir, "test1.md"), "Test file 1 content")
    File.write(File.join(@test_dir, "test2.md"), "Test file 2 content")
  end

  # Helper: Load and merge multiple presets via API (equivalent to CLI `-p preset1 -p preset2`)
  # Tests CLI preset composition without subprocess overhead
  # @param preset_names [Array<String>] Names of presets to load and merge
  # @return [Ace::Bundle::Models::BundleData] The generated bundle with metadata and content
  def load_multiple_presets(preset_names)
    result = Ace::Bundle.load_multiple_presets(preset_names)
    refute result.metadata[:error], "API should not have errors: #{result.metadata[:error]}"
    result
  end

  # Helper: Inspect merged config via API (equivalent to CLI `--inspect-config`)
  # Returns YAML representation of merged configuration without loading file contents
  # @param preset_names [Array<String>] Names of presets to inspect
  # @return [String] YAML representation of merged configuration
  def inspect_config(preset_names)
    result = Ace::Bundle.inspect_config(preset_names)
    refute result.metadata[:error], "API should not have errors: #{result.metadata[:error]}"
    result.content
  end

  def test_cli_accepts_multiple_preset_flags
    # -p base -p extended --inspect-config
    output = inspect_config(%w[base extended])

    assert_match(/description:/, output)
    assert_match(/test1.md/, output)
    assert_match(/test2.md/, output)
  end

  def test_cli_accepts_comma_separated_presets
    # --presets base,extended --inspect-config
    # Comma-separated is just parsed to array, same as multiple -p flags
    output = inspect_config(%w[base extended])

    assert_match(/description:/, output)
    assert_match(/test1.md/, output)
    assert_match(/test2.md/, output)
  end

  def test_inspect_config_shows_merged_configuration
    output = inspect_config(%w[base extended])

    # Should show merged params (timeout: 60 from extended overrides 30 from base)
    assert_match(/timeout:\s*60/, output)

    # Should show merged files
    assert_match(/test1.md/, output)
    assert_match(/test2.md/, output)

    # Should NOT contain actual file content (inspect mode)
    refute_match(/Test file 1 content/, output)
    refute_match(/Test file 2 content/, output)
  end

  # Test for top-level preset references (context.presets)
  # This specifically tests the fix for the issue where context.presets was ignored
  def test_cli_loads_top_level_presets_in_single_preset
    # The "extended" preset has: context: presets: [base]
    # Loading just "extended" should compose with base preset
    result = load_multiple_presets(%w[extended])

    # Key verification: composition metadata is preserved on the BundleData object
    assert_equal true, result.metadata[:composed], "Should mark the bundle as composed"
    assert_equal %w[base extended], result.metadata[:composed_from],
      "Should record the full composition chain"

    # Preset body content is stored in metadata, not injected into rendered bundle output
    assert_match(/Base preset content/, result.metadata[:preset_content], "Should retain base preset body")
    assert_match(/Extended preset content/, result.metadata[:preset_content], "Should retain extended preset body")

    # Rendered output should contain merged file content from both presets
    assert_match(/Test file 1 content/, result.content, "Should include base preset file content")
    assert_match(/Test file 2 content/, result.content, "Should include extended preset file content")
  end

  def test_cli_top_level_presets_with_inspect_config
    # Loading just "extended" should show merged config from "base"
    output = inspect_config(%w[extended])

    # Should show merged files from both presets
    assert_match(/test1.md/, output, "Should include base preset files in merged config")
    assert_match(/test2.md/, output, "Should include extended preset files in merged config")

    # Should show extended's timeout (current wins over referenced)
    assert_match(/timeout:\s*60/, output, "Current preset timeout should win")
  end
end
