# frozen_string_literal: true

require "digest"
require "json"
require "openssl"

module Ace
  module Herdr
    module Molecules
      # Shared receipt authenticity; neither filesystem selection nor native
      # discovery belongs here. The retained event owner supplies exact context.
      module InboxReceiptAuthentication
        module_function

        def signature_refusal(key:, key_sha256:, receipt:, signed_bytes:, signature:)
          return "trusted receipt public key is unavailable" unless key.is_a?(OpenSSL::PKey::RSA) && !key.private?
          return "trusted receipt public key differs from the enqueued event" unless
            Digest::SHA256.hexdigest(key.public_to_der) == key_sha256
          return "receipt signature is missing" unless signed_bytes.is_a?(String) && signature.is_a?(String)
          parsed = JSON.parse(signed_bytes.dup.force_encoding(Encoding::UTF_8), create_additions: false,
            max_nesting: 32, allow_duplicate_key: false, allow_comments: false)
          return "signed receipt content differs from parsed receipt" unless parsed == receipt
          return "receipt signature is invalid" unless key.verify(OpenSSL::Digest::SHA256.new, signature, signed_bytes)
          nil
        rescue JSON::ParserError, EncodingError, OpenSSL::PKey::PKeyError
          "receipt signature is invalid"
        end

        def proof_refusal(receipt)
          return "invalid reconciliation outcome" unless %w[consumed superseded].include?(receipt["outcome"])
          observer = receipt["observer"]
          unless observer.is_a?(Hash) && %w[operator supervisor].include?(observer["role"]) &&
              observer["id"].is_a?(String) && !observer["id"].strip.empty?
            return "receipt requires an identified operator or supervisor"
          end
          evidence = receipt["evidence"]
          kinds = receipt["outcome"] == "consumed" ? %w[consumed_acknowledged] :
            %w[queue_evicted queue_expired thread_replaced]
          unless evidence.is_a?(Hash) && kinds.include?(evidence["kind"]) &&
              evidence["native_reference"].is_a?(String) && !evidence["native_reference"].strip.empty? &&
              evidence["observation"].is_a?(String) && !evidence["observation"].strip.empty?
            return "receipt requires a native outcome observation and reference"
          end
          nil
        end
      end
    end
  end
end
