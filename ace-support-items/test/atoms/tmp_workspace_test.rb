# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class TmpWorkspaceTest < AceSupportItemsTestCase
  def test_create_workspace_for_label
    time = Time.new(2026, 3, 4, 10, 0, 0, "+00:00")
    partition = Ace::Support::Items::Atoms::DatePartitionPath.compute(time)
    b36ts = Ace::B36ts.encode(time)

    Dir.mktmpdir do |root|
      workspace = Ace::Support::Items::Atoms::TmpWorkspace.create(
        "feedback-synthesis",
        project_root: root,
        time: time
      )

      expected = File.join(root, ".ace-local", "tmp", partition, "#{b36ts}-feedback-synthesis")
      assert_equal expected, workspace
      assert_path_exists workspace
      assert_equal partition, workspace.match(%r{/\.ace-local/tmp/(.+?)/#{b36ts}-feedback-synthesis})[1]
    end
  end

  def test_create_workspace_requires_label
    assert_raises(ArgumentError) do
      Ace::Support::Items::Atoms::TmpWorkspace.create("", project_root: Dir.pwd)
    end
  end

  def test_create_accepts_custom_project_root
    time = Time.new(2026, 1, 1, 8, 0, 0, "+00:00")
    Dir.mktmpdir do |root|
      workspace = Ace::Support::Items::Atoms::TmpWorkspace.create(
        "gitleaks-report",
        project_root: root,
        time: time
      )

      assert_match(/^#{Regexp.escape(root)}/, workspace)
      assert_includes workspace, "/.ace-local/tmp/"
    end
  end
end
