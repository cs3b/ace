# frozen_string_literal: true

require_relative "../test_helper"
require "open3"
require "fileutils"

class CliAutoFormatTest < AceTestCase
  BIN = File.expand_path("../../exe/ace-context", __dir__)

  def setup
    @temp_dir = Dir.mktmpdir("ace-context-auto-format-test")
    @original_dir = Dir.pwd
    Dir.chdir(@temp_dir)

    # Create a minimal .ace structure
    FileUtils.mkdir_p(".ace/context/presets")
  end

  def teardown
    Dir.chdir(@original_dir)
    FileUtils.rm_rf(@temp_dir)
  end

  # --- Auto-format behavior tests ---

  def test_small_content_outputs_to_stdio
    # Create a small file (under 500 lines)
    create_small_preset

    stdout, stderr, status = Open3.capture3(BIN, "small-test")

    assert status.success?, "Command should succeed: #{stderr}"
    # Should output content directly (not a "Context saved" message)
    assert_includes stdout, "# Small Test Content"
    refute_includes stdout, "Context saved"
    refute_includes stdout, "output file:"
  end

  def test_large_content_outputs_to_cache
    # Create a large file (over 500 lines)
    create_large_preset

    stdout, stderr, status = Open3.capture3(BIN, "large-test")

    assert status.success?, "Command should succeed: #{stderr}"
    # Should output cache path (not raw content)
    assert_includes stdout, "Context saved"
    assert_includes stdout, "output file:"
    assert_includes stdout, ".cache/ace-context"
  end

  def test_explicit_stdio_overrides_auto_format
    # Even large content should go to stdio with --output stdio
    create_large_preset

    stdout, stderr, status = Open3.capture3(BIN, "large-test", "--output", "stdio")

    assert status.success?, "Command should succeed: #{stderr}"
    # Should output content directly despite being large
    refute_includes stdout, "Context saved"
    assert_includes stdout, "# Large Test Content"
  end

  def test_explicit_cache_overrides_auto_format
    # Even small content should go to cache with --output cache
    create_small_preset

    stdout, stderr, status = Open3.capture3(BIN, "small-test", "--output", "cache")

    assert status.success?, "Command should succeed: #{stderr}"
    # Should output cache path despite being small
    assert_includes stdout, "Context saved"
    assert_includes stdout, "output file:"
  end

  def test_at_threshold_goes_to_cache
    # Create content that will result in >= 500 lines after processing
    # The preset loader adds ~2 lines of wrapper, so we need ~498 content lines
    create_preset_with_lines("at-threshold-test", 498)

    stdout, stderr, status = Open3.capture3(BIN, "at-threshold-test")

    assert status.success?, "Command should succeed: #{stderr}"
    # Should go to cache (output mentions saving)
    assert_includes stdout, "Context saved", "Content at/above threshold should go to cache"
  end

  def test_below_threshold_goes_to_stdio
    # Create content that will result in < 500 lines after processing
    # Small enough to definitely be under threshold
    create_preset_with_lines("below-threshold-test", 100)

    stdout, stderr, status = Open3.capture3(BIN, "below-threshold-test")

    assert status.success?, "Command should succeed: #{stderr}"
    # Should go to stdio (shows content directly)
    refute_includes stdout, "Context saved", "Content below threshold should go to stdio"
    assert_includes stdout, "# Test Content"
  end

  private

  def create_small_preset
    content = <<~MD
      ---
      name: small-test
      ---

      # Small Test Content

      This is a small preset with only a few lines.
      It should be output directly to stdout.
    MD

    File.write(".ace/context/presets/small-test.md", content)
  end

  def create_large_preset
    lines = (1..600).map { |i| "Line #{i} of large content" }.join("\n")
    content = <<~MD
      ---
      name: large-test
      ---

      # Large Test Content

      #{lines}
    MD

    File.write(".ace/context/presets/large-test.md", content)
  end

  def create_preset_with_lines(name, line_count)
    # Account for frontmatter and header (5 lines)
    content_lines = line_count - 5
    lines = (1..content_lines).map { |i| "Line #{i}" }.join("\n")

    content = <<~MD
      ---
      name: #{name}
      ---

      # Test Content

      #{lines}
    MD

    File.write(".ace/context/presets/#{name}.md", content)
  end
end
