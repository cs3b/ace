# frozen_string_literal: true

require "yaml"
require "time"

module Ace
  module Prompt
    module Molecules
      # Track enhancement chains in archive
      class EnhancementTracker
        # Track enhancement with proper metadata (simplified API for PromptProcessor)
        # @param prompt_path [String] Path to the prompt file
        # @param enhanced_content [String] The enhanced content (without frontmatter)
        # @param original_frontmatter [Hash] Original frontmatter from the prompt
        # @param archive_subdir [String] Archive subdirectory name
        # @return [Hash] Result with :content, :frontmatter, :iteration, :base
        def self.track_enhancement(prompt_path, enhanced_content, original_frontmatter = {}, archive_subdir = "archive")
          # Determine enhancement lineage
          if original_frontmatter&.key?("enhancement_of")
            # Continuing enhancement chain
            base = original_frontmatter["enhancement_of"]
            iteration = (original_frontmatter["enhancement_iteration"] || 0) + 1
          else
            # First enhancement - find the archived original
            archive_dir = File.join(File.dirname(prompt_path), archive_subdir)
            archives = Dir.glob(File.join(archive_dir, "*.md"))
              .reject { |f| File.basename(f).match?(/_e\d+\.md$/) }
              .sort
            latest = archives.last
            base = latest ? "archive/#{File.basename(latest)}" : "archive/unknown.md"
            iteration = 1
          end

          # Build tracking metadata
          metadata = {
            "enhancement_of" => base,
            "enhancement_iteration" => iteration,
            "context_used" => original_frontmatter&.dig("enhancement", "context") ? true : false,
            "enhanced_at" => Time.now.utc.iso8601
          }

          # Merge with original frontmatter (preserving enhancement config and other fields)
          merged_frontmatter = (original_frontmatter || {}).merge(metadata)

          {
            content: enhanced_content,
            frontmatter: merged_frontmatter,
            iteration: iteration,
            base: base
          }
        end

        # Find next enhancement iteration number by reading frontmatter
        # @param original_path [String] Path to original archived prompt
        # @param archive_dir [String] Archive directory to search
        # @return [Integer] Next iteration number (1, 2, 3, etc.)
        def self.next_iteration(original_path, archive_dir)
          # Find all files with _e suffix in archive
          all_enhanced = Dir.glob(File.join(archive_dir, "*_e*.md"))

          # Read frontmatter from each to find those referencing this base
          base_filename = "archive/#{File.basename(original_path)}"
          iterations = []

          all_enhanced.each do |enhanced_file|
            content = File.read(enhanced_file)
            if match = content.match(/\A---\n(.*?)\n---/m)
              frontmatter = YAML.safe_load(match[1])
              if frontmatter&.dig("enhancement_of") == base_filename
                iterations << frontmatter["enhancement_iteration"]
              end
            end
          rescue => e
            # Skip files that can't be parsed
            warn "Warning: Could not parse #{enhanced_file}: #{e.message}" if ENV["DEBUG"]
          end

          (iterations.compact.max || 0) + 1
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
