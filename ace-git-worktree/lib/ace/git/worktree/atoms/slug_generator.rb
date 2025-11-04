# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Atoms
        # Pure functions for generating URL-safe slugs from text
        class SlugGenerator
          DEFAULT_MAX_LENGTH = 50
          DEFAULT_SEPARATOR = "-"

          # Generate a slug from text
          # @param text [String] Text to convert to slug
          # @param max_length [Integer] Maximum length for slug
          # @param separator [String] Character to use between words
          # @return [String] URL-safe slug
          def self.generate(text, max_length: DEFAULT_MAX_LENGTH, separator: DEFAULT_SEPARATOR)
            return "" if text.nil? || text.empty?

            slug = text
              .downcase
              .gsub(/[^a-z0-9\s-]/, "") # Remove special characters
              .gsub(/\s+/, separator)   # Replace spaces with separator
              .gsub(/#{Regexp.escape(separator)}+/, separator) # Collapse multiple separators
              .gsub(/^#{Regexp.escape(separator)}|#{Regexp.escape(separator)}$/, "") # Trim separators

            # Truncate if needed, but try to avoid cutting words
            if slug.length > max_length
              truncated = slug[0...max_length]
              # Try to find last separator to avoid cutting a word
              last_sep = truncated.rindex(separator)
              if last_sep && last_sep > max_length / 2
                truncated = truncated[0...last_sep]
              end
              slug = truncated.gsub(/#{Regexp.escape(separator)}$/, "")
            end

            # Return empty string if only special chars were in input
            slug.empty? ? "" : slug
          end

          # Generate a git-safe branch name from text
          # @param text [String] Text to convert
          # @param prefix [String] Optional prefix for branch
          # @param max_length [Integer] Maximum total length
          # @return [String] Git-safe branch name
          def self.branch_name(text, prefix: nil, max_length: 100)
            slug = generate(text, max_length: max_length - (prefix ? prefix.length + 1 : 0))

            # Git branch names can't start with certain characters
            slug = "branch-#{slug}" if slug =~ /^[.-]/ || slug.empty?

            prefix ? "#{prefix}-#{slug}" : slug
          end

          # Validate if a string is a valid git branch name
          # @param name [String] Branch name to validate
          # @return [Boolean] true if valid
          def self.valid_branch_name?(name)
            return false if name.nil? || name.empty?

            # Git branch name rules:
            # - Cannot start with . or -
            # - Cannot end with .lock
            # - Cannot contain .. or @{ or \ or // or spaces
            # - Cannot be HEAD
            return false if name =~ /^[.-]/
            return false if name.end_with?(".lock")
            return false if name.include?("..") || name.include?("@{") ||
                           name.include?("\\") || name.include?("//") ||
                           name.include?(" ")
            return false if name == "HEAD"

            true
          end

          # Sanitize a string for use in file paths
          # @param text [String] Text to sanitize
          # @return [String] Sanitized string safe for file paths
          def self.sanitize_path(text)
            return "" if text.nil? || text.empty?

            # Remove or replace problematic characters for file paths
            text
              .gsub(/[<>:"|?*]/, "") # Remove Windows-incompatible chars
              .gsub(/\//, "-")       # Replace forward slashes with dashes
              .gsub(/\\/, "-")       # Replace backslashes with dashes
              .gsub(/\s+/, "-")      # Replace spaces with dashes
              .gsub(/-+/, "-")       # Collapse multiple dashes
              .gsub(/^-|-$/, "")     # Trim dashes from ends
          end

          # Format a template string with variables
          # @param template [String] Template with {var} placeholders
          # @param variables [Hash] Variable values
          # @return [String] Formatted string
          def self.format_template(template, variables = {})
            return "" if template.nil? || template.empty?

            result = template.dup
            variables.each do |key, value|
              result.gsub!("{#{key}}", value.to_s)
            end
            result
          end

          # Extract variables from a template
          # @param template [String] Template string
          # @return [Array<String>] List of variable names
          def self.extract_variables(template)
            return [] if template.nil? || template.empty?

            template.scan(/\{([^}]+)\}/).flatten.uniq
          end
        end
      end
    end
  end
end