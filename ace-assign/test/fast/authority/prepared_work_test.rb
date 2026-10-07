# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/prepared_work"

module Ace
  module Assign
    class PreparedWorkTest < AceAssignTestCase
      def fixture(step: "---\nname: execute\nstatus: pending\ncontext: fork\ntaskref: 8wr.t.qk0.3\n---\nDo exact work.\n")
        files = {"definition.json" => JSON.generate({"session_id" => "batch", "project_id" => "ace", "task_id" => "8wr.t.qk0.3"}),
          "job.yaml" => "assignment:\n  name: test\nsteps: []\n", "steps/010.01-execute.st.md" => step,
          "context/8wr.t.qk0.3/spec.md" => "---\nid: 8wr.t.qk0.3\nstatus: pending\nneeds_review: false\ndependencies: []\n---\nReviewed task.\n", "context/8wr.t.qk0.3/bundle.txt" => "Exact captured instruction.\n"}
        record = lambda { |path| {"filename" => path, "bytes" => files.fetch(path).bytesize, "sha256" => Digest::SHA256.hexdigest(files.fetch(path))} }
        manifest = {"version" => 1, "assignment_id" => "batch", "project_id" => "ace", "task_id" => "8wr.t.qk0.3", "scope" => "010.01",
          "job" => record.call("job.yaml"), "steps" => [record.call("steps/010.01-execute.st.md").merge("filename" => "010.01-execute.st.md", "number" => "010.01")],
          "context" => [{"uri" => "task://8wr.t.qk0.3", "task_id" => "8wr.t.qk0.3", "spec" => record.call("context/8wr.t.qk0.3/spec.md"), "text" => record.call("context/8wr.t.qk0.3/bundle.txt"), "reports" => []}]}
        files["manifest.json"] = Authority::PreparedWork.canonical_manifest(manifest) + "\n"
        files
      end

      def test_binds_exact_bytes_and_derives_non_circular_definition
        files = fixture
        work = Authority::PreparedWork.new(files: files)
        ref = work.reference(head: "a" * 40, tree: "b" * 40)
        value = JSON.parse(work.definition_bytes(head: "a" * 40, tree: "b" * 40))
        assert_equal ref, value.fetch("prepared_work")
        assert_equal Digest::SHA256.hexdigest(files.fetch("manifest.json")), ref.fetch("manifest_sha256")
        files["steps/010.01-execute.st.md"] = "changed"
        assert_match "Do exact work", work.files.fetch("steps/010.01-execute.st.md")
        assert work.manifest.frozen?
      end

      def test_refuses_substitution_extra_inventory_and_noncanonical_manifest
        [lambda { |files| files["job.yaml"] += "changed" }, lambda { |files| files["extra"] = "undeclared" },
          lambda { |files| files["manifest.json"] = " " + files["manifest.json"] }, lambda { |files| files["context/8wr.t.qk0.3/bundle.txt"] = "\xff".b }].each do |mutation|
          files = fixture; mutation.call(files)
          assert_raises(ArgumentError) { Authority::PreparedWork.new(files: files) }
        end
      end

      def test_duplicate_yaml_pending_and_filename_are_not_bypassed_by_matching_hashes
        ["---\nname: execute\nstatus: pending\nstatus: done\n---\nbody", "---\nname: execute\nstatus: active\n---\nbody", "---\nname: other\nstatus: pending\n---\nbody"].each do |step|
          assert_raises(ArgumentError) { Authority::PreparedWork.new(files: fixture(step: step)) }
        end
      end

      def test_progress_projection_keeps_work_and_ignores_only_closed_progress
        before = fixture.fetch("steps/010.01-execute.st.md")
        progressed = before.sub("status: pending", "status: done\ncompleted_at: 2026-10-07")
        assert_equal Authority::PreparedWork.work_projection(before), Authority::PreparedWork.work_projection(progressed)
        refute_equal Authority::PreparedWork.work_projection(before), Authority::PreparedWork.work_projection(progressed.sub("Do exact work", "Do different work"))
        refute_equal Authority::PreparedWork.work_projection(before), Authority::PreparedWork.work_projection(progressed.sub("context: fork", "context: inline"))
      end

      def replace_captured(files, path, content)
        files[path] = content
        manifest = JSON.parse(files.fetch("manifest.json"))
        visit = lambda do |node|
          if node.is_a?(Hash)
            if node["filename"] == path
              node["bytes"] = content.bytesize; node["sha256"] = Digest::SHA256.hexdigest(content)
            end
            node.each_value { |value| visit.call(value) }
          elsif node.is_a?(Array)
            node.each { |value| visit.call(value) }
          end
        end
        visit.call(manifest)
        files["manifest.json"] = Authority::PreparedWork.canonical_manifest(manifest) + "\n"
      end

      def test_authenticated_hashes_cannot_override_review_status_or_dependency_closure
        ["needs_review: true", "status: done", "dependencies: [missing]", "dependencies: [8wr.t.qk0.3]"].each do |change|
          files = fixture
          content = files.fetch("context/8wr.t.qk0.3/spec.md")
          key = change.split(":").first
          replace_captured(files, "context/8wr.t.qk0.3/spec.md", content.sub(/^#{key}:.*$/, change))
          assert_raises(ArgumentError) { Authority::PreparedWork.new(files: files) }
        end
      end

      def test_actual_job_refuses_typed_key_collisions_and_deep_nesting
        ["true: first\nTRUE: second\n", "1: first\n01: second\n", "!!int 1: value\n", "---\nsteps: []\n---\nsteps: changed\n", "value: .nan\n", "steps: " + "[" * 100 + "x" + "]" * 100 + "\n"].each do |job|
          files = fixture; replace_captured(files, "job.yaml", job)
          error = assert_raises(ArgumentError) { Authority::PreparedWork.new(files: files) }
          assert_match "prepared_input_invalid", error.message
        end
      end

      def test_version_is_integer_not_numerically_equal_json_float
        files = fixture
        manifest = JSON.parse(files.fetch("manifest.json")); manifest["version"] = 1.0
        files["manifest.json"] = Authority::PreparedWork.canonical_manifest(manifest) + "\n"
        assert_raises(ArgumentError) { Authority::PreparedWork.new(files: files) }
      end

      def test_rejects_oversized_text_and_wrong_git_identity
        files = fixture; files["job.yaml"] = "x" * (Authority::PreparedWork::MAX_TEXT + 1)
        assert_raises(ArgumentError) { Authority::PreparedWork.new(files: files) }
        work = Authority::PreparedWork.new(files: fixture)
        assert_raises(ArgumentError) { work.reference(head: "main", tree: "b" * 40) }
      end
    end
  end
end
