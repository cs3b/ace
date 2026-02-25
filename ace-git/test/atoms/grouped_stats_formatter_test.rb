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
                { display_path: "cli/diff.rb", additions: 7, deletions: 1, binary: false },
                { display_path: "assets/logo.bin", additions: nil, deletions: nil, binary: true }
              ]
            }
          ]
        }
      ],
      total: { additions: 10, deletions: 3, files: 2 }
    }
  end

  def test_format_plain_includes_totals_and_binary_marker
    output = @formatter.format(grouped_data)

    assert_match(/\+10,\s+-3\s+2 files\s+total/, output)
    assert_match(/ace-git\//, output)
    assert_match(/assets\/logo\.bin \(binary\)/, output)
  end

  def test_format_markdown_wraps_large_groups_in_details
    output = @formatter.format(grouped_data, markdown: true, collapse_above: 1)

    assert_match(/<details>/, output)
    assert_match(/<summary>ace-git\//, output)
    assert_match(/```text/, output)
  end
end
