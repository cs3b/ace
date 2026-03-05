# frozen_string_literal: true

require "ace/git"

module Ace
  module Search
    module Organisms
      # Main search orchestration - coordinates search execution
      # This is an organism - orchestrates atoms and molecules for search operations
      class UnifiedSearcher
        def initialize
          @rg_executor = Atoms::RipgrepExecutor
          @fd_executor = Atoms::FdExecutor
          @result_parser = Atoms::ResultParser
          @dwim_analyzer = Molecules::DwimAnalyzer.new
        end

        # Execute search with given options
        # @param pattern [String] Search pattern
        # @param options [Hash] Search options
        # @return [Hash] Search results
        def search(pattern, options = {})
          search_mode = determine_search_mode(pattern, options)

          case search_mode
          when :file
            search_files(pattern, options)
          when :content
            search_content(pattern, options)
          when :hybrid
            search_hybrid(pattern, options)
          else
            search_content(pattern, options)
          end
        end

        private

        # Determine search mode based on pattern and options
        def determine_search_mode(pattern, options)
          return options[:type].to_sym if options[:type] && options[:type] != :auto

          @dwim_analyzer.determine_mode(pattern, options)
        end

        # Search for files matching pattern
        def search_files(pattern, options)
          fd_options = build_fd_options(options)
          result = @fd_executor.execute(pattern, fd_options)

          return {success: false, error: result[:error]} unless result[:success]

          files = @result_parser.parse_fd_output(result[:stdout])

          # Apply git scope filtering if needed
          files = apply_git_scope_filter(files, options) if options[:scope]

          # Apply time filtering if needed
          files = apply_time_filter(files, options) if options[:since] || options[:before]

          # Limit results
          files = files.first(options[:max_results]) if options[:max_results]

          {
            success: true,
            results: files,
            count: files.size,
            mode: :file
          }
        end

        # Search file content matching pattern
        def search_content(pattern, options)
          rg_options = build_rg_options(options)
          result = @rg_executor.execute(pattern, rg_options)

          return {success: false, error: result[:error]} unless result[:success]

          parse_mode = options[:files_with_matches] ? :files_only : :text
          matches = @result_parser.parse_ripgrep_output(result[:stdout], parse_mode)

          # Limit results
          matches = matches.first(options[:max_results]) if options[:max_results]

          {
            success: true,
            results: matches,
            count: matches.size,
            mode: :content
          }
        end

        # Search both files and content (hybrid mode)
        def search_hybrid(pattern, options)
          file_results = search_files(pattern, options)
          content_results = search_content(pattern, options)

          all_results = []
          all_results.concat(file_results[:results]) if file_results[:success]
          all_results.concat(content_results[:results]) if content_results[:success]

          {
            success: true,
            results: all_results,
            count: all_results.size,
            mode: :hybrid
          }
        end

        # Build ripgrep options from search options
        def build_rg_options(options)
          rg_opts = {}
          rg_opts[:ignore_case] = true if options[:case_insensitive]
          rg_opts[:word_regexp] = true if options[:whole_word]
          rg_opts[:multiline] = true if options[:multiline]
          rg_opts[:context] = options[:context] if options[:context]
          rg_opts[:before_context] = options[:before_context] if options[:before_context]
          rg_opts[:after_context] = options[:after_context] if options[:after_context]
          rg_opts[:glob] = options[:glob] if options[:glob]
          rg_opts[:hidden] = options[:hidden] if options[:hidden]
          rg_opts[:files_with_matches] = options[:files_with_matches] if options[:files_with_matches]
          rg_opts[:max_count] = options[:max_results] if options[:max_results]
          rg_opts[:search_path] = options[:search_path] if options[:search_path]

          rg_opts
        end

        # Build fd options from search options
        def build_fd_options(options)
          fd_opts = {}
          fd_opts[:ignore_case] = true if options[:case_insensitive]
          fd_opts[:hidden] = options[:hidden] if options[:hidden]
          fd_opts[:max_results] = options[:max_results] if options[:max_results]
          fd_opts[:exclude] = options[:exclude] if options[:exclude]
          fd_opts[:search_path] = options[:search_path] if options[:search_path]

          fd_opts
        end

        # Apply git scope filtering
        def apply_git_scope_filter(files, options)
          return files unless options[:scope]

          git_files = Ace::Git::Atoms::GitScopeFilter.get_files(options[:scope].to_sym)
          git_file_set = Set.new(git_files)

          files.select { |f| git_file_set.include?(f[:path]) }
        end

        # Apply time filtering
        def apply_time_filter(files, options)
          file_paths = files.map { |f| f[:path] }
          filtered_paths = Molecules::TimeFilter.filter(
            file_paths,
            since: options[:since],
            before: options[:before]
          )
          filtered_set = Set.new(filtered_paths)

          files.select { |f| filtered_set.include?(f[:path]) }
        end
      end
    end
  end
end
