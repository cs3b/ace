# frozen_string_literal: true

require_relative "deployment"

module Ace
  module Assign
    module Authority
      # Immutable installer configuration, indexed by canonical content identity.
      # This object is never a transport selector or an execution ledger.
      class DeploymentHistory
        PATH = "/etc/ace/assignment-deployment-history.json"
        attr_reader :original, :candidate, :artifact_reference

        def self.load = load_protected(nil)

        def self.load_artifact(reference)
          validate_reference!(reference)
          load_protected(reference)
        end

        def self.load_protected(reference)
          Ace::Runtime::Molecules::ProtectedArtifactSet.new.with do |artifacts|
            bytes = if reference
              artifacts.read!(reference)
            else
              held, selected = artifacts.read_path!(PATH, limit: 65_536)
              reference = selected
              held
            end
            raw = bytes.dup.force_encoding(Encoding::UTF_8)
            raise ArgumentError, "history manifest is not UTF-8" unless raw.valid_encoding?
            value = JSON.parse(raw, create_additions: false, max_nesting: 32,
              allow_duplicate_key: false, allow_comments: false)
            unless value.is_a?(Hash) && value.keys.sort ==
                %w[candidate_descriptor descriptors original_descriptor public_keys schema] &&
                value["schema"] == "ace.assign.deployment-history/v1"
              raise ArgumentError, "invalid deployment history manifest"
            end
            descriptors = value.fetch("descriptors")
            keys = value.fetch("public_keys")
            unless descriptors.is_a?(Array) && descriptors.size.between?(1, 128) &&
                keys.is_a?(Array) && keys.size <= 128 && descriptors.size + keys.size <= 255
              raise ArgumentError, "deployment history inventory exceeds bounds"
            end
            index = {}
            descriptors.each do |selected|
              validate_reference!(selected)
              digest = selected.fetch("sha256")
              raise ArgumentError, "duplicate historical descriptor selector" if index.key?(digest)
              index[digest] = Deployment.send(:from_verified_bytes, artifacts.read!(selected), immutable(selected))
            end
            selections = %w[original_descriptor candidate_descriptor].map do |name|
              selected = value.fetch(name)
              validate_reference!(selected)
              descriptor = index.fetch(selected.fetch("sha256")) do
                raise ArgumentError, "transaction descriptor is not retained"
              end
              unless descriptor.artifact_reference == selected
                raise ArgumentError, "transaction descriptor reference conflicts"
              end
              descriptor
            end
            public_keys = {}
            keys.each do |entry|
              unless entry.is_a?(Hash) && entry.keys.sort == %w[public_key_sha256 ref] &&
                  digest?(entry["public_key_sha256"])
                raise ArgumentError, "invalid historical public key entry"
              end
              validate_reference!(entry.fetch("ref"))
              digest = entry.fetch("public_key_sha256")
              raise ArgumentError, "duplicate historical public key selector" if public_keys.key?(digest)
              key = OpenSSL::PKey.read(artifacts.read!(entry.fetch("ref")))
              unless key.is_a?(OpenSSL::PKey::RSA) && !key.private? &&
                  Digest::SHA256.hexdigest(key.public_key.to_der) == digest
                raise ArgumentError, "historical public key identity differs"
              end
              public_keys[digest] = key.freeze
            end
            selections.first.maintenance_inventory(selections.last)
            history = new(selections, index, public_keys, immutable(reference))
            artifacts.verify_unchanged!
            history.freeze
          end
        end

        def initialize(selections, descriptors, keys, reference)
          @original, @candidate = selections
          @descriptors, @keys = descriptors.freeze, keys.freeze
          @artifact_reference = reference
        end
        private_class_method :new

        def descriptor!(sha256:)
          @descriptors.fetch(sha256) do
            raise AttemptErrors::EvidenceUnavailable, "original protected descriptor is not retained"
          end
        end

        def public_key!(sha256:)
          @keys.fetch(sha256) do
            raise AttemptErrors::EvidenceUnavailable, "original protected public key is not retained"
          end
        end

        def descriptors = @descriptors.values.freeze

        # Publication moves verified bytes to the fixed current descriptor path.
        # Retention paths stay immutable; canonical content, not pathname, joins
        # the installed selection to that exact independently verified artifact.
        def selects?(deployment, selection: nil)
          return false unless deployment.is_a?(Deployment) && deployment.frozen? && deployment.artifact_reference
          choices = case selection
          when :original then [original]
          when :candidate then [candidate]
          when nil then [original, candidate]
          else raise ArgumentError, "invalid history transaction selection"
          end
          choices.any? do |selected|
            selected.artifact_reference.values_at("sha256", "bytes") == deployment.artifact_reference.values_at("sha256", "bytes")
          end
        end

        def self.digest?(value) = value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/)

        def self.validate_reference!(value)
          unless value.is_a?(Hash) && value.keys.sort == %w[bytes path sha256] &&
              value["path"].is_a?(String) && value["path"].start_with?("/") &&
              !value["path"].include?("\0") && File.expand_path(value["path"]) == value["path"] &&
              digest?(value["sha256"]) && value["bytes"].is_a?(Integer) && value["bytes"].between?(1, 65_536)
            raise ArgumentError, "invalid protected history artifact reference"
          end
        end

        def self.immutable(value)
          case value
          when Hash then value.to_h { |key, item| [key.dup.freeze, immutable(item)] }.freeze
          when Array then value.map { |item| immutable(item) }.freeze
          when String then value.dup.freeze
          else value.freeze
          end
        end
        private_class_method :digest?, :validate_reference!, :immutable, :load_protected
      end
    end
  end
end
