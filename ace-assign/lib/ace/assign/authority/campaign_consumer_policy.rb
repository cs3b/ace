# frozen_string_literal: true
require "json"
require "ace/runtime/molecules/protected_artifact_set"
require_relative "campaign_execution"
require_relative "posix_acl"

module Ace
  module Assign
    module Authority
      # One accepted descriptor reference, held for the entire store/CAS guard.
      # There is deliberately no ordinary review configuration cascade here.
      class CampaignConsumerPolicy
        class Protection < Ace::Runtime::Molecules::ProtectedArtifactSet::Protection
          def initialize(acl: PosixAcl.new, **options)
            super(**options)
            @acl = acl
          end

          def verify!(path, handle, directory:)
            super
            unless @acl.entries(path).nil? && (!directory || @acl.entries(path, attribute: "system.posix_acl_default").nil?)
              raise Ace::Runtime::RuntimeUnavailableError, "campaign policy ACL differs"
            end
          end
        end
        def self.reference!(reference)
          unless reference.is_a?(Hash) && reference.keys.sort == %w[bytes path sha256] &&
              reference["path"].is_a?(String) && reference["path"].encoding == Encoding::UTF_8 &&
              reference["path"].valid_encoding? && reference["path"].bytesize.between?(1, 4096) &&
              !reference["path"].include?("\0") && reference["path"].start_with?("/") &&
              File.expand_path(reference["path"]) == reference["path"] &&
              reference["sha256"].is_a?(String) && reference["sha256"].match?(/\A[0-9a-f]{64}\z/) &&
              reference["bytes"].is_a?(Integer) && reference["bytes"].between?(1, 65_536)
            raise ArgumentError, "invalid campaign consumer policy reference"
          end
          reference
        end

        def initialize(artifacts: Ace::Runtime::Molecules::ProtectedArtifactSet.new(protection: Protection.new))
          @artifacts = artifacts
        end

        def with(reference)
          begin
            self.class.reference!(reference)
          rescue ArgumentError
            unavailable!
          end
          @artifacts.with do |artifacts|
            profiles = read_profiles!(artifacts, reference)
            verify_artifacts!(artifacts)
            result = yield profiles, artifacts
            verify_artifacts!(artifacts)
            result
          end
        end

        private

        def read_profiles!(artifacts, reference)
          bytes = artifacts.read!(reference).dup.force_encoding(Encoding::UTF_8)
          raise ArgumentError, "campaign consumer policy is not UTF-8" unless bytes.valid_encoding?
          value = JSON.parse(bytes, create_additions: false, max_nesting: 16,
            allow_duplicate_key: false, allow_comments: false)
          unless value.is_a?(Hash) && value.keys.sort == %w[profiles schema] &&
              value["schema"] == "ace.review.consumer-policy/v1" && value["profiles"].is_a?(Hash) &&
              value["profiles"].size <= 32
            raise ArgumentError, "campaign consumer policy fields differ"
          end
          profiles = value.fetch("profiles").to_h do |id, policy|
            CampaignExecution::Contract.id!(id, "consumer profile")
            [id, policy.nil? ? nil : CampaignExecution::Contract.policy!(policy)]
          end
          freeze_value!(profiles)
          profiles
        rescue ArgumentError, KeyError, TypeError, JSON::ParserError, Ace::Runtime::RuntimeUnavailableError, SystemCallError, IOError
          unavailable!
        end

        def verify_artifacts!(artifacts)
          artifacts.verify_unchanged!
        rescue Ace::Runtime::RuntimeUnavailableError, SystemCallError, IOError
          unavailable!
        end

        def unavailable!
          raise AttemptErrors::EvidenceUnavailable, "current campaign consumer policy is unavailable"
        end

        def freeze_value!(value)
          case value
          when Hash then value.each { |key, child| key.freeze; freeze_value!(child) }
          when Array then value.each { |child| freeze_value!(child) }
          end
          value.freeze
        end
      end
    end
  end
end
