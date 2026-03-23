# frozen_string_literal: true

require_relative "../test_helper"

class GroupedStatsFormatterTest < AceGitTestCase
  def setup
    super
    @formatter = Ace::Git::Atoms::GroupedStatsFormatter
  end

  def grouped_data
    {
      groups: [
        {
          name: "ace-git/",
          additions: 10,
          deletions: 3,
          file_count: 2,
          layers: [
            {
              name: "lib/",
              additions: 10,
              deletions: 3,
              file_count: 2,
              files: [
                {display_path: "cli/diff.rb", additions: 7, deletions: 1, binary: false},
                {display_path: "assets/logo.bin", additions: nil, deletions: nil, binary: true}
              ]
            }
          ]
        }
      ],
      total: {additions: 10, deletions: 3, files: 2}
    }
  end

  def test_format_plain_includes_totals_and_binary_marker
    output = @formatter.format(grouped_data)

    assert_match(/\+10,\s+-3\s+2 files\s+total/, output)
    assert_match(/ace-git\//, output)
    refute_match(/🧱 lib\//, output)
    assert_match(/assets\/logo\.bin \(binary\)/, output)
  end

  def test_format_plain_no_blank_lines_within_group
    output = @formatter.format(grouped_data)
    lines = output.split("\n")

    # Find the group header line index
    group_header_idx = lines.index { |l| l.include?("ace-git/") }
    refute_nil group_header_idx, "expected group header line"

    # No blank line immediately after group header
    refute_equal "", lines[group_header_idx + 1],
      "expected no blank line after group header"
  end

  def test_format_markdown_wraps_large_groups_in_details
    output = @formatter.format(grouped_data, markdown: true, collapse_above: 1)

    assert_match(/<details>/, output)
    assert_match(/<summary>ace-git\//, output)
    assert_match(/```text/, output)
    refute_match(/🧱 lib\//, output)
  end

  def test_non_mapped_layer_name_remains_plain
    data = {
      groups: [{
        name: "pkg/", additions: 2, deletions: 1, file_count: 1,
        layers: [{
          name: "other/", additions: 2, deletions: 1, file_count: 1,
          files: [{display_path: "pkg/docs/readme.md", additions: 2, deletions: 1, binary: false}]
        }]
      }],
      total: {additions: 2, deletions: 1, files: 1}
    }

    output = @formatter.format(data)
    refute_match(/other\//, output)
    refute_match(/misc\//, output)
    assert_match(/pkg\/docs\/readme\.md/, output)
    refute_match(/📚|🧪|🧱/, output)
  end

  def test_squashes_consecutive_renames_in_same_directory
    data = {
      groups: [{
        name: "pkg/", additions: 10, deletions: 5, file_count: 3,
        layers: [{
          name: "lib/", additions: 10, deletions: 5, file_count: 3,
          files: [
            {display_path: "pkg/atoms/old_parser.rb -> pkg/atoms/new_parser.rb", additions: 5, deletions: 3, binary: false},
            {display_path: "pkg/atoms/old_grouper.rb -> pkg/atoms/new_grouper.rb", additions: 5, deletions: 2, binary: false},
            {display_path: "pkg/cli/old_cmd.rb -> pkg/cli/new_cmd.rb", additions: 0, deletions: 0, binary: false}
          ]
        }]
      }],
      total: {additions: 10, deletions: 5, files: 3}
    }
    output = @formatter.format(data)

    # First rename: compact shared prefix once
    assert_match(/pkg\/atoms\/old_parser\.rb -> new_parser\.rb/, output)
    # Second rename in same dir: squashed (no repeated dir prefix)
    refute_match(/pkg\/atoms\/old_grouper\.rb/, output)
    assert_match(/old_grouper\.rb -> .*new_grouper\.rb/, output)
    # Third rename in different dir: full path again
    assert_match(/pkg\/cli\/old_cmd\.rb -> pkg\/cli\/new_cmd\.rb/, output)
  end

  def test_compacts_single_rename_with_shared_prefix
    data = {
      groups: [{
        name: ".ace-taskflow/", additions: 1, deletions: 1, file_count: 1,
        layers: [{
          name: "other/", additions: 1, deletions: 1, file_count: 1,
          files: [{
            display_path: "v.0.9.0/tasks/284-task-assign-rethink/284-ace-assign-phase-lifec.s.md -> v.0.9.0/tasks/_archive/284-task-assign-rethink/284-ace-assign-phase-lifec.s.md",
            additions: 1, deletions: 1, binary: false
          }]
        }]
      }],
      total: {additions: 1, deletions: 1, files: 1}
    }

    output = @formatter.format(data)
    assert_match(/v\.0\.9\.0\/tasks\/284-task-assign-rethink\/284-ace-assign-phase-lifec\.s\.md -> _archive\/284-task-assign-rethink\/284-ace-assign-phase-lifec\.s\.md/, output)
  end

  def test_non_rename_after_rename_shows_full_path
    data = {
      groups: [{
        name: "pkg/", additions: 8, deletions: 2, file_count: 2,
        layers: [{
          name: "lib/", additions: 8, deletions: 2, file_count: 2,
          files: [
            {display_path: "pkg/atoms/old.rb -> pkg/atoms/new.rb", additions: 5, deletions: 2, binary: false},
            {display_path: "pkg/atoms/other.rb", additions: 3, deletions: 0, binary: false}
          ]
        }]
      }],
      total: {additions: 8, deletions: 2, files: 2}
    }
    output = @formatter.format(data)

    assert_match(/pkg\/atoms\/other\.rb/, output)
  end

  def test_squashes_repeated_directory_prefix
    data = {
      groups: [{
        name: "pkg/", additions: 10, deletions: 0, file_count: 3,
        layers: [{
          name: "lib/", additions: 10, deletions: 0, file_count: 3,
          files: [
            {display_path: "pkg/atoms/parser.rb", additions: 3, deletions: 0, binary: false},
            {display_path: "pkg/atoms/grouper.rb", additions: 4, deletions: 0, binary: false},
            {display_path: "pkg/cli/command.rb", additions: 3, deletions: 0, binary: false}
          ]
        }]
      }],
      total: {additions: 10, deletions: 0, files: 3}
    }
    output = @formatter.format(data)

    assert_match(/pkg\/atoms\/parser\.rb/, output)       # first: full path
    assert_match(/^\s+\+4.*grouper\.rb/, output)        # second: basename only
    refute_match(/pkg\/atoms\/grouper\.rb/, output)      # no repeated prefix
    assert_match(/pkg\/cli\/command\.rb/, output)        # different dir: full path
  end

  def test_project_root_renders_single_header_with_dot_slash
    data = {
      groups: [{
        name: "./", additions: 6, deletions: 1, file_count: 2,
        layers: [{
          name: "root/", additions: 6, deletions: 1, file_count: 2,
          files: [
            {display_path: "CHANGELOG.md", additions: 5, deletions: 1, binary: false},
            {display_path: "README.md", additions: 1, deletions: 0, binary: false}
          ]
        }]
      }],
      total: {additions: 6, deletions: 1, files: 2}
    }

    output = @formatter.format(data)
    assert_match(/\.\/$/, output.lines[2].strip)
    refute_match(/root\//, output)
  end

  def test_compacts_layer_header_when_summary_matches_group
    data = {
      groups: [{
        name: ".ace/", additions: 5, deletions: 0, file_count: 1,
        layers: [{
          name: "test/", additions: 5, deletions: 0, file_count: 1,
          files: [{display_path: "suite.yml", additions: 5, deletions: 0, binary: false}]
        }]
      }],
      total: {additions: 5, deletions: 0, files: 1}
    }

    output = @formatter.format(data)
    assert_match(/\.ace\//, output)
    refute_match(/🧪 test\//, output)
    assert_match(/suite\.yml/, output)
  end

  def test_header_icon_uses_dedicated_column_for_group_and_layer
    data = {
      groups: [{
        name: "ace-overseer/", additions: 4, deletions: 4, file_count: 3,
        layers: [{
          name: "test/", additions: 3, deletions: 3, file_count: 2,
          files: [
            {display_path: "e2e/TC-005-prune-workflow.runner.md", additions: 2, deletions: 2, binary: false},
            {display_path: "e2e/TC-005-prune-workflow.verify.md", additions: 1, deletions: 1, binary: false}
          ]
        }]
      }],
      total: {additions: 4, deletions: 4, files: 3}
    }

    output = @formatter.format(data)
    lines = output.split("\n")
    group_line = lines.find { |line| line.include?("ace-overseer/") }
    layer_line = lines.find { |line| line.include?("🧪 test/") }

    refute_nil group_line
    refute_nil layer_line
    assert_match(/files\s{6}ace-overseer\//, group_line)
    assert_match(/files\s{3}🧪 test\//, layer_line)
  end

  def test_file_name_uses_same_name_column_as_headers
    data = {
      groups: [{
        name: "ace-overseer/", additions: 4, deletions: 4, file_count: 3,
        layers: [{
          name: "test/", additions: 3, deletions: 3, file_count: 2,
          files: [
            {display_path: "e2e/TC-005-prune-workflow.runner.md", additions: 2, deletions: 2, binary: false},
            {display_path: "e2e/TC-005-prune-workflow.verify.md", additions: 1, deletions: 1, binary: false}
          ]
        }]
      }],
      total: {additions: 4, deletions: 4, files: 3}
    }

    output = @formatter.format(data)
    lines = output.split("\n")
    group_line = lines.find { |line| line.include?("ace-overseer/") }
    file_line = lines.find { |line| line.include?("e2e/TC-005-prune-workflow.runner.md") }

    refute_nil group_line
    refute_nil file_line
    assert_equal group_line.index("ace-overseer/"), file_line.index("e2e/TC-005-prune-workflow.runner.md")
  end
end
