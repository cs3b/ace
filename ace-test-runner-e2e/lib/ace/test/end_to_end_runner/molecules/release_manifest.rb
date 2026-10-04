# frozen_string_literal: true

require "digest"
require "fileutils"
require "json"
require "rubygems/version"
require "rubygems/requirement"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Validates the frozen release installation manifest used by release
        # verification scenarios (TS-MONO-001).
        #
        # The manifest is an exact-version contract: schema_version 1, a full
        # source commit, and a nonempty package array. Every package entry
        # carries a unique ACE gem name, one exact artifact version (never a
        # requirement), the full source commit the artifact was built from,
        # and an optional explicit supersession list of earlier versions of
        # the same package.
        #
        # Validation is strict on purpose: unknown fields, missing fields,
        # duplicate names, non-exact versions, malformed SHAs, and
        # contradictory supersession entries all fail before any install
        # attempt is made.
        class ReleaseManifest
          SCHEMA_VERSION = 1
          GEM_NAME_PATTERN = /\Aace-[a-z0-9](?:[a-z0-9-]*[a-z0-9])?\z/
          SOURCE_SHA_PATTERN = /\A[0-9a-f]{40}\z/

          # Raised for any manifest content or source-path failure. Setup
          # converts this into a setup failure before installation runs.
          class Invalid < StandardError; end

          # Validate the manifest at +path+ and return its parsed content.
          # @raise [Invalid] when the file is missing, unreadable,
          #   malformed, or violates the schema.
          def self.load_validated(path)
            data = parse_json(path)
            validate_schema!(data)
            data
          end

          # Validate the manifest at +source_path+ and copy the exact bytes
          # to +target_path+, creating the target directory when needed.
          # +required_packages+ names the gems the calling scenario's proof
          # depends on; the manifest must cover every one of them. Entries
          # may be plain names or {name, supersedes} maps requiring an
          # explicit supersession declaration. The buffer is read once so
          # the validated content, the written copy, and the returned digest
          # are the same bytes even if the source file changes mid-flight.
          # @raise [Invalid]
          def self.validate_and_copy(source_path:, target_path:, required_packages: nil)
            raw = read_source(source_path)
            data = parse_buffer(raw, source_path)
            validate_schema!(data)
            entries = data["packages"].to_h { |package| [package["name"], package] }
            Array(required_packages).each do |required|
              name, supersedes = required_packages_entry(required)
              entry = entries[name]
              raise Invalid, "release manifest is missing required package: #{name}" unless entry

              missing = Array(supersedes) - Array(entry["supersedes"])
              next if missing.empty?

              raise Invalid,
                "release manifest does not declare that #{name} #{entry["artifact_version"]} supersedes #{missing.join(", ")}"
            end
            FileUtils.mkdir_p(File.dirname(target_path))
            File.binwrite(target_path, raw)
            Digest::SHA256.hexdigest(raw)
          end

          class << self
            private

            def read_source(path)
              raise Invalid, "release manifest is missing: #{path}" unless File.file?(path)
              raise Invalid, "release manifest is not readable: #{path}" unless File.readable?(path)

              raw = File.binread(path)
              raise Invalid, "release manifest is empty: #{path}" if raw.strip.empty?

              raw
            end

            def parse_buffer(raw, path)
              data = JSON.parse(raw)
              raise Invalid, "release manifest must be a JSON object: #{path}" unless data.is_a?(Hash)

              data
            rescue JSON::ParserError => e
              raise Invalid, "release manifest is not valid JSON: #{path} (#{e.message})"
            end

            def parse_json(path)
              parse_buffer(read_source(path), path)
            end

            def validate_schema!(data)
              reject_unknown_keys!(data, %w[schema_version source_sha packages], "manifest")

              schema_version = data["schema_version"]
              unless schema_version.is_a?(Integer) && schema_version == SCHEMA_VERSION
                raise Invalid,
                  "unsupported schema_version: #{schema_version.inspect} (expected #{SCHEMA_VERSION})"
              end

              validate_source_sha!(data["source_sha"], "manifest source_sha")

              packages = data["packages"]
              raise Invalid, "packages must be a nonempty array" unless packages.is_a?(Array) && !packages.empty?

              seen = {}
              packages.each_with_index do |entry, index|
                name = validate_package!(entry, index)
                raise Invalid, "duplicate package name: #{name}" if seen.key?(name)

                seen[name] = true
              end
            end

            def validate_package!(entry, index)
              label = "packages[#{index}]"
              raise Invalid, "#{label} must be an object" unless entry.is_a?(Hash)

              reject_unknown_keys!(entry, %w[name artifact_version source_sha supersedes runtime_dependencies], label)

              name = entry["name"]
              unless name.is_a?(String) && name.match?(GEM_NAME_PATTERN)
                raise Invalid, "#{label} has invalid ACE gem name: #{name.inspect}"
              end

              validate_exact_version!(entry["artifact_version"], "#{label}(#{name}) artifact_version")
              validate_source_sha!(entry["source_sha"], "#{label}(#{name}) source_sha")
              validate_supersedes!(entry["supersedes"], entry["artifact_version"], "#{label}(#{name})")
              validate_runtime_dependencies!(entry["runtime_dependencies"], label) if entry.key?("runtime_dependencies")
              name
            end

            # These are frozen source declarations, not requirements inferred
            # from whatever a registry happened to return during the proof.
            def validate_runtime_dependencies!(raw, label)
              unless raw.is_a?(Hash)
                raise Invalid, "#{label} runtime_dependencies must be an object"
              end
              raw.each do |name, requirements|
                unless name.is_a?(String) && name.match?(GEM_NAME_PATTERN) &&
                    requirements.is_a?(Array) && !requirements.empty? &&
                    requirements.uniq.length == requirements.length
                  raise Invalid, "#{label} has invalid runtime dependency declaration"
                end
                requirements.each do |requirement|
                  parsed = requirement.is_a?(String) ? Gem::Requirement.new(requirement) : nil
                  canonical = parsed&.requirements&.map { |operator, version| "#{operator} #{version}" }
                  unless canonical == [requirement]
                    raise Invalid, "#{label} runtime dependency requirements must be canonical strings"
                  end
                rescue ArgumentError
                  raise Invalid, "#{label} has invalid runtime dependency requirement"
                end
              end
            end

            def validate_exact_version!(raw, label)
              unless raw.is_a?(String) && !raw.strip.empty?
                raise Invalid, "#{label} must be an exact version string, got #{raw.inspect}"
              end

              version = begin
                Gem::Version.new(raw)
              rescue ArgumentError
                raise Invalid, "#{label} is not a valid version: #{raw.inspect}"
              end

              return if version.to_s == raw

              raise Invalid,
                "#{label} must be an exact version, not a requirement or shorthand: #{raw.inspect}"
            end

            def validate_source_sha!(raw, label)
              return if raw.is_a?(String) && raw.match?(SOURCE_SHA_PATTERN)

              raise Invalid, "#{label} must be a full 40-character commit SHA, got #{raw.inspect}"
            end

            def validate_supersedes!(raw, artifact_version, label)
              return if raw.nil?

              unless raw.is_a?(Array)
                raise Invalid, "#{label} supersedes must be an array of version strings"
              end

              artifact = Gem::Version.new(artifact_version)
              seen = {}
              raw.each do |entry|
                validate_exact_version!(entry, "#{label} supersedes entry")
                raise Invalid, "#{label} supersedes duplicates version #{entry}" if seen.key?(entry)

                seen[entry] = true
                next unless Gem::Version.new(entry) >= artifact

                raise Invalid,
                  "#{label} supersedes must list earlier versions of the same package: #{entry} >= #{artifact_version}"
              end
            end

            def reject_unknown_keys!(hash, allowed, label)
              unknown = hash.keys - allowed
              return if unknown.empty?

              raise Invalid, "#{label} has unknown fields: #{unknown.sort.join(", ")}"
            end

            def required_packages_entry(required)
              case required
              when String
                [required, nil]
              when Hash
                reject_unknown_keys!(required, %w[name supersedes], "required package entry")
                name = required["name"]
                unless name.is_a?(String) && name.match?(GEM_NAME_PATTERN)
                  raise Invalid, "required package entry has invalid ACE gem name: #{name.inspect}"
                end

                [name, required["supersedes"]]
              else
                raise Invalid, "required package entries must be names or {name, supersedes} maps"
              end
            end
          end
        end
      end
    end
  end
end
