# frozen_string_literal: true

require_relative "../test_helper"
require "ace/taskflow/molecules/task_arg_parser"

class TaskArgParserTest < Minitest::Test
  def test_parse_display_mode_with_path_flag
    args = ["--path", "other", "args"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_display_mode(args)

    assert_equal "path", result
    assert_equal ["other", "args"], args # --path removed
  end

  def test_parse_display_mode_with_content_flag
    args = ["something", "--content"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_display_mode(args)

    assert_equal "content", result
    assert_equal ["something"], args # --content removed
  end

  def test_parse_display_mode_with_tree_flag
    args = ["--tree"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_display_mode(args)

    assert_equal "tree", result
    assert_equal [], args # --tree removed
  end

  def test_parse_display_mode_defaults_to_formatted
    args = ["no", "display", "flags"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_display_mode(args)

    assert_equal "formatted", result
    assert_equal ["no", "display", "flags"], args # unchanged
  end

  def test_parse_display_mode_with_empty_args
    args = []
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_display_mode(args)

    assert_equal "formatted", result
    assert_equal [], args
  end

  def test_parse_create_args_with_title_only
    args = ["Fix", "the", "bug"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args(args)

    assert_equal "Fix the bug", result[:title]
    assert_equal "current", result[:release]
  end

  def test_parse_create_args_with_backlog_flag
    args = ["New", "task", "--backlog"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args(args)

    assert_equal "New task", result[:title]
    assert_equal "backlog", result[:release]
  end

  def test_parse_create_args_with_release_flag
    args = ["Feature", "task", "--release", "v.0.10.0"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args(args)

    assert_equal "Feature task", result[:title]
    assert_equal "v.0.10.0", result[:release]
  end

  def test_parse_create_args_with_backlog_in_middle
    args = ["Some", "--backlog", "task"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args(args)

    assert_equal "Some task", result[:title]
    assert_equal "backlog", result[:release]
  end

  def test_parse_create_args_with_release_and_title
    args = ["--release", "v.0.9.0", "Important", "fix"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args(args)

    assert_equal "Important fix", result[:title]
    assert_equal "v.0.9.0", result[:release]
  end

  def test_parse_create_args_with_empty_array
    args = []
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args(args)

    assert_equal "", result[:title]
    assert_equal "current", result[:release]
  end

  def test_parse_dependency_args_with_long_flag
    args = ["034", "--depends-on", "031"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_dependency_args(args)

    assert_equal "034", result[:task_ref]
    assert_equal "031", result[:depends_on_ref]
  end

  def test_parse_dependency_args_with_short_flag
    args = ["task.042", "-d", "task.040"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_dependency_args(args)

    assert_equal "task.042", result[:task_ref]
    assert_equal "task.040", result[:depends_on_ref]
  end

  def test_parse_dependency_args_with_qualified_refs
    args = ["v.0.9.0+task.034", "--depends-on", "v.0.9.0+task.031"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_dependency_args(args)

    assert_equal "v.0.9.0+task.034", result[:task_ref]
    assert_equal "v.0.9.0+task.031", result[:depends_on_ref]
  end

  def test_parse_dependency_args_missing_dependency_ref
    args = ["034", "--depends-on"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_dependency_args(args)

    assert_equal "034", result[:task_ref]
    assert_nil result[:depends_on_ref]
  end

  def test_parse_dependency_args_missing_task_ref
    args = ["--depends-on", "031"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_dependency_args(args)

    assert_equal "--depends-on", result[:task_ref] # First arg becomes task_ref
    assert_equal "031", result[:depends_on_ref]
  end

  def test_parse_dependency_args_no_flag
    args = ["034", "031"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_dependency_args(args)

    assert_equal "034", result[:task_ref]
    assert_nil result[:depends_on_ref]
  end

  def test_parse_dependency_args_empty
    args = []
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_dependency_args(args)

    assert_nil result[:task_ref]
    assert_nil result[:depends_on_ref]
  end

  # Tests for parse_create_args_with_optparse

  def test_parse_create_args_with_optparse_positional_title_only
    args = ["Add", "feature"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Add feature", result[:title]
    assert_equal "current", result[:release]
    assert_equal({}, result[:metadata])
  end

  def test_parse_create_args_with_optparse_title_flag_only
    args = ["--title", "Add feature"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Add feature", result[:title]
    assert_equal "current", result[:release]
    assert_equal({}, result[:metadata])
  end

  def test_parse_create_args_with_optparse_title_with_status
    args = ["--title", "Task", "--status", "draft"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Task", result[:title]
    assert_equal "draft", result[:metadata][:status]
  end

  def test_parse_create_args_with_optparse_title_with_estimate
    args = ["--title", "Task", "--estimate", "2h"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Task", result[:title]
    assert_equal "2h", result[:metadata][:estimate]
  end

  def test_parse_create_args_with_optparse_dependencies_parsed
    args = ["--title", "Task", "--dependencies", "018,019,020"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal ["018", "019", "020"], result[:metadata][:dependencies]
  end

  def test_parse_create_args_with_optparse_dependencies_with_spaces
    args = ["--title", "Task", "--dependencies", "018, 019, 020"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal ["018", "019", "020"], result[:metadata][:dependencies]
  end

  def test_parse_create_args_with_optparse_backlog_flag
    args = ["--title", "Task", "--backlog"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "backlog", result[:release]
  end

  def test_parse_create_args_with_optparse_release_flag
    args = ["--title", "Task", "--release", "v.0.10.0"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "v.0.10.0", result[:release]
  end

  def test_parse_create_args_with_optparse_all_metadata_flags
    args = ["--title", "Task", "--status", "draft", "--estimate", "3h", "--dependencies", "018,019"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Task", result[:title]
    assert_equal "draft", result[:metadata][:status]
    assert_equal "3h", result[:metadata][:estimate]
    assert_equal ["018", "019"], result[:metadata][:dependencies]
  end

  def test_parse_create_args_with_optparse_positional_title_with_metadata
    args = ["My", "task", "--status", "draft"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "My task", result[:title]
    assert_equal "draft", result[:metadata][:status]
  end

  def test_parse_create_args_with_optparse_positional_precedence
    # When both positional and --title are provided, positional wins
    args = ["Positional", "--title", "Flag"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Positional", result[:title]
  end

  def test_parse_create_args_with_optparse_empty_args
    args = []
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_nil result[:title]
    assert_equal "current", result[:release]
    assert_equal({}, result[:metadata])
  end

  def test_parse_create_args_with_optparse_special_chars_in_title
    args = ["--title", "Fix: bug #42 [urgent]"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Fix: bug #42 [urgent]", result[:title]
  end

  def test_parse_create_args_with_optparse_help_flag_exits
    args = ["--help"]

    # Capture stdout to verify help is shown
    original_stdout = $stdout
    $stdout = StringIO.new

    begin
      assert_raises(SystemExit) do
        Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)
      end

      output = $stdout.string
      assert_includes output, "Usage: ace-taskflow task create"
    ensure
      $stdout = original_stdout
    end
  end

  def test_parse_create_args_with_optparse_help_short_flag_exits
    args = ["-h"]

    original_stdout = $stdout
    $stdout = StringIO.new

    begin
      assert_raises(SystemExit) do
        Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)
      end

      output = $stdout.string
      assert_includes output, "Usage: ace-taskflow task create"
    ensure
      $stdout = original_stdout
    end
  end

  # Tests for --child-of / -p flag (subtask creation)

  def test_parse_create_args_with_child_of_long_flag
    args = ["Subtask", "--child-of", "121"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Subtask", result[:title]
    assert_equal "121", result[:parent_ref]
  end

  def test_parse_create_args_with_child_of_short_flag
    args = ["-p", "121", "Subtask title"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Subtask title", result[:title]
    assert_equal "121", result[:parent_ref]
  end

  def test_parse_create_args_child_of_with_qualified_ref
    args = ["Subtask", "--child-of", "v.0.9.0+task.121"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Subtask", result[:title]
    assert_equal "v.0.9.0+task.121", result[:parent_ref]
  end

  def test_parse_create_args_child_of_with_backlog_release
    args = ["Subtask", "--child-of", "121", "--backlog"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Subtask", result[:title]
    assert_equal "121", result[:parent_ref]
    assert_equal "backlog", result[:release]
  end

  def test_parse_create_args_child_of_with_explicit_release
    args = ["Subtask", "--child-of", "121", "--release", "v.0.10.0"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Subtask", result[:title]
    assert_equal "121", result[:parent_ref]
    assert_equal "v.0.10.0", result[:release]
  end

  def test_parse_create_args_child_of_with_metadata
    args = ["Subtask", "--child-of", "121", "--status", "draft", "--estimate", "2h"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Subtask", result[:title]
    assert_equal "121", result[:parent_ref]
    assert_equal "draft", result[:metadata][:status]
    assert_equal "2h", result[:metadata][:estimate]
  end

  # Tests for --dry-run in create

  def test_parse_create_args_dry_run_long_flag
    args = ["Test task", "--dry-run"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Test task", result[:title]
    assert_equal true, result[:dry_run]
  end

  def test_parse_create_args_dry_run_short_flag
    args = ["Test task", "-n"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Test task", result[:title]
    assert_equal true, result[:dry_run]
  end

  def test_parse_create_args_dry_run_with_all_options
    args = ["--title", "Test", "--status", "draft", "--dry-run", "--backlog"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal "Test", result[:title]
    assert_equal "draft", result[:metadata][:status]
    assert_equal true, result[:dry_run]
    assert_equal "backlog", result[:release]
  end

  def test_parse_create_args_dry_run_defaults_to_false
    args = ["Test task"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args_with_optparse(args)

    assert_equal false, result[:dry_run]
  end

  # Tests for parse_move_args_with_optparse

  def test_parse_move_args_task_ref_only
    args = ["019"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "019", result[:task_ref]
    assert_nil result[:child_of]
    assert_equal false, result[:dry_run]
    assert_nil result[:release]
  end

  def test_parse_move_args_with_release_positional
    args = ["019", "backlog"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "019", result[:task_ref]
    assert_equal "backlog", result[:release]
  end

  def test_parse_move_args_with_release_flag
    args = ["019", "--release", "v.0.10.0"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "019", result[:task_ref]
    assert_equal "v.0.10.0", result[:release]
  end

  def test_parse_move_args_with_backlog_flag
    args = ["019", "--backlog"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "019", result[:task_ref]
    assert_equal "backlog", result[:release]
  end

  def test_parse_move_args_child_of_with_parent
    args = ["019", "--child-of", "121"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "019", result[:task_ref]
    assert_equal "121", result[:child_of]
  end

  def test_parse_move_args_child_of_short_flag
    args = ["019", "-p", "121"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "019", result[:task_ref]
    assert_equal "121", result[:child_of]
  end

  def test_parse_move_args_child_of_promote_subtask
    # --child-of without argument means promote subtask to standalone
    args = ["121.01", "--child-of"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "121.01", result[:task_ref]
    assert_equal :promote, result[:child_of]
  end

  def test_parse_move_args_child_of_none_sentinel
    # --child-of none also means promote subtask to standalone
    args = ["121.01", "--child-of", "none"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "121.01", result[:task_ref]
    assert_equal :promote, result[:child_of]
  end

  def test_parse_move_args_child_of_empty_string_backwards_compat
    # --child-of= (empty string) also promotes subtask to standalone (backwards compatibility)
    args = ["121.01", "--child-of="]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "121.01", result[:task_ref]
    assert_equal :promote, result[:child_of]
  end

  def test_parse_move_args_child_of_self_for_orchestrator
    args = ["019", "--child-of", "self"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "019", result[:task_ref]
    assert_equal "self", result[:child_of]
  end

  def test_parse_move_args_with_dry_run_long
    args = ["019", "--child-of", "121", "--dry-run"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "019", result[:task_ref]
    assert_equal "121", result[:child_of]
    assert_equal true, result[:dry_run]
  end

  def test_parse_move_args_with_dry_run_short
    args = ["019", "-n", "--child-of", "121"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "019", result[:task_ref]
    assert_equal "121", result[:child_of]
    assert_equal true, result[:dry_run]
  end

  def test_parse_move_args_qualified_ref
    args = ["v.0.9.0+task.019", "--child-of", "v.0.9.0+task.121"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "v.0.9.0+task.019", result[:task_ref]
    assert_equal "v.0.9.0+task.121", result[:child_of]
  end

  def test_parse_move_args_empty
    args = []
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_nil result[:task_ref]
    assert_nil result[:child_of]
    assert_equal false, result[:dry_run]
    assert_nil result[:release]
  end

  def test_parse_move_args_all_options
    args = ["019", "--child-of", "121", "--dry-run", "--release", "v.0.10.0"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "019", result[:task_ref]
    assert_equal "121", result[:child_of]
    assert_equal true, result[:dry_run]
    assert_equal "v.0.10.0", result[:release]
  end

  def test_parse_move_args_help_flag_exits
    args = ["--help"]

    original_stdout = $stdout
    $stdout = StringIO.new

    begin
      assert_raises(SystemExit) do
        Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)
      end

      output = $stdout.string
      assert_includes output, "Usage: ace-taskflow task move"
      assert_includes output, "--child-of"
      assert_includes output, "--dry-run"
    ensure
      $stdout = original_stdout
    end
  end

  def test_parse_move_args_release_flag_overrides_positional
    # When both positional release and --release flag are provided, flag wins
    args = ["019", "backlog", "--release", "v.0.10.0"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_move_args_with_optparse(args)

    assert_equal "019", result[:task_ref]
    assert_equal "v.0.10.0", result[:release]
  end
end
