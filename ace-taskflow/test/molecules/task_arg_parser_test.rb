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
    assert_equal "current", result[:context]
  end

  def test_parse_create_args_with_backlog_flag
    args = ["New", "task", "--backlog"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args(args)

    assert_equal "New task", result[:title]
    assert_equal "backlog", result[:context]
  end

  def test_parse_create_args_with_release_flag
    args = ["Feature", "task", "--release", "v.0.10.0"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args(args)

    assert_equal "Feature task", result[:title]
    assert_equal "v.0.10.0", result[:context]
  end

  def test_parse_create_args_with_backlog_in_middle
    args = ["Some", "--backlog", "task"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args(args)

    assert_equal "Some task", result[:title]
    assert_equal "backlog", result[:context]
  end

  def test_parse_create_args_with_release_and_title
    args = ["--release", "v.0.9.0", "Important", "fix"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args(args)

    assert_equal "Important fix", result[:title]
    assert_equal "v.0.9.0", result[:context]
  end

  def test_parse_create_args_with_empty_array
    args = []
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_create_args(args)

    assert_equal "", result[:title]
    assert_equal "current", result[:context]
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
    args = ["v.0.9.0+034", "--depends-on", "v.0.9.0+031"]
    result = Ace::Taskflow::Molecules::TaskArgParser.parse_dependency_args(args)

    assert_equal "v.0.9.0+034", result[:task_ref]
    assert_equal "v.0.9.0+031", result[:depends_on_ref]
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
end
