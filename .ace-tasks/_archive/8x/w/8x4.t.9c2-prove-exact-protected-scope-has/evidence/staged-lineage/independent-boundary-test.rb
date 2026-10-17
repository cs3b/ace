require_relative '../../ace-assign/test/fast/molecules/execution_scope_lineage_test'

module Ace
  module Assign
    class IndependentStagedLineageBoundaryTest < ExecutionScopeLineageTest
      def test_parent_only_closure_is_positive_but_never_launchable
        parent = bound
        sealed = seal
        proof = append('scope_closed_no_writers', proof_payload)
        2.times do
          value = reader
          assert_nil value.native_event
          assert_nil value.child_event
          assert_equal proof_payload, value.require_positive!(scope_generation: 2,
            scope_binding_event_id: parent['digest'], seal_event_id: sealed['digest'], proof_id: proof['digest'])
          assert_raises(AttemptErrors::Conflict) { value.require_launch_bound! }
        end
      end
      def test_child_after_seal_refuses_even_with_matching_retained_native_reference
        bound
        native
        seal
        child
        assert Models::EvidenceEvent.chain_valid?(@events)
        assert_raises(AttemptErrors::EvidenceUnavailable) { reader }
      end
      def test_foreign_native_digest_refuses_without_hash_corruption
        bound
        native
        append('scope_child_bound', {'scope_generation' => 2,
          'scope_binding_event_id' => @events.find { |e| e['type'] == 'scope_bound' }['digest'],
          'native_binding_event_id' => 'd' * 64, 'original_process_binding' => @original})
        assert Models::EvidenceEvent.chain_valid?(@events)
        assert_raises(AttemptErrors::EvidenceUnavailable) { reader }
      end
      def test_child_projection_is_detached_and_deeply_immutable
        bound
        native
        child
        accepted = reader.require_launch_bound!
        @original['native_origin']['command'][-1] = 'changed'
        assert_equal 'ticket', accepted['native_origin']['command'].last
        assert_raises(FrozenError) { accepted['native_origin']['command'] << 'extra' }
      end
    end
  end
end
