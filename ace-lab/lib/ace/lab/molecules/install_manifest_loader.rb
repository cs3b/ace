# frozen_string_literal: true

require_relative "../errors"
require_relative "../atoms/install_schema"
require_relative "grant_resolver"
require "yaml"

module Ace
  module Lab
    module Molecules
      # Loads the trusted install manifest through the same fail-closed
      # deployment-ownership verification as the authorization document
      # (GrantResolver.read_verified): every traversed element root-owned
      # and not group/world-writable, O_NOFOLLOW on the final file. The
      # loader adds nothing to trust — it only classifies absence and parse
      # failures with value-free, path-bearing messages.
      class InstallManifestLoader
        class << self
          # @param path [String] trusted manifest location (default: the
          #   fixed deployment path)
          # @param platform [String, nil] platform for home-path defaults
          # @return [Hash] normalized manifest (Atoms::InstallSchema)
          # @raise [Ace::Lab::InvalidConfigurationError] missing, untrusted,
          #   unparseable or schema-invalid manifest
          def load(path: Ace::Lab.install_manifest_path, platform: nil)
            # The nested GrantResolver message speaks of the
            # "authorization file" — a wrong remedy lead inside an
            # install-manifest error. The wrapper already states the
            # requirement, so the nested message is not embedded.
            content = begin
              GrantResolver.read_verified(path)
            rescue Ace::Lab::InvalidConfigurationError
              raise Ace::Lab::InvalidConfigurationError,
                "invalid lab install manifest: #{path} failed trusted deployment verification " \
                "or could not be read; failing closed"
            end

            if content.nil?
              raise Ace::Lab::InvalidConfigurationError,
                "invalid lab install manifest: #{path} not found; create the root-owned " \
                "deployment manifest at this path (administrator action) " \
                "and keep it outside the caller-writable configuration cascade"
            end

            document = begin
              YAML.safe_load(content, permitted_classes: [], aliases: false)
            rescue Psych::DisallowedClass
              # It parsed; it just carries types outside the permitted
              # set — a different remedy than fixing YAML syntax.
              raise Ace::Lab::InvalidConfigurationError,
                "invalid lab install manifest: #{path} contains YAML types outside the " \
                "permitted set; use plain scalars, sequences and mappings only"
            rescue Psych::Exception
              raise Ace::Lab::InvalidConfigurationError,
                "invalid lab install manifest: #{path} could not be parsed as YAML"
            end

            Atoms::InstallSchema.normalize(document, platform: platform)
          end
        end
      end
    end
  end
end
