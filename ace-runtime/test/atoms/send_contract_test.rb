# frozen_string_literal: true

require "test_helper"

module Ace
  module Runtime
    module Atoms
      class SendContractTest < AceRuntimeTestCase
        def test_unknown_profile_is_a_usage_error
          error = assert_raises(ArgumentError) do
            SendContract.normalize!(command: "run", items: [], profile: :teleport)
          end

          assert_match(/unknown send profile/, error.message)
        end

        def test_empty_send_is_rejected_for_both_profiles
          [:plain_pane, :agent_aware].each do |profile|
            error = assert_raises(SendRejectedError) do
              SendContract.normalize!(command: nil, items: [], profile: profile)
            end

            assert_match(/requires content/, error.message)
          end
        end

        def test_items_must_be_single_key_hashes
          [{foo: "x"}, {message: "a", key: "b"}, "raw"].each do |bad_item|
            error = assert_raises(SendRejectedError) do
              SendContract.normalize!(command: nil, items: [bad_item], profile: :plain_pane)
            end

            assert_match(/items\[0\]/, error.message)
          end
        end

        def test_item_values_are_validated
          error = assert_raises(SendRejectedError) do
            SendContract.normalize!(command: nil, items: [{message: 42}], profile: :plain_pane)
          end

          assert_match(/message must be a non-empty String/, error.message)

          error = assert_raises(SendRejectedError) do
            SendContract.normalize!(command: nil, items: [{key: "  "}], profile: :plain_pane)
          end

          assert_match(/key must be a non-empty key name/, error.message)
        end

        def test_only_message_and_key_kinds_are_accepted
          error = assert_raises(SendRejectedError) do
            SendContract.normalize!(command: nil, items: [{blob: "x"}], profile: :plain_pane)
          end

          assert_match(/must use :message or :key/, error.message)
        end

        def test_string_and_symbol_item_keys_are_equivalent
          request = SendContract.normalize!(
            command: nil,
            items: [{"message" => "hi"}, {"key" => "Enter"}],
            profile: :plain_pane
          )

          assert_equal [{message: "hi"}, {key: "Enter"}], request.items
        end

        def test_command_requires_key_only_items
          error = assert_raises(SendRejectedError) do
            SendContract.normalize!(command: "run", items: [{message: "hi"}], profile: :plain_pane)
          end

          assert_match(/items must be post-command keys only/, error.message)
        end

        def test_blank_command_counts_as_no_command
          request = SendContract.normalize!(command: "   ", items: [{message: "hi"}], profile: :plain_pane)

          assert_nil request.command
        end

        def test_plain_pane_preserves_order
          request = SendContract.normalize!(
            command: nil,
            items: [{message: "one"}, {key: "Enter"}, {message: "two"}],
            profile: :plain_pane
          )

          assert_equal :plain_pane, request.profile
          assert_nil request.command
          assert_equal [{message: "one"}, {key: "Enter"}, {message: "two"}], request.items
          refute request.dropped_trailing_enter
        end

        def test_plain_pane_command_yields_single_submission_shape
          request = SendContract.normalize!(command: "run", items: [{key: "C-c"}], profile: :plain_pane)

          assert_equal "run", request.command
          assert_equal [{key: "C-c"}], request.items
          refute request.dropped_trailing_enter
        end

        def test_agent_aware_command_becomes_single_prompt
          request = SendContract.normalize!(command: "Reply with: pong", items: [], profile: :agent_aware)

          assert_nil request.command
          assert_equal [{message: "Reply with: pong"}], request.items
          refute request.dropped_trailing_enter
        end

        def test_agent_aware_messages_concatenate_into_one_prompt
          request = SendContract.normalize!(
            command: nil,
            items: [{message: "line one"}, {message: "line two"}],
            profile: :agent_aware
          )

          assert_equal [{message: "line one\nline two"}], request.items
          refute request.dropped_trailing_enter
        end

        def test_agent_aware_single_trailing_enter_is_dropped_and_reported
          request = SendContract.normalize!(
            command: nil,
            items: [{message: "hello"}, {key: "Enter"}],
            profile: :agent_aware
          )

          assert_equal [{message: "hello"}], request.items
          assert request.dropped_trailing_enter
        end

        def test_agent_aware_command_with_single_trailing_enter_is_dropped_and_reported
          request = SendContract.normalize!(command: "run", items: [{key: "Enter"}], profile: :agent_aware)

          assert_equal [{message: "run"}], request.items
          assert request.dropped_trailing_enter
        end

        def test_agent_aware_enter_matching_is_case_insensitive
          request = SendContract.normalize!(command: nil, items: [{message: "hello"}, {key: "enter"}], profile: :agent_aware)

          assert request.dropped_trailing_enter
        end

        def test_agent_aware_keys_only_is_accepted
          request = SendContract.normalize!(command: nil, items: [{key: "C-c"}, {key: "C-r"}], profile: :agent_aware)

          assert_equal [{key: "C-c"}, {key: "C-r"}], request.items
          refute request.dropped_trailing_enter
        end

        def test_agent_aware_keys_between_messages_rejected
          error = assert_raises(SendRejectedError) do
            SendContract.normalize!(
              command: nil,
              items: [{message: "a"}, {key: "C-c"}, {message: "b"}],
              profile: :agent_aware
            )
          end

          assert_match(/reject interleaved input/, error.message)
        end

        def test_agent_aware_multiple_enters_rejected
          error = assert_raises(SendRejectedError) do
            SendContract.normalize!(command: nil, items: [{message: "a"}, {key: "Enter"}, {key: "Enter"}], profile: :agent_aware)
          end

          assert_match(/at most one Enter/, error.message)

          error = assert_raises(SendRejectedError) do
            SendContract.normalize!(command: nil, items: [{key: "Enter"}, {key: "Enter"}], profile: :agent_aware)
          end

          assert_match(/at most one Enter/, error.message)
        end

        def test_agent_aware_command_with_messages_rejected
          error = assert_raises(SendRejectedError) do
            SendContract.normalize!(command: "run", items: [{message: "hi"}], profile: :agent_aware)
          end

          assert_match(/items must be post-command keys only/, error.message)
        end

        def test_agent_aware_command_with_non_enter_key_rejected
          error = assert_raises(SendRejectedError) do
            SendContract.normalize!(command: "run", items: [{key: "C-c"}], profile: :agent_aware)
          end

          assert_match(/only supports a single trailing Enter/, error.message)
        end

        def test_agent_aware_messages_with_non_enter_key_rejected
          error = assert_raises(SendRejectedError) do
            SendContract.normalize!(command: nil, items: [{message: "a"}, {key: "C-c"}], profile: :agent_aware)
          end

          assert_match(/reject interleaved input/, error.message)
        end

        def test_convenience_request_shapes
          command = SendContract.command_request(command: "run", profile: :plain_pane)
          keys = SendContract.keys_request(%w[C-c Enter], profile: :plain_pane)

          assert_equal "run", command.command
          assert_equal [{key: "C-c"}, {key: "Enter"}], keys.items
        end
      end
    end
  end
end
