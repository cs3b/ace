# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Pure logic for version validation and manipulation
      # Unit testable - no I/O
      class VersionValidator
        VERSION_PATTERN = /^v\.\d+\.\d+\.\d+$/
        VERSION_EXTRACT_PATTERN = /^(v\.\d+\.\d+\.\d+)/

        # Validate version format
        # @param version [String] Version to validate
        # @return [Boolean] True if valid format
        def self.valid_format?(version)
          return false if version.nil? || version.empty?
          !!(version =~ VERSION_PATTERN)
        end

        # Extract version from release name
        # @param name [String] Release name like "v.0.9.0" or "v.0.9.0-feature"
        # @return [String, nil] Version string or nil if invalid
        def self.extract_version(name)
          return nil if name.nil? || name.empty?
          match = name.match(VERSION_EXTRACT_PATTERN)
          match ? match[1] : nil
        end

        # Convert version string to array for comparison
        # @param version [String] Version like "v.0.9.0"
        # @return [Array<Integer>] Array like [0, 9, 0]
        def self.version_to_array(version)
          return [] if version.nil? || version.empty?
          version.gsub(/^v\./, "").split(".").map(&:to_i)
        end

        # Increment the minor version
        # @param version [String] Current version like "v.0.9.0"
        # @return [String] Incremented version like "v.0.10.0"
        def self.increment_minor(version)
          parts = version_to_array(version)
          return nil if parts.empty? || parts.length != 3

          parts[1] += 1  # Increment minor version
          parts[2] = 0   # Reset patch version
          "v.#{parts.join('.')}"
        end

        # Increment the major version
        # @param version [String] Current version like "v.0.9.0"
        # @return [String] Incremented version like "v.1.0.0"
        def self.increment_major(version)
          parts = version_to_array(version)
          return nil if parts.empty? || parts.length != 3

          parts[0] += 1  # Increment major version
          parts[1] = 0   # Reset minor version
          parts[2] = 0   # Reset patch version
          "v.#{parts.join('.')}"
        end

        # Increment the patch version
        # @param version [String] Current version like "v.0.9.0"
        # @return [String] Incremented version like "v.0.9.1"
        def self.increment_patch(version)
          parts = version_to_array(version)
          return nil if parts.empty? || parts.length != 3

          parts[2] += 1  # Increment patch version
          "v.#{parts.join('.')}"
        end

        # Compare two versions
        # @param version1 [String] First version
        # @param version2 [String] Second version
        # @return [Integer] -1 if v1 < v2, 0 if equal, 1 if v1 > v2, nil if invalid
        def self.compare(version1, version2)
          v1_parts = version_to_array(version1)
          v2_parts = version_to_array(version2)

          return nil if v1_parts.empty? || v2_parts.empty?
          return nil if v1_parts.length != 3 || v2_parts.length != 3

          v1_parts <=> v2_parts
        end

        # Check if version1 is greater than version2
        # @param version1 [String] First version
        # @param version2 [String] Second version
        # @return [Boolean, nil] True if v1 > v2, nil if invalid
        def self.greater_than?(version1, version2)
          result = compare(version1, version2)
          result == 1 if result
        end

        # Check if version1 is less than version2
        # @param version1 [String] First version
        # @param version2 [String] Second version
        # @return [Boolean, nil] True if v1 < v2, nil if invalid
        def self.less_than?(version1, version2)
          result = compare(version1, version2)
          result == -1 if result
        end

        # Build release name with version and codename
        # @param version [String] Version like "v.0.10.0"
        # @param codename [String] Codename like "feature-name"
        # @return [String] Full name like "v.0.10.0-feature-name"
        def self.build_release_name(version, codename)
          return version if codename.nil? || codename.empty?

          # Normalize the codename
          normalized = codename.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')

          # If codename is empty or just a version, return version only
          if normalized.empty? || normalized.match?(/^v\.\d+\.\d+\.\d+$/)
            version
          else
            "#{version}-#{normalized}"
          end
        end
      end
    end
  end
end
