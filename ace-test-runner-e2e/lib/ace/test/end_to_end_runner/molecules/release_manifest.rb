# frozen_string_literal: true

require "fileutils"
require "json"
require "rubygems/version"

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
          # depends on; the manifest must cover every one of them.
          # @raise [Invalid]
          def self.validate_and_copy(source_path:, target_path:, required_packages: nil)
            data = load_validated(source_path)
            Array(required_packages).each do |name|
              unless data["packages"].any? { |package| package["name"] == name }
                raise Invalid, "release manifest is missing required package: #{name}"
              end
            end
            FileUtils.mkdir_p(File.dirname(target_path))
            FileUtils.cp(source_path, target_path)
            target_path
          end

          class << self
            private

            def parse_json(path)
              raise Invalid, "release manifest is missing: #{path}" unless File.file?(path)
              raise Invalid, "release manifest is not readable: #{path}" unless File.readable?(path)

              raw = File.read(path)
              raise Invalid, "release manifest is empty: #{path}" if raw.strip.empty?

              data = JSON.parse(raw)
              raise Invalid, "release manifest must be a JSON object: #{path}" unless data.is_a?(Hash)

              data
            rescue JSON::ParserError => e
              raise Invalid, "release manifest is not valid JSON: #{path} (#{e.message})"
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

              reject_unknown_keys!(entry, %w[name artifact_version source_sha supersedes], label)

              name = entry["name"]
              unless name.is_a?(String) && name.match?(GEM_NAME_PATTERN)
                raise Invalid, "#{label} has invalid ACE gem name: #{name.inspect}"
              end

              validate_exact_version!(entry["artifact_version"], "#{label}(#{name}) artifact_version")
              validate_source_sha!(entry["source_sha"], "#{label}(#{name}) source_sha")
              validate_supersedes!(entry["supersedes"], entry["artifact_version"], "#{label}(#{name})")
              name
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
          end
        end
      end
    end
  end
end
