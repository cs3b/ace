# frozen_string_literal: true

require "json"
require "digest"
require "time"
require_relative "ref"
require_relative "secret_gate"

module Ace
  module Hitl
    module Contract
      class InvalidEnvelope < ArgumentError; end

      # Pure wire vocabulary, owned semantically by HITL. Validation proves
      # structure and exact correlation only, never actor/effect authority.
      # Transport message.v1 and Herdr's reverse address stay separate schemas.
      class ManagedEnvelope
        SCHEMA = "ace.hitl.managed/v1"
        REQUIRED = %w[schema request_id request_incarnation project assignment_id attempt_id requester correlation_id kind reverse].freeze
        OPTIONAL = %w[payload_sha256 message effect].freeze
        TOKEN = /\A[A-Za-z0-9][A-Za-z0-9._:-]{0,127}\z/
        COMPACT = /\A[0-9a-z][0-9a-z]{4,63}\z/
        DIGEST = /\A[0-9a-f]{64}\z/
        KINDS = %w[text choice confirm review question decision verification otp proposal].freeze
        MESSAGE_SCHEMA = "ace.hitl.hermes.message/v1"

        def self.inbox_event_id(value)
          data = load(value)
          raise InvalidEnvelope, "OTP has no ordinary native inbox event" if data["kind"] == "otp"
          "inb-#{Digest::SHA256.hexdigest([data['request_id'], data['request_incarnation']].join(':'))[0, 32]}"
        end

        def self.load(value, expected: {})
          data = value.is_a?(String) ? JSON.parse(value) : JSON.parse(JSON.generate(value))
          raise InvalidEnvelope, "managed envelope must be an object" unless data.is_a?(Hash)
          missing = REQUIRED - data.keys
          unknown = data.keys - REQUIRED - OPTIONAL
          raise InvalidEnvelope, "managed envelope fields differ (missing #{missing.join(',')}; unknown #{unknown.join(',')})" unless missing.empty? && unknown.empty?
          raise InvalidEnvelope, "unsupported managed envelope version" unless data["schema"] == SCHEMA
          %w[request_id request_incarnation project requester correlation_id].each { |key| token!(data[key], key) }
          %w[assignment_id attempt_id].each do |key|
            raise InvalidEnvelope, "invalid #{key}" unless data[key].is_a?(String) && COMPACT.match?(data[key])
          end
          raise InvalidEnvelope, "unsupported managed request kind" unless KINDS.include?(data["kind"])
          reverse!(data["reverse"])
          if data["kind"] == "otp"
            if data.key?("payload_sha256") || data.key?("effect") || (data.key?("message") && data.dig("message", "kind") != "question")
              raise InvalidEnvelope, "OTP envelope cannot contain payload digest, folder answer or effect"
            end
          else
            raise InvalidEnvelope, "invalid non-secret payload digest" unless data["payload_sha256"].is_a?(String) && DIGEST.match?(data["payload_sha256"])
          end
          message!(data["message"], data) if data.key?("message")
          effect!(data["effect"]) if data.key?("effect")
          expected.each do |key, wanted|
            raise InvalidEnvelope, "managed #{key} does not match authoritative binding" unless data[key.to_s] == wanted
          end
          data
        rescue JSON::ParserError, JSON::GeneratorError, TypeError => e
          raise InvalidEnvelope, "invalid managed envelope JSON (#{e.class})"
        end

        def self.reverse!(value)
          return if value.nil? # Explicit pane-less consume, never a fallback target.
          unless value.is_a?(Hash) && value.keys.sort == %w[pane schema session] && value["schema"] == Providers::Ref::SCHEMA
            raise InvalidEnvelope, "invalid reverse address schema"
          end
          %w[session pane].each { |key| Providers::Ref.validate!(value[key], "reverse.#{key}") }
        rescue Providers::InvalidRefError => e
          raise InvalidEnvelope, e.message
        end

        def self.message!(value, envelope)
          unless value.is_a?(Hash) && value["schema"] == MESSAGE_SCHEMA && value["id"] == envelope["correlation_id"]
            raise InvalidEnvelope, "folder message correlation/version differs"
          end
          kind = value["kind"]
          body_key, time_key = {"question" => %w[question created_at], "answer" => %w[answer received_at]}[kind]
          raise InvalidEnvelope, "unsupported folder message kind" unless body_key
          unless value.keys.sort == ["schema", "id", "kind", "sender", body_key, time_key].sort
            raise InvalidEnvelope, "invalid folder message fields"
          end
          token!(value["sender"], "message.sender")
          body = value[body_key]
          unless body.is_a?(String) && body.valid_encoding? && !body.strip.empty? && !body.include?("\0")
            raise InvalidEnvelope, "invalid folder message body"
          end
          # Conservative secret gate shared with the ordinary folder boundary.
          if kind == "answer" && SecretGate::PATTERN.match?(body)
            raise InvalidEnvelope, "secret-bearing folder answers are prohibited"
          end
          if envelope.key?("payload_sha256") && envelope["payload_sha256"] != Digest::SHA256.hexdigest(body)
            raise InvalidEnvelope, "folder payload digest differs"
          end
          unless value[time_key].is_a?(String) && value[time_key].match?(/\A\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z\z/)
            raise InvalidEnvelope, "invalid folder message timestamp"
          end
          begin
            parsed = Time.iso8601(value[time_key])
            unless parsed.utc.strftime("%Y-%m-%dT%H:%M:%SZ") == value[time_key]
              raise ArgumentError, "non-canonical calendar components"
            end
          rescue ArgumentError
            raise InvalidEnvelope, "invalid folder message timestamp"
          end
        end

        def self.effect!(value)
          unless value.is_a?(Hash) && (value.keys - %w[authorization_ref receipt_ref]).empty? && value.key?("authorization_ref")
            raise InvalidEnvelope, "effect requires an authorization reference"
          end
          value.each { |key, item| token!(item, "effect.#{key}") }
        end

        def self.token!(value, label)
          raise InvalidEnvelope, "invalid #{label}" unless value.is_a?(String) && TOKEN.match?(value)
        end
        private_class_method :reverse!, :message!, :effect!, :token!
      end
    end
  end
end
