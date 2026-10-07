# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/launch_control_channel"
require "ace/assign/authority/launch_driver"

module Ace
  module Assign
    class LaunchControlChannelTest < AceAssignTestCase
      WIRE = Ace::Runtime::Molecules::ProtectedSocket
      def deadline = WIRE.deadline(2)
      def with_channel
        Dir.mktmpdir("launch-channel-", Etc.getpwuid(Process.uid).dir) do |root|
          File.chmod(0700, root)
          reader, writer = UNIXSocket.pair
          codec = Authority::TransferCodec.new(root: root)
          results = []
          channel = Authority::LaunchControlChannel.new(socket: reader, codec: codec, outcome: ->(result) {
            raise "callback channel was closed" if channel.closed?
            results << result
            {"outcome" => result.dig("guarded_evidence", "outcome"), "journal_commit" => "b" * 40}
          })
          server = Thread.new { channel.serve }
          yield channel, writer, codec, results
        ensure
          channel&.close
          reader&.close
          writer&.close
          server&.join
        end
      end

      def frame(codec, body, id = "prompt")
        {"version" => 1, "type" => "prompt_dispatch", "mutation_id" => id, "attempt_id" => "attempt",
          "intent_event_id" => "a" * 64, "journal_commit" => "b" * 40, "original_binding_digest" => "c" * 64,
          "transfer_id" => "d" * 32, "text_descriptor" => codec.descriptor([body], purpose: :prompt_text)}
      end

      def reply(frame)
        frame.slice("mutation_id", "intent_event_id", "original_binding_digest").merge("version" => 1,
          "type" => "prompt_dispatch_outcome", "guarded_evidence" => {"outcome" => "uncertain", "origin" => {}})
      end

      def dispatch(channel, **options)
        reservation = channel.reserve_dispatch!
        channel.dispatch_prompt(**options, reservation: reservation)
      ensure
        channel.release_dispatch!(reservation) if reservation
      end

      def test_two_dispatches_and_original_owner_outcome_ingestion_do_not_hold_channel_mutex
        with_channel do |channel, socket, codec, results|
          ["first secret", "second secret"].each_with_index do |body, index|
            dispatch = frame(codec, body, "prompt-#{index}")
            request = Thread.new { dispatch(channel, frame: dispatch, bytes: body, deadline: deadline) }
            actual = WIRE.read(socket, deadline: deadline)
            assert_equal dispatch, actual
            accepted = codec.receive_launch_prompt(socket, descriptor: actual.fetch("text_descriptor"),
              transfer_id: actual.fetch("transfer_id"), deadline: deadline) { |input| input.bytes }
            assert_equal body, accepted
            # The source callback is able to acquire the channel mutex too.
            refute channel.closed?
            WIRE.write(socket, reply(actual), deadline: deadline)
            recorded = WIRE.read(socket, deadline: deadline)
            assert Authority::LaunchControlChannel.validate_recorded!(recorded, dispatch, reply(actual).fetch("guarded_evidence"))
            assert_equal reply(actual), request.value
          end
          assert_equal 2, results.length
        end
      end

      def test_wrong_outcome_attribution_closes_channel_without_accepted_owner_evidence
        with_channel do |channel, socket, codec, results|
          dispatch = frame(codec, "secret")
          request = Thread.new do
            dispatch(channel, frame: dispatch, bytes: "secret", deadline: deadline)
          rescue AttemptErrors::EvidenceUnavailable => error
            error
          end
          actual = WIRE.read(socket, deadline: deadline)
          codec.receive_launch_prompt(socket, descriptor: actual.fetch("text_descriptor"),
            transfer_id: actual.fetch("transfer_id"), deadline: deadline) { |input| input.bytes }
          WIRE.write(socket, reply(actual).merge("intent_event_id" => "f" * 64), deadline: deadline)
          assert_instance_of AttemptErrors::EvidenceUnavailable, request.value
          assert_empty results
          assert channel.closed?
        end
      end

      def test_owner_close_wakes_waiting_dispatch_and_never_claims_no_issuance
        with_channel do |channel, socket, codec, results|
          dispatch = frame(codec, "secret")
          request = Thread.new do
            dispatch(channel, frame: dispatch, bytes: "secret", deadline: deadline)
          rescue AttemptErrors::EvidenceUnavailable => error
            error
          end
          WIRE.read(socket, deadline: deadline)
          channel.close
          assert_instance_of AttemptErrors::EvidenceUnavailable, request.value
          assert_empty results
        end
      end

      def test_frame_refuses_unknown_field_and_oversized_extra_parts_before_queue
        with_channel do |channel, _socket, codec, results|
          dispatch = frame(codec, "secret")
          [dispatch.merge("version" => 1.0), dispatch.merge("journal_commit" => "b" * 41), dispatch.merge("native_path" => "/tmp/other"), dispatch.merge("intent_event_id" => "other"),
            dispatch.merge("text_descriptor" => codec.descriptor(["a", "b"], purpose: :artifacts))].each do |invalid|
            assert_raises(AttemptErrors::EvidenceUnavailable, AttemptErrors::ReceiptRejected) do
              dispatch(channel, frame: invalid, bytes: "secret", deadline: deadline)
            end
          end
          assert_empty results
        end
      end

      def test_delayed_retained_completion_is_reported_before_opening_control_stream_and_only_once
        driver = Authority::LaunchDriver.allocate
        state = {"phase" => "issued", "assignment_id" => "assignment", "attempt_id" => "attempt"}
        id = "a" * 64
        evidence = {"outcome" => "submitted"}
        driver.instance_variable_set(:@issued_state, state)
        driver.instance_variable_set(:@steering_binding, {})
        driver.instance_variable_set(:@seen_prompt_intents, {id => evidence})
        driver.instance_variable_set(:@prompt_issuance_refs, {id => {"intent_event_id" => id}})
        entered = Queue.new
        finish = Queue.new
        calls = []
        client = Object.new
        client.define_singleton_method(:call) do |operation, params, **options|
          calls << operation
          entered << true
          finish.pop
          Authority::Client::Reply.new(data: {"intent_event_id" => id, "outcome" => "submitted", "journal_commit" => "b" * 40})
        end
        client.define_singleton_method(:with_launch_control) do |**|
          calls << :control
          driver.request_control_cancel
          raise AttemptErrors::EvidenceUnavailable, "controlled connection ended"
        end
        driver.instance_variable_set(:@client, client)
        owner = Thread.new { driver.serve_control!(state: state) { flunk "No ready connection in this fixture" } }
        entered.pop
        assert_equal ["launch_prompt_completion"], calls
        finish << true
        owner.join(2)
        refute owner.alive?
        assert_equal ["launch_prompt_completion", :control], calls
        driver.send(:report_retained_prompt_completions!, state)
        assert_equal ["launch_prompt_completion", :control], calls
      ensure
        finish << true if finish
        driver&.request_control_cancel
        owner&.join(2)
      end

      def test_reserved_capacity_excludes_another_issue_before_enqueue_and_can_be_released_after_failed_admission
        with_channel do |channel, _socket, _codec, _results|
          original = channel.reserve_dispatch!
          assert channel.dispatch_reserved?(original)
          assert_raises(AttemptErrors::Conflict) { channel.reserve_dispatch! }
          channel.release_dispatch!(Object.new)
          assert channel.dispatch_reserved?(original)
          channel.release_dispatch!(original)
          refute channel.dispatch_reserved?(original)
          replacement = channel.reserve_dispatch!
          refute_same original, replacement
          channel.release_dispatch!(replacement)
        end
      end

      def test_client_private_ready_refuses_inexact_commit_length_and_float_version
        client = Authority::Client.allocate
        state = {"attempt_id" => "attempt"}
        ready = {"version" => 1, "type" => "launch_control_ready", "attempt_id" => "attempt",
          "generation" => 1, "journal_commit" => "a" * 40, "original_binding_digest" => "b" * 64}
        assert client.send(:validate_launch_control_ready!, ready, state)
        [ready.merge("journal_commit" => "a" * 41), ready.merge("version" => 1.0)].each do |invalid|
          assert_raises(AttemptErrors::EvidenceUnavailable) { client.send(:validate_launch_control_ready!, invalid, state) }
        end
      end

      def test_canonical_recorded_ack_refuses_wrong_issue_outcome_commit_and_float_version
        codec = Authority::TransferCodec.new
        dispatch = frame(codec, "secret")
        evidence = {"outcome" => "submitted"}
        recorded = dispatch.slice("mutation_id", "intent_event_id", "original_binding_digest").merge(
          "version" => 1, "type" => "prompt_outcome_recorded", "outcome" => "submitted", "journal_commit" => "b" * 40)
        assert Authority::LaunchControlChannel.validate_recorded!(recorded, dispatch, evidence)
        [recorded.merge("intent_event_id" => "f" * 64), recorded.merge("outcome" => "uncertain"),
          recorded.merge("journal_commit" => "b" * 41), recorded.merge("version" => 1.0)].each do |invalid|
          assert_raises(AttemptErrors::EvidenceUnavailable) { Authority::LaunchControlChannel.validate_recorded!(invalid, dispatch, evidence) }
        end
      end
    end
  end
end
