# frozen_string_literal: true

require "date"
require "time"
require_relative "../atoms/timestamp_parser"

module Ace
  module Docs
    module Models
      # Model representing a managed document with frontmatter and content
      class Document
        attr_accessor :path, :frontmatter, :content, :doc_type, :purpose,
                      :update_config, :context_config, :rules, :metadata

        def initialize(path: nil, frontmatter: {}, content: "")
          @path = path
          @frontmatter = frontmatter || {}
          @content = content || ""

          # Extract key fields from frontmatter
          @doc_type = @frontmatter["doc-type"]
          @purpose = @frontmatter["purpose"]
          @update_config = @frontmatter["update"] || {}
          @context_config = @frontmatter["context"] || {}
          @rules = @frontmatter["rules"] || {}
          @metadata = @frontmatter["metadata"] || {}

          # Extract ace-docs namespace configuration
          @ace_docs_config = @frontmatter["ace-docs"] || {}
        end

        # Check if document is managed by ace-docs
        def managed?
          !@doc_type.nil? && !@purpose.nil?
        end

        # Get the update frequency configuration
        def update_frequency
          @update_config["frequency"] || "on-change"
        end

        # Get the last updated date or datetime
        #
        # Polymorphic Return Type:
        #   - Date object for date-only timestamps (YYYY-MM-DD)
        #   - Time object (UTC) for ISO 8601 timestamps (YYYY-MM-DDTHH:MM:SSZ)
        #
        # This preserves the precision of the original timestamp format. When comparing
        # dates for freshness calculations, Time objects are converted to Date objects.
        #
        # @return [Date, Time, nil] The last updated timestamp, or nil if not set
        def last_updated
          # Try ace-docs namespace first
          date_str = @ace_docs_config["last-updated"]

          return nil unless date_str

          result = case date_str
                   when Date, Time
                     date_str  # Return as-is
                   when String
                     Atoms::TimestampParser.parse_timestamp(date_str)
                   else
                     nil
                   end

          # Ensure Time objects are in UTC
          result.is_a?(Time) ? result.utc : result
        rescue ArgumentError
          nil
        end

        # Get the last checked date or datetime
        #
        # Polymorphic Return Type:
        #   - Date object for date-only timestamps (YYYY-MM-DD)
        #   - Time object (UTC) for ISO 8601 timestamps (YYYY-MM-DDTHH:MM:SSZ)
        #
        # @return [Date, Time, nil] The last checked timestamp, or nil if not set
        # @see #last_updated for detailed behavior documentation
        def last_checked
          date_str = @update_config["last-checked"]
          return nil unless date_str

          result = case date_str
                   when Date, Time
                     date_str  # Return as-is
                   when String
                     Atoms::TimestampParser.parse_timestamp(date_str)
                   else
                     nil
                   end

          # Ensure Time objects are in UTC
          result.is_a?(Time) ? result.utc : result
        rescue ArgumentError
          nil
        end

        # Check if document needs updating based on frequency and last updated date
        def needs_update?
          return true unless last_updated

          # Convert Time to Date for comparison
          last_updated_date = last_updated.is_a?(Time) ? last_updated.to_date : last_updated
          days_since_update = (Date.today - last_updated_date).to_i

          case update_frequency
          when "daily"
            days_since_update >= 1
          when "weekly"
            days_since_update >= 7
          when "monthly"
            days_since_update >= 30
          when "on-change"
            false # Only update when changes detected
          else
            false
          end
        end

        # Get the freshness status
        # Uses configurable thresholds from .ace-defaults/docs/config.yml
        # Follows ADR-022 pattern for configuration loading
        def freshness_status
          return :unknown unless last_updated

          # Convert Time to Date for comparison
          last_updated_date = last_updated.is_a?(Time) ? last_updated.to_date : last_updated
          days_since_update = (Date.today - last_updated_date).to_i

          thresholds = freshness_thresholds

          case update_frequency
          when "daily"
            if days_since_update == 0
              :current
            elsif days_since_update <= thresholds[:daily_stale]
              :stale
            else
              :outdated
            end
          when "weekly"
            if days_since_update <= thresholds[:weekly_current]
              :current
            elsif days_since_update <= thresholds[:weekly_stale]
              :stale
            else
              :outdated
            end
          when "monthly"
            if days_since_update <= thresholds[:monthly_current]
              :current
            elsif days_since_update <= thresholds[:monthly_stale]
              :stale
            else
              :outdated
            end
          when "on-change"
            :current # Always current for on-change documents
          else
            :unknown
          end
        end

        # Get freshness thresholds from configuration
        # Falls back to historical defaults if config not available
        # Supports frequency-specific thresholds from .ace-defaults/docs/config.yml
        # @return [Hash] Threshold values for different update frequencies
        def freshness_thresholds
          config_thresholds = Ace::Docs.config["default_freshness_days"] || {}

          # Extract frequency-specific thresholds with historical defaults
          daily_config = config_thresholds["daily"] || {}
          weekly_config = config_thresholds["weekly"] || {}
          monthly_config = config_thresholds["monthly"] || {}

          {
            # Daily frequency: current=today (0 days), stale within 2 days
            daily_stale: daily_config["stale"] || 2,
            # Weekly frequency: historical defaults 7/14 days
            weekly_current: weekly_config["current"] || 7,
            weekly_stale: weekly_config["stale"] || 14,
            # Monthly frequency: historical defaults 30/45 days
            monthly_current: monthly_config["current"] || 30,
            monthly_stale: monthly_config["stale"] || 45
          }
        end

        # Get the focus hints for LLM analysis
        def focus_hints
          @update_config["focus"] || {}
        end

        # Get the ace-docs configuration namespace
        def ace_docs_config
          @ace_docs_config
        end

        # Get subject diff filters
        # @return [Array<String>] Flat array of path filters for single subject
        def subject_diff_filters
          # Try new format first
          filters = @ace_docs_config.dig("subject", "diff", "filters")
          return filters if filters && !filters.empty?

          []
        end

        # Check if document has multi-subject configuration
        # @return [Boolean] True if subject is an array of hashes
        def multi_subject?
          subject_config = @ace_docs_config["subject"]
          subject_config.is_a?(Array)
        end

        # Get structured subject configurations for multi-subject support
        # @return [Array<Hash>] Array of {name: String, filters: Array<String>}
        def subject_configurations
          subject_config = @ace_docs_config["subject"]

          if subject_config.is_a?(Array)
            # Multi-subject format: array of single-key hashes
            # [ { "code" => { "diff" => { "filters" => [...] } } }, { "docs" => {...} } ]
            subject_config.map do |subject_hash|
              # Each item should be a hash with one key (the subject name)
              name = subject_hash.keys.first
              config = subject_hash[name] || {}
              filters = config.dig("diff", "filters") || []

              {
                name: name,
                filters: filters
              }
            end.reject { |s| s[:filters].empty? }
          else
            # No valid subject configuration
            []
          end
        end

        # Get context keywords for LLM analysis
        def context_keywords
          @ace_docs_config.dig("context", "keywords") || []
        end

        # Get the context preset
        def context_preset
          # Try new ace-docs namespace first
          preset = @ace_docs_config.dig("context", "preset")
          return preset if preset

          # Fall back to legacy format
          @context_config["preset"]
        end

        # Get additional context includes
        def context_includes
          @context_config["includes"] || []
        end

        # Get the maximum line count rule
        def max_lines
          @rules["max-lines"]
        end

        # Get required sections
        def required_sections
          @rules["sections"] || []
        end

        # Get documents to avoid duplication from
        def no_duplicate_from
          @rules["no-duplicate-from"] || []
        end

        # Get auto-generation rules
        def auto_generate
          @rules["auto-generate"] || []
        end

        # Get the document title from content
        def title
          # Extract first heading from content
          match = @content.match(/^#\s+(.+)$/m)
          match ? match[1].strip : File.basename(@path || "untitled", ".md")
        end

        # Get display name for document
        def display_name
          @path ? File.basename(@path) : "untitled.md"
        end

        # Get relative path from current directory
        def relative_path
          return nil unless @path

          begin
            require 'pathname'
            # Try to get a nice relative path from current directory
            pwd_path = Pathname.new(Dir.pwd)
            file_path = Pathname.new(@path)

            # If file is under current directory or we can compute relative path
            relative = file_path.relative_path_from(pwd_path).to_s

            # If relative path goes up too many levels, just use absolute
            if relative.start_with?("../../../")
              @path
            else
              relative
            end
          rescue
            # If we can't compute relative path, use absolute
            @path
          end
        end

        # Convert to hash for serialization
        def to_h
          {
            path: @path,
            doc_type: @doc_type,
            purpose: @purpose,
            title: title,
            last_updated: last_updated&.to_s,
            update_frequency: update_frequency,
            needs_update: needs_update?,
            freshness: freshness_status,
            rules: @rules,
            context: @context_config,
            metadata: @metadata
          }
        end

        # Format for display
        def to_s
          "Document: #{display_name} (#{@doc_type || 'untyped'})"
        end

        # Check equality
        def ==(other)
          return false unless other.is_a?(Document)
          @path == other.path
        end

        # Generate hash code
        def hash
          @path.hash
        end

        # Make documents comparable by path
        def <=>(other)
          return nil unless other.is_a?(Document)
          (@path || "") <=> (other.path || "")
        end
      end
    end
  end
end
