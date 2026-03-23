# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Atoms
        # Slug generation atom
        #
        # Converts task titles and other text into URL-safe slugs suitable
        # for git branch names and directory names.
        #
        # @example Generate a slug from a task title
        #   SlugGenerator.from_title("Fix authentication bug in login flow")
        #   # => "fix-authentication-bug-in-login-flow"
        #
        # @example Generate a slug with custom max length
        #   SlugGenerator.from_title("Very long task title...", max_length: 20)
        #   # => "very-long-task-title"
        class SlugGenerator
          # Default maximum length for slugs
          DEFAULT_MAX_LENGTH = 50

          # Minimum length to avoid empty or too-short slugs
          MIN_LENGTH = 3

          # Characters that are not allowed in git branch names
          FORBIDDEN_CHARS = /[~\^*?\[\]:]/

          # Characters to replace with hyphens
          SEPARATORS = /[ ._\/\\()]+/

          # Multiple consecutive non-word characters (but allow single hyphens)
          MULTIPLE_SEPARATORS = /-{2,}|[^a-zA-Z0-9-]+/

          # Leading/trailing separators and hyphens
          TRIM_SEPARATORS = /^[-_]+|[-_]+$/

          class << self
            # Generate a slug from a task title
            #
            # @param title [String] Task title to convert
            # @param max_length [Integer] Maximum length of the slug
            # @param fallback [String] Fallback string if slug is too short/empty
            # @return [String] URL-safe slug
            #
            # @example
            #   SlugGenerator.from_title("Fix authentication bug")
            #   # => "fix-authentication-bug"
            #
            #   SlugGenerator.from_title("Add user:profile endpoint", max_length: 20)
            #   # => "add-user-profile-end"
            def from_title(title, max_length: DEFAULT_MAX_LENGTH, fallback: "task")
              return fallback if title.nil? || title.empty?

              # Convert to string and strip whitespace
              title_str = title.to_s.strip

              # Remove forbidden characters that git doesn't allow in branch names
              cleaned = title_str.gsub(FORBIDDEN_CHARS, "")

              # Replace separators (spaces, dots, underscores, slashes) with hyphens
              normalized = cleaned.gsub(SEPARATORS, "-")

              # Remove any remaining non-alphanumeric characters except hyphens
              sanitized = normalized.gsub(MULTIPLE_SEPARATORS, "-")

              # Remove leading/trailing hyphens and underscores
              trimmed = sanitized.gsub(TRIM_SEPARATORS, "")

              # Convert to lowercase
              slug = trimmed.downcase

              # Handle empty or too-short result
              if slug.length < MIN_LENGTH
                slug = fallback
              end

              # Truncate to max length, avoiding cutting in the middle of a word if possible
              if slug.length > max_length
                slug = truncate_slug(slug, max_length)
              end

              # Final validation - ensure we still have a valid slug
              if slug.empty? || slug.length < MIN_LENGTH
                slug = fallback
              end

              slug
            end

            # Generate a slug for a task ID
            #
            # @param task_id [String] Task ID (e.g., "081", "task.081", "v.0.9.0+081")
            # @return [String] Simple task ID slug
            #
            # @example
            #   SlugGenerator.from_task_id("081") # => "task-081"
            #   SlugGenerator.from_task_id("v.0.9.0+081") # => "task-081"
            def from_task_id(task_id)
              return "task" if task_id.nil? || task_id.empty?

              # Extract the numeric part from various task ID formats
              numeric_part = task_id.to_s.match(/(\d+)$/)
              return "task-#{task_id}" unless numeric_part

              "task-#{numeric_part[1]}"
            end

            # Generate a combined slug from task ID and title
            #
            # @param task_id [String] Task ID
            # @param title [String] Task title
            # @param max_length [Integer] Maximum length of the combined slug
            # @return [String] Combined slug like "081-fix-authentication-bug"
            #
            # @example
            #   SlugGenerator.combined("081", "Fix authentication bug")
            #   # => "081-fix-authentication-bug"
            def combined(task_id, title, max_length: DEFAULT_MAX_LENGTH)
              task_slug = from_task_id(task_id).gsub(/^task-/, "")
              title_slug = from_title(title, max_length: max_length - task_slug.length - 1)

              "#{task_slug}-#{title_slug}"
            end

            # Sanitize an existing slug
            #
            # @param slug [String] Slug to sanitize
            # @return [String] Sanitized slug
            #
            # @example
            #   SlugGenerator.sanitize("invalid@branch#name") # => "invalid-branch-name"
            def sanitize(slug)
              return "task" if slug.nil? || slug.empty?

              slug_str = slug.to_s.strip

              # Remove forbidden characters
              cleaned = slug_str.gsub(FORBIDDEN_CHARS, "")

              # Replace separators with hyphens
              normalized = cleaned.gsub(SEPARATORS, "-")

              # Remove multiple consecutive separators
              sanitized = normalized.gsub(MULTIPLE_SEPARATORS, "-")

              # Trim leading/trailing separators
              trimmed = sanitized.gsub(TRIM_SEPARATORS, "")

              # Convert to lowercase
              slug = trimmed.downcase

              # Fallback if result is empty
              slug.empty? ? "task" : slug
            end

            # Convert a branch name to a safe directory name
            #
            # Sanitizes branch names for use as directory names by replacing
            # characters that are not alphanumeric, hyphens, or underscores with hyphens.
            # Also handles slash-separated branch names (e.g., "origin/feature/auth").
            #
            # @param branch_name [String] Branch name to convert
            # @return [String] Directory-safe name
            #
            # @example Simple branch name
            #   SlugGenerator.to_directory_name("feature-branch")
            #   # => "feature-branch"
            #
            # @example Branch with slashes (remote or hierarchical)
            #   SlugGenerator.to_directory_name("origin/feature/auth")
            #   # => "origin-feature-auth"
            #
            # @example Branch with special characters
            #   SlugGenerator.to_directory_name("fix:bug#123")
            #   # => "fix-bug-123"
            def to_directory_name(branch_name)
              return "worktree" if branch_name.nil? || branch_name.empty?

              # Replace slashes and any non-alphanumeric/hyphen/underscore with hyphens
              branch_name.to_s.tr("/", "-").gsub(/[^a-zA-Z0-9\-_]/, "-")
            end

            # Check if a slug is valid for git branch names
            #
            # @param slug [String] Slug to validate
            # @return [Boolean] true if slug is valid
            #
            # @example
            #   SlugGenerator.valid?("valid-branch-name") # => true
            #   SlugGenerator.valid?("invalid@branch") # => false
            def valid?(slug)
              return false if slug.nil? || slug.empty?
              return false if slug.length > 255 # Git branch name limit
              return false if slug.match?(FORBIDDEN_CHARS)
              return false if slug.start_with?("-") || slug.end_with?("-")
              return false if slug.include?(".")  # Dots not allowed in git branch names
              return false if slug.include?(" ")  # Spaces not allowed

              # Check for invalid git branch name patterns
              return false if slug == "HEAD"
              return false if slug.include?("..")
              return false if slug.include?("@")

              true
            end

            private

            # Truncate slug intelligently to avoid cutting words
            #
            # @param slug [String] Slug to truncate
            # @param max_length [Integer] Maximum length
            # @return [String] Truncated slug
            def truncate_slug(slug, max_length)
              return slug if slug.length <= max_length

              # Try to truncate at a hyphen to avoid cutting words
              truncated = slug[0, max_length]

              # Find the last hyphen before the cutoff
              last_hyphen = truncated.rindex("-")
              if last_hyphen && last_hyphen > max_length * 0.7 # Don't cut too much
                truncated = slug[0, last_hyphen]
              end

              # Remove trailing hyphen
              truncated.gsub(/-$/, "")
            end
          end
        end
      end
    end
  end
end
