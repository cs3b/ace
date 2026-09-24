# frozen_string_literal: true

require "test_helper"
require "tmpdir"
require "fileutils"

class ReviewPacketIntegrationTest < Minitest::Test
  def test_real_bundle_preserves_complete_diff_file
    Dir.mktmpdir("ace-review-packet") do |root|
      diff = "diff --git a/app.rb b/app.rb\n@@ -1 +1 @@\n-old\n+new\n"
      diff_path = File.join(root, "changes.patch")
      File.write(diff_path, diff)
      manager = Ace::Review::Organisms::ReviewManager.new(project_root: root)
      config = {"bundle" => {"sections" => {"pr_changes" => {
        "title" => "PR changes", "files" => [diff_path]
      }}}}
      input = manager.send(:create_context_file, root, config, nil, "review.context.md")
      output = File.join(root, "review.prompt.md")

      manifest = manager.send(:execute_ace_context, input, output, expected_content: diff)

      assert_includes File.read(output), diff
      assert_equal Digest::SHA256.hexdigest(diff), manifest[:sources].first[:sha256]
    end
  end
end
