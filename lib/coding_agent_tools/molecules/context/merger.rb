# frozen_string_literal: true

require "set"

module CodingAgentTools
  module Molecules
    module Context
      # Merger - Molecule for merging multiple context results
      #
      # Responsibilities:
      # - Merge multiple context results into a single combined result
      # - Deduplicate files by path (first occurrence wins)
      # - Preserve all commands with source attribution
      # - Aggregate errors from all sources
      # - Track metadata about merged sources
      class Merger
        # Merge multiple context results into one
        #
        # @param contexts [Array<Hash>] Array of context results to merge
        # @return [Hash] Merged context result
        def merge_contexts(contexts)
          return contexts.first if contexts.nil? || contexts.empty?
          return contexts.first if contexts.size == 1

          {
            success: true,
            files: merge_files(contexts),
            commands: merge_commands(contexts),
            errors: merge_errors(contexts),
            sources: extract_sources(contexts),
            merged: true,
            total_contexts: contexts.size,
            total_files: contexts.sum { |c| c[:total_files] || c[:files]&.size || 0 },
            total_commands: contexts.sum { |c| c[:total_commands] || c[:commands]&.size || 0 },
            total_errors: contexts.sum { |c| c[:total_errors] || c[:errors]&.size || 0 },
            total_size: contexts.sum { |c| c[:total_size] || 0 }
          }
        end

        # Determine output path from multiple presets
        #
        # @param presets [Array<Hash>] Array of preset configurations
        # @param command_output [String, nil] Output path from command line
        # @return [String, nil] Resolved output path (nil means stdout)
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

        private

        # Merge files from multiple contexts, deduplicating by path
        #
        # @param contexts [Array<Hash>] Context results
        # @return [Array<Hash>] Merged files array
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
        #
        # @param contexts [Array<Hash>] Context results
        # @return [Array<Hash>] Merged commands array
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
        #
        # @param contexts [Array<Hash>] Context results
        # @return [Array<String>] Merged errors array
        def merge_errors(contexts)
          contexts.flat_map { |c| c[:errors] || [] }
        end

        # Extract source identifiers from contexts
        #
        # @param contexts [Array<Hash>] Context results
        # @return [Array<String>] List of source identifiers
        def extract_sources(contexts)
          contexts.map do |context|
            context[:source_input] || context[:preset_name] || "unknown"
          end.compact
        end
      end
    end
  end
end
