# frozen_string_literal: true

require "test_helper"

class FileGrouperTest < AceGitTestCase
  def setup
    super
    @grouper = Ace::Git::Atoms::FileGrouper
  end

  def test_group_splits_package_dotfile_and_root
    entries = [
      {path: "ace-git/lib/ace/git/cli.rb", display_path: "ace-git/lib/ace/git/cli.rb", additions: 5, deletions: 1, binary: false},
      {path: "ace-git/test/commands/diff_test.rb", display_path: "ace-git/test/commands/diff_test.rb", additions: 3, deletions: 2, binary: false},
      {path: ".ace-task/v.0.9.0/tasks/281.md", display_path: ".ace-task/v.0.9.0/tasks/281.md", additions: 1, deletions: 0, binary: false},
      {path: "README.md", display_path: "README.md", additions: 2, deletions: 0, binary: false}
    ]

    result = @grouper.group(entries, layers: %w[lib test handbook], dotfile_groups: [".ace-task"])

    assert_equal 4, result[:total][:files]
    assert_equal 11, result[:total][:additions]
    assert_equal 3, result[:total][:deletions]

    names = result[:groups].map { |g| g[:name] }
    assert_includes names, "ace-git/"
    assert_includes names, ".ace-task/"
    assert_includes names, "./"
  end

  def test_group_relativizes_rename_display_path
    entries = [
      {
        path: "ace-git/lib/new_name.rb",
        display_path: "ace-git/lib/old_name.rb -> ace-git/lib/new_name.rb",
        rename_from: "ace-git/lib/old_name.rb",
        rename_to: "ace-git/lib/new_name.rb",
        additions: 4,
        deletions: 1,
        binary: false
      }
    ]

    result = @grouper.group(entries, layers: %w[lib], dotfile_groups: [])
    file_entry = result[:groups].first[:layers].first[:files].first

    assert_equal "old_name.rb -> new_name.rb", file_entry[:display_path]
  end
end
