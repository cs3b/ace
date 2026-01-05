# frozen_string_literal: true

require_relative "../test_helper"
require "ace/taskflow/molecules/command_option_parser"

class CommandOptionParserTest < Minitest::Test
  # Helper to create parser with specific option sets
  def create_parser(option_sets:, banner: nil, &block)
    Ace::Taskflow::Molecules::CommandOptionParser.new(
      option_sets: option_sets,
      banner: banner,
      &block
    )
  end

  # ============================================
  # Basic Initialization Tests
  # ============================================

  def test_default_option_sets
    parser = Ace::Taskflow::Molecules::CommandOptionParser.new
    assert_includes parser.option_sets, :display
    assert_includes parser.option_sets, :release
    assert_includes parser.option_sets, :filter
    assert_includes parser.option_sets, :limits
    assert_includes parser.option_sets, :help
  end

  def test_custom_option_sets
    parser = create_parser(option_sets: [:display, :help])
    assert_equal [:display, :help], parser.option_sets
  end

  def test_banner_stored
    parser = create_parser(
      option_sets: [:help],
      banner: "Custom banner"
    )
    assert_equal "Custom banner", parser.banner
  end

  # ============================================
  # Display Options Tests
  # ============================================

  def test_parse_stats_flag
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["--stats"])

    assert_equal true, result[:parsed][:stats]
  end

  def test_parse_tree_flag
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["--tree"])

    assert_equal true, result[:parsed][:tree]
  end

  def test_parse_path_flag
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["--path"])

    assert_equal true, result[:parsed][:path]
  end

  def test_parse_list_flag
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["--list"])

    assert_equal true, result[:parsed][:list]
  end

  def test_parse_flat_flag
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["--flat"])

    assert_equal true, result[:parsed][:flat]
  end

  def test_parse_verbose_flag_long
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["--verbose"])

    assert_equal true, result[:parsed][:verbose]
  end

  def test_parse_verbose_flag_short
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["-v"])

    assert_equal true, result[:parsed][:verbose]
  end

  def test_parse_format_flag
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["--format", "json"])

    assert_equal "json", result[:parsed][:format]
  end

  def test_parse_output_flag_long
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["--output", "/tmp/out.txt"])

    assert_equal "/tmp/out.txt", result[:parsed][:output]
  end

  def test_parse_output_flag_short
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["-o", "/tmp/out.txt"])

    assert_equal "/tmp/out.txt", result[:parsed][:output]
  end

  # ============================================
  # Release Options Tests
  # ============================================

  def test_parse_release_flag
    parser = create_parser(option_sets: [:release])
    result = parser.parse(["--release", "v.0.10.0"])

    assert_equal "v.0.10.0", result[:parsed][:release]
  end

  def test_parse_backlog_flag
    parser = create_parser(option_sets: [:release])
    result = parser.parse(["--backlog"])

    assert_equal "backlog", result[:parsed][:release]
  end

  def test_parse_current_flag
    parser = create_parser(option_sets: [:release])
    result = parser.parse(["--current"])

    assert_equal "current", result[:parsed][:release]
  end

  def test_parse_all_flag
    parser = create_parser(option_sets: [:release])
    result = parser.parse(["--all"])

    assert_equal true, result[:parsed][:all]
  end

  # ============================================
  # Filter Options Tests
  # ============================================

  def test_parse_single_filter
    parser = create_parser(option_sets: [:filter])
    result = parser.parse(["--filter", "status:pending"])

    assert_equal ["status:pending"], result[:parsed][:filter]
    assert_equal 1, result[:parsed][:filter_specs].size
    assert_equal "status", result[:parsed][:filter_specs][0][:key]
    assert_equal ["pending"], result[:parsed][:filter_specs][0][:values]
  end

  def test_parse_multiple_filters
    parser = create_parser(option_sets: [:filter])
    result = parser.parse(["--filter", "status:pending", "--filter", "priority:high"])

    assert_equal 2, result[:parsed][:filter].size
    assert_equal 2, result[:parsed][:filter_specs].size
  end

  def test_parse_filter_with_or_values
    parser = create_parser(option_sets: [:filter])
    result = parser.parse(["--filter", "status:pending|in-progress"])

    spec = result[:parsed][:filter_specs][0]
    assert_equal ["pending", "in-progress"], spec[:values]
    assert_equal true, spec[:or_mode]
  end

  def test_parse_filter_with_negation
    parser = create_parser(option_sets: [:filter])
    result = parser.parse(["--filter", "status:!done"])

    spec = result[:parsed][:filter_specs][0]
    assert_equal ["done"], spec[:values]
    assert_equal true, spec[:negated]
  end

  def test_parse_filter_clear_flag
    parser = create_parser(option_sets: [:filter])
    result = parser.parse(["--filter-clear"])

    assert_equal true, result[:parsed][:filter_clear]
  end

  # ============================================
  # Limits Options Tests
  # ============================================

  def test_parse_limit_flag_integer_coercion
    parser = create_parser(option_sets: [:limits])
    result = parser.parse(["--limit", "10"])

    assert_equal 10, result[:parsed][:limit]
    assert_kind_of Integer, result[:parsed][:limit]
  end

  def test_parse_days_flag_integer_coercion
    parser = create_parser(option_sets: [:limits])
    result = parser.parse(["--days", "7"])

    assert_equal 7, result[:parsed][:days]
    assert_kind_of Integer, result[:parsed][:days]
  end

  # ============================================
  # Subtasks Options Tests
  # ============================================

  def test_parse_subtasks_flag
    parser = create_parser(option_sets: [:subtasks])
    result = parser.parse(["--subtasks"])

    assert_equal :show, result[:parsed][:subtasks_display]
  end

  def test_parse_no_subtasks_flag
    parser = create_parser(option_sets: [:subtasks])
    result = parser.parse(["--no-subtasks"])

    assert_equal :hide, result[:parsed][:subtasks_display]
  end

  # ============================================
  # Sort Options Tests
  # ============================================

  def test_parse_sort_flag_field_only
    parser = create_parser(option_sets: [:sort])
    result = parser.parse(["--sort", "priority"])

    assert_equal({ by: :priority, ascending: true }, result[:parsed][:sort])
  end

  def test_parse_sort_flag_with_asc_direction
    parser = create_parser(option_sets: [:sort])
    result = parser.parse(["--sort", "priority:asc"])

    assert_equal({ by: :priority, ascending: true }, result[:parsed][:sort])
  end

  def test_parse_sort_flag_with_desc_direction
    parser = create_parser(option_sets: [:sort])
    result = parser.parse(["--sort", "priority:desc"])

    assert_equal({ by: :priority, ascending: false }, result[:parsed][:sort])
  end

  # ============================================
  # Actions Options Tests
  # ============================================

  def test_parse_dry_run_long_flag
    parser = create_parser(option_sets: [:actions])
    result = parser.parse(["--dry-run"])

    assert_equal true, result[:parsed][:dry_run]
  end

  def test_parse_dry_run_short_flag
    parser = create_parser(option_sets: [:actions])
    result = parser.parse(["-n"])

    assert_equal true, result[:parsed][:dry_run]
  end

  # ============================================
  # Help Options Tests
  # ============================================

  def test_parse_help_long_flag
    parser = create_parser(
      option_sets: [:help],
      banner: "Usage: test"
    )

    # Capture stdout
    original_stdout = $stdout
    $stdout = StringIO.new

    begin
      result = parser.parse(["--help"])
      assert_equal true, result[:help_requested]

      output = $stdout.string
      assert_includes output, "Usage: test"
    ensure
      $stdout = original_stdout
    end
  end

  def test_parse_help_short_flag
    parser = create_parser(
      option_sets: [:help],
      banner: "Usage: test"
    )

    original_stdout = $stdout
    $stdout = StringIO.new

    begin
      result = parser.parse(["-h"])
      assert_equal true, result[:help_requested]
    ensure
      $stdout = original_stdout
    end
  end

  # ============================================
  # Positional Arguments Tests
  # ============================================

  def test_remaining_positional_args
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["preset_name", "--stats", "extra"])

    assert_equal ["preset_name", "extra"], result[:remaining]
    assert_equal true, result[:parsed][:stats]
  end

  def test_preserves_args_order
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["first", "--stats", "second", "third"])

    assert_equal ["first", "second", "third"], result[:remaining]
  end

  def test_unknown_flags_in_remaining
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["--unknown-flag", "--stats"])

    assert_includes result[:remaining], "--unknown-flag"
    assert_equal true, result[:parsed][:stats]
  end

  # ============================================
  # Thor Options Merge Tests
  # ============================================

  def test_thor_options_merged
    parser = create_parser(option_sets: [:display, :limits])
    result = parser.parse([], thor_options: { stats: true, limit: 5 })

    assert_equal true, result[:parsed][:stats]
    assert_equal 5, result[:parsed][:limit]
  end

  def test_thor_options_override_args
    parser = create_parser(option_sets: [:limits])
    result = parser.parse(["--limit", "10"], thor_options: { limit: 20 })

    # Thor options take precedence
    assert_equal 20, result[:parsed][:limit]
  end

  def test_thor_options_false_not_merged
    # False Thor options shouldn't override default false values
    parser = create_parser(option_sets: [:display])
    result = parser.parse([], thor_options: { stats: false })

    assert_equal false, result[:parsed][:stats]
  end

  def test_thor_options_nil_ignored
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["--stats"], thor_options: { stats: nil })

    # Args should still work when Thor option is nil
    assert_equal true, result[:parsed][:stats]
  end

  def test_thor_json_converts_to_format
    parser = create_parser(option_sets: [:display])
    result = parser.parse([], thor_options: { json: true })

    assert_equal "json", result[:parsed][:format]
  end

  # ============================================
  # Custom Options Tests
  # ============================================

  def test_custom_options_block
    parser = create_parser(
      option_sets: [:help],
      banner: "Custom"
    ) do |opts, parsed|
      opts.on("--component TYPE", "Custom component option") do |v|
        parsed[:component] = v
      end
    end

    result = parser.parse(["--component", "tasks"])

    assert_equal "tasks", result[:parsed][:component]
  end

  def test_custom_options_with_standard_options
    parser = create_parser(
      option_sets: [:display, :help]
    ) do |opts, parsed|
      opts.on("--custom") { parsed[:custom] = true }
    end

    result = parser.parse(["--stats", "--custom"])

    assert_equal true, result[:parsed][:stats]
    assert_equal true, result[:parsed][:custom]
  end

  # ============================================
  # Defaults Tests
  # ============================================

  def test_display_defaults_to_false
    parser = create_parser(option_sets: [:display])
    result = parser.parse([])

    assert_equal false, result[:parsed][:stats]
    assert_equal false, result[:parsed][:tree]
    assert_equal false, result[:parsed][:path]
    assert_equal false, result[:parsed][:list]
    assert_equal false, result[:parsed][:flat]
    assert_equal false, result[:parsed][:verbose]
  end

  def test_filter_defaults_to_empty_array
    parser = create_parser(option_sets: [:filter])
    result = parser.parse([])

    assert_equal [], result[:parsed][:filter]
  end

  def test_actions_defaults_to_false
    parser = create_parser(option_sets: [:actions])
    result = parser.parse([])

    assert_equal false, result[:parsed][:dry_run]
  end

  # ============================================
  # Combined Usage Tests
  # ============================================

  def test_full_tasks_command_usage
    parser = create_parser(
      option_sets: [:display, :release, :filter, :limits, :subtasks, :sort, :help],
      banner: "Usage: ace-taskflow tasks [preset] [options]"
    )

    result = parser.parse([
      "next",
      "--filter", "status:pending",
      "--filter", "priority:high",
      "--limit", "10",
      "--subtasks",
      "--sort", "priority:desc"
    ])

    assert_equal ["next"], result[:remaining]
    assert_equal 2, result[:parsed][:filter_specs].size
    assert_equal 10, result[:parsed][:limit]
    assert_equal :show, result[:parsed][:subtasks_display]
    assert_equal({ by: :priority, ascending: false }, result[:parsed][:sort])
    assert_equal false, result[:help_requested]
  end

  def test_real_world_thor_integration
    # Simulates how TasksCommand would use this
    parser = create_parser(
      option_sets: [:display, :release, :filter, :limits, :help],
      banner: "Usage: ace-taskflow tasks [preset] [options]"
    )

    # Thor passes these class options
    thor_options = {
      status: nil,
      stats: nil,
      tree: nil,
      all: true,
      limit: 20
    }

    result = parser.parse(
      ["all", "--filter", "status:pending"],
      thor_options: thor_options
    )

    assert_equal ["all"], result[:remaining]
    assert_equal true, result[:parsed][:all]
    assert_equal 20, result[:parsed][:limit]
    assert_equal 1, result[:parsed][:filter_specs].size
  end

  # ============================================
  # Help Text Tests
  # ============================================

  def test_help_text_includes_banner
    parser = create_parser(
      option_sets: [:display, :help],
      banner: "Custom banner text"
    )

    help = parser.help_text
    assert_includes help, "Custom banner text"
  end

  def test_help_text_includes_options
    parser = create_parser(
      option_sets: [:display, :filter, :limits, :help],
      banner: "Usage: test"
    )

    help = parser.help_text
    assert_includes help, "--stats"
    assert_includes help, "--filter"
    assert_includes help, "--limit"
    assert_includes help, "--help"
  end

  # ============================================
  # Error Handling Tests
  # ============================================

  def test_missing_argument_raises
    parser = create_parser(option_sets: [:limits])

    assert_raises(ArgumentError) do
      parser.parse(["--limit"])
    end
  end

  def test_does_not_mutate_input_args
    parser = create_parser(option_sets: [:display])
    original_args = ["--stats", "arg"]
    args_copy = original_args.dup

    parser.parse(args_copy)

    assert_equal original_args, args_copy
  end

  # ============================================
  # Empty Input Tests
  # ============================================

  def test_empty_args_returns_defaults
    parser = create_parser(option_sets: [:display, :filter])
    result = parser.parse([])

    assert_equal [], result[:remaining]
    assert_equal false, result[:help_requested]
    assert_equal false, result[:parsed][:stats]
    assert_equal [], result[:parsed][:filter]
  end

  def test_empty_thor_options_works
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["--stats"], thor_options: {})

    assert_equal true, result[:parsed][:stats]
  end

  def test_nil_thor_options_works
    parser = create_parser(option_sets: [:display])
    result = parser.parse(["--stats"], thor_options: nil)

    assert_equal true, result[:parsed][:stats]
  end
end
