# frozen_string_literal: true

require_relative "../molecules/release_resolver"
require_relative "../molecules/config_loader"

module Ace
  module Taskflow
    module Organisms
      # Handles release metadata updates and rescheduling
      class ReleaseScheduler
        def initialize(root_path = nil)
          @root_path = root_path || Molecules::ConfigLoader.find_root
          @release_resolver = Molecules::ReleaseResolver.new(@root_path)
        end

        # Reschedule release with updated metadata
        # @param reference [String] Release reference (e.g., v.0.9.0)
        # @param options [Hash] Update options
        # @option options [String] :status New status value
        # @option options [String] :target_date Target completion date (YYYY-MM-DD)
        # @return [Hash] Result with :success and :message
        def reschedule(reference, options = {})
          # Find the release
          release = @release_resolver.find_release(reference)
          unless release
            return { success: false, message: "Release '#{reference}' not found" }
          end

          # Check if release has a metadata file
          release_meta_file = find_release_metadata_file(release[:path])

          # Update metadata
          updates = {}
          updates[:status] = options[:status] if options[:status]
          updates[:target_date] = options[:target_date] if options[:target_date]

          if updates.empty?
            return { success: false, message: "No updates specified" }
          end

          # Update or create metadata file
          if update_release_metadata(release[:path], release_meta_file, updates)
            message = build_update_message(reference, updates)
            { success: true, message: message }
          else
            { success: false, message: "Failed to update release metadata" }
          end
        end

        private

        def find_release_metadata_file(release_path)
          # Look for common metadata files
          possible_files = [
            File.join(release_path, "release.yml"),
            File.join(release_path, "release.yaml"),
            File.join(release_path, ".release"),
            File.join(release_path, "metadata.yml")
          ]

          possible_files.find { |f| File.exist?(f) }
        end

        def update_release_metadata(release_path, metadata_file, updates)
          # If no metadata file exists, create one
          metadata_file ||= File.join(release_path, "release.yml")

          # Load existing metadata or start fresh
          metadata = if File.exist?(metadata_file)
            require 'yaml'
            YAML.load_file(metadata_file) || {}
          else
            {}
          end

          # Apply updates
          updates.each do |key, value|
            metadata[key.to_s] = value
          end

          # Add timestamp
          metadata["updated_at"] = Time.now.iso8601

          # Write metadata back
          require 'yaml'
          File.write(metadata_file, metadata.to_yaml)
          true
        rescue StandardError => e
          false
        end

        def build_update_message(reference, updates)
          parts = ["Release '#{reference}' updated:"]

          if updates[:status]
            parts << "  Status: #{updates[:status]}"
          end

          if updates[:target_date]
            parts << "  Target date: #{updates[:target_date]}"
          end

          parts.join("\n")
        end
      end
    end
  end
end