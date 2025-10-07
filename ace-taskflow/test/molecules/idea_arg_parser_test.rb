# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/taskflow/molecules/idea_arg_parser"

class IdeaArgParserTest < Minitest::Test
  def test_parse_capture_options_with_content_only
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "Implement", "caching", "layer"
    ])

    assert_equal "Implement caching layer", result[:content]
    assert_nil result[:location]
    assert_nil result[:git_commit]
    assert_nil result[:llm_enhance]
  end

  def test_parse_capture_options_with_backlog
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "Future", "feature", "--backlog"
    ])

    assert_equal "Future feature", result[:content]
    assert_equal "backlog", result[:location]
  end

  def test_parse_capture_options_with_release
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "Bug", "fix", "--release", "v.0.9.0"
    ])

    assert_equal "Bug fix", result[:content]
    assert_equal "v.0.9.0", result[:location]
  end

  def test_parse_capture_options_with_release_short_flag
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "New", "feature", "-r", "v.1.0.0"
    ])

    assert_equal "New feature", result[:content]
    assert_equal "v.1.0.0", result[:location]
  end

  def test_parse_capture_options_with_current
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "Hotfix", "--current"
    ])

    assert_equal "Hotfix", result[:content]
    assert_equal "current", result[:location]
  end

  def test_parse_capture_options_with_git_commit
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "My", "idea", "--git-commit"
    ])

    assert_equal "My idea", result[:content]
    assert_equal true, result[:git_commit]
  end

  def test_parse_capture_options_with_git_commit_short
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "My", "idea", "-gc"
    ])

    assert_equal true, result[:git_commit]
  end

  def test_parse_capture_options_with_no_git_commit
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "My", "idea", "--no-git-commit"
    ])

    assert_equal false, result[:git_commit]
  end

  def test_parse_capture_options_with_llm_enhance
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "Complex", "idea", "--llm-enhance"
    ])

    assert_equal "Complex idea", result[:content]
    assert_equal true, result[:llm_enhance]
  end

  def test_parse_capture_options_with_llm_enhance_short
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "Complex", "idea", "-llm"
    ])

    assert_equal true, result[:llm_enhance]
  end

  def test_parse_capture_options_with_no_llm_enhance
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "Simple", "idea", "--no-llm-enhance"
    ])

    assert_equal false, result[:llm_enhance]
  end

  def test_parse_capture_options_with_all_options
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "New", "feature",
      "--release", "v.0.10.0",
      "--git-commit",
      "--llm-enhance"
    ])

    assert_equal "New feature", result[:content]
    assert_equal "v.0.10.0", result[:location]
    assert_equal true, result[:git_commit]
    assert_equal true, result[:llm_enhance]
  end

  def test_parse_capture_options_empty
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([])

    assert_equal "", result[:content]
    assert_nil result[:location]
  end

  def test_parse_capture_options_flags_only
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "--backlog", "--git-commit"
    ])

    assert_equal "", result[:content]
    assert_equal "backlog", result[:location]
    assert_equal true, result[:git_commit]
  end

  def test_parse_context_default
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_context([])

    assert_equal "current", result
  end

  def test_parse_context_backlog
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_context(["--backlog"])

    assert_equal "backlog", result
  end

  def test_parse_context_current
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_context(["--current"])

    assert_equal "current", result
  end

  def test_parse_context_release
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_context(["--release", "v.0.9.0"])

    assert_equal "v.0.9.0", result
  end

  def test_parse_context_release_short
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_context(["-r", "v.1.0.0"])

    assert_equal "v.1.0.0", result
  end

  def test_parse_context_with_other_args
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_context([
      "some", "content", "--release", "v.0.8.0", "more", "content"
    ])

    assert_equal "v.0.8.0", result
  end

  def test_parse_reschedule_options_with_reference_only
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_reschedule_options(["idea-001"])

    assert_equal "idea-001", result[:reference]
    assert_equal({}, result[:options])
  end

  def test_parse_reschedule_options_with_add_next
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_reschedule_options([
      "idea-001", "--add-next"
    ])

    assert_equal "idea-001", result[:reference]
    assert_equal true, result[:options][:add_next]
  end

  def test_parse_reschedule_options_with_add_at_end
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_reschedule_options([
      "idea-001", "--add-at-end"
    ])

    assert_equal true, result[:options][:add_at_end]
  end

  def test_parse_reschedule_options_with_after
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_reschedule_options([
      "idea-001", "--after", "idea-002"
    ])

    assert_equal "idea-001", result[:reference]
    assert_equal "idea-002", result[:options][:after]
  end

  def test_parse_reschedule_options_with_before
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_reschedule_options([
      "idea-001", "--before", "idea-003"
    ])

    assert_equal "idea-003", result[:options][:before]
  end

  def test_parse_reschedule_options_no_reference
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_reschedule_options([
      "--add-next"
    ])

    assert_nil result[:reference]
    assert_equal true, result[:options][:add_next]
  end

  def test_determine_location_with_explicit_location
    options = { location: "backlog" }
    result = Ace::Taskflow::Molecules::IdeaArgParser.determine_location(options, {})

    assert_equal "backlog", result
  end

  def test_determine_location_with_config_active
    options = {}
    config = { "defaults" => { "idea_location" => "active" } }
    result = Ace::Taskflow::Molecules::IdeaArgParser.determine_location(options, config)

    assert_equal "current", result
  end

  def test_determine_location_with_config_current
    options = {}
    config = { "defaults" => { "idea_location" => "current" } }
    result = Ace::Taskflow::Molecules::IdeaArgParser.determine_location(options, config)

    assert_equal "current", result
  end

  def test_determine_location_with_config_backlog
    options = {}
    config = { "defaults" => { "idea_location" => "backlog" } }
    result = Ace::Taskflow::Molecules::IdeaArgParser.determine_location(options, config)

    assert_equal "backlog", result
  end

  def test_determine_location_with_config_release
    options = {}
    config = { "defaults" => { "idea_location" => "v.0.9.0" } }
    result = Ace::Taskflow::Molecules::IdeaArgParser.determine_location(options, config)

    assert_equal "v.0.9.0", result
  end

  def test_determine_location_default
    options = {}
    result = Ace::Taskflow::Molecules::IdeaArgParser.determine_location(options, {})

    assert_equal "current", result
  end

  def test_determine_location_explicit_overrides_config
    options = { location: "backlog" }
    config = { "defaults" => { "idea_location" => "current" } }
    result = Ace::Taskflow::Molecules::IdeaArgParser.determine_location(options, config)

    assert_equal "backlog", result
  end

  # Tests for --note flag
  def test_parse_capture_options_with_note_flag
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "--note", "Explicit note text"
    ])

    assert_equal "Explicit note text", result[:content]
    assert_equal "Explicit note text", result[:note]
    refute result[:clipboard]
  end

  def test_parse_capture_options_with_note_short_flag
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "-n", "Short form note"
    ])

    assert_equal "Short form note", result[:content]
    assert_equal "Short form note", result[:note]
  end

  def test_parse_capture_options_note_overrides_positional
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "Ignored positional", "--note", "This takes precedence"
    ])

    assert_equal "This takes precedence", result[:content]
    assert_equal "This takes precedence", result[:note]
  end

  def test_parse_capture_options_note_with_other_flags
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "--note", "My idea",
      "--git-commit",
      "--backlog"
    ])

    assert_equal "My idea", result[:content]
    assert_equal "My idea", result[:note]
    assert_equal true, result[:git_commit]
    assert_equal "backlog", result[:location]
  end

  # Tests for --clipboard flag
  def test_parse_capture_options_with_clipboard_flag
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "--clipboard"
    ])

    assert_equal true, result[:clipboard]
    assert_equal "", result[:content]
  end

  def test_parse_capture_options_with_clipboard_short_flag
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "-c"
    ])

    assert_equal true, result[:clipboard]
  end

  def test_parse_capture_options_clipboard_with_positional
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "Main", "idea", "--clipboard"
    ])

    assert_equal "Main idea", result[:content]
    assert_equal true, result[:clipboard]
  end

  def test_parse_capture_options_clipboard_with_note
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "--note", "Main context", "--clipboard"
    ])

    assert_equal "Main context", result[:content]
    assert_equal "Main context", result[:note]
    assert_equal true, result[:clipboard]
  end

  def test_parse_capture_options_clipboard_with_all_flags
    result = Ace::Taskflow::Molecules::IdeaArgParser.parse_capture_options([
      "--note", "Design proposal",
      "--clipboard",
      "--git-commit",
      "--llm-enhance",
      "--backlog"
    ])

    assert_equal "Design proposal", result[:content]
    assert_equal true, result[:clipboard]
    assert_equal true, result[:git_commit]
    assert_equal true, result[:llm_enhance]
    assert_equal "backlog", result[:location]
  end
end
