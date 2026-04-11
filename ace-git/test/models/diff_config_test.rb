# frozen_string_literal: true

require_relative "../test_helper"

class DiffConfigTest < AceGitTestCase
  def setup
    super
    @config_class = Ace::Git::Models::DiffConfig
  end

  # --- git_flags tests ---

  def test_git_flags_includes_whitespace_flag_by_default
    config = @config_class.new
    assert_includes config.git_flags, "-w"
  end

  def test_git_flags_excludes_whitespace_flag_when_disabled
    config = @config_class.new(exclude_whitespace: false)
    refute_includes config.git_flags, "-w"
  end

  def test_git_flags_uses_diff_filter_for_exclude_renames
    # We use --diff-filter instead of --no-renames to avoid redundant flags
    config = @config_class.new(exclude_renames: true)
    # Should have --diff-filter but NOT --no-renames (removed as redundant)
    assert_includes config.git_flags, "--diff-filter=ACDMTUXB"
    refute_includes config.git_flags, "--no-renames"
  end

  def test_git_flags_has_no_diff_filter_by_default
    config = @config_class.new
    refute config.git_flags.any? { |f| f.start_with?("--diff-filter") }
  end

  def test_git_flags_applies_diff_filter_only_when_excluding_renames
    # When exclude_renames is true, apply filter (excludes R but includes D)
    config_exclude = @config_class.new(exclude_renames: true)
    filter_flags = config_exclude.git_flags.select { |f| f.start_with?("--diff-filter") }
    assert_equal 1, filter_flags.length
    assert_equal "--diff-filter=ACDMTUXB", filter_flags.first

    # When exclude_renames is false (default), no filter - show all changes
    config_default = @config_class.new
    filter_flags = config_default.git_flags.select { |f| f.start_with?("--diff-filter") }
    assert_empty filter_flags
  end

  def test_git_flags_diff_filter_includes_deletions
    # Critical: ensure D (deletions) is always included in the filter
    config = @config_class.new(exclude_renames: true)
    filter_flag = config.git_flags.find { |f| f.start_with?("--diff-filter") }

    assert filter_flag, "Expected --diff-filter flag when exclude_renames is true"
    assert_includes filter_flag, "D", "diff-filter must include D (deletions)"
  end

  def test_git_flags_diff_filter_excludes_renames
    # When exclude_renames is true, R should not be in the filter
    config = @config_class.new(exclude_renames: true)
    filter_flag = config.git_flags.find { |f| f.start_with?("--diff-filter") }

    refute_includes filter_flag, "R", "diff-filter should not include R when excluding renames"
  end

  # --- format handling tests ---

  def test_format_defaults_to_diff_symbol
    config = @config_class.new
    assert_equal :diff, config.format
  end

  def test_format_converts_string_to_symbol
    config = @config_class.new(format: "summary")
    assert_equal :summary, config.format
  end

  def test_format_preserves_symbol
    config = @config_class.new(format: :summary)
    assert_equal :summary, config.format
  end

  def test_grouped_stats_defaults_are_set
    config = @config_class.new

    assert_equal %w[lib test handbook], config.grouped_stats_layers
    assert_equal 5, config.grouped_stats_collapse_above
    assert_equal "collapsible", config.grouped_stats_show_full_tree
    assert_equal %w[.ace-task .ace], config.grouped_stats_dotfile_groups
  end

  # --- from_hash tests ---

  def test_from_hash_handles_string_keys
    config = @config_class.from_hash(
      "exclude_patterns" => ["test/**/*"],
      "exclude_whitespace" => false,
      "format" => "summary"
    )

    assert_equal ["test/**/*"], config.exclude_patterns
    assert_equal false, config.exclude_whitespace?
    assert_equal :summary, config.format
  end

  def test_from_hash_handles_symbol_keys
    config = @config_class.from_hash(
      exclude_patterns: ["test/**/*"],
      exclude_whitespace: false,
      format: :summary
    )

    assert_equal ["test/**/*"], config.exclude_patterns
    assert_equal false, config.exclude_whitespace?
    assert_equal :summary, config.format
  end

  def test_from_hash_reads_grouped_stats_nested_config
    config = @config_class.from_hash(
      "format" => "grouped_stats",
      "grouped_stats" => {
        "layers" => %w[lib handbook],
        "collapse_above" => 7,
        "show_full_tree" => "always",
        "dotfile_groups" => [".ace-task"]
      }
    )

    assert_equal :grouped_stats, config.format
    assert_equal %w[lib handbook], config.grouped_stats_layers
    assert_equal 7, config.grouped_stats_collapse_above
    assert_equal "always", config.grouped_stats_show_full_tree
    assert_equal [".ace-task"], config.grouped_stats_dotfile_groups
  end

  # --- merge tests ---

  def test_merge_overrides_values
    config1 = @config_class.new(max_lines: 1000, format: :diff)
    config2 = @config_class.new(max_lines: 500, format: :summary)

    merged = config1.merge(config2)

    assert_equal 500, merged.max_lines
    assert_equal :summary, merged.format
  end

  # --- to_h tests ---

  def test_to_h_returns_complete_hash
    config = @config_class.new(
      exclude_patterns: ["test/**/*"],
      max_lines: 5000,
      format: :summary
    )

    hash = config.to_h

    assert_equal ["test/**/*"], hash[:exclude_patterns]
    assert_equal 5000, hash[:max_lines]
    assert_equal :summary, hash[:format]
    assert hash.key?(:exclude_whitespace)
    assert hash.key?(:exclude_renames)
  end
end
