# frozen_string_literal: true

require 'set'
require 'time'

module Ace
  module Core
    module Molecules
      # ContextMerger merges multiple context results into a single combined result
      class ContextMerger
        # Merge multiple context results into one
        def merge_contexts(contexts)
          return contexts.first if contexts.nil? || contexts.empty?
          return contexts.first if contexts.size == 1

          {
            success: true,
            files: merge_files(contexts),
            commands: merge_commands(contexts),
            errors: merge_errors(contexts),
            sources: extract_sources(contexts),
            metadata: merge_metadata(contexts),
            merged: true,
            total_contexts: contexts.size,
            total_files: contexts.sum { |c| c[:total_files] || c[:files]&.size || 0 },
            total_commands: contexts.sum { |c| c[:total_commands] || c[:commands]&.size || 0 },
            total_errors: contexts.sum { |c| c[:total_errors] || c[:errors]&.size || 0 },
            total_size: contexts.sum { |c| c[:total_size] || 0 }
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
        def merge_with_attribution(contexts, source_key = nil)
          merged_data = {
            files: [],
            commands: [],
            errors: [],
            metadata: {}
          }

          contexts.each do |context|
            source = extract_source(context, source_key)

            # Add files with source
            if context[:files]
              context[:files].each do |file|
                file_with_source = file.dup
                file_with_source[:source] = source if source
                merged_data[:files] << file_with_source
              end
            end

            # Add commands with source
            if context[:commands]
              context[:commands].each do |cmd|
                cmd_with_source = cmd.dup
                cmd_with_source[:source] = source if source
                merged_data[:commands] << cmd_with_source
              end
            end

            # Collect errors
            if context[:errors]
              merged_data[:errors].concat(context[:errors])
            end

            # Merge metadata
            if context[:metadata]
              merged_data[:metadata] = deep_merge(merged_data[:metadata], context[:metadata])
            end
          end

          merged_data
        end

        private

        # Merge files from multiple contexts, deduplicating by path
        def merge_files(contexts)
          seen_paths = Set.new
          merged = []

          contexts.each do |context|
            next unless context[:files]

            context[:files].each do |file|
              path = file[:path]
              unless seen_paths.include?(path)
                seen_paths.add(path)
                # Add source attribution if available
                file[:source] = context[:source_input] || context[:preset_name] if context[:source_input] || context[:preset_name]
                merged << file
              end
            end
          end

          merged
        end

        # Merge commands from multiple contexts
        def merge_commands(contexts)
          merged = []

          contexts.each do |context|
            next unless context[:commands]

            context[:commands].each do |cmd|
              # Add source attribution
              cmd[:source] = context[:source_input] || context[:preset_name] if context[:source_input] || context[:preset_name]
              merged << cmd
            end
          end

          merged
        end

        # Merge errors from multiple contexts
        def merge_errors(contexts)
          errors = []

          contexts.each do |context|
            next unless context[:errors]

            context[:errors].each do |error|
              # Add source information to error if not present
              if error.is_a?(String)
                source = context[:source_input] || context[:preset_name]
                errors << (source ? "[#{source}] #{error}" : error)
              else
                errors << error
              end
            end
          end

          errors.uniq
        end

        # Extract source information from contexts
        def extract_sources(contexts)
          sources = []

          contexts.each do |context|
            if context[:preset_name]
              sources << { type: 'preset', name: context[:preset_name] }
            elsif context[:source_input]
              sources << { type: 'input', path: context[:source_input] }
            elsif context[:file_path]
              sources << { type: 'file', path: context[:file_path] }
            end
          end

          sources
        end

        # Merge metadata from multiple contexts
        def merge_metadata(contexts)
          metadata = {}

          contexts.each do |context|
            next unless context[:metadata]

            metadata = deep_merge(metadata, context[:metadata])
          end

          # Add merge timestamp
          metadata[:merged_at] = Time.now.iso8601

          metadata
        end

        # Extract source identifier from context
        def extract_source(context, source_key = nil)
          if source_key && context[source_key]
            context[source_key]
          elsif context[:preset_name]
            "preset:#{context[:preset_name]}"
          elsif context[:source_input]
            "input:#{context[:source_input]}"
          elsif context[:file_path]
            "file:#{context[:file_path]}"
          else
            nil
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