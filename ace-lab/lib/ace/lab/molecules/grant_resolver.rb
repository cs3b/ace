# frozen_string_literal: true

require "yaml"

module Ace
  module Lab
    module Molecules
      # Resolves authorization grants from the single deployment-controlled
      # document at a fixed path — never from the configuration cascade and
      # never from caller-selected locations (review rounds 4-5).
      #
      # Trust is established per traversal hop along the ORIGINAL path: every
      # element — directories, any symlinks, and the file itself — must be
      # root-owned and not group/world-writable, so a caller-writable
      # directory cannot redirect the path to attacker-chosen content
      # (review round 8, F2). The final component is opened O_NOFOLLOW and
      # re-verified via fstat. Grants are validated structurally only and
      # intersect with the local topology at query time: the grants file is
      # machine-global while topology is per-directory (review round 8, F1).
      # Any failed verification fails closed; no trusted document means
      # nobody is authorized.
      class GrantResolver
        MAX_SYMLINK_HOPS = 8

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

            parse_grants(content, trusted_path)
          end

          private

          def verify_error(path)
            "invalid lab configuration: trusted authorization file #{path} failed the deployment " \
              "ownership verification or could not be read; failing closed " \
              "(required: every traversed element root-owned and not group/world-writable)"
          end

          # Read the grants document only after proving the deployment owns
          # the storage along the original path. Genuine absence is nil
          # (nobody authorized); every other filesystem failure — including
          # races between lstat and open — classifies fail-closed
          # (review rounds 6-7, F2).
          # @return [String, nil] file content, or nil when absent
          def read_verified(path)
            candidate = begin
              verified_resolve(path)
            rescue Ace::Lab::InvalidConfigurationError
              raise
            rescue
              raise Ace::Lab::InvalidConfigurationError, verify_error(path)
            end
            return nil if candidate.nil?

            begin
              io = File.open(candidate, File::RDONLY | File::NOFOLLOW)
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

          # Walk the ORIGINAL path component by component. Symlinks are
          # followed only when the link itself is root-owned (a caller-writable
          # redirect is rejected); symlink permission bits are ignored because
          # Linux symlinks always report 0777 and cannot be changed
          # (review round 9, F1). Intermediate directories must be real,
          # root-owned directories; the opened file is re-verified via fstat.
          # @return [String, nil] verified file path, or nil when absent
          def verified_resolve(path)
            remaining = path.split(File::SEPARATOR).reject(&:empty?)
            current = File::SEPARATOR
            hops = 0

            until remaining.empty?
              component = remaining.shift
              candidate = (current == File::SEPARATOR) ? "/#{component}" : File.join(current, component)
              stat = begin
                File.lstat(candidate)
              rescue Errno::ENOENT, Errno::ENOTDIR
                return nil
              end

              if stat.symlink?
                hops += 1
                raise Ace::Lab::InvalidConfigurationError, verify_error(path) if hops > MAX_SYMLINK_HOPS
                raise Ace::Lab::InvalidConfigurationError, verify_error(path) unless stat.uid.zero?

                target = File.readlink(candidate)
                target_components = target.split(File::SEPARATOR).reject(&:empty?)
                remaining = target_components + remaining
                current = target.start_with?(File::SEPARATOR) ? File::SEPARATOR : current
                next
              end

              if remaining.empty?
                return candidate
              end

              unless stat.directory? && secure_file_stat?(stat)
                raise Ace::Lab::InvalidConfigurationError, verify_error(path)
              end

              current = candidate
            end

            raise Ace::Lab::InvalidConfigurationError, verify_error(path)
          end

          def secure_file_stat?(stat)
            stat.uid.zero? && (stat.mode & 0o022).zero?
          end

          # Structural validation only: the grants file is machine-global, so
          # referenced projects may legitimately not exist in the local
          # directory's topology; such grants simply never match at query
          # time (review round 8, F1). Messages are value-free.
          def parse_grants(content, path)
            document = YAML.safe_load(content, permitted_classes: [Date], aliases: true)
            unless document.is_a?(Hash)
              raise Ace::Lab::InvalidConfigurationError,
                "invalid lab configuration: trusted authorization file #{path} must contain a YAML mapping"
            end

            principals = document["principals"] || {}
            unless principals.is_a?(Hash)
              raise Ace::Lab::InvalidConfigurationError,
                "invalid lab configuration: trusted authorization file #{path} principals must be a mapping"
            end

            validated = principals.map do |identity, policy|
              unless identity.is_a?(String) && !identity.strip.empty?
                raise Ace::Lab::InvalidConfigurationError,
                  "invalid lab configuration: trusted authorization file #{path} principal name " \
                  "must be a non-empty string"
              end
              unless policy.is_a?(Hash) && policy["projects"].is_a?(Array) &&
                  policy["projects"].all? { |project| project.is_a?(String) && !project.strip.empty? }
                raise Ace::Lab::InvalidConfigurationError,
                  "invalid lab configuration: trusted authorization file #{path} principal projects " \
                  "must be an array of non-empty strings"
              end

              [identity.strip, {"projects" => policy["projects"].map(&:strip).uniq}]
            end

            {"principals" => validated.to_h}
          rescue Psych::Exception
            raise Ace::Lab::InvalidConfigurationError,
              "invalid lab configuration: trusted authorization file #{path} could not be parsed as YAML"
          end
        end
      end
    end
  end
end
