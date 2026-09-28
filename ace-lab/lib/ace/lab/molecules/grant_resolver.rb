# frozen_string_literal: true

module Ace
  module Lab
    module Molecules
      # Resolves authorization grants from a single trusted,
      # deployment-controlled document — never from the configuration
      # cascade (review round 4, F3). Caller-writable cascade tiers
      # (project, user) must not be able to define or expand grants, so an
      # `authorization` section in any cascade document is rejected as
      # invalid configuration, pointing operators at the trusted channel.
      #
      # No trusted document means nobody is authorized (fail closed).
      class GrantResolver
        class << self
          # @param documents [Array<Hash>] {path:, document:, defaults:}
          #   from Ace::Lab.cascade_documents
          # @param topology [Hash] normalized topology (project IDs)
          # @param trusted_path [String] deployment-controlled grants file
          # @return [Hash] principals mapping for CallerAuthorizer
          # @raise [Ace::Lab::InvalidConfigurationError]
          def resolve(documents:, topology:, trusted_path:)
            offending = documents.reject { |document| document[:defaults] }
              .find { |document| document[:document].key?("authorization") }
            if offending
              raise Ace::Lab::InvalidConfigurationError,
                "invalid lab configuration: authorization grants come from the trusted file " \
                "#{trusted_path}, not the cascade; remove the authorization section from #{offending[:path]}"
            end

            trusted = read_trusted(trusted_path)
            return {"principals" => {}} if trusted.nil?

            Atoms::TopologySchema.normalize_authorization!(trusted, topology)
          end

          private

          def read_trusted(path)
            return nil unless File.exist?(path)

            document = begin
              require "yaml"
              YAML.safe_load_file(path, permitted_classes: [Date], aliases: true)
            rescue
              raise Ace::Lab::InvalidConfigurationError,
                "invalid lab configuration: trusted authorization file #{path} could not be parsed as YAML"
            end
            unless document.is_a?(Hash)
              raise Ace::Lab::InvalidConfigurationError,
                "invalid lab configuration: trusted authorization file #{path} must contain a YAML mapping"
            end

            document
          end
        end
      end
    end
  end
end
