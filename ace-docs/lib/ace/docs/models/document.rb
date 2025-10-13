# frozen_string_literal: true

require "date"

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
        end

        # Check if document is managed by ace-docs
        def managed?
          !@doc_type.nil? && !@purpose.nil?
        end

        # Get the update frequency configuration
        def update_frequency
          @update_config["frequency"] || "on-change"
        end

        # Get the last updated date
        def last_updated
          date_str = @update_config["last-updated"]
          return nil unless date_str

          case date_str
          when Date
            date_str
          when Time
            date_str.to_date
          when String
            Date.parse(date_str)
          else
            nil
          end
        rescue ArgumentError
          nil
        end

        # Get the last checked date
        def last_checked
          date_str = @update_config["last-checked"]
          return nil unless date_str

          case date_str
          when Date
            date_str
          when Time
            date_str.to_date
          when String
            Date.parse(date_str)
          else
            nil
          end
        rescue ArgumentError
          nil
        end

        # Check if document needs updating based on frequency and last updated date
        def needs_update?
          return true unless last_updated

          days_since_update = (Date.today - last_updated).to_i

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
        def freshness_status
          return :unknown unless last_updated

          days_since_update = (Date.today - last_updated).to_i

          case update_frequency
          when "daily"
            if days_since_update == 0
              :current
            elsif days_since_update <= 2
              :stale
            else
              :outdated
            end
          when "weekly"
            if days_since_update <= 7
              :current
            elsif days_since_update <= 14
              :stale
            else
              :outdated
            end
          when "monthly"
            if days_since_update <= 30
              :current
            elsif days_since_update <= 45
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

        # Get the focus hints for LLM analysis
        def focus_hints
          @update_config["focus"] || {}
        end

        # Get the context preset
        def context_preset
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

        # Get relative path from project root
        def relative_path
          return nil unless @path

          if @path.start_with?(Dir.pwd)
            @path.sub("#{Dir.pwd}/", "")
          else
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