# frozen_string_literal: true

require "yaml"

module Ace
  module Lab
    module Molecules
      # Resolves authorization grants from the single deployment-controlled
      # document at a fixed path — never from the configuration cascade and
      # never from caller-selected locations (review rounds 4-5). The file
      # must be owned by root and not group/world-writable, including every
      # directory on its real path; the file itself is opened O_NOFOLLOW and
      # re-verified via fstat. Any failed verification fails closed.
      #
      # No trusted document means nobody is authorized (fail closed).
      class GrantResolver
        class << self
          # @param documents [Array<Hash>] {path:, document:, defaults:}
          #   from Ace::Lab.cascade_documents
          # @param topology [Hash] normalized topology (project IDs)
          # @param trusted_path [String] fixed deployment grants path
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

            content = read_verified(trusted_path)
            return {"principals" => {}} if content.nil?

            parse_grants(content, trusted_path, topology)
          end

          private

          def verify_error(path)
            "invalid lab configuration: trusted authorization file #{path} failed the deployment " \
              "ownership verification or could not be read; failing closed " \
              "(required: root-owned, not group/world-writable, including every directory on its real path)"
          end

          # Read the grants document only after proving the deployment owns
          # the storage: every directory on the real path and the file itself
          # must be root-owned and not group/world-writable, and the file is
          # opened with O_NOFOLLOW then re-verified via fstat. Genuine
          # absence is nil (nobody authorized); every other filesystem
          # failure — including races between realpath, lstat, and open —
          # classifies fail-closed (review rounds 6-7, F2).
          # @return [String, nil] file content, or nil when absent
          def read_verified(path)
            real = begin
              File.realpath(path)
            rescue Errno::ENOENT
              return nil
            rescue
              raise Ace::Lab::InvalidConfigurationError, verify_error(path)
            end

            begin
              verify_path_ownership!(real, path)

              io = File.open(real, File::RDONLY | File::NOFOLLOW)
              begin
                raise Ace::Lab::InvalidConfigurationError, verify_error(path) unless secure_file_stat?(io.stat)

                io.read
              ensure
                io.close
              end
            rescue Ace::Lab::InvalidConfigurationError
              raise
            rescue
              raise Ace::Lab::InvalidConfigurationError, verify_error(path)
            end
          end

          def verify_path_ownership!(real, display_path)
            components = real.split(File::SEPARATOR).reject(&:empty?)
            components[0...-1].reduce(File::SEPARATOR) do |parent, component|
              directory = File.join(parent, component)
              stat = File.lstat(directory)
              unless stat.directory? && secure_file_stat?(stat)
                raise Ace::Lab::InvalidConfigurationError, verify_error(display_path)
              end

              directory
            end
          end

          def secure_file_stat?(stat)
            stat.uid.zero? && (stat.mode & 0o022).zero?
          end

          def parse_grants(content, path, topology)
            document = YAML.safe_load(content, permitted_classes: [Date], aliases: true)
            unless document.is_a?(Hash)
              raise Ace::Lab::InvalidConfigurationError,
                "invalid lab configuration: trusted authorization file #{path} must contain a YAML mapping"
            end

            Atoms::TopologySchema.normalize_authorization!(document, topology)
          rescue Psych::Exception
            raise Ace::Lab::InvalidConfigurationError,
              "invalid lab configuration: trusted authorization file #{path} could not be parsed as YAML"
          end
        end
      end
    end
  end
end
