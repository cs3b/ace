# frozen_string_literal: true

require "openssl"
require "digest"
require "ace/runtime/molecules/protected_artifact_set"
require_relative "inbox_context_store"

module Ace
  module Herdr
    module Molecules
      # Both fixed installer artifacts are read from held protected descriptors.
      class InboxContextKey
        LIMIT = 16_384
        def initialize(context_id:, public_key_path:, config_path:, artifacts: Ace::Runtime::Molecules::ProtectedArtifactSet.new)
          @context_id, @key_path, @config_path, @artifacts = context_id, public_key_path, config_path, artifacts
        end

        def snapshot
          @artifacts.with do |reader|
            key_bytes, key_ref = reader.read_path!(@key_path, limit: LIMIT)
            config_bytes, config_ref = reader.read_path!(@config_path, limit: LIMIT)
            config = InboxContextStore.decode(config_bytes, limit: LIMIT)
            unless config.is_a?(Hash) && config.keys.sort == %w[context_id key_generation public_key_sha256 schema] &&
                config["schema"] == "ace.herdr.inbox-key/v1" && config["context_id"] == @context_id &&
                config["key_generation"].is_a?(Integer) && config["key_generation"].between?(1, (1 << 63) - 1) &&
                config["public_key_sha256"] == key_ref.fetch("sha256")
              raise ValidationError, "installed context key configuration differs"
            end
            key = public_key!(key_bytes)
            reader.verify_unchanged!
            {"key_generation" => config.fetch("key_generation"),
              "fingerprint" => Digest::SHA256.hexdigest(key.public_to_der),
              "public_key_sha256" => key_ref.fetch("sha256"), "config_sha256" => config_ref.fetch("sha256")}
          end
        rescue Ace::Runtime::RuntimeUnavailableError, OpenSSL::PKey::PKeyError, KeyError
          raise ValidationError, "installed context key evidence is unavailable"
        end

        def self.public_key!(bytes)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, LIMIT)
            raise ValidationError, "context public key exceeds bounds"
          end
          key = OpenSSL::PKey.read(bytes)
          unless key.is_a?(OpenSSL::PKey::RSA) && !key.private? && key.n.num_bits >= 2048
            raise ValidationError, "context key must be public RSA"
          end
          key
        rescue OpenSSL::PKey::PKeyError
          raise ValidationError, "context public key is invalid"
        end

        private

        def public_key!(bytes) = self.class.public_key!(bytes)
      end
    end
  end
end
