# frozen_string_literal: true

require "openssl"
require "ace/runtime/molecules/protected_artifact_set"
require_relative "posix_acl"

module Ace
  module Assign
    module Authority
      # The installed descriptor selects the only key. Retained protected inode
      # and ACL checks cover the complete signing callback, not a pathname read.
      class InboxSigningKey
        class Protection < Ace::Runtime::Molecules::ProtectedArtifactSet::Protection
          def initialize(signer_uid:, acl: PosixAcl.new, **options)
            super(**options)
            @signer_uid, @acl = signer_uid, acl
          end

          def verify!(path, handle, directory:)
            super
            return if directory
            stat = handle.stat
            rows = @acl.entries(path)
            unless (stat.mode & 0o007).zero? && rows &&
                rows.select { |tag, _perm, _id| tag == 2 }.all? { |_tag, perm, uid| uid == @signer_uid && perm == 4 } &&
                rows.any? { |tag, perm, uid| tag == 2 && uid == @signer_uid && perm == 4 } &&
                rows.select { |tag, _perm, _id| [4, 8, 32].include?(tag) }.all? { |_tag, perm, _id| perm.zero? } &&
                rows.find { |tag, _perm, _id| tag == 16 }&.at(1) == 4
              raise Ace::Runtime::RuntimeUnavailableError, "receipt private key must be readable only by root and fixed signer"
            end
          end
        end

        def initialize(signer_uid:, artifacts: nil)
          @artifacts = artifacts || Ace::Runtime::Molecules::ProtectedArtifactSet.new(
            protection: Protection.new(signer_uid: signer_uid), file_limit: 16_384, total_limit: 16_384, count_limit: 1)
        end

        def with(reference:, fingerprint:)
          unless reference.is_a?(Hash) && reference.keys.sort == %w[bytes path sha256] &&
              reference["path"].is_a?(String) && reference["path"].start_with?("/") &&
              File.expand_path(reference["path"]) == reference["path"] && !reference["path"].include?("\0") &&
              reference["bytes"].is_a?(Integer) && reference["bytes"].between?(1, 16_384) &&
              [reference["sha256"], fingerprint].all? { |value| value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/) }
            raise AttemptErrors::EvidenceUnavailable, "fixed signing key reference is unavailable"
          end
          @artifacts.with do |reader|
            bytes = reader.read!(reference)
            key = OpenSSL::PKey.read(bytes)
            unless key.is_a?(OpenSSL::PKey::RSA) && key.private? && key.n.num_bits >= 2048 &&
                Digest::SHA256.hexdigest(key.public_to_der) == fingerprint
              raise AttemptErrors::EvidenceUnavailable, "fixed signing key does not match pinned event verifier"
            end
            reader.verify_unchanged!
            result = yield key, reader
            reader.verify_unchanged!
            result
          end
        rescue OpenSSL::PKey::PKeyError
          raise AttemptErrors::EvidenceUnavailable, "fixed receipt signing key is invalid"
        end
      end
    end
  end
end
