# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/inbox_signing_key"

module Ace
  module Assign
    class InboxSigningKeyTest < AceAssignTestCase
      class Artifacts
        attr_accessor :changed
        attr_reader :checks
        def initialize(bytes) = (@bytes, @checks = bytes, 0)
        def with = yield self
        def read!(reference)
          raise Ace::Runtime::RuntimeUnavailableError, "digest differs" unless reference["sha256"] == Digest::SHA256.hexdigest(@bytes)
          @bytes
        end
        def verify_unchanged!
          @checks += 1
          raise Ace::Runtime::RuntimeUnavailableError, "changed" if changed
        end
      end

      def setup
        super
        @key = OpenSSL::PKey::RSA.new(2048)
        @bytes = @key.to_pem
        @reference = {"path" => "/etc/ace/fixed-key.pem", "bytes" => @bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(@bytes)}
        @fingerprint = Digest::SHA256.hexdigest(@key.public_to_der)
        @artifacts = Artifacts.new(@bytes)
        @loader = Authority::InboxSigningKey.new(signer_uid: 40, artifacts: @artifacts)
      end

      def test_fixed_key_matches_pinned_verifier_and_is_rechecked_after_callback
        result = @loader.with(reference: @reference, fingerprint: @fingerprint) do |key, _|
          key.sign(OpenSSL::Digest::SHA256.new, "exact proof")
        end
        assert @key.verify(OpenSSL::Digest::SHA256.new, result, "exact proof")
        assert_equal 2, @artifacts.checks
      end

      def test_changed_key_or_wrong_pinned_verifier_never_returns_signature
        assert_raises(AttemptErrors::EvidenceUnavailable) { @loader.with(reference: @reference, fingerprint: "a" * 64) { flunk } }
        assert_raises(Ace::Runtime::RuntimeUnavailableError) do
          @loader.with(reference: @reference, fingerprint: @fingerprint) { @artifacts.changed = true; "signature" }
        end
        assert_raises(AttemptErrors::EvidenceUnavailable) do
          @loader.with(reference: @reference.merge("path" => "/etc/ace/../key.pem"), fingerprint: @fingerprint) { flunk }
        end
      end

      def test_private_acl_excludes_other_users_groups_and_other_readers
        stat = Struct.new(:uid, :mode).new(0, 0o100640)
        stat.define_singleton_method(:file?) { true }
        handle = Struct.new(:stat).new(stat)
        mounts = Object.new
        mounts.define_singleton_method(:mount_identity) { |_| {"filesystem_type" => "ext4"} }
        rows = [[1, 6, 0xffffffff], [2, 4, 40], [4, 0, 0xffffffff], [16, 4, 0xffffffff], [32, 0, 0xffffffff]]
        acl = Object.new
        acl.define_singleton_method(:entries) { |_| rows }
        protection = Authority::InboxSigningKey::Protection.new(signer_uid: 40, acl: acl, mounts: mounts)
        protection.verify!("/fixed", handle, directory: false)
        rows << [2, 4, 41]
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { protection.verify!("/fixed", handle, directory: false) }
        rows.pop
        rows[2][1] = 4
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { protection.verify!("/fixed", handle, directory: false) }
      end

      def test_public_or_weak_key_cannot_sign
        [@key.public_to_pem, OpenSSL::PKey::RSA.new(1024).to_pem].each do |bytes|
          reference = @reference.merge("bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes))
          loader = Authority::InboxSigningKey.new(signer_uid: 40, artifacts: Artifacts.new(bytes))
          assert_raises(AttemptErrors::EvidenceUnavailable) { loader.with(reference: reference, fingerprint: @fingerprint) { flunk } }
        end
      end
    end
  end
end
