# frozen_string_literal: true
require_relative "../test_helper"
require_relative "../support/prepared_registration_fixture"
require "ace/assign/authority/prepared_queue"

module Ace
  module Assign
    class PreparedQueueTest < AceAssignTestCase
      # Real private files/Git/queue/scanner/writer; no kernel, provider,
      # installed artifact, deployment or network boundary is constructed.
      def fixture
        Dir.mktmpdir("prepared-queue-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          definition = {"session_id" => "assignment", "name" => "prepared", "created_at" => "2026-10-07T00:00:00Z",
            "source_config" => "captured-job.yaml", "task_id" => "qk0.3", "project_id" => "project"}
          artifact = PreparedRegistrationFixture.build(root: root, definition: definition, scope: "010.01")
          descriptor = artifact.work.reference(head: artifact.head, tree: artifact.tree).merge(
            "mapping_id" => "mapping", "attempt_id" => "launch-original", "assignment_id" => "assignment",
            "original_worker_scratch_root" => root)
          queue = Authority::PreparedQueue.new(work: artifact.work, descriptor: descriptor)
          yield queue, artifact, root
        end
      end

      def test_initial_atomic_queue_uses_real_consumers_and_keeps_complete_progress
        fixture do |queue, artifact, root|
          assert_equal File.join(root, "prepared-queues", "mapping", "launch-original"), queue.cache_base
          assert_equal "010.01", queue.activate_original!.number
          assert_raises(AttemptErrors::EvidenceUnavailable) { queue.activate_original! }
          queue.with_executor do |executor|
            status = executor.status
            assert_equal :active, status.fetch(:current).status
            assert_equal "Exact fixture work.", status.fetch(:current).instructions
            executor.finish_step(report_content: "Actual report.", fork_root: "010.01")
          end
          queue.with_executor do |executor|
            status = executor.status
            assert status.fetch(:state).subtree_complete?("010.01")
            assert_equal "Actual report.", status.fetch(:state).steps.first.report
          end
          assert_nil queue.activate_original!
          assert_equal artifact.work.files.fetch("job.yaml"), File.binread(File.join(queue.directory, "job.yaml"))
          assert_empty Dir.children(queue.cache_base).select { |name| name.start_with?(".prepared-") }
        end
      end

      def test_descendant_missing_queue_never_reconstructs_and_changed_work_refuses
        fixture do |queue, _artifact, _root|
          assert_raises(AttemptErrors::EvidenceUnavailable) { queue.with_executor { flunk "must not consume missing queue" } }
          refute File.exist?(queue.directory)
          queue.activate_original!
          path = File.join(queue.directory, "steps", "010.01-execute.st.md")
          accepted = File.binread(path)
          File.binwrite(path, accepted.sub("Exact fixture work.", "Changed instructions."))
          assert_raises(AttemptErrors::EvidenceUnavailable) { queue.with_executor(&:status) }
          File.binwrite(path, accepted)
          FileUtils.rm_rf(queue.directory)
          assert_raises(AttemptErrors::EvidenceUnavailable) { queue.with_executor(&:status) }
          refute File.exist?(queue.directory)
        end
      end

      def test_queue_inventory_symlink_status_and_job_replacement_are_refused
        fixture do |queue, _artifact, root|
          queue.activate_original!
          path = File.join(queue.directory, "steps", "010.01-execute.st.md")
          original = File.binread(path)
          File.binwrite(path, original.sub("status: active", "status: invented"))
          assert_raises(AttemptErrors::EvidenceUnavailable) { queue.with_executor(&:status) }
          File.binwrite(path, original)
          File.binwrite(File.join(queue.directory, "steps", "020-extra.st.md"), original)
          assert_raises(AttemptErrors::EvidenceUnavailable) { queue.with_executor(&:status) }
          File.delete(File.join(queue.directory, "steps", "020-extra.st.md"))
          outside = File.join(root, "outside.md"); File.binwrite(outside, original)
          File.delete(path); File.symlink(outside, path)
          assert_raises(AttemptErrors::EvidenceUnavailable) { queue.with_executor(&:status) }
          File.delete(path); File.binwrite(path, original); File.chmod(0600, path)
          File.binwrite(File.join(queue.directory, "job.yaml"), "steps: []\n")
          assert_raises(AttemptErrors::EvidenceUnavailable) { queue.with_executor(&:status) }
          File.binwrite(File.join(queue.directory, "job.yaml"), queue.work.files.fetch("job.yaml"))
          metadata_path = File.join(queue.directory, "assignment.yaml")
          metadata = YAML.safe_load(File.binread(metadata_path))
          metadata["updated_at"] = []
          File.binwrite(metadata_path, metadata.to_yaml)
          assert_raises(AttemptErrors::EvidenceUnavailable) { queue.with_executor(&:status) }
        end
      end
    end
  end
end
