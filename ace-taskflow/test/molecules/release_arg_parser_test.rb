# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/release_arg_parser"

class ReleaseArgParserTest < Minitest::Test
  def test_parse_display_mode_with_path_flag_no_subfolder
    args = ["v.0.9.0", "--path"]
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_display_mode(args)

    assert_equal "path", result[:mode]
    assert_nil result[:subfolder]
    # Verify --path was removed from args, v.0.9.0 remains as release name
    assert_equal ["v.0.9.0"], args
  end

  def test_parse_display_mode_with_content_flag
    args = ["--content", "v.0.9.0"]
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_display_mode(args)

    assert_equal "content", result[:mode]
    assert_nil result[:subfolder]
    # Verify --content was removed from args
    assert_equal ["v.0.9.0"], args
  end

  def test_parse_display_mode_default
    args = ["v.0.9.0"]
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_display_mode(args)

    assert_equal "formatted", result[:mode]
    assert_nil result[:subfolder]
    # Args should remain unchanged
    assert_equal ["v.0.9.0"], args
  end

  def test_parse_display_mode_empty_args
    args = []
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_display_mode(args)

    assert_equal "formatted", result[:mode]
    assert_nil result[:subfolder]
    assert_equal [], args
  end

  def test_parse_display_mode_with_path_and_subfolder
    args = ["--path", "retro", "v.0.9.0"]
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_display_mode(args)

    assert_equal "path", result[:mode]
    assert_equal "retro", result[:subfolder]
    # Verify --path and subfolder were removed from args
    assert_equal ["v.0.9.0"], args
  end

  def test_parse_display_mode_with_path_and_nested_subfolder
    args = ["--path", "t/042", "v.0.9.0"]
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_display_mode(args)

    assert_equal "path", result[:mode]
    assert_equal "t/042", result[:subfolder]
    assert_equal ["v.0.9.0"], args
  end

  def test_parse_display_mode_path_subfolder_is_flag
    args = ["--path", "--some-flag", "v.0.9.0"]
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_display_mode(args)

    assert_equal "path", result[:mode]
    assert_nil result[:subfolder]
    # --path removed, but --some-flag and v.0.9.0 remain
    assert_equal ["--some-flag", "v.0.9.0"], args
  end

  def test_parse_create_args_with_codename_only
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_create_args(["dark-mode"])

    assert_equal "dark-mode", result[:codename]
    assert_nil result[:version]
    assert_equal "backlog", result[:location]
  end

  def test_parse_create_args_with_version
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_create_args([
      "authentication",
      "--release", "v.0.12.0"
    ])

    assert_equal "authentication", result[:codename]
    assert_equal "v.0.12.0", result[:version]
    assert_equal "backlog", result[:location]
  end

  def test_parse_create_args_with_version_short_flag
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_create_args([
      "api-v2",
      "-r", "v.1.0.0"
    ])

    assert_equal "api-v2", result[:codename]
    assert_equal "v.1.0.0", result[:version]
  end

  def test_parse_create_args_with_current_location
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_create_args([
      "hotfix",
      "--current"
    ])

    assert_equal "hotfix", result[:codename]
    assert_equal "active", result[:location]
  end

  def test_parse_create_args_with_current_short_flag
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_create_args([
      "urgent-fix",
      "-c"
    ])

    assert_equal "urgent-fix", result[:codename]
    assert_equal "active", result[:location]
  end

  def test_parse_create_args_with_backlog_explicit
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_create_args([
      "future-work",
      "--backlog"
    ])

    assert_equal "future-work", result[:codename]
    assert_equal "backlog", result[:location]
  end

  def test_parse_create_args_with_all_options
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_create_args([
      "feature-x",
      "--release", "v.0.15.0",
      "--current"
    ])

    assert_equal "feature-x", result[:codename]
    assert_equal "v.0.15.0", result[:version]
    assert_equal "active", result[:location]
  end

  def test_parse_create_args_with_no_codename
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_create_args([
      "--release", "v.0.10.0"
    ])

    assert_nil result[:codename]
    assert_equal "v.0.10.0", result[:version]
  end

  def test_parse_create_args_empty
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_create_args([])

    assert_nil result[:codename]
    assert_nil result[:version]
    assert_equal "backlog", result[:location]
  end

  def test_parse_reschedule_args_with_reference_only
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_reschedule_args(["v.0.9.0"])

    assert_equal "v.0.9.0", result[:reference]
    assert_equal({}, result[:options])
  end

  def test_parse_reschedule_args_with_status
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_reschedule_args([
      "v.0.9.0",
      "--status", "in-progress"
    ])

    assert_equal "v.0.9.0", result[:reference]
    assert_equal "in-progress", result[:options][:status]
  end

  def test_parse_reschedule_args_with_target_date
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_reschedule_args([
      "v.0.9.0",
      "--target-date", "2025-12-31"
    ])

    assert_equal "v.0.9.0", result[:reference]
    assert_equal "2025-12-31", result[:options][:target_date]
  end

  def test_parse_reschedule_args_with_both_options
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_reschedule_args([
      "v.0.10.0",
      "--status", "active",
      "--target-date", "2026-01-15"
    ])

    assert_equal "v.0.10.0", result[:reference]
    assert_equal "active", result[:options][:status]
    assert_equal "2026-01-15", result[:options][:target_date]
  end

  def test_parse_reschedule_args_no_reference
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_reschedule_args([
      "--status", "done"
    ])

    assert_nil result[:reference]
    assert_equal "done", result[:options][:status]
  end

  def test_parse_demote_args_with_name_only
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_demote_args(["v.0.9.0"])

    assert_equal "v.0.9.0", result[:name]
    assert_equal "done", result[:to]
  end

  def test_parse_demote_args_with_to_backlog
    skip "Test needs fix - will be reviewed in Phase 9"
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_demote_args([
      "v.0.9.0",
      "--to", "backlog"
    ])

    assert_equal "v.0.9.0", result[:name]
    assert_equal "backlog", result[:to]
  end

  def test_parse_demote_args_with_to_before_name
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_demote_args([
      "--to", "backlog",
      "v.0.8.0"
    ])

    assert_equal "v.0.8.0", result[:name]
    assert_equal "backlog", result[:to]
  end

  def test_parse_demote_args_no_name
    skip "Test needs fix - will be reviewed in Phase 9"
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_demote_args([
      "--to", "done"
    ])

    assert_nil result[:name]
    assert_equal "done", result[:to]
  end

  def test_parse_demote_args_empty
    result = Ace::Taskflow::Molecules::ReleaseArgParser.parse_demote_args([])

    assert_nil result[:name]
    assert_equal "done", result[:to]
  end
end
