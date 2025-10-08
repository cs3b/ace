# frozen_string_literal: true

module Ace
  module Search
    module Atoms
      # PatternAnalyzer provides intelligent analysis of search patterns for DWIM mode selection
      # This is an atom - pure function for pattern analysis
      module PatternAnalyzer
        # File glob indicators
        FILE_GLOB_PATTERNS = [
          /^\*+\./,                    # *.extension
          /\*\*\/\*/,                  # **/* recursive patterns
          /^\w+\/\*+/,                 # dir/* patterns
          /\.\w+$/,                    # .extension endings
          /\/\*+$/,                    # ending with /*
          /^\w+\*+\w*$/                # word* or *word patterns for filenames
        ].freeze

        # Content regex indicators
        CONTENT_REGEX_PATTERNS = [
          /[|+?{}()\[\]\\]/,           # Regex metacharacters (removed * from here)
          /def\s+\w+/,                 # Method definitions
          /class\s+\w+/,               # Class definitions
          /function\s+\w+/,            # Function definitions
          /import\s+/,                 # Import statements
          /require\s+/,                # Require statements
          /\b(TODO|FIXME|BUG|HACK)\b/, # Code annotations
          /^\^/,                       # Line start anchor
          /\$$/,                       # Line end anchor
          /\\[bBdDsSwW]/               # Character class escapes
        ].freeze

        # Literal text indicators
        LITERAL_INDICATORS = [
          /^\w+$/,                     # Single word
          /^[\w\s]+$/,                 # Words with spaces
          /^"[^"]*"$/,                 # Quoted strings
          /^'[^']*'$/                  # Single quoted strings
        ].freeze

        module_function

        # Analyze a pattern and determine its most likely type
        # @param pattern [String] Pattern to analyze
        # @return [Hash] Analysis result with type and confidence
        def analyze_pattern(pattern)
          return {type: :invalid, confidence: 0.0, reason: "Pattern is nil"} if pattern.nil?
          return {type: :invalid, confidence: 0.0, reason: "Pattern is empty"} if pattern.empty?

          clean_pattern = pattern.strip

          # Check for file glob patterns
          if file_glob_pattern?(clean_pattern)
            return {
              type: :file_glob,
              confidence: calculate_file_glob_confidence(clean_pattern),
              reason: "Contains file glob patterns",
              suggested_tool: "fd"
            }
          end

          # Check for content regex patterns
          if content_regex_pattern?(clean_pattern)
            return {
              type: :content_regex,
              confidence: calculate_content_regex_confidence(clean_pattern),
              reason: "Contains regex metacharacters or code patterns",
              suggested_tool: "rg"
            }
          end

          # Check for literal patterns
          if literal_pattern?(clean_pattern)
            return {
              type: :literal,
              confidence: calculate_literal_confidence(clean_pattern),
              reason: "Simple literal text pattern",
              suggested_tool: "rg"
            }
          end

          # Default to hybrid if unclear
          {
            type: :hybrid,
            confidence: 0.5,
            reason: "Pattern could match files or content",
            suggested_tool: "both"
          }
        end

        # Check if pattern looks like a file glob
        def file_glob_pattern?(pattern)
          FILE_GLOB_PATTERNS.any? { |regex| pattern.match?(regex) }
        end

        # Check if pattern looks like content regex
        def content_regex_pattern?(pattern)
          CONTENT_REGEX_PATTERNS.any? { |regex| pattern.match?(regex) }
        end

        # Check if pattern looks like literal text
        def literal_pattern?(pattern)
          LITERAL_INDICATORS.any? { |regex| pattern.match?(regex) }
        end

        # Suggest search mode based on pattern analysis
        def suggest_search_mode(pattern, flags = {})
          return :files if flags[:files_only] || flags[:name_only]
          return :content if flags[:content_only]

          analysis = analyze_pattern(pattern)

          case analysis[:type]
          when :file_glob
            :files
          when :content_regex, :literal
            :content
          when :hybrid
            :both
          else
            :content
          end
        end

        # Extract file extensions from a pattern if present
        def extract_extensions(pattern)
          extensions = []

          # Match patterns like *.rb, **/*.js, etc.
          extension_matches = pattern.scan(/\*+\.(\w+)/)
          extensions.concat(extension_matches.flatten)

          # Match explicit .ext at the end
          if pattern.match?(/\.(\w+)$/)
            extension_match = pattern.match(/\.(\w+)$/)
            extensions << extension_match[1]
          end

          extensions.uniq
        end

        def calculate_file_glob_confidence(pattern)
          confidence = 0.5

          confidence += 0.3 if pattern.include?("*")
          confidence += 0.2 if pattern.match?(/\.\w+$/)
          confidence += 0.1 if pattern.include?("/")

          [confidence, 1.0].min
        end

        def calculate_content_regex_confidence(pattern)
          confidence = 0.5

          metachar_count = pattern.scan(/[|+?{}()\[\]\\]/).length
          confidence += metachar_count * 0.1

          confidence += 0.2 if pattern.match?(/\b(def|class|function|import|require)\s+/)
          confidence += 0.1 if pattern.match?(/^\^|\$$/)

          [confidence, 1.0].min
        end

        def calculate_literal_confidence(pattern)
          confidence = 0.6

          confidence += 0.2 if pattern.match?(/^\w+$/)
          confidence += 0.1 if pattern.length < 20
          confidence += 0.3 if pattern.match?(/^["'][^"']*["']$/)

          [confidence, 1.0].min
        end
      end
    end
  end
end
