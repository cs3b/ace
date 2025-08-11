# frozen_string_literal: true

require_relative '../../atoms/search/pattern_analyzer'
require_relative '../../models/search/search_options'

module CodingAgentTools
  module Molecules
    module Search
      # DwimHeuristicsEngine provides intelligent "Do What I Mean" mode selection
      # This is a molecule - it composes pattern analysis atoms for intelligent search mode selection
      class DwimHeuristicsEngine
        def initialize
          @pattern_analyzer = CodingAgentTools::Atoms::Search::PatternAnalyzer
        end

        # Analyze search intent and suggest optimal search configuration
        # @param pattern [String] Search pattern
        # @param flags [Hash] CLI flags and options
        # @param context [Hash] Additional context (working directory, git status, etc.)
        # @return [Hash] Analysis result with suggestions
        def analyze_search_intent(pattern, flags = {}, context = {})
          # Analyze the pattern itself
          pattern_analysis = @pattern_analyzer.analyze_pattern(pattern)
          
          # Consider explicit user flags
          explicit_mode = determine_explicit_mode(flags)
          
          # Analyze context clues
          context_hints = analyze_context(context, pattern)
          
          # Combine all factors to determine intent
          final_decision = make_final_decision(pattern_analysis, explicit_mode, context_hints, flags)
          
          {
            pattern_analysis: pattern_analysis,
            explicit_mode: explicit_mode,
            context_hints: context_hints,
            recommended_mode: final_decision[:mode],
            recommended_tools: final_decision[:tools],
            confidence: final_decision[:confidence],
            reasoning: final_decision[:reasoning],
            suggested_options: suggest_search_options(pattern, final_decision, flags)
          }
        end

        # Generate optimal search options based on analysis
        # @param pattern [String] Search pattern
        # @param flags [Hash] CLI flags
        # @param context [Hash] Additional context
        # @return [SearchOptions] Optimized search options
        def generate_search_options(pattern, flags = {}, context = {})
          analysis = analyze_search_intent(pattern, flags, context)
          base_options = CodingAgentTools::Models::Search::SearchOptions.from_cli_args(flags.merge(pattern: pattern))
          
          # Apply DWIM recommendations
          dwim_overrides = {
            mode: analysis[:recommended_mode]
          }
          
          # Add context-specific optimizations
          if analysis[:context_hints][:is_code_repository]
            dwim_overrides[:file_types] ||= []
            dwim_overrides[:file_types].concat(common_code_extensions) if dwim_overrides[:file_types].empty?
          end
          
          if analysis[:pattern_analysis][:suggested_tool] == 'fd'
            # Optimize for file search
            dwim_overrides[:max_results] ||= 1000 # Reasonable default for file searches
          elsif analysis[:pattern_analysis][:suggested_tool] == 'rg'
            # Optimize for content search
            dwim_overrides[:context_lines] ||= 2 # Show context for content matches
          end
          
          base_options.merge(dwim_overrides)
        end

        # Suggest search strategy based on pattern and context
        # @param pattern [String] Search pattern
        # @param context [Hash] Context information
        # @return [Hash] Strategy recommendations
        def suggest_search_strategy(pattern, context = {})
          analysis = @pattern_analyzer.analyze_pattern(pattern)
          
          strategies = []
          
          case analysis[:type]
          when :file_glob
            strategies << {
              approach: 'file_name_search',
              tool: 'fd',
              rationale: 'Pattern appears to be a file glob, fd is optimized for file name searching'
            }
            
            # Also suggest content search if pattern could match content
            if could_be_content_pattern?(pattern)
              strategies << {
                approach: 'content_search_fallback',
                tool: 'rg',
                rationale: 'Pattern might also match file content'
              }
            end
            
          when :content_regex, :literal
            strategies << {
              approach: 'content_search',
              tool: 'rg',
              rationale: 'Pattern appears to be content-oriented'
            }
            
            # Suggest file search if it's a simple enough pattern
            if analysis[:type] == :literal && analysis[:confidence] < 0.8
              strategies << {
                approach: 'filename_search_fallback',
                tool: 'fd',
                rationale: 'Simple pattern might also match file names'
              }
            end
            
          when :hybrid
            strategies << {
              approach: 'parallel_search',
              tool: 'both',
              rationale: 'Ambiguous pattern benefits from searching both files and content'
            }
            
          else
            strategies << {
              approach: 'content_search_default',
              tool: 'rg',
              rationale: 'Default to content search for unclear patterns'
            }
          end
          
          # Add repository-specific strategies
          if context[:is_git_repository]
            strategies.each do |strategy|
              strategy[:git_optimizations] = suggest_git_optimizations(pattern, context)
            end
          end
          
          strategies
        end

        private

        # Determine if user provided explicit mode flags
        # @param flags [Hash] CLI flags
        # @return [Symbol, nil] Explicit mode or nil
        def determine_explicit_mode(flags)
          return :files if flags[:files_only] || flags[:name_only]
          return :content if flags[:content_only]
          return :both if flags[:both]
          
          nil
        end

        # Analyze context for additional hints
        # @param context [Hash] Context information
        # @param pattern [String] Search pattern
        # @return [Hash] Context analysis
        def analyze_context(context, pattern)
          hints = {}
          
          # Check if we're in a code repository
          hints[:is_code_repository] = code_repository?(context[:working_directory])
          hints[:is_git_repository] = git_repository?(context[:working_directory])
          
          # Check if pattern matches common programming constructs
          hints[:looks_like_code_search] = programming_pattern?(pattern)
          
          # Check if pattern matches common file operations
          hints[:looks_like_file_search] = file_operation_pattern?(pattern)
          
          # Analyze file types in current directory
          if context[:working_directory]
            hints[:common_extensions] = analyze_directory_extensions(context[:working_directory])
          end
          
          hints
        end

        # Make final decision combining all factors
        # @param pattern_analysis [Hash] Pattern analysis results
        # @param explicit_mode [Symbol, nil] Explicit user mode
        # @param context_hints [Hash] Context analysis
        # @param flags [Hash] CLI flags
        # @return [Hash] Final decision
        def make_final_decision(pattern_analysis, explicit_mode, context_hints, flags)
          # Explicit mode always wins
          if explicit_mode
            return {
              mode: explicit_mode,
              tools: tools_for_mode(explicit_mode),
              confidence: 1.0,
              reasoning: "User explicitly requested #{explicit_mode} mode"
            }
          end
          
          base_confidence = pattern_analysis[:confidence]
          
          # Boost confidence based on context
          if context_hints[:looks_like_code_search] && pattern_analysis[:type] == :content_regex
            base_confidence += 0.2
          end
          
          if context_hints[:looks_like_file_search] && pattern_analysis[:type] == :file_glob
            base_confidence += 0.2
          end
          
          # Determine mode based on pattern analysis and context
          mode = case pattern_analysis[:type]
                 when :file_glob
                   :files
                 when :content_regex, :literal
                   :content
                 when :hybrid
                   # For hybrid patterns, prefer content search unless it's clearly a file pattern
                   if context_hints[:looks_like_file_search] && !context_hints[:looks_like_code_search]
                     :files
                   else
                     # Default to content for hybrid patterns
                     :content
                   end
                 else
                   :content # Safe default
                 end
          
          {
            mode: mode,
            tools: tools_for_mode(mode),
            confidence: [base_confidence, 1.0].min,
            reasoning: build_reasoning(pattern_analysis, context_hints, mode)
          }
        end

        # Suggest additional search options based on analysis
        # @param pattern [String] Search pattern
        # @param decision [Hash] Decision results
        # @param flags [Hash] CLI flags
        # @return [Hash] Suggested option overrides
        def suggest_search_options(pattern, decision, flags)
          suggestions = {}
          
          # Suggest file type filtering for code searches
          if decision[:mode] == :content && programming_pattern?(pattern)
            extensions = @pattern_analyzer.extract_extensions(pattern)
            suggestions[:file_types] = extensions unless extensions.empty?
          end
          
          # Suggest case insensitive search for simple patterns
          if decision[:mode] == :content && pattern.match?(/^[a-zA-Z\s]+$/)
            suggestions[:case_sensitive] = false
          end
          
          # Suggest multiline for complex regex patterns
          if pattern.include?('.*') || pattern.include?('\n')
            suggestions[:multiline] = true
          end
          
          suggestions
        end

        # Get tools for a given mode
        # @param mode [Symbol] Search mode
        # @return [Array<String>] Tool names
        def tools_for_mode(mode)
          case mode
          when :files
            ['fd']
          when :content
            ['rg']
          when :both
            ['fd', 'rg']
          else
            ['rg']
          end
        end

        # Build reasoning explanation
        # @param pattern_analysis [Hash] Pattern analysis
        # @param context_hints [Hash] Context hints
        # @param mode [Symbol] Selected mode
        # @return [String] Reasoning explanation
        def build_reasoning(pattern_analysis, context_hints, mode)
          reasons = []
          
          reasons << "Pattern analysis: #{pattern_analysis[:reason]}"
          
          if context_hints[:looks_like_code_search]
            reasons << "Context suggests code search"
          end
          
          if context_hints[:looks_like_file_search]
            reasons << "Context suggests file search"
          end
          
          reasons << "Selected #{mode} mode for optimal results"
          
          reasons.join('. ')
        end

        # Check if pattern could match content even if it looks like a file glob
        # @param pattern [String] Pattern to check
        # @return [Boolean] True if pattern could match content
        def could_be_content_pattern?(pattern)
          # Remove file extensions and check if remaining part could be content
          without_ext = pattern.gsub(/\*\.\w+$/, '')
          without_ext.length > 2 && !without_ext.include?('/')
        end

        # Check if directory looks like a code repository
        # @param directory [String, nil] Directory path
        # @return [Boolean] True if looks like code repository
        def code_repository?(directory)
          return false unless directory && Dir.exist?(directory)
          
          # Check for common code repository indicators
          code_indicators = %w[.git package.json Gemfile Cargo.toml setup.py requirements.txt]
          code_indicators.any? { |indicator| File.exist?(File.join(directory, indicator)) }
        end

        # Check if directory is a git repository
        # @param directory [String, nil] Directory path
        # @return [Boolean] True if git repository
        def git_repository?(directory)
          return false unless directory
          
          File.exist?(File.join(directory, '.git'))
        end

        # Check if pattern looks like a programming search
        # @param pattern [String] Pattern to check
        # @return [Boolean] True if looks like programming pattern
        def programming_pattern?(pattern)
          programming_keywords = %w[
            def class function method variable const let var
            import require include using namespace
            TODO FIXME BUG HACK NOTE XXX
            return yield throw catch try except
          ]
          
          programming_keywords.any? { |keyword| pattern.include?(keyword) }
        end

        # Check if pattern looks like a file operation search
        # @param pattern [String] Pattern to check
        # @return [Boolean] True if looks like file operation
        def file_operation_pattern?(pattern)
          # Only consider it a file pattern if it has wildcards or file extensions
          # A simple path like "bin/tn" is more likely content search
          pattern.include?('*') || pattern.match?(/\.\w+$/)
        end

        # Analyze common file extensions in directory
        # @param directory [String] Directory to analyze
        # @return [Array<String>] Common extensions
        def analyze_directory_extensions(directory)
          return [] unless Dir.exist?(directory)
          
          extensions = Dir.glob(File.join(directory, '**/*'))
                          .select { |f| File.file?(f) }
                          .map { |f| File.extname(f)[1..-1] }
                          .compact
                          .tally
          
          # Return extensions that appear more than once, sorted by frequency
          extensions.select { |_, count| count > 1 }
                   .sort_by { |_, count| -count }
                   .map { |ext, _| ext }
                   .first(5) # Top 5 most common
        end

        # Get common code file extensions
        # @return [Array<String>] Common code extensions
        def common_code_extensions
          %w[rb js ts py java cpp c h cs php go rs swift kt scala clj]
        end

        # Suggest git-specific optimizations
        # @param pattern [String] Search pattern
        # @param context [Hash] Context information
        # @return [Hash] Git optimization suggestions
        def suggest_git_optimizations(pattern, context)
          optimizations = {}
          
          # Suggest searching only tracked files for content searches
          if programming_pattern?(pattern)
            optimizations[:git_scope] = :tracked
            optimizations[:rationale] = 'Focus on tracked files for code searches'
          end
          
          optimizations
        end
      end
    end
  end
end