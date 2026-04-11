# frozen_string_literal: true

require_relative "../test_helper"

class DiffNumstatParserTest < AceGitTestCase
  def setup
    super
    @parser = Ace::Git::Atoms::DiffNumstatParser
  end

  def test_parse_standard_numstat_lines
    output = "93\t25\tace-task/lib/ace/taskflow/organisms/task_manager.rb\n1\t1\tace-task/lib/ace/taskflow/version.rb"

    result = @parser.parse(output)

    assert_equal 2, result.length
    assert_equal "ace-task/lib/ace/taskflow/organisms/task_manager.rb", result[0][:path]
    assert_equal 93, result[0][:additions]
    assert_equal 25, result[0][:deletions]
    refute result[0][:binary]
  end

  def test_parse_binary_line_sets_binary_flag
    output = "-\t-\tace-task/test/fixtures/archive.bin"

    result = @parser.parse(output)

    assert_equal 1, result.length
    assert result[0][:binary]
    assert_nil result[0][:additions]
    assert_nil result[0][:deletions]
  end

  def test_parse_rename_line_uses_arrow_display
    output = "7\t2\tace-git/lib/{old_name.rb => new_name.rb}"

    result = @parser.parse(output)

    assert_equal 1, result.length
    assert_equal "ace-git/lib/new_name.rb", result[0][:path]
    assert_equal "ace-git/lib/old_name.rb -> ace-git/lib/new_name.rb", result[0][:display_path]
    assert_equal "ace-git/lib/old_name.rb", result[0][:rename_from]
    assert_equal "ace-git/lib/new_name.rb", result[0][:rename_to]
  end

  def test_parse_brace_rename_with_empty_left_side
    output = "1\t1\t.ace-task/v.0.9.0/tasks/{ => _archive}/284-task-assign-rethink/284-ace-assign-phase-lifec.s.md"

    result = @parser.parse(output)

    assert_equal 1, result.length
    assert_equal ".ace-task/v.0.9.0/tasks/_archive/284-task-assign-rethink/284-ace-assign-phase-lifec.s.md", result[0][:path]
    assert_equal ".ace-task/v.0.9.0/tasks/284-task-assign-rethink/284-ace-assign-phase-lifec.s.md -> .ace-task/v.0.9.0/tasks/_archive/284-task-assign-rethink/284-ace-assign-phase-lifec.s.md", result[0][:display_path]
    assert_equal ".ace-task/v.0.9.0/tasks/284-task-assign-rethink/284-ace-assign-phase-lifec.s.md", result[0][:rename_from]
    assert_equal ".ace-task/v.0.9.0/tasks/_archive/284-task-assign-rethink/284-ace-assign-phase-lifec.s.md", result[0][:rename_to]
  end
end
