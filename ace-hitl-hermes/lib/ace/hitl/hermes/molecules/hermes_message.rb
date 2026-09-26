# frozen_string_literal: true

require "json"
require "time"
require_relative "../atoms/hermes_tokens"

module Ace
  module Hitl
    module Hermes
      module Molecules
        # Typed message envelope for schema ace.hitl.hermes.message/v1
        # (spec 8wm.t.vs1 §3). One message per file; the payload id MUST
        # equal the file name stem. Validation is fail closed and names
        # every violated rule. The Captain's answer file shape is exactly
        # {schema, id, kind: "answer", answer, sender, received_at}.
        class HermesMessage
          TIMESTAMP_PATTERN = /\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/
          KINDS = %w[question answer].freeze

          EXPECTED_FIELDS = {
            "question" => %w[schema id kind sender question created_at],
            "answer" => %w[schema id kind sender answer received_at]
          }.freeze

          attr_reader :schema, :id, :kind, :sender, :body, :timestamp_field, :timestamp

          def self.question(id:, question:, sender:, created_at:)
            new(
              id: id, kind: :question, sender: sender,
              body_field: "question", body: question,
              timestamp_field: "created_at", timestamp: created_at
            )
          end

          def self.answer(id:, answer:, sender:, received_at:)
            new(
              id: id, kind: :answer, sender: sender,
              body_field: "answer", body: answer,
              timestamp_field: "received_at", timestamp: received_at
            )
          end

          # Fail-closed parse of an already-decoded envelope Hash.
          # `filename_id` (when given) must equal the payload id.
          def self.from_hash(hash, filename_id: nil)
            kind_name = hash["kind"]
            unless KINDS.include?(kind_name)
              raise InvalidMessageError,
                "message kind must be one of #{KINDS.join(", ")} (got #{kind_name.inspect})"
            end

            expected = EXPECTED_FIELDS.fetch(kind_name)
            missing = expected - hash.keys
            extra = hash.keys - expected
            unless missing.empty? && extra.empty?
              raise InvalidMessageError,
                "message fields violate schema #{HermesContract::MESSAGE_SCHEMA} " \
                "(missing: #{missing.join(", ") || "none"}; " \
                "unexpected: #{extra.join(", ") || "none"})"
            end

            id = Atoms::HermesTokens.validate!(hash["id"], "message id")
            if filename_id && id != filename_id
              raise InvalidMessageError,
                "message id #{id.inspect} does not match file name stem #{filename_id.inspect}"
            end

            sender = Atoms::HermesTokens.validate!(hash["sender"], "sender")

            body_field = (kind_name == "question") ? "question" : "answer"
            body = hash[body_field]
            unless body.is_a?(String) && !body.strip.empty?
              raise InvalidMessageError, "message #{body_field} must be a non-empty string"
            end

            timestamp_field = (kind_name == "question") ? "created_at" : "received_at"
            timestamp = validate_timestamp!(hash[timestamp_field], timestamp_field)

            new(
              id: id, kind: kind_name.to_sym, sender: sender,
              body_field: body_field, body: body,
              timestamp_field: timestamp_field, timestamp: timestamp
            )
          end

          def self.validate_timestamp!(value, field)
            unless value.is_a?(String) && value.match?(TIMESTAMP_PATTERN)
              raise InvalidMessageError,
                "message #{field} must be UTC ISO-8601 YYYY-MM-DDTHH:MM:SSZ " \
                "(got #{value.inspect})"
            end

            begin
              Time.iso8601(value)
            rescue ArgumentError
              raise InvalidMessageError,
                "message #{field} is not a real calendar timestamp: #{value.inspect}"
            end
            value
          end

          def initialize(id:, kind:, sender:, body_field:, body:, timestamp_field:, timestamp:)
            @schema = HermesContract::MESSAGE_SCHEMA
            @id = id
            @kind = kind
            @sender = sender
            @body_field = body_field
            @body = body
            @timestamp_field = timestamp_field
            @timestamp = timestamp
          end

          def question?
            @kind == :question
          end

          def answer?
            @kind == :answer
          end

          def to_h
            {
              "schema" => @schema,
              "id" => @id,
              "kind" => @kind.to_s,
              "sender" => @sender,
              @body_field => @body,
              @timestamp_field => @timestamp
            }
          end

          # Canonical serialization: fixed key order, compact JSON.
          def to_json(*)
            JSON.generate(to_h)
          end
        end
      end
    end
  end
end
