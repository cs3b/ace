# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../support/coworker_fixture"

module Ace
  module Coworker
    module Molecules
      class AssignmentMetadataTest < AceCoworkerTestCase
        def setup
          super
          @dir = Dir.mktmpdir("coworker-meta")
          @meta = AssignmentMetadata.new(project_root: @dir)
        end

        def teardown
          FileUtils.remove_entry(@dir)
        end

        def test_unknown_assignment_raises_specific_error
          error = assert_raises(Error) { @meta.task_id!("nope12") }
          assert_equal "assignment 'nope12' not found under .ace-local/assign/nope12", error.message
        end

        def test_reads_task_id
          CoworkerFixture.build_assignment(@dir, id: "abc123", task_id: "8xg.t.sbz.2")
          assert_equal "8xg.t.sbz.2", @meta.task_id!("abc123")
        end

        def test_task_mismatch_is_a_specific_error
          CoworkerFixture.build_assignment(@dir, id: "abc123", task_id: "other.task")
          error = assert_raises(Error) { @meta.verify_task_match!("abc123", "8xg.t.sbz.2") }
          assert_equal "assignment 'abc123' belongs to task 'other.task', not '8xg.t.sbz.2'", error.message
        end

        def test_assignment_without_task_id_cannot_match
          CoworkerFixture.build_assignment(@dir, id: "abc123", task_id: "")
          error = assert_raises(Error) { @meta.verify_task_match!("abc123", "8xg.t.sbz.2") }
          assert_includes error.message, "has no task_id"
        end

        def test_matching_task_passes
          CoworkerFixture.build_assignment(@dir, id: "abc123", task_id: "8xg.t.sbz.2")
          assert_equal "8xg.t.sbz.2", @meta.verify_task_match!("abc123", "8xg.t.sbz.2")
        end

        def test_traversal_assignment_id_is_rejected
          error = assert_raises(Error) { @meta.task_id!("../escape") }
          assert_includes error.message, "invalid assignment id"
        end
      end
    end
  end
end
