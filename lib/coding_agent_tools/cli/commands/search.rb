# frozen_string_literal: true

require "dry/cli"
require_relative "../../organisms/search/unified_searcher"
require_relative "../../molecules/search/preset_manager"
require_relative "../../molecules/search/fzf_integrator"

module CodingAgentTools
  module Cli
    module Commands
      # Search command for unified project-aware search functionality
      class Search < Dry::CLI::Command
        desc "Unified project-aware search tool"
        
        # Search type options
        option :type, type: :string, values: %w[file content hybrid auto], desc: "Search type (file, content, hybrid, auto)"
        option :files, type: :boolean, default: false, desc: "Search for files only"
        option :content, type: :boolean, default: false, desc: "Search in file content only"
        
        # Pattern matching options
        option :case_insensitive, type: :boolean, default: false, desc: "Case insensitive search", aliases: ["i"]
        option :whole_word, type: :boolean, default: false, desc: "Match whole words only", aliases: ["w"]
        option :multiline, type: :boolean, default: false, desc: "Enable multiline matching", aliases: ["U"]
        
        # Context options
        option :after, type: :integer, desc: "Show NUM lines after match", aliases: ["A"]
        option :before, type: :integer, desc: "Show NUM lines before match", aliases: ["B"]  
        option :context, type: :integer, desc: "Show NUM lines of context", aliases: ["C"]
        
        # File filtering options
        option :glob, type: :string, desc: "File glob pattern to include", aliases: ["g"]
        option :include, type: :string, desc: "Include only these paths/globs (comma-separated)"
        option :exclude, type: :string, desc: "Exclude paths/globs (comma-separated, use 'none' to clear defaults)", aliases: ["e"]
        option :include_archived, type: :boolean, default: false, desc: "Include archived/done tasks (overrides default exclusions)"
        
        # Search root option
        option :search_root, type: :string, desc: "Root directory for search (default: project root)"
        option :since, type: :string, desc: "Files modified since TIME"
        option :before_time, type: :string, desc: "Files modified before TIME"
        
        # Git scope options
        option :staged, type: :boolean, default: false, desc: "Search staged files only"
        option :tracked, type: :boolean, default: false, desc: "Search tracked files only" 
        option :changed, type: :boolean, default: false, desc: "Search changed files only"
        
        # Output options
        option :json, type: :boolean, default: false, desc: "Output in JSON format"
        option :yaml, type: :boolean, default: false, desc: "Output in YAML format"
        option :files_with_matches, type: :boolean, default: false, desc: "Only print filenames", aliases: ["l"]
        option :max_results, type: :integer, desc: "Limit number of results"
        
        # Interactive options
        option :fzf, type: :boolean, default: false, desc: "Use fzf for interactive selection"
        
        # Preset options
        option :preset, type: :string, desc: "Use search preset", aliases: ["p"]
        option :list_presets, type: :boolean, default: false, desc: "List available presets"

        argument :pattern, type: :string, required: false, desc: "Search pattern"

        example [
          'search "TODO"                    # Search for TODO in content',
          'search --files "*.rb"            # Search for Ruby files',
          'search --json "class.*User"      # JSON output',
          'search --fzf "function"          # Interactive mode',
          'search --preset docs "error"     # Use preset',
        ]

        def call(pattern: nil, **options)
          # Convert CLI options to internal format
          search_options = build_search_options(options)
          
          # Handle list presets
          if options[:list_presets]
            list_presets
            return
          end
          
          # Validate pattern
          if pattern.nil? || pattern.empty?
            puts "Error: No search pattern provided"
            puts "Usage: coding_agent_tools search [options] PATTERN"
            exit 1
          end
          
          # Execute search
          execute_search(pattern, search_options)
          
        rescue => e
          puts "Error: #{e.message}"
          puts e.backtrace if ENV["DEBUG"]
          exit 1
        end

        private

        def build_search_options(options)
          # Default exclusions for archived/done tasks
          default_excludes = [
            "dev-taskflow/current/*/tasks/x/*",
            "dev-taskflow/done/**/*"
          ]
          
          search_options = {
            type: determine_search_type(options),
            format: determine_format(options),
            max_results: options[:max_results],
            case_insensitive: options[:case_insensitive],
            whole_word: options[:whole_word],
            multi_line: options[:multiline],
            show_context: options[:context] || 0,
            after_context: options[:after],
            before_context: options[:before],
            interactive: options[:fzf],
            preset: options[:preset],
            since: options[:since],
            before: options[:before_time],
            scope: determine_git_scope(options),
            glob: options[:glob],
            include_paths: parse_path_list(options[:include]),
            exclude_paths: determine_exclude_paths(options, default_excludes),
            search_root: options[:search_root] ? File.expand_path(options[:search_root]) : nil,
            files_only: options[:files_with_matches]
          }
          
          search_options
        end
        
        def determine_search_type(options)
          return :file if options[:files]
          return :content if options[:content]
          return options[:type].to_sym if options[:type]
          :auto
        end
        
        def determine_format(options)
          return :json if options[:json]
          return :yaml if options[:yaml]
          :text
        end
        
        def determine_git_scope(options)
          return :staged if options[:staged]
          return :tracked if options[:tracked]
          return :changed if options[:changed]
          nil
        end
        
        def parse_path_list(path_string)
          return [] unless path_string
          path_string.split(',').map(&:strip)
        end
        
        def determine_exclude_paths(options, default_excludes)
          if options[:include_archived]
            return []
          end
          
          excludes = default_excludes.dup
          
          if options[:exclude]
            if options[:exclude].downcase == 'none'
              excludes = []
            else
              excludes.concat(parse_path_list(options[:exclude]))
            end
          end
          
          excludes
        end

        def execute_search(pattern, search_options)
          unified_searcher = Organisms::Search::UnifiedSearcher.new
          preset_manager = Molecules::Search::PresetManager.new
          
          # Apply preset if specified
          if search_options[:preset]
            apply_preset(preset_manager, search_options[:preset], search_options)
          end

          # Perform search (don't pass format to the searcher)
          searcher_options = search_options.dup
          searcher_options.delete(:format)  # Remove format, handle it in CLI
          
          results = unified_searcher.search(pattern, searcher_options)
          
          # Handle interactive mode
          if search_options[:interactive]
            handle_interactive_results(results)
          else
            output_results(results, search_options)
          end
        end

        def apply_preset(preset_manager, preset_name, search_options)
          unless preset_manager.exists?(preset_name)
            puts "Error: Preset '#{preset_name}' not found"
            exit 1
          end
          
          preset = preset_manager.get(preset_name)
          search_options.merge!(preset.transform_keys(&:to_sym))
        end

        def list_presets
          preset_manager = Molecules::Search::PresetManager.new
          puts "Available search presets:"
          preset_manager.list.each do |name|
            preset = preset_manager.get(name)
            puts "  #{name}: #{preset['description'] || 'No description'}"
          end
        end

        def handle_interactive_results(results)
          fzf = Molecules::Search::FzfIntegrator.new(multi: true)
          
          unless fzf.available?
            puts "Error: fzf is not installed. Install with: brew install fzf"
            exit 1
          end
          
          # Format results for fzf - handle both flat and repository structures
          items = []
          if results[:results]
            # New flat structure
            results[:results].each do |result|
              if result[:line]
                items << "#{result[:file]}:#{result[:line]}: #{result[:text]}"
              else
                items << "#{result[:file] || result[:path] || result}"
              end
            end
          elsif results[:repositories]
            # Legacy repository structure
            results[:repositories].each do |repo_name, repo_data|
              repo_data[:results].each do |result|
                if result[:line]
                  items << "#{repo_name}:#{result[:file]}:#{result[:line]}: #{result[:text]}"
                else
                  items << "#{repo_name}:#{result}"
                end
              end
            end
          end
          
          selection = fzf.select_interactive(items, prompt: "Select results")
          
          if selection[:success]
            puts "Selected:"
            selection[:selected].each { |item| puts "  #{item}" }
          end
        end

        def output_results(results, search_options)
          case search_options[:format]
          when :json
            require 'json'
            puts JSON.pretty_generate(results)
          when :yaml
            require "yaml"
            puts YAML.dump(results)
          else
            output_text_results(results, search_options)
          end
        end

        def output_text_results(results, search_options)
          # Get search mode from metadata or determine from results
          search_mode = results.dig(:metadata, :search_mode) || determine_search_mode(results)
          
          # Build search context information
          context_parts = []
          
          # Search mode
          case search_mode
          when :files, :file
            context_parts << "mode: files"
          when :content
            context_parts << "mode: content"
          when :hybrid, :both
            context_parts << "mode: files+content"
          end
          
          # Pattern (from metadata if available)
          if results.dig(:metadata, :pattern)
            context_parts << "pattern: \"#{results[:metadata][:pattern]}\""
          end
          
          # Active filters
          filters = []
          opts = results.dig(:metadata, :options) || search_options
          
          filters << "glob: #{opts[:glob]}" if opts[:glob]
          filters << "since: #{opts[:since]}" if opts[:since]
          filters << "before: #{opts[:before]}" if opts[:before]
          filters << "scope: #{opts[:scope]}" if opts[:scope]
          filters << "case-insensitive" if opts[:case_insensitive]
          filters << "whole-word" if opts[:whole_word]
          
          if opts[:include_paths] && !opts[:include_paths].empty?
            filters << "include: #{opts[:include_paths].join(',')}"
          end
          
          if opts[:exclude_paths] && !opts[:exclude_paths].empty?
            filters << "exclude: #{opts[:exclude_paths].join(',')}"
          end
          
          context_parts << "filters: [#{filters.join(', ')}]" if filters.any?
          
          context_line = "Search context: #{context_parts.join(' | ')}"
          
          if results[:total_results] == 0
            puts context_line
            puts "No results found"
            return
          end
          
          puts context_line
          
          # Handle flat structure (unified search) vs legacy repository structure
          if results[:results]
            # New flat structure
            puts "Found #{results[:total_results]} results"
            puts
            
            results[:results].each do |result|
              output_single_result(result, search_options)
            end
          elsif results[:repositories]
            # Legacy repository structure
            puts "Found #{results[:total_results]} results across #{results[:repositories].size} repositories"
            puts
            
            results[:repositories].each do |repo_name, repo_data|
              next if repo_data[:count] == 0
              
              puts "#{repo_name}: (#{repo_data[:count]} results)"
              
              if repo_data[:results].is_a?(Array)
                repo_data[:results].each do |result|
                  output_single_result(result, search_options)
                end
              elsif repo_data[:results].is_a?(Hash)
                # Check if it's the search result format {success: bool, results: array}
                if repo_data[:results][:results].is_a?(Array)
                  repo_data[:results][:results].each do |result|
                    output_single_result(result, search_options)
                  end
                # Or if it's the hybrid format {files: array, content: array}
                elsif repo_data[:results][:files] || repo_data[:results][:content]
                  if repo_data[:results][:files]
                    puts "  Files:"
                    if repo_data[:results][:files].empty?
                      puts "    (no matching files found)"
                    else
                      repo_data[:results][:files].each { |f| puts "    #{f}" }
                    end
                  end
                  if repo_data[:results][:content]
                    puts "  Content:"
                    if repo_data[:results][:content].empty?
                      puts "    (no matching content found)"
                    else
                      repo_data[:results][:content].each { |r| output_single_result(r, search_options) }
                    end
                  end
                end
              end
              
              puts
            end
          end
        end

        def determine_search_mode(results)
          # Handle flat structure (unified search)
          if results[:results]
            # For flat structure, determine based on result content
            return :content # Default assumption for flat results
          end
          
          # Handle legacy repository structure
          return :unknown if results[:repositories].nil? || results[:repositories].empty?
          
          has_files = false
          has_content = false
          
          results[:repositories].each do |_, repo_data|
            next unless repo_data[:results].is_a?(Hash)
            
            if repo_data[:results][:files]
              has_files = true
            end
            if repo_data[:results][:content] || repo_data[:results][:results]
              has_content = true
            end
          end
          
          if has_files && has_content
            :hybrid
          elsif has_files
            :files
          elsif has_content
            :content
          else
            :unknown
          end
        end
        
        def output_single_result(result, search_options)
          if search_options[:files_only]
            puts "  #{result[:file] || result[:path] || result}"
          elsif result[:line]
            puts "  #{result[:file]}:#{result[:line]}:#{result[:column] || 0}: #{result[:text]}"
          else
            puts "  #{result[:file] || result[:path] || result}"
          end
        end
      end
    end
  end
end