# frozen_string_literal: true

require "json"
require "digest"

module Ace
  module Herdr
    module Molecules
      # One operational identity, not a delivery ledger. Both owners serialize
      # the same closed fields before an effect or canonical acknowledgement.
      module InboxContextEffectBinding
        FIELDS = %w[schema project_id assignment_id attempt_id mapping_id inbox_context_id event_id
          mutation_id operation_id key_generation registration receipt_sha256 signature_sha256].freeze
        REGISTRATION_FIELDS = %w[event_id attempt_id payload_sha256 receipt_key_sha256].freeze
        TOKEN = /\A[A-Za-z0-9][A-Za-z0-9._-]{0,127}\z/
        DIGEST = /\A[0-9a-f]{64}\z/
        module_function

        def verify!(value)
          unless value.is_a?(Hash) && value.keys.sort == FIELDS.sort &&
              value["schema"] == "ace.herdr.inbox-context-effect/v1" &&
              %w[project_id assignment_id attempt_id mapping_id inbox_context_id event_id mutation_id].all? { |key|
                value[key].is_a?(String) && TOKEN.match?(value[key]) } &&
              value["operation_id"].is_a?(String) && value["operation_id"].match?(/\A[0-9a-f]{32}\z/) &&
              value["key_generation"].is_a?(Integer) && value["key_generation"].between?(1, (1 << 63) - 1) &&
              %w[receipt_sha256 signature_sha256].all? { |key| digest?(value[key]) }
            raise ValidationError, "context effect binding differs"
          end
          registration = value["registration"]
          unless registration.is_a?(Hash) && registration.keys.sort == REGISTRATION_FIELDS.sort &&
              registration.values_at("event_id", "attempt_id") == value.values_at("event_id", "attempt_id") &&
              %w[payload_sha256 receipt_key_sha256].all? { |key| digest?(registration[key]) }
            raise ValidationError, "context effect registration differs"
          end
          FIELDS.to_h { |field| [field.freeze, field == "registration" ?
            REGISTRATION_FIELDS.to_h { |key| [key.freeze, registration.fetch(key).dup.freeze] }.freeze :
            value.fetch(field).is_a?(String) ? value.fetch(field).dup.freeze : value.fetch(field)] }.freeze
        end

        def digest(value) = Digest::SHA256.hexdigest(JSON.generate(verify!(value))).freeze
        def digest?(value) = value.is_a?(String) && DIGEST.match?(value)
      end
    end
  end
end
