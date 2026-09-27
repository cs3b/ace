# frozen_string_literal: true

require "securerandom"
require_relative "errors"
require_relative "identity"
require_relative "atomic_json"
require_relative "kinds"

module Ace
  module Hitl
    module Lifecycle
      # The Root Overseer's bounded response channel — the reverse
      # address of the HITL conversation (spec 8wm.t.y21 §6; ports of
      # overseer-send/overseer-pending/overseer-ack). Responses are
      # bounded, type-tagged, and free of internal identifiers; the
      # transport that relays them is NOT part of this surface.
      class Overseer
        MAX_RESPONSE = 1200
        TYPE_TAGS = %w[[decyzja] [pytanie] [info]].freeze
        TYPE_TAG = /\A\[(decyzja|pytanie|info)\]/i

        FULL_SHA = /\b[0-9a-fA-F]{40,64}\b/
        ATTEMPT_REFERENCE = /\bA-[0-9a-fA-F]{24}\b/
        WORK_REFERENCE = /\bW[0-9]{3,}\b/
        TASK_REFERENCE = /\b[0-9a-z]{3,}\.t\.[0-9a-z.]+\b/i
        SHA_WORD = /\bSHA(?:-?256)?\b/i

        attr_reader :outbox_dir

        def initialize(outbox_dir:, overseer_user: "mo", ownership: AtomicJson::DEFAULT_OWNERSHIP,
          identity: Identity)
          @outbox_dir = Pathname.new(outbox_dir)
          @overseer_user = overseer_user
          @ownership = ownership
          @identity = identity
        end

        # Queue one bounded, type-tagged response (read from the reader,
        # e.g. stdin). Only the overseer user may respond.
        def send_response(reader:, reply_to: "")
          unless @identity.username == @overseer_user
            raise PermissionError, "only the Root Overseer can send channel responses"
          end
          reply_to = reply_to.to_s
          if !reply_to.empty? && (!/\A\d+\z/.match?(reply_to) || reply_to.length > 32)
            raise StateError, "invalid source message id"
          end

          response = reader.call(MAX_RESPONSE + 1).to_s.strip
          if response.empty? || response.length > MAX_RESPONSE || response.include?("\u0000")
            raise StateError, "response must contain 1-#{MAX_RESPONSE} characters"
          end
          unless TYPE_TAG.match?(response)
            raise StateError,
              "response must open with a type tag: #{TYPE_TAGS.join(", ")}"
          end
          if FULL_SHA.match?(response) || ATTEMPT_REFERENCE.match?(response) ||
              WORK_REFERENCE.match?(response) || TASK_REFERENCE.match?(response) ||
              SHA_WORD.match?(response)
            raise StateError,
              "rewrite for Captain without SHA, Work/Attempt/task IDs, hashes, or internal references"
          end

          message_id = "msg-#{SecureRandom.hex(8)}"
          value = {
            "id" => message_id,
            "reply_to_message_id" => reply_to,
            "response" => response,
            "created_at" => Time.now.to_i,
            "requester" => @overseer_user
          }
          AtomicJson.call(@outbox_dir.join("#{message_id}.json"), value, mode: 0o600, ownership_strategy: @ownership)
          response.clear
          {
            "id" => message_id,
            "queued" => true,
            "reply_to_message_id" => reply_to
          }
        end

        # Root-only drain view of the outbox.
        def pending
          require_root!("overseer-pending")
          @outbox_dir.glob("*.json").sort.filter_map { |path| AtomicJson.read(path) }
        end

        # Root-only acknowledgement: the transport removes one response
        # exactly once it has been relayed.
        def ack(message_id)
          require_root!("overseer-ack")
          id = message_id.to_s
          raise StateError, "invalid message id" unless Kinds::REQUEST_ID.match?(id)

          path = @outbox_dir.join("#{id}.json")
          raise StateError, "unknown Overseer response" unless path.exist?

          path.unlink
          {"id" => id, "acknowledged" => true}
        end

        private

        def require_root!(operation)
          unless @identity.root?
            raise Lifecycle::PermissionError, "#{operation} is a host-broker operation"
          end
        end
      end
    end
  end
end
