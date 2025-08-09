# frozen_string_literal: true

require_relative "../../molecules/git/multi_repo_coordinator"
require_relative "../../atoms/search/ripgrep_executor"
require_relative "../../atoms/search/fd_executor"
require_relative "../../molecules/search/dwim_heuristics_engine"
require_relative "result_aggregator"

module CodingAgentTools
  module Organisms
    module Search
      # Coordinates searches across multiple repositories
      class UnifiedSearcher
        # Initialize unified searcher
        # @param options [Hash] Configuration options
        def initialize(options = {})
          @options = options
          @coordinator = Molecules::Git::MultiRepoCoordinator.new
          @ripgrep = Atoms::Search::RipgrepExecutor.new
          @fd = Atoms::Search::FdExecutor.new
          @dwim = Molecules::Search::DwimHeuristicsEngine.new
          @aggregator = ResultAggregator.new
        end

        # Execute search across all repositories
        # @param pattern [String] Search pattern
        # @param options [Hash] Search options
        # @return [Hash] Aggregated search results
        def search(pattern, options = {})
          merged_options = @options.merge(options)
          
          # Determine search mode using DWIM heuristics
          mode = merged_options[:type] || @dwim.determine_mode(pattern)
          
          # Get repositories to search
          repositories = get_repositories(merged_options)
          
          # Execute search across repositories
          results = search_repositories(repositories, pattern, mode, merged_options)
          
          # Aggregate and format results
          @aggregator.aggregate(results, merged_options)
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

        # Get repository information
        # @return [Array<Hash>] Repository details
        def repositories
          @coordinator.repositories.map do |repo|
            {
              name: repo[:name],
              path: repo[:path],
              type: repo[:type],
              status: check_repository_status(repo[:path])
            }
          end
        end

        private

        # Get repositories to search based on options
        def get_repositories(options)
          if options[:repository]
            # Filter to specific repository
            @coordinator.repositories.select do |repo|
              repo[:name] == options[:repository] ||
              repo[:path] == options[:repository]
            end
          elsif options[:main_only]
            # Only search main repository
            [@coordinator.main_repository].compact
          else
            # Search all repositories
            @coordinator.repositories
          end
        end

        # Search across multiple repositories
        def search_repositories(repositories, pattern, mode, options)
          results = {}
          
          repositories.each do |repo|
            repo_results = search_single_repository(repo, pattern, mode, options)
            results[repo[:name]] = {
              repository: repo,
              results: repo_results,
              metadata: generate_metadata(repo, repo_results)
            }
          end
          
          results
        end

        # Search a single repository
        def search_single_repository(repo, pattern, mode, options)
          # Change to repository directory
          Dir.chdir(repo[:path]) do
            case mode
            when :file
              search_files_in_repo(pattern, options)
            when :content
              search_content_in_repo(pattern, options)
            when :hybrid
              # Search both files and content
              {
                files: search_files_in_repo(pattern, options),
                content: search_content_in_repo(pattern, options)
              }
            else
              { error: "Unknown search mode: #{mode}" }
            end
          end
        rescue => e
          { error: "Search failed: #{e.message}" }
        end

        # Search for files in repository
        def search_files_in_repo(pattern, options)
          if @fd.available?
            @fd.find_files(pattern, options)
          else
            # Fallback to basic file search
            fallback_file_search(pattern, options)
          end
        end

        # Search content in repository
        def search_content_in_repo(pattern, options)
          if @ripgrep.available?
            @ripgrep.search(pattern, options)
          else
            # Fallback to git grep
            fallback_content_search(pattern, options)
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
          { error: "Unable to check status" }
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
            if match = line.match(/^([^:]+):(\d+):(.*)$/)
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
            if match = line.match(/^([^:]+):(\d+):(.*)$/)
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