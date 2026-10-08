# frozen_string_literal: true

require_relative "service_input"

module Ace
  module Lab
    module Atoms
      # One accepted artifact, never a queue selector or a build instruction.
      module ProtectedPublicationInput
        REGISTRY = "https://rubygems.org"
        PUBLICATION_FIELDS = %w[gem_name version head registry artifact_relative_path].freeze
        NAME = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,127}\z/
        VERSION = /\A[0-9]+(?:\.[0-9A-Za-z]+)*(?:-[0-9A-Za-z]+(?:\.[0-9A-Za-z]+)*)?\z/

        def self.decode!(bytes)
          unless bytes.is_a?(String) && bytes.bytesize.between?(1, ServiceInput::MAX_BYTES)
            raise ArgumentError, "publication input exceeds its bound"
          end
          input = JSON.parse(bytes, allow_duplicate_key: false, allow_comments: false,
            allow_nan: false, create_additions: false, max_nesting: 16)
          validate!(input)
        rescue JSON::ParserError
          raise ArgumentError, "publication input must be valid JSON"
        end

        def self.validate!(input)
          unless input.is_a?(Hash) && input.keys.sort == %w[publication target] &&
              input["publication"].is_a?(Hash) && input["publication"].keys.sort == PUBLICATION_FIELDS.sort &&
              input["target"].is_a?(Hash) && input["target"].keys.sort == %w[artifact_digest resource]
            raise ArgumentError, "publication input fields differ"
          end
          value = input.fetch("publication")
          name, version, head, registry, path = value.values_at(*PUBLICATION_FIELDS)
          unless name.is_a?(String) && name.match?(NAME) && version.is_a?(String) &&
              version.bytesize.between?(1, 128) && version.match?(VERSION) &&
              head.is_a?(String) && head.match?(/\A[0-9a-f]{40}\z/) && registry == REGISTRY &&
              path.is_a?(String) && path.bytesize.between?(1, 4096) && path.end_with?(".gem") &&
              path.split("/", -1).all? { |part| part.match?(/\A[a-zA-Z0-9_.-]+\z/) && !%w[. ..].include?(part) } &&
              input.dig("target", "resource") == "rubygems:#{name}:#{version}" &&
              input.dig("target", "artifact_digest").is_a?(String) &&
              input.dig("target", "artifact_digest").match?(ServiceInput::SHA256)
            raise ArgumentError, "publication artifact selection differs"
          end
          ServiceInput.validate!(input)
          input
        end
      end
    end
  end
end
