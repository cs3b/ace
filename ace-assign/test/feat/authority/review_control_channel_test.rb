# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/launch_control_channel"

module Ace
  module Assign
    class ReviewControlChannelTest < AceAssignTestCase
      WIRE = Ace::Runtime::Molecules::ProtectedSocket

      def request_frame
        {"version" => 1, "type" => "launch_review_delegate", "attempt_id" => "attempt",
          "mutation_id" => "request", "request_event_id" => "a" * 64,
          "journal_commit" => "b" * 40, "original_binding_digest" => "c" * 64}
      end

      def assigned(frame)
        frame.slice("mutation_id", "request_event_id", "original_binding_digest").merge(
          "version" => 1, "type" => "launch_review_assigned", "assignment_event_id" => "d" * 64,
          "journal_commit" => "e" * 40)
      end

      def with_channel
        left, right = UNIXSocket.pair
        codec = Object.new # Bodyless review must never use the transfer codec.
        channel = Authority::LaunchControlChannel.new(socket: left, codec: codec,
          outcome: ->(*) { flunk "review cannot use prompt completion" })
        owner = Thread.new { channel.serve }
        yield channel, right
      ensure
        channel&.close
        left&.close
        right&.close
        assert owner.join(3), "controlled channel must finish" if owner
      end

      def test_actual_socket_review_exchange_uses_existing_reserved_capacity_without_body
        with_channel do |channel, peer|
          reservation = channel.reserve_dispatch!
          assert_raises(AttemptErrors::Conflict) { channel.reserve_dispatch! }
          request = Thread.new { channel.dispatch_review(frame: request_frame, deadline: WIRE.deadline(2), reservation: reservation) }
          received = WIRE.read(peer, deadline: WIRE.deadline(2))
          assert_equal request_frame, received
          response = assigned(received)
          WIRE.write(peer, response, deadline: WIRE.deadline(2))
          assert request.join(3)
          assert_equal response, request.value
          refute channel.dispatch_reserved?(reservation)
          replacement = channel.reserve_dispatch!
          channel.release_dispatch!(replacement)
        ensure
          channel.close
          request&.join(3)
        end
      end

      def test_mismatched_reply_closes_channel_and_never_becomes_an_assignment
        with_channel do |channel, peer|
          reservation = channel.reserve_dispatch!
          request = Thread.new do
            channel.dispatch_review(frame: request_frame, deadline: WIRE.deadline(2), reservation: reservation)
          rescue AttemptErrors::EvidenceUnavailable => error
            error
          end
          received = WIRE.read(peer, deadline: WIRE.deadline(2))
          WIRE.write(peer, assigned(received).merge("request_event_id" => "f" * 64), deadline: WIRE.deadline(2))
          assert request.join(3)
          assert_instance_of AttemptErrors::EvidenceUnavailable, request.value
          assert channel.closed?
        ensure
          channel.close
          request&.join(3)
        end
      end

      def test_closed_control_schemas_refuse_wrong_types_selectors_and_extra_fields
        valid = request_frame
        assert Authority::LaunchControlChannel.validate_review!(valid)
        [valid.merge("version" => 1.0), valid.merge("attempt_id" => ""), valid.merge("mutation_id" => "x" * 300),
          valid.merge("journal_commit" => "b" * 41), valid.merge("request_event_id" => "z" * 64), valid.merge("text" => "hidden")].each do |bad|
          assert_raises(AttemptErrors::EvidenceUnavailable) { Authority::LaunchControlChannel.validate_review!(bad) }
        end
        response = assigned(valid)
        assert Authority::LaunchControlChannel.validate_review_assigned!(response, valid)
        [response.merge("version" => 1.0), response.merge("journal_commit" => "e" * 41),
          response.merge("assignment_event_id" => "bad"), response.merge("mutation_id" => "foreign"),
          response.merge("original_binding_digest" => "f" * 64), response.merge("approved" => true)].each do |bad|
          assert_raises(AttemptErrors::EvidenceUnavailable) { Authority::LaunchControlChannel.validate_review_assigned!(bad, valid) }
        end
      end
    end
  end
end
