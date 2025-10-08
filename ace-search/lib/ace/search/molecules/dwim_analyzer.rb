# frozen_string_literal: true

module Ace
  module Search
    module Molecules
      # Do-What-I-Mean analyzer for intelligent search mode detection
      # This is a molecule - composed operation using PatternAnalyzer atom
      class DwimAnalyzer
        def initialize(pattern_analyzer: Atoms::PatternAnalyzer)
          @pattern_analyzer = pattern_analyzer
        end

        # Determine search mode based on pattern and options
        # @param pattern [String] Search pattern
        # @param options [Hash] Search options
        # @return [Symbol] :file, :content, or :hybrid
        def determine_mode(pattern, options = {})
          # Explicit flags override DWIM
          return :file if options[:files_only] || options[:type] == :file
          return :content if options[:content_only] || options[:type] == :content
          return :hybrid if options[:type] == :hybrid

          # Analyze pattern for DWIM mode
          analysis = @pattern_analyzer.analyze_pattern(pattern)

          case analysis[:type]
          when :file_glob
            :file
          when :content_regex, :literal
            :content
          when :hybrid
            :hybrid
          else
            :content # Default to content search
          end
        end

        # Check if pattern is suitable for file search
        def file_search_suitable?(pattern)
          analysis = @pattern_analyzer.analyze_pattern(pattern)
          analysis[:type] == :file_glob || analysis[:type] == :hybrid
        end

        # Check if pattern is suitable for content search
        def content_search_suitable?(pattern)
          analysis = @pattern_analyzer.analyze_pattern(pattern)
          [:content_regex, :literal, :hybrid].include?(analysis[:type])
        end
      end
    end
  end
end
