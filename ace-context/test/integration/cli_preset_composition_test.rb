# frozen_string_literal: true

require_relative "../test_helper"
require "fileutils"
require "tmpdir"
require "open3"

class CLIPresetCompositionTest < AceTestCase
  def setup
    # Create a temporary directory for test presets
    @test_dir = Dir.mktmpdir
    @presets_dir = File.join(@test_dir, ".ace", "context", "presets")
    FileUtils.mkdir_p(@presets_dir)

    @original_pwd = Dir.pwd
    Dir.chdir(@test_dir)

    create_test_presets
    create_test_files

    # Get path to ace-context executable
    @ace_context_bin = File.expand_path("../../exe/ace-context", __dir__)
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
        context:
          params:
            timeout: 30
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
        context:
          presets:
            - base
          params:
            timeout: 60
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

  def run_ace_context(*args)
    stdout, stderr, status = Open3.capture3(@ace_context_bin, *args, chdir: @test_dir)
    [stdout, stderr, status]
  end

  def test_cli_accepts_multiple_preset_flags
    stdout, stderr, status = run_ace_context("-p", "base", "-p", "extended", "--inspect-config")

    assert status.success?, "Command should succeed: #{stderr}"
    assert_match(/description:/, stdout)
    assert_match(/test1.md/, stdout)
    assert_match(/test2.md/, stdout)
  end

  def test_cli_accepts_comma_separated_presets
    stdout, stderr, status = run_ace_context("--presets", "base,extended", "--inspect-config")

    assert status.success?, "Command should succeed: #{stderr}"
    assert_match(/description:/, stdout)
    assert_match(/test1.md/, stdout)
    assert_match(/test2.md/, stdout)
  end

  def test_inspect_config_shows_merged_configuration
    stdout, stderr, status = run_ace_context("-p", "base", "-p", "extended", "--inspect-config")

    assert status.success?, "Command should succeed: #{stderr}"

    # Should show merged params (timeout: 60 from extended overrides 30 from base)
    assert_match(/timeout:\s*60/, stdout)

    # Should show merged files
    assert_match(/test1.md/, stdout)
    assert_match(/test2.md/, stdout)

    # Should NOT contain actual file content (inspect mode)
    refute_match(/Test file 1 content/, stdout)
    refute_match(/Test file 2 content/, stdout)
  end

  def test_single_preset_with_inspect_config
    stdout, stderr, status = run_ace_context("base", "--inspect-config")

    assert status.success?, "Command should succeed: #{stderr}"
    assert_match(/test1.md/, stdout)
    assert_match(/timeout:\s*30/, stdout)
  end

  def test_nonexistent_preset_shows_warning
    stdout, stderr, status = run_ace_context("-p", "base", "-p", "nonexistent", "--inspect-config")

    # Should show warning but still process base preset
    assert_match(/test1.md/, stdout) || assert_match(/Preset 'nonexistent' not found/, stderr)
  end
end
