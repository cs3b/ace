# frozen_string_literal: true

require_relative "../../atoms/project_root_detector"
require_relative "../../atoms/search/ripgrep_executor"
require_relative "../../atoms/search/fd_executor"
require_relative "../../molecules/search/dwim_heuristics_engine"
require_relative "result_aggregator"

module CodingAgentTools
  module Organisms
    module Search
      # Executes unified search across the entire project from project root
      class UnifiedSearcher
        # Initialize unified searcher
        # @param options [Hash] Configuration options
        def initialize(options = {})
          @options = options
          @project_root = Atoms::ProjectRootDetector.find_project_root
          @ripgrep = Atoms::Search::RipgrepExecutor.new
          @fd = Atoms::Search::FdExecutor.new
          @dwim = Molecules::Search::DwimHeuristicsEngine.new
          @aggregator = ResultAggregator.new
        end

        # Execute unified search across the entire project from project root
        # @param pattern [String] Search pattern
        # @param options [Hash] Search options
        # @return [Hash] Aggregated search results
        def search(pattern, options = {})
          merged_options = @options.merge(options)

          # Determine search mode using DWIM heuristics
          mode = if merged_options[:type] && merged_options[:type] != :auto
            merged_options[:type]
          else
            analysis = @dwim.analyze_search_intent(pattern, merged_options)
            analysis[:recommended_mode] || :content
          end

          # Execute search directly (assumes we're already in project root or executors handle paths correctly)
          results = case mode
          when :file, :files
            search_files(pattern, merged_options)
          when :content
            search_content_direct(pattern, merged_options)
          when :hybrid, :both
            {
              files: search_files(pattern, merged_options),
              content: search_content_direct(pattern, merged_options)
            }
          else
            {error: "Unknown search mode: #{mode}"}
          end

          # Format results for aggregator - simulate single repository structure
          formatted_results = {
            "project" => {
              repository: {name: "project", path: @project_root},
              results: results,
              metadata: {
                repository_name: "project",
                repository_path: @project_root,
                search_time: Time.now.iso8601,
                result_count: count_results(results)
              }
            }
          }

          # Aggregate and format results
          @aggregator.aggregate(formatted_results, merged_options.merge(search_mode: mode, pattern: pattern))
        end

        # Search for files across repositories
        # @param pattern [String] File pattern
        # @param options [Hash] Search options
        # @return [Hash] File search results
        def find_files(pattern, options = {})
          search(pattern, options.merge(type: :file))
        end

        # Search content across repositories
        # @param pattern [String] Content pattern
        # @param options [Hash] Search options
        # @return [Hash] Content search results
        def search_content(pattern, options = {})
          search(pattern, options.merge(type: :content))
        end

        # Get repository information (simplified - returns project info)
        # @return [Array<Hash>] Repository details
        def repositories
          [{
            name: "project",
            path: @project_root,
            type: "main",
            status: check_repository_status(@project_root)
          }]
        end

        private

        # Search for files using fd executor
        def search_files(pattern, options)
          # Use project root as default search path unless explicitly overridden
          options_with_path = options.dup
          options_with_path[:search_path] ||= @project_root

          if @fd.available?
            @fd.find_files(pattern, options_with_path)
          else
            fallback_file_search(pattern, options_with_path)
          end
        end

        # Search content using ripgrep executor
        def search_content_direct(pattern, options)
          # Use project root as default search path unless explicitly overridden
          options_with_path = options.dup
          options_with_path[:search_path] ||= @project_root

          if @ripgrep.available?
            @ripgrep.search(pattern, options_with_path)
          else
            fallback_content_search(pattern, options_with_path)
          end
        end

        # Fallback file search without fd
        def fallback_file_search(pattern, options)
          # Use git ls-files if in git repo
          if system("git rev-parse --git-dir > /dev/null 2>&1")
            files = `git ls-files`.split("\n")
            # Filter by pattern
            files.select { |f| File.fnmatch(pattern, f) }
          else
            # Use Ruby's Dir.glob
            Dir.glob(pattern, File::FNM_DOTMATCH)
          end
        end

        # Fallback content search without ripgrep
        def fallback_content_search(pattern, options)
          # Use git grep if in git repo
          if system("git rev-parse --git-dir > /dev/null 2>&1")
            output = `git grep -n "#{pattern}" 2>/dev/null`
            parse_git_grep_output(output)
          else
            # Basic grep fallback
            output = `grep -rn "#{pattern}" . 2>/dev/null`
            parse_grep_output(output)
          end
        end

        # Check repository status
        def check_repository_status(path)
          Dir.chdir(path) do
            if system("git rev-parse --git-dir > /dev/null 2>&1")
              {
                is_git: true,
                branch: `git branch --show-current`.strip,
                clean: system("git diff --quiet && git diff --staged --quiet")
              }
            else
              {
                is_git: false
              }
            end
          end
        rescue
          {error: "Unable to check status"}
        end

        # Generate metadata for repository results
        def generate_metadata(repo, results)
          {
            repository_name: repo[:name],
            repository_path: repo[:path],
            search_time: Time.now.iso8601,
            result_count: count_results(results)
          }
        end

        # Count results
        def count_results(results)
          case results
          when Array
            results.size
          when Hash
            if results[:files] && results[:content]
              results[:files].size + results[:content].size
            else
              results.values.flatten.size
            end
          else
            0
          end
        end

        # Parse git grep output
        def parse_git_grep_output(output)
          output.lines.map do |line|
            if (match = line.match(/^([^:]+):(\d+):(.*)$/))
              {
                file: match[1],
                line: match[2].to_i,
                text: match[3].strip
              }
            end
          end.compact
        end

        # Parse grep output
        def parse_grep_output(output)
          output.lines.map do |line|
            if (match = line.match(/^([^:]+):(\d+):(.*)$/))
              {
                file: match[1].sub(/^\.\//, ""),
                line: match[2].to_i,
                text: match[3].strip
              }
            end
          end.compact
        end
      end
    end
  end
end
