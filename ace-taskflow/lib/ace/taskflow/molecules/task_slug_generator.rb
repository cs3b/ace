# frozen_string_literal: true

module Ace
  module Taskflow
    module Molecules
      # Generates deterministic slugs for task directories
      class TaskSlugGenerator
        # Task type prefixes
        TYPE_PREFIXES = {
          'feature' => 'feat',
          'fix' => 'fix',
          'docs' => 'docs',
          'documentation' => 'docs',
          'test' => 'test',
          'testing' => 'test',
          'refactor' => 'refactor',
          'perf' => 'perf',
          'performance' => 'perf',
          'chore' => 'chore',
          'style' => 'style',
          'build' => 'build',
          'ci' => 'ci',
          'revert' => 'revert'
        }.freeze

        # Default type when none can be inferred
        DEFAULT_TYPE = 'task'.freeze

        # Maximum length for each slug component
        MAX_TYPE_LENGTH = 8
        MAX_CONTEXT_LENGTH = 12
        MAX_KEYWORDS_LENGTH = 30

        # Generate a descriptive slug for a task
        # @param task_number [String, Integer] The task number (e.g., "025")
        # @param title [String] The task title
        # @param metadata [Hash] Optional metadata (priority, type, etc.)
        # @return [String] The generated slug (e.g., "025-feat-taskflow-idea-gc-llm")
        def self.generate(task_number, title, metadata = {})
          number = task_number.to_s.rjust(3, '0')
          type = extract_type(title, metadata)
          context = extract_context(title, metadata)
          keywords = extract_keywords(title, type, context)

          # Build the slug components
          components = [number, type]
          components << context unless context.empty?
          components << keywords unless keywords.empty?

          components.join('-')
        end

        # Generate only the descriptive part (without task number)
        # @param title [String] The task title
        # @param metadata [Hash] Optional metadata
        # @return [String] The descriptive part (e.g., "feat-taskflow-idea-gc-llm")
        def self.generate_descriptive_part(title, metadata = {})
          type = extract_type(title, metadata)
          context = extract_context(title, metadata)
          keywords = extract_keywords(title, type, context)

          components = [type]
          components << context unless context.empty?
          components << keywords unless keywords.empty?

          components.join('-')
        end

        # Parse a slug to extract its components
        # @param slug [String] The slug to parse
        # @return [Hash] Components { number:, type:, context:, keywords: }
        def self.parse_slug(slug)
          parts = slug.split('-')

          {
            number: parts[0] =~ /^\d+$/ ? parts[0] : nil,
            type: parts[1] || DEFAULT_TYPE,
            context: parts[2] || '',
            keywords: parts[3..-1]&.join('-') || ''
          }
        end

        private

        def self.extract_type(title, metadata)
          # Check metadata first
          if metadata[:type]
            normalized = normalize_type(metadata[:type].to_s)
            return normalized unless normalized == DEFAULT_TYPE
          end

          # Try to infer from title
          title_lower = title.downcase

          # Check for type keywords in title
          TYPE_PREFIXES.each do |keyword, prefix|
            return prefix if title_lower.include?(keyword)
          end

          # Check for common patterns
          return 'feat' if title_lower =~ /\b(add|implement|create|enhance)\b/
          return 'fix' if title_lower =~ /\b(fix|repair|resolve|correct)\b/
          return 'docs' if title_lower =~ /\b(document|readme|guide)\b/
          return 'test' if title_lower =~ /\b(test|spec|coverage)\b/
          return 'refactor' if title_lower =~ /\b(refactor|restructure|reorganize)\b/

          DEFAULT_TYPE
        end

        def self.normalize_type(type_str)
          type_lower = type_str.downcase.strip
          TYPE_PREFIXES[type_lower] || type_lower[0...MAX_TYPE_LENGTH]
        end

        def self.extract_context(title, metadata)
          # Check metadata first
          if metadata[:component] || metadata[:context]
            context = (metadata[:component] || metadata[:context]).to_s
            return sanitize_slug_component(context)[0...MAX_CONTEXT_LENGTH]
          end

          # Try to extract ACE component from title
          title_lower = title.downcase

          # Look for ace-* components
          if match = title_lower.match(/ace[- ]?(\w+)/)
            component = match[1]
            return component[0...MAX_CONTEXT_LENGTH]
          end

          # Look for common component names
          components = %w[taskflow context core nav test llm git handbook tools]
          components.each do |comp|
            return comp if title_lower.include?(comp)
          end

          ''
        end

        def self.extract_keywords(title, type, context)
          # Remove noise words and already extracted components
          words = title.downcase
                       .gsub(/[^a-z0-9\s-]/, '') # Remove special chars
                       .split(/\s+/)              # Split on whitespace

          # Remove common noise words
          noise_words = %w[
            the a an in on at to for from with of and or but
            add implement create fix update enhance improve
            ace task feature bug
          ]

          # Also remove the type and context if present
          noise_words << type if type != DEFAULT_TYPE
          noise_words << context unless context.empty?

          keywords = words.reject { |w| noise_words.include?(w) || w.length < 2 }

          # Take most significant keywords (up to 5)
          keywords = keywords.take(5)

          # Join and truncate
          result = keywords.join('-')
          result[0...MAX_KEYWORDS_LENGTH]
        end

        def self.sanitize_slug_component(str)
          str.downcase
             .gsub(/[^a-z0-9-]/, '-')  # Replace non-alphanumeric with hyphen
             .gsub(/-+/, '-')           # Collapse multiple hyphens
             .gsub(/^-|-$/, '')         # Remove leading/trailing hyphens
        end
      end
    end
  end
end