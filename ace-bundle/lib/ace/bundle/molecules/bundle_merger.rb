# frozen_string_literal: true

require "time"

module Ace
  module Bundle
    module Molecules
      # BundleMerger merges multiple bundle results into a single combined result
      class BundleMerger
        # Merge multiple bundle results into one
        def merge_bundles(bundles)
          return empty_merge_result if bundles.nil? || bundles.empty?
          return bundles.first if bundles.size == 1

          {
            success: true,
            files: merge_files(bundles),
            commands: merge_commands(bundles),
            errors: merge_errors(bundles),
            sources: extract_sources(bundles),
            metadata: merge_metadata(bundles),
            merged: true,
            total_bundles: bundles.size,
            total_files: bundles.sum { |c| c[:total_files] || c[:files]&.size || 0 },
            total_commands: bundles.sum { |c| c[:total_commands] || c[:commands]&.size || 0 },
            total_errors: bundles.sum { |c| c[:total_errors] || c[:errors]&.size || 0 },
            total_size: bundles.sum { |c| c[:total_size] || 0 }
          }
        end

        # Determine output path from multiple presets
        def resolve_output_path(presets, command_output = nil)
          # Command-line flag has highest priority
          return command_output if command_output

          # Extract output paths from presets
          output_paths = presets.map { |p| p[:output] }.compact

          # If any preset wants stdout (no output), use stdout
          return nil if output_paths.size < presets.size

          # If all presets have the same output path, use it
          return output_paths.first if output_paths.uniq.size == 1

          # Different output paths = conflict, default to stdout
          nil
        end

        # Merge data structures with source attribution
        def merge_with_attribution(bundles, source_key = nil)
          merged_data = {
            files: [],
            commands: [],
            errors: [],
            metadata: {}
          }

          bundles.each do |bundle|
            source = extract_source(bundle, source_key)

            # Add files with source
            if bundle[:files]
              bundle[:files].each do |file|
                file_with_source = file.dup
                file_with_source[:source] = source if source
                merged_data[:files] << file_with_source
              end
            end

            # Add commands with source
            if bundle[:commands]
              bundle[:commands].each do |cmd|
                cmd_with_source = cmd.dup
                cmd_with_source[:source] = source if source
                merged_data[:commands] << cmd_with_source
              end
            end

            # Collect errors
            if bundle[:errors]
              merged_data[:errors].concat(bundle[:errors])
            end

            # Merge metadata
            if bundle[:metadata]
              merged_data[:metadata] = deep_merge(merged_data[:metadata], bundle[:metadata])
            end
          end

          merged_data
        end

        private

        # Return empty hash structure for nil/empty bundle inputs
        # This ensures consistent return type with multi-bundle merge results
        def empty_merge_result
          {
            success: true,
            files: [],
            commands: [],
            errors: [],
            sources: [],
            metadata: {merged_at: Time.now.iso8601},
            merged: false,
            total_bundles: 0,
            total_files: 0,
            total_commands: 0,
            total_errors: 0,
            total_size: 0
          }
        end

        # Merge files from multiple bundles, deduplicating by path
        def merge_files(bundles)
          seen_paths = Set.new
          merged = []

          bundles.each do |bundle|
            next unless bundle[:files]

            bundle[:files].each do |file|
              path = file[:path]
              unless seen_paths.include?(path)
                seen_paths.add(path)
                # Add source attribution if available
                file[:source] = bundle[:source_input] || bundle[:preset_name] if bundle[:source_input] || bundle[:preset_name]
                merged << file
              end
            end
          end

          merged
        end

        # Merge commands from multiple bundles
        def merge_commands(bundles)
          merged = []

          bundles.each do |bundle|
            next unless bundle[:commands]

            bundle[:commands].each do |cmd|
              # Add source attribution
              cmd[:source] = bundle[:source_input] || bundle[:preset_name] if bundle[:source_input] || bundle[:preset_name]
              merged << cmd
            end
          end

          merged
        end

        # Merge errors from multiple bundles
        def merge_errors(bundles)
          errors = []

          bundles.each do |bundle|
            next unless bundle[:errors]

            bundle[:errors].each do |error|
              # Add source information to error if not present
              if error.is_a?(String)
                source = bundle[:source_input] || bundle[:preset_name]
                errors << (source ? "[#{source}] #{error}" : error)
              else
                errors << error
              end
            end
          end

          errors.uniq
        end

        # Extract source information from bundles
        def extract_sources(bundles)
          sources = []

          bundles.each do |bundle|
            if bundle[:preset_name]
              sources << {type: "preset", name: bundle[:preset_name]}
            elsif bundle[:source_input]
              sources << {type: "input", path: bundle[:source_input]}
            elsif bundle[:file_path]
              sources << {type: "file", path: bundle[:file_path]}
            end
          end

          sources
        end

        # Merge metadata from multiple bundles
        def merge_metadata(bundles)
          metadata = {}

          bundles.each do |bundle|
            next unless bundle[:metadata]

            metadata = deep_merge(metadata, bundle[:metadata])
          end

          # Add merge timestamp
          metadata[:merged_at] = Time.now.iso8601

          metadata
        end

        # Extract source identifier from bundle
        def extract_source(bundle, source_key = nil)
          if source_key && bundle[source_key]
            bundle[source_key]
          elsif bundle[:preset_name]
            "preset:#{bundle[:preset_name]}"
          elsif bundle[:source_input]
            "input:#{bundle[:source_input]}"
          elsif bundle[:file_path]
            "file:#{bundle[:file_path]}"
          end
        end

        # Deep merge two hashes
        def deep_merge(hash1, hash2)
          return hash2 if hash1.nil?
          return hash1 if hash2.nil?

          merged = hash1.dup

          hash2.each do |key, value2|
            if merged.key?(key)
              value1 = merged[key]

              merged[key] = if value1.is_a?(Hash) && value2.is_a?(Hash)
                deep_merge(value1, value2)
              elsif value1.is_a?(Array) && value2.is_a?(Array)
                (value1 + value2).uniq
              else
                value2
              end
            else
              merged[key] = value2
            end
          end

          merged
        end
      end
    end
  end
end
