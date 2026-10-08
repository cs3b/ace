# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/assign/authority/campaign_consumer_policy"

module Ace
  module Assign
    class CampaignConsumerPolicyTest < AceAssignTestCase
      class Protection
        def root_path!(_path); end
        def verify!(_path, handle, directory:)
          raise Ace::Runtime::RuntimeUnavailableError, "unsupported fixture" unless directory ? handle.stat.directory? : handle.stat.file?
        end
      end

      def policy
        {"revision" => "v1", "minimum_rounds" => 3, "clean_rounds" => 2, "required_scopes" => ["full"], "required_checks" => ["tests"]}
      end

      def with_policy(bytes)
        Dir.mktmpdir("campaign-policy-", File.realpath(Etc.getpwuid(Process.uid).dir)) do |root|
          path = File.join(root, "policy.json")
          File.binwrite(path, bytes)
          ref = {"path" => path, "bytes" => bytes.bytesize, "sha256" => Digest::SHA256.hexdigest(bytes)}
          artifacts = Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: Protection.new)
          yield Authority::CampaignConsumerPolicy.new(artifacts: artifacts), ref, root
        end
      end

      def document(profiles)
        JSON.generate("schema" => "ace.review.consumer-policy/v1", "profiles" => profiles)
      end

      def test_strict_current_policy_bytes_and_complete_bounded_profiles
        base = document("delivery" => policy)
        exact = document("delivery" => policy.merge("revision" => "v" * (65_536 - base.bytesize + 2)))
        assert_equal 65_536, exact.bytesize
        with_policy(exact) { |owner, ref, _| owner.with(ref) { |profiles, _| assert_equal 65_536 - base.bytesize + 2, profiles.fetch("delivery").fetch("revision").bytesize } }
        with_policy(document(32.times.to_h { |index| ["profile-#{index}", policy] })) do |owner, ref, _|
          owner.with(ref) do |profiles, artifacts|
            assert_equal 32, profiles.size
            assert profiles.frozen?
            assert profiles.fetch("profile-0").fetch("required_scopes").frozen?
            assert artifacts.verify_unchanged!
          end
        end
        [document(33.times.to_h { |index| ["profile-#{index}", policy] }), document("bad/name" => policy),
          '{"schema":"ace.review.consumer-policy/v1","profiles":{"delivery":null,"delivery":null}}',
          JSON.generate("schema" => "ace.review.consumer-policy/v1", "profiles" => {}, "extra" => true),
          document("delivery" => policy.merge("minimum_rounds" => 3.0)), "\xff".b].each do |bytes|
          with_policy(bytes) { |owner, ref, _| assert_raises(AttemptErrors::EvidenceUnavailable) { owner.with(ref) { flunk } } }
        end
        with_policy(document("delivery" => nil)) do |owner, ref, _|
          owner.with(ref) { |profiles, _| assert_nil profiles.fetch("delivery") }
          [ref.merge("bytes" => 65_537), ref.merge("bytes" => ref.fetch("bytes") + 1),
            ref.merge("sha256" => "f" * 64), ref.merge("path" => File.dirname(ref.fetch("path")) + "/../policy.json")].each do |wrong|
            assert_raises(AttemptErrors::EvidenceUnavailable) { owner.with(wrong) { flunk } }
          end
        end
      end

      def test_held_policy_replacement_refuses_and_consumer_errors_are_not_mislabeled
        with_policy(document("delivery" => policy)) do |owner, ref, root|
          assert_raises(AttemptErrors::EvidenceUnavailable) do
            owner.with(ref) do |_profiles, _|
              replacement = File.join(root, "replacement")
              File.binwrite(replacement, File.binread(ref.fetch("path")))
              File.rename(replacement, ref.fetch("path"))
            end
          end
          error = ArgumentError.new("consumer bug")
          observed = assert_raises(ArgumentError) { owner.with(ref) { raise error } }
          assert_same error, observed
        end
      end

      def test_protected_policy_enforces_root_modes_and_access_and_default_acl
        acl = Struct.new(:access, :default) do
          def entries(_path, attribute: nil) = attribute ? self.default : access
        end.new
        mounts = Object.new
        mounts.define_singleton_method(:mount_identity) { |_handle| {"filesystem_type" => "ext4"} }
        stat = Struct.new(:uid, :mode, :kind) do
          def file? = kind == :file
          def directory? = kind == :directory
        end.new(0, 0640, :file)
        handle = Struct.new(:stat).new(stat)
        protection = Authority::CampaignConsumerPolicy::Protection.new(acl: acl, mounts: mounts)
        assert_nil protection.verify!("/fixed/policy", handle, directory: false)
        acl.access = ["named entry"]
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { protection.verify!("/fixed/policy", handle, directory: false) }
        acl.access = nil; stat.kind = :directory; stat.mode = 0750; acl.default = ["default entry"]
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { protection.verify!("/fixed", handle, directory: true) }
        acl.default = nil; stat.kind = :file; stat.uid = 13001; stat.mode = 0640
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { protection.verify!("/fixed/policy", handle, directory: false) }
        stat.uid = 0; stat.mode = 0660
        assert_raises(Ace::Runtime::RuntimeUnavailableError) { protection.verify!("/fixed/policy", handle, directory: false) }
      end
    end
  end
end
