# frozen_string_literal: true
require "json"
require_relative "managed_envelope"

module Ace
  module Hitl
    module Contract
      # A question has a real local requester and project, but no execution or
      # effect authority. Its closed schema cannot carry managed/OTP grants.
      class OperatorEnvelope
        SCHEMA = "ace.hitl.operator-question/v1"
        FIELDS = %w[schema context request_id request_incarnation project requester requester_uid
          correlation_id kind payload_sha256 input_sha256].freeze

        def self.load(value, expected: {})
          data = value.is_a?(String) ? JSON.parse(value) : JSON.parse(JSON.generate(value))
          unless data.is_a?(Hash) && data.keys.sort == FIELDS.sort && data["schema"] == SCHEMA &&
              data["context"] == "operator-question" && data["kind"] == "question"
            raise InvalidEnvelope, "invalid closed operator question envelope"
          end
          %w[request_id project requester correlation_id].each do |key|
            unless data[key].is_a?(String) && ManagedEnvelope::TOKEN.match?(data[key])
              raise InvalidEnvelope, "invalid operator #{key}"
            end
          end
          unless data["request_incarnation"].is_a?(String) && data["request_incarnation"].match?(/\A[0-9a-f]{16}\z/) &&
              data["requester_uid"].is_a?(Integer) && data["requester_uid"] >= 0 &&
              data["correlation_id"] == data["request_id"] &&
              %w[payload_sha256 input_sha256].all? { |key|
                data[key].is_a?(String) && ManagedEnvelope::DIGEST.match?(data[key]) }
            raise InvalidEnvelope, "invalid operator question identity or input digest"
          end
          expected.each do |key, wanted|
            raise InvalidEnvelope, "operator #{key} differs from authoritative binding" unless data[key.to_s] == wanted
          end
          data
        rescue JSON::ParserError, JSON::GeneratorError, TypeError => e
          raise InvalidEnvelope, "invalid operator envelope JSON (#{e.class})"
        end
      end
    end
  end
end
