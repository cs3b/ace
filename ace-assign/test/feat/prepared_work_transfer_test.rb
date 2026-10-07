# frozen_string_literal: true
require_relative "../test_helper"
require "ace/assign/authority/prepared_work"
require "ace/assign/authority/prepared_queue"
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
            "job.yaml" => "session:\n  name: test\nsteps:\n- number: '010.01'\n  name: execute\n  context: fork\n  taskref: 8wr.t.qk0.3\n", "steps/010.01-execute.st.md" => "---\nname: execute\nstatus: pending\ncontext: fork\ntaskref: 8wr.t.qk0.3\n---\nDo work.\n",
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

      def test_production_export_round_trips_exact_prepared_tree_and_retains_complete_bundle
        with_tree do |root, files, _head, _tree, _bytes|
          work = Authority::PreparedWork.new(files: files)
          exported = Authority::CandidateTransfer.new(root: root).export_prepared(work: work)
          assert exported.frozen?
          assert exported.fetch("bundle").frozen?
          assert_equal Digest::SHA256.hexdigest(exported.fetch("bundle")), exported.fetch("sha256")
          admitted = Authority::PreparedWork.admit(root: root, bytes: exported.fetch("bundle"),
            size: exported.fetch("bytes"), sha256: exported.fetch("sha256"),
            head: exported.fetch("head"), tree: exported.fetch("tree"))
          assert_equal files, admitted.files
          assert_equal work.selection_sha256, admitted.selection_sha256
          assert_equal admitted.definition_bytes(head: exported.fetch("head"), tree: exported.fetch("tree")),
            exported.fetch("definition_bytes")
          assert_empty Dir.children(root).select { |name| name.start_with?("prepared-export-", "quarantine-") }
          assert_raises(AttemptErrors::ReceiptRejected) do
            Authority::CandidateTransfer.new(root: root).export_prepared(work: files)
          end
        end
      end

      def test_actual_default_leaf_producer_job_and_materialized_selected_steps_are_admitted
        Dir.mktmpdir("prepared-default-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          task_id = "8wr.t.qk0.3"
          manager = Object.new
          manager.define_singleton_method(:show) { |_| Struct.new(:status).new("pending") }
          executor = Organisms::AssignmentExecutor.new(cache_base: root)
          creator = Organisms::TaskAssignmentCreator.new(task_manager: manager, executor: executor)
          result = Ace::Assign.stub(:cache_dir, root) do
            creator.call(task_refs: [task_id, "8wr.t.qk0.1"], project_id: "ace")
          end
          assignment = result.fetch(:assignment)
          assert_equal "ace", assignment.project_id
          assert_equal "ace", executor.assignment_manager.load(assignment.id).project_id
          job_bytes = File.binread(result.fetch(:job_path))
          job = YAML.safe_load(job_bytes, permitted_classes: [Time, Date])
          selected = job.fetch("steps").select { |step| step["context"] == "fork" && step["taskref"] == task_id }
          assert_equal 1, selected.length
          scope = selected.first.fetch("number")
          files = {"definition.json" => JSON.generate(assignment.to_h), "job.yaml" => job_bytes,
            "context/#{task_id}/spec.md" => "---\nid: #{task_id}\nstatus: pending\nneeds_review: false\ndependencies: []\n---\nReviewed.\n",
            "context/#{task_id}/bundle.txt" => "Exact reviewed task instructions.\n"}
          steps = Dir.children(assignment.steps_dir).filter_map do |filename|
            next unless filename.end_with?(".st.md")
            number = filename.split("-", 2).first
            next unless number == scope || number.start_with?(scope + ".")
            files["steps/" + filename] = File.binread(File.join(assignment.steps_dir, filename))
            [number, filename]
          end.sort_by { |number, _| number.split(".").map(&:to_i) }
          record = ->(path) { {"filename" => path, "bytes" => files.fetch(path).bytesize, "sha256" => Digest::SHA256.hexdigest(files.fetch(path))} }
          manifest = {"version" => 1, "assignment_id" => assignment.id, "project_id" => "ace", "task_id" => task_id, "scope" => scope,
            "job" => record.call("job.yaml"), "steps" => steps.map { |number, filename| record.call("steps/" + filename).merge("filename" => filename, "number" => number) },
            "context" => [{"uri" => "task://#{task_id}", "task_id" => task_id, "spec" => record.call("context/#{task_id}/spec.md"), "text" => record.call("context/#{task_id}/bundle.txt"), "reports" => []}]}
          files["manifest.json"] = Authority::PreparedWork.canonical_manifest(manifest) + "\n"
          work = Authority::PreparedWork.new(files: files)
          assert_equal job_bytes, work.files.fetch("job.yaml").b
          assert_operator steps.length, :>, 1
          assert_equal scope, work.manifest.fetch("scope")
          descriptor = work.reference(head: "a" * 40, tree: "b" * 40).merge("assignment_id" => assignment.id,
            "mapping_id" => "mapping", "attempt_id" => "launch-original", "original_worker_scratch_root" => root)
          File.chmod(0700, root)
          queue = Authority::PreparedQueue.new(work: work, descriptor: descriptor)
          assert_equal scope, queue.activate_original!.number
          queue.with_executor do |selected_executor|
            state = selected_executor.status.fetch(:state)
            assert_equal steps.map(&:first), state.steps.map(&:number)
            assert_equal scope, state.current.number
            assert_equal job_bytes, File.binread(File.join(queue.directory, "job.yaml"))
            started = selected_executor.start_step(fork_root: scope).fetch(:started)
            assert started.number.start_with?(scope + ".")
            assert_equal :active, started.status
            selected_executor.fail("Selected child failed.", fork_root: scope)
            assert_equal :failed, selected_executor.status.fetch(:state).find_by_number(started.number).status
          end
          assert_raises(AttemptErrors::EvidenceUnavailable) { queue.activate_original! }
        end
      end
    end
  end
end
