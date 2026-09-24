# frozen_string_literal: true

require "digest"
require_relative "../atoms/diff_boundary_finder"
require_relative "subject_filter"

module Ace
  module Review
    module Molecules
      # Selects complete file diffs before ace-bundle renders a review packet.
      # Refuses unparsed input instead of silently dropping a changed file.
      module DiffScope
        def self.select(diff, patterns = nil, groups: nil)
          patterns = patterns.transform_keys(&:to_s) if patterns.is_a?(Hash)
          groups = groups.map { |group| group.is_a?(Hash) ? group.transform_keys(&:to_s) : group } if groups.is_a?(Array)
          valid_groups = groups.nil? || (groups.is_a?(Array) && groups.all? { |group| valid_patterns?(group) && !group.nil? })
          unless valid_patterns?(patterns) && valid_groups
            return {success: false, error: "Review file patterns/groups must contain include/exclude arrays of glob strings"}
          end

          blocks = Atoms::DiffBoundaryFinder.parse(diff)
          unless blocks.any? && blocks.map { |block| block[:content] }.join == diff
            return {success: false, error: "Cannot account for every PR diff block; review input is incomplete"}
          end

          filters = [patterns, *Array(groups)].compact
          selected, excluded = blocks.partition { |block| selected_block?(block, filters) }
          if selected.empty?
            return {success: false, error: "Review scope contains no changed files"}
          end

          {
            success: true,
            diff: selected.map { |block| block[:content] }.join,
            manifest: {
              raw_sha256: Digest::SHA256.hexdigest(diff),
              selected_sha256: Digest::SHA256.hexdigest(selected.map { |block| block[:content] }.join),
              selected_files: selected.map { |block| block[:path] },
              excluded_files: excluded.map { |block| block[:path] },
              binary_files: binary_paths(blocks),
              renames: selected.filter_map do |block|
                {from: block[:old_path], to: block[:path]} if block[:old_path] != block[:path]
              end,
              received_diff_accounted_for: true,
              file_pattern_groups: filters
            }
          }
        rescue ArgumentError => e
          {success: false, error: "Cannot account for every PR diff block: #{e.message}"}
        end

        def self.binary_paths(blocks)
          blocks.select { |block| binary_only?(block) }.map { |block| block[:path] }
        end

        def self.valid_patterns?(patterns)
          return true if patterns.nil?
          return false unless patterns.is_a?(Hash)
          return false unless (patterns.keys.map(&:to_s) - %w[include exclude]).empty?

          patterns.values.all? { |value| value.is_a?(Array) && value.all? { |item| item.is_a?(String) && !item.empty? } }
        end
        private_class_method :valid_patterns?

        def self.binary_only?(block)
          block[:content].each_line.any? do |line|
            line.start_with?("Binary files ", "GIT binary patch")
          end
        end
        private_class_method :binary_only?

        def self.selected_block?(block, filters)
          return true if filters.empty?
          paths = [block[:path], block[:old_path]].compact.uniq
          return false if filters.any? do |patterns|
            paths.any? do |path|
              Array(patterns["exclude"]).any? { |pattern| SubjectFilter.glob_match?(pattern, path) }
            end
          end

          paths.any? do |path|
            filters.all? do |patterns|
              includes = Array(patterns["include"])
              includes.empty? || includes.any? { |pattern| SubjectFilter.glob_match?(pattern, path) }
            end
          end
        end
        private_class_method :selected_block?
      end
    end
  end
end
