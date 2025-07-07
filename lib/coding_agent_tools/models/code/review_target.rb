# frozen_string_literal: true

module CodingAgentTools
  module Models
    module Code
      # Represents the target of a code review (what is being reviewed)
      # This is a pure data structure with no external dependencies
      ReviewTarget = Struct.new(
        :type,            # Target type: 'git_diff', 'file_pattern', 'single_file'
        :target_spec,     # Original target specification string
        :resolved_paths,  # Array of resolved file paths (for file-based targets)
        :content_type,    # Content format: 'diff' or 'xml'
        :size_info,       # Hash with size information: {lines: N, words: N, files: N}
        keyword_init: true
      ) do
        # Validate required fields
        def validate!
          raise ArgumentError, "type is required" if type.nil? || type.empty?
          raise ArgumentError, "target_spec is required" if target_spec.nil? || target_spec.empty?
          raise ArgumentError, "content_type is required" if content_type.nil? || content_type.empty?
          
          valid_types = %w[git_diff file_pattern single_file]
          raise ArgumentError, "type must be one of: #{valid_types.join(', ')}" unless valid_types.include?(type)
          
          valid_content_types = %w[diff xml]
          raise ArgumentError, "content_type must be one of: #{valid_content_types.join(', ')}" unless valid_content_types.include?(content_type)
          
          true
        end

        # Check if target is git-based
        def git_based?
          type == "git_diff"
        end

        # Check if target is file-based
        def file_based?
          %w[file_pattern single_file].include?(type)
        end

        # Get file count
        def file_count
          if file_based? && resolved_paths
            resolved_paths.size
          elsif size_info && size_info[:files]
            size_info[:files]
          else
            0
          end
        end

        # Get line count
        def line_count
          size_info && size_info[:lines] || 0
        end

        # Get word count
        def word_count
          size_info && size_info[:words] || 0
        end

        # Special target keywords
        def self.special_keywords
          %w[staged unstaged working]
        end

        # Check if target is a special keyword
        def special_keyword?
          self.class.special_keywords.include?(target_spec)
        end
      end
    end
  end
end