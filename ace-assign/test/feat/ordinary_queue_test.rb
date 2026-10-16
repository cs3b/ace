# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/prepared_registration_fixture"
require "ace/assign/authority/ordinary_queue"

module Ace
  module Assign
    class OrdinaryQueueTest < AceAssignTestCase
      def test_progress_is_recovered_from_exact_snapshot_with_no_disposable_cache
        with_queue do |queue, work, root|
          assert_equal :pending, queue.status.steps.first.status
          running = queue.transition(operation: :activate)
          assert_equal :active, running.status.steps.first.status
          assert_empty Dir.children(root)
          restored = Authority::OrdinaryQueue.new(work: work, root: root, bytes: running.bytes)
          completed = restored.transition(operation: :finish, report: "Executed and verified.")
          assert completed.status.subtree_complete?("010.01")
          assert_equal "Executed and verified.", completed.status.steps.first.report
          assert_empty Dir.children(root)
          again = Authority::OrdinaryQueue.new(work: work, root: root, bytes: completed.bytes)
          assert_equal completed.bytes, again.bytes
          assert_raises(AttemptErrors::EvidenceUnavailable) { again.transition(operation: :activate) }
          assert_empty Dir.children(root)
        end
      end

      def test_invalid_progress_cannot_change_instructions_or_create_foreign_paths
        with_queue do |queue, work, root|
          original = JSON.parse(queue.bytes)
          [->(value) { value["steps"]["010.01-execute.st.md"].sub!("Exact fixture work.", "Different work.") },
            ->(value) { value["steps"]["010.01-execute.st.md"].sub!("pending", "invented") },
            ->(value) { value["steps"]["010.01-execute.st.md"].sub!("status: pending", "status: pending\nfork_pid_file: /foreign/writer") },
            ->(value) { value["reports"]["../../outside"] = "report" },
            ->(value) { value["steps"]["020-foreign.st.md"] = value["steps"].values.first }].each do |change|
            modified = Marshal.load(Marshal.dump(original)); change.call(modified)
            assert_raises(AttemptErrors::EvidenceUnavailable) do
              Authority::OrdinaryQueue.new(work: work, root: root, bytes: JSON.generate(modified))
            end
          end
          assert_empty Dir.children(root)
        end
      end

      private

      def with_queue
        Dir.mktmpdir("ordinary-queue-test-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          artifact = PreparedRegistrationFixture.build(root: root, scope: "010.01", definition: {
            "session_id" => "batch", "name" => "delivery", "created_at" => "2026-10-16T00:00:00Z",
            "source_config" => "job.yaml", "task_id" => "8xf.t.ei9.0", "project_id" => "atlas"})
          yield Authority::OrdinaryQueue.new(work: artifact.work, root: root), artifact.work, root
        end
      end
    end
  end
end
