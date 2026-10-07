# frozen_string_literal: true
require_relative "../test_helper"
require "ace/assign/authority/prepared_work"
require "open3"

module Ace
  module Assign
    class PreparedWorkTransferTest < AceAssignTestCase
      def git(directory, *args)
        output, error, status = Open3.capture3("/usr/bin/git", "-C", directory, *args)
        assert status.success?, error
        output
      end

      def with_tree(mode: nil)
        Dir.mktmpdir("prepared-work-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          source = File.join(root, "source"); FileUtils.mkdir_p(source, mode: 0700)
          files = {"definition.json" => JSON.generate({"session_id" => "batch", "project_id" => "ace", "task_id" => "8wr.t.qk0.3"}),
            "job.yaml" => "assignment:\n  name: test\nsteps: []\n", "steps/010.01-execute.st.md" => "---\nname: execute\nstatus: pending\ncontext: fork\n---\nDo work.\n",
            "context/8wr.t.qk0.3/spec.md" => "---\nid: 8wr.t.qk0.3\nstatus: pending\nneeds_review: false\ndependencies: []\n---\nReviewed.\n", "context/8wr.t.qk0.3/bundle.txt" => "captured " * 5000}
          record = ->(path) { {"filename" => path, "bytes" => files.fetch(path).bytesize, "sha256" => Digest::SHA256.hexdigest(files.fetch(path))} }
          manifest = {"version" => 1, "assignment_id" => "batch", "project_id" => "ace", "task_id" => "8wr.t.qk0.3", "scope" => "010.01", "job" => record.call("job.yaml"),
            "steps" => [record.call("steps/010.01-execute.st.md").merge("filename" => "010.01-execute.st.md", "number" => "010.01")],
            "context" => [{"uri" => "task://8wr.t.qk0.3", "task_id" => "8wr.t.qk0.3", "spec" => record.call("context/8wr.t.qk0.3/spec.md"), "text" => record.call("context/8wr.t.qk0.3/bundle.txt"), "reports" => []}]}
          files["manifest.json"] = Authority::PreparedWork.canonical_manifest(manifest) + "\n"
          files.each { |path, bytes| target = File.join(source, path); FileUtils.mkdir_p(File.dirname(target)); File.binwrite(target, bytes) }
          File.chmod(0755, File.join(source, "job.yaml")) if mode == :executable
          git(source, "init", "-b", "main"); git(source, "add", ".")
          git(source, "-c", "user.name=test", "-c", "user.email=test@example.invalid", "commit", "-m", "prepared")
          head = git(source, "rev-parse", "HEAD").strip; tree = git(source, "rev-parse", "HEAD^{tree}").strip
          bundle = File.join(root, "prepared.bundle"); git(source, "bundle", "create", bundle, "--all")
          yield root, files, head, tree, File.binread(bundle)
        end
      end

      def test_actual_complete_git_transfer_reads_exact_large_context_and_immutable_definition
        with_tree do |root, files, head, tree, bytes|
          work = Authority::PreparedWork.admit(root: root, head: head, tree: tree, bytes: bytes, size: bytes.bytesize, sha256: Digest::SHA256.hexdigest(bytes))
          assert_operator work.files.fetch("context/8wr.t.qk0.3/bundle.txt").bytesize, :>, 32_768
          assert_equal files, work.files
          assert_equal head, JSON.parse(work.definition_bytes(head: head, tree: tree)).dig("prepared_work", "prepared_head")
          assert_empty Dir.children(root).select { |name| name.start_with?("quarantine-") }
        end
      end

      def test_verified_git_objects_do_not_allow_executable_instruction_files
        with_tree(mode: :executable) do |root, _files, head, tree, bytes|
          assert_raises(AttemptErrors::ReceiptRejected) do
            Authority::PreparedWork.admit(root: root, head: head, tree: tree, bytes: bytes, size: bytes.bytesize, sha256: Digest::SHA256.hexdigest(bytes))
          end
        end
      end
    end
  end
end
