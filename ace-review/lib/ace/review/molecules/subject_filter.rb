# frozen_string_literal: true

module Ace
  module Review
    module Molecules
      # Pure module for filtering review subjects based on file patterns.
      #
      # Provides file pattern matching logic for filtering diff content,
      # file lists, and bundle sections. Uses glob patterns with include/exclude
      # semantics following the standard: include patterns whitelist files,
      # exclude patterns blacklist them.
      #
      # @example Filtering a diff
      #   patterns = { "include" => ["lib/**/*.rb"], "exclude" => ["**/*_test.rb"] }
      #   SubjectFilter.filter(diff_string, patterns)
      #
      # @example Checking file match
      #   SubjectFilter.matches_file?("lib/models/user.rb", patterns)
      #   #=> true
      #
      module SubjectFilter
        # File.fnmatch flags for glob pattern matching
        FNMATCH_FLAGS = File::FNM_PATHNAME | File::FNM_EXTGLOB

        # Filter subject content based on file patterns
        #
        # Dispatches to appropriate filter method based on subject type.
        # Returns subject unchanged if no patterns configured.
        #
        # @param subject [String, Hash] Subject to filter (diff string or hash)
        # @param file_patterns [Hash, nil] File patterns with include/exclude arrays
        # @return [String, Hash] Filtered subject
        def self.filter(subject, file_patterns)
          return subject unless has_patterns?(file_patterns)

          case subject
          when String
            filter_diff(subject, file_patterns)
          when Hash
            filter_hash(subject, file_patterns)
          else
            subject
          end
        end

        # Filter diff content based on file patterns
        #
        # Splits diff into per-file chunks, filters by patterns, and rejoins.
        # Uses the destination (b/) path for consistency with renamed files.
        #
        # @param diff_content [String] Git diff content
        # @param file_patterns [Hash] File patterns with include/exclude arrays
        # @return [String] Filtered diff with only matching files
        def self.filter_diff(diff_content, file_patterns)
          return diff_content unless has_patterns?(file_patterns)

          # Split diff into file chunks
          chunks = split_diff_into_chunks(diff_content)

          # Filter chunks based on file patterns
          filtered_chunks = chunks.select do |chunk|
            file_path = extract_file_path_from_chunk(chunk)
            file_path ? matches_file?(file_path, file_patterns) : true
          end

          filtered_chunks.join
        end

        # Filter subject hash based on file patterns
        #
        # Filters files arrays and bundle sections within the hash.
        #
        # @param subject [Hash] Subject hash with files or sections
        # @param file_patterns [Hash] File patterns with include/exclude arrays
        # @return [Hash] Filtered subject
        def self.filter_hash(subject, file_patterns)
          return subject unless has_patterns?(file_patterns)

          result = normalize_keys(subject.dup)

          # Filter files array if present
          if result["files"].is_a?(Array)
            result["files"] = result["files"].select { |f| matches_file?(f.to_s, file_patterns) }
          end

          # Filter bundle sections if present
          if result["bundle"].is_a?(Hash) && result["bundle"]["sections"].is_a?(Hash)
            result["bundle"] = normalize_keys(result["bundle"].dup)
            result["bundle"]["sections"] = filter_bundle_sections(result["bundle"]["sections"], file_patterns)
          end

          result
        end

        # Filter bundle sections based on file patterns
        #
        # Recursively filters files arrays within each section.
        #
        # @param sections [Hash] Bundle sections
        # @param file_patterns [Hash] File patterns with include/exclude arrays
        # @return [Hash] Filtered sections
        def self.filter_bundle_sections(sections, file_patterns)
          filtered = {}

          sections.each do |name, section|
            section = normalize_keys(section) if section.is_a?(Hash)

            if section.is_a?(Hash) && section["files"].is_a?(Array)
              filtered_files = section["files"].select { |f| matches_file?(f.to_s, file_patterns) }
              next if filtered_files.empty?

              filtered[name] = section.merge("files" => filtered_files)
            else
              filtered[name] = section
            end
          end

          filtered
        end

        # Check if a file path matches the given patterns
        #
        # Include patterns: file must match at least one (if any exist)
        # Exclude patterns: file must not match any
        #
        # @param file_path [String] File path to check
        # @param file_patterns [Hash] File patterns with include/exclude arrays
        # @return [Boolean] True if file matches patterns
        def self.matches_file?(file_path, file_patterns)
          return true unless has_patterns?(file_patterns)

          includes = file_patterns["include"] || []
          excludes = file_patterns["exclude"] || []

          # If include patterns exist, file must match at least one
          if includes.any?
            return false unless includes.any? { |pattern| File.fnmatch?(pattern, file_path, FNMATCH_FLAGS) }
          end

          # File must not match any exclude pattern
          return false if excludes.any? { |pattern| File.fnmatch?(pattern, file_path, FNMATCH_FLAGS) }

          true
        end

        # Check if file patterns are configured and non-empty
        #
        # @param file_patterns [Hash, nil] File patterns hash
        # @return [Boolean] True if patterns are configured
        def self.has_patterns?(file_patterns)
          return false unless file_patterns.is_a?(Hash)

          (file_patterns["include"].is_a?(Array) && file_patterns["include"].any?) ||
            (file_patterns["exclude"].is_a?(Array) && file_patterns["exclude"].any?)
        end

        # Split diff content into per-file chunks
        #
        # @param diff_content [String] Git diff content
        # @return [Array<String>] Array of diff chunks
        def self.split_diff_into_chunks(diff_content)
          chunks = diff_content.split(/(?=^diff --git )/m)
          chunks.reject(&:empty?)
        end
        private_class_method :split_diff_into_chunks

        # Extract file path from a diff chunk
        #
        # Uses the destination (b/) path for consistency with DiffBoundaryFinder.
        # For renamed files, this ensures filtering uses the new name, not the old.
        #
        # @param chunk [String] Diff chunk
        # @return [String, nil] File path or nil if not found
        def self.extract_file_path_from_chunk(chunk)
          # Match "diff --git a/path b/path" - use b/ side (destination path)
          if chunk =~ /^diff --git a\/.+? b\/(.+?)$/m
            return Regexp.last_match(1)
          end
          # Fallback to +++ header for edge cases
          if chunk =~ /^\+\+\+ b\/(.+)$/
            return Regexp.last_match(1)
          end
          nil
        end
        private_class_method :extract_file_path_from_chunk

        # Normalize hash keys to strings
        #
        # @param hash [Hash] Hash with symbol or string keys
        # @return [Hash] Hash with string keys
        def self.normalize_keys(hash)
          return {} unless hash.is_a?(Hash)
          hash.transform_keys(&:to_s)
        end
        private_class_method :normalize_keys
      end
    end
  end
end
