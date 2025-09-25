# frozen_string_literal: true

require "fileutils"
require_relative "../molecules/release_resolver"
require_relative "../atoms/path_builder"

module Ace
  module Taskflow
    module Organisms
      # Creates new releases with directory structure and metadata
      class ReleaseCreator
        attr_reader :root_path, :resolver

        def initialize(root_path)
          @root_path = root_path
          @resolver = Molecules::ReleaseResolver.new(root_path)
        end

        # Create a new release with the specified parameters
        # @param codename [String] Release codename/feature name
        # @param version [String, nil] Specific version or nil for auto-increment
        # @param location [String] "backlog" (default) or "active"
        # @return [Hash] Result with :success, :message, :path, :version
        def create(codename, version: nil, location: "backlog")
          # Auto-increment version if not specified
          version ||= calculate_next_version

          # Build the full release name
          release_name = build_release_name(version, codename)

          # Check if already exists
          if @resolver.exists?(release_name)
            return {
              success: false,
              message: "Release #{release_name} already exists"
            }
          end

          # Create the release
          release_path = create_release_structure(release_name, location)

          {
            success: true,
            message: "Created release #{release_name} in #{location}",
            path: release_path,
            version: version,
            name: release_name
          }
        rescue StandardError => e
          {
            success: false,
            message: "Failed to create release: #{e.message}"
          }
        end

        private

        # Calculate the next available version number
        # @return [String] Next version in format "v.X.Y.Z"
        def calculate_next_version
          all_releases = @resolver.find_all

          # Extract version numbers
          versions = all_releases.map do |release|
            extract_version(release[:name])
          end.compact

          # If no releases exist, start with v.0.1.0
          return "v.0.1.0" if versions.empty?

          # Find the highest version and increment minor version
          latest = versions.max_by { |v| version_to_array(v) }
          increment_version(latest)
        end

        # Extract version from release name
        # @param name [String] Release name like "v.0.9.0" or "v.0.9.0-feature"
        # @return [String, nil] Version string or nil if invalid
        def extract_version(name)
          match = name.match(/^(v\.\d+\.\d+\.\d+)/)
          match ? match[1] : nil
        end

        # Convert version string to array for comparison
        # @param version [String] Version like "v.0.9.0"
        # @return [Array<Integer>] Array like [0, 9, 0]
        def version_to_array(version)
          version.gsub(/^v\./, "").split(".").map(&:to_i)
        end

        # Increment the minor version
        # @param version [String] Current version like "v.0.9.0"
        # @return [String] Incremented version like "v.0.10.0"
        def increment_version(version)
          parts = version_to_array(version)
          parts[1] += 1  # Increment minor version
          parts[2] = 0   # Reset patch version
          "v.#{parts.join('.')}"
        end

        # Build the full release name
        # @param version [String] Version like "v.0.10.0"
        # @param codename [String] Codename like "feature-name"
        # @return [String] Full name like "v.0.10.0-feature-name"
        def build_release_name(version, codename)
          # Normalize the codename
          normalized_codename = codename.downcase.gsub(/[^a-z0-9]+/, '-').gsub(/^-|-$/, '')

          # If codename is empty or just a version, return version only
          if normalized_codename.empty? || normalized_codename.match?(/^v\.\d+\.\d+\.\d+$/)
            version
          else
            "#{version}-#{normalized_codename}"
          end
        end

        # Create the release directory structure
        # @param release_name [String] Full release name
        # @param location [String] "backlog" or "active"
        # @return [String] Path to created release
        def create_release_structure(release_name, location)
          release_path = Atoms::PathBuilder.build_release_path(@root_path, release_name, location)

          # Create main directory
          FileUtils.mkdir_p(release_path)

          # Create subdirectories
          %w[t ideas docs retro].each do |dir|
            FileUtils.mkdir_p(File.join(release_path, dir))
          end

          # Create release overview file
          overview_file = File.join(release_path, "#{release_name}.md")
          File.write(overview_file, generate_release_template(release_name, location))

          release_path
        end

        # Generate the release overview template
        # @param name [String] Release name
        # @param location [String] "backlog" or "active"
        # @return [String] Markdown template content
        def generate_release_template(name, location)
          status = location == "active" ? "active" : "backlog"

          <<~TEMPLATE
            # Release: #{name}

            ## Overview

            *Description of this release and its main objectives*

            ## Goals

            - [ ] Primary goal or feature
            - [ ] Secondary goal or improvement
            - [ ] Additional objectives

            ## Key Features

            - Feature 1: Brief description
            - Feature 2: Brief description
            - Feature 3: Brief description

            ## Technical Scope

            - Component/module affected
            - API changes or additions
            - Infrastructure updates

            ## Status

            - **Created**: #{Time.now.strftime('%Y-%m-%d')}
            - **Status**: #{status}
            - **Target Date**: TBD
            - **Progress**: 0/0 tasks (0%)

            ## Success Metrics

            - Metric 1: How we measure success
            - Metric 2: Key performance indicator
            - Metric 3: Quality benchmark

            ## Notes

            *Additional context, constraints, or considerations for this release*

            ## References

            - Related documentation
            - Design specifications
            - Technical requirements
          TEMPLATE
        end
      end
    end
  end
end