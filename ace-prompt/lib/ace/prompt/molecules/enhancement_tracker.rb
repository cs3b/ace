# frozen_string_literal: true

module Ace
  module Prompt
    module Molecules
      # Track enhancement chains in archive
      class EnhancementTracker
        # Find next enhancement iteration number
        # @param original_path [String] Path to original archived prompt
        # @param archive_dir [String] Archive directory to search
        # @return [Integer] Next iteration number (1, 2, 3, etc.)
        def self.next_iteration(original_path, archive_dir)
          base_name = File.basename(original_path, ".md")

          # Find all enhancement files for this base
          pattern = File.join(archive_dir, "#{base_name}_e*.md")
          existing = Dir.glob(pattern)

          # Extract iteration numbers and find max
          iterations = existing.map do |path|
            if path =~ /_e(\d+)\.md$/
              $1.to_i
            else
              0
            end
          end

          (iterations.max || 0) + 1
        end

        # Generate enhancement frontmatter
        # @param original_path [String] Path to original prompt
        # @param iteration [Integer] Enhancement iteration number
        # @param context_used [Boolean] Whether context was loaded
        # @return [Hash] Frontmatter hash for enhancement
        def self.generate_frontmatter(original_path, iteration, context_used: false)
          {
            "enhancement_of" => "archive/#{File.basename(original_path)}",
            "enhancement_iteration" => iteration,
            "context_used" => context_used
          }
        end

        # Add enhancement frontmatter to content
        # @param content [String] Original content
        # @param frontmatter [Hash] Frontmatter to add
        # @return [String] Content with frontmatter prepended
        def self.add_frontmatter(content, frontmatter)
          yaml_front = YAML.dump(frontmatter)
          "---\n#{yaml_front}---\n\n#{content}"
        end
      end
    end
  end
end
