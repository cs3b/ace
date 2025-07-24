# frozen_string_literal: true

require "time"
require "shellwords"
require_relative "../../atoms/git/git_command_executor"
require_relative "../../atoms/git/repository_scanner"
require_relative "../../atoms/git/submodule_detector"
require_relative "../../atoms/git/path_resolver"
require_relative "../../atoms/git/status_color_formatter"
require_relative "../../atoms/git/log_color_formatter"
require_relative "../../molecules/git/path_dispatcher"
require_relative "../../molecules/git/multi_repo_coordinator"
require_relative "../../molecules/git/concurrent_executor"
require_relative "../../molecules/git/commit_message_generator"

module CodingAgentTools
  module Organisms
    module Git
      class GitOrchestrationError < StandardError; end

      class GitOrchestrator
        def initialize(project_root = nil, options = {})
          @project_root = project_root || CodingAgentTools::Atoms::ProjectRootDetector.find_project_root
          @debug = options.fetch(:debug, false)
          @repositories = CodingAgentTools::Atoms::Git::RepositoryScanner.discover_repositories(@project_root)
        end

        # Status operations
        def status(options = {})
          coordinator = CodingAgentTools::Molecules::Git::MultiRepoCoordinator.new(@project_root)
          result = coordinator.execute_across_repositories("status", options.merge(capture_output: true))

          format_status_output(result, options)
        end

        # Log operations
        def log(options = {})
          coordinator = CodingAgentTools::Molecules::Git::MultiRepoCoordinator.new(@project_root)
          log_command = build_log_command(options)
          result = coordinator.execute_across_repositories(log_command, options.merge(capture_output: true))

          format_log_output(result, options)
        end

        # Add operations with path intelligence
        def add(paths, options = {})
          return {success: false, error: "No paths provided"} if paths.nil? || paths.empty?

          dispatcher = CodingAgentTools::Molecules::Git::PathDispatcher.new(@project_root)
          dispatch_info = dispatcher.dispatch_paths(paths)

          commands_by_repo = build_add_commands(dispatch_info, options)

          if options[:concurrent]
            CodingAgentTools::Molecules::Git::ConcurrentExecutor.execute_concurrently(commands_by_repo, options)
          else
            execute_sequentially(commands_by_repo, options)
          end
        end

        # Commit operations with LLM integration
        def commit(options = {})
          files = options[:files] || []

          puts "DEBUG: commit options = #{options.inspect}" if options[:debug]

          # Stage files if provided
          if files.any?
            add_result = add(files, options)
            return add_result unless add_result[:success]
          elsif !options[:repo_only]
            # Default behavior: stage all changes across all repositories
            # Only skip this if --repo-only flag is specified
            puts "DEBUG: Running add_all because repo_only = #{options[:repo_only]}" if options[:debug]
            add_result = add_all(options)
            return add_result unless add_result[:success]
          elsif options[:debug]
            puts "DEBUG: Skipping add_all because repo_only = #{options[:repo_only]}"
          end
          # Note: With --repo-only flag, commit only already staged changes

          # Perform the initial commit
          commit_result = if options[:message]
            commit_with_message(options[:message], options)
          else
            commit_with_llm_message(options)
          end

          # If we had specific files and commits were successful, check for submodule reference updates
          if files.any? && commit_result[:success] && !options[:repo_only]
            puts "DEBUG: Checking for submodule reference updates after file-specific commits" if options[:debug]
            # Stage any submodule reference updates that may have been created
            final_add_result = add_all(options.merge(main_only: true))
            if final_add_result[:success]
              # Commit any submodule reference updates
              final_commit_result = if options[:message]
                commit_with_message(options[:message], options.merge(main_only: true))
              else
                commit_with_llm_message(options.merge(main_only: true))
              end
              # Merge the results if additional commits were made
              if final_commit_result[:success] && final_commit_result[:results]&.any?
                commit_result[:results] = (commit_result[:results] || {}).merge(final_commit_result[:results])
                commit_result[:repositories_processed] = ((commit_result[:repositories_processed] || []) + (final_commit_result[:repositories_processed] || [])).uniq
              end
            end
          end

          commit_result
        end

        # Push operations
        def push(options = {})
          push_command = build_push_command(options)

          puts "DEBUG: Push options = #{options.inspect}" if options[:debug]

          # Handle repository filtering
          if options[:repo_only]
            # Push only the current repository
            current_repo = detect_current_repository
            puts "DEBUG: Current repository detected as: #{current_repo}" if options[:debug]
            coordinator = CodingAgentTools::Molecules::Git::MultiRepoCoordinator.new(@project_root)
            coordinator.execute_across_repositories(push_command, options.merge(repository: current_repo))
          elsif options[:concurrent]
            # Default behavior: push all repositories concurrently (submodules first, then main)
            execute_push_concurrent(push_command, options)
          else
            # Default behavior: push all repositories sequentially
            execute_push_sequential(push_command, options)
          end
        end

        # Pull operations
        def pull(options = {})
          pull_command = build_pull_command(options)

          if options[:concurrent]
            execute_pull_concurrent(pull_command, options)
          else
            execute_pull_sequential(pull_command, options)
          end
        end

        # Other git operations
        def diff(options = {})
          coordinator = CodingAgentTools::Molecules::Git::MultiRepoCoordinator.new(@project_root)
          diff_command = build_diff_command(options)
          coordinator.execute_across_repositories(diff_command, options.merge(capture_output: true))
        end

        def fetch(options = {})
          coordinator = CodingAgentTools::Molecules::Git::MultiRepoCoordinator.new(@project_root)
          fetch_command = build_fetch_command(options)
          coordinator.execute_across_repositories(fetch_command, options.merge(capture_output: true))
        end

        # Checkout operations
        def checkout(branch_or_paths, options = {})
          coordinator = CodingAgentTools::Molecules::Git::MultiRepoCoordinator.new(@project_root)
          checkout_command = build_checkout_command(branch_or_paths, options)

          if options[:concurrent]
            coordinator.execute_across_repositories(checkout_command, options.merge(capture_output: true, concurrent: true))
          else
            coordinator.execute_across_repositories(checkout_command, options.merge(capture_output: true))
          end
        end

        # Switch operations
        def switch(branch, options = {})
          coordinator = CodingAgentTools::Molecules::Git::MultiRepoCoordinator.new(@project_root)
          switch_command = build_switch_command(branch, options)

          if options[:concurrent]
            coordinator.execute_across_repositories(switch_command, options.merge(capture_output: true, concurrent: true))
          else
            coordinator.execute_across_repositories(switch_command, options.merge(capture_output: true))
          end
        end

        # Move/rename operations with path intelligence
        def mv(sources, destination, options = {})
          return {success: false, error: "No sources provided"} if sources.nil? || sources.empty?
          return {success: false, error: "No destination provided"} if destination.nil? || destination.empty?

          dispatcher = CodingAgentTools::Molecules::Git::PathDispatcher.new(@project_root)

          # Group sources by repository
          all_paths = sources + [destination]
          dispatch_info = dispatcher.dispatch_paths(all_paths)

          commands_by_repo = build_mv_commands(dispatch_info, sources, destination, options)

          if options[:concurrent]
            CodingAgentTools::Molecules::Git::ConcurrentExecutor.execute_concurrently(commands_by_repo, options)
          else
            execute_sequentially(commands_by_repo, options)
          end
        end

        # Remove operations with path intelligence
        def rm(paths, options = {})
          return {success: false, error: "No paths provided"} if paths.nil? || paths.empty?

          dispatcher = CodingAgentTools::Molecules::Git::PathDispatcher.new(@project_root)
          dispatch_info = dispatcher.dispatch_paths(paths)

          commands_by_repo = build_rm_commands(dispatch_info, options)

          if options[:concurrent]
            CodingAgentTools::Molecules::Git::ConcurrentExecutor.execute_concurrently(commands_by_repo, options)
          else
            execute_sequentially(commands_by_repo, options)
          end
        end

        # Restore operations with path intelligence
        def restore(pathspecs, options = {})
          return {success: false, error: "No pathspecs provided"} if pathspecs.nil? || pathspecs.empty?

          dispatcher = CodingAgentTools::Molecules::Git::PathDispatcher.new(@project_root)
          dispatch_info = dispatcher.dispatch_paths(pathspecs)

          commands_by_repo = build_restore_commands(dispatch_info, options)

          if options[:concurrent]
            CodingAgentTools::Molecules::Git::ConcurrentExecutor.execute_concurrently(commands_by_repo, options)
          else
            execute_sequentially(commands_by_repo, options)
          end
        end

        # Repository information
        attr_reader :repositories

        private

        attr_reader :project_root, :debug

        # Status formatting
        def format_status_output(result, options)
          formatted_output = []
          color_formatter = CodingAgentTools::Atoms::Git::StatusColorFormatter.new(options)

          result[:results].each do |repo_name, repo_result|
            next unless repo_result[:success]

            output = repo_result[:stdout] || ""
            next if output.strip.empty? && !options[:verbose]

            formatted_line = color_formatter.format_repository_status(repo_name, output)
            formatted_output << formatted_line
          end

          result.merge(formatted_output: formatted_output.join("\n\n"))
        end

        # Log command building and formatting
        def build_log_command(options)
          cmd_parts = ["log"]

          # Always include timestamp for sorting, but format according to user preference
          if options[:oneline]
            # For oneline, include timestamp at the end in a parseable format
            cmd_parts << "--pretty=format:#{Shellwords.escape("%h %s (%ci)")}"
          else
            # For regular format, use default but add timestamp marker for parsing
            cmd_parts << "--date=iso"
            cmd_parts << "--pretty=format:#{Shellwords.escape("TIMESTAMP:%ci%ncommit %H%nAuthor: %an <%ae>%nDate:   %ci%n%n%w(0,4,4)%s%n%+b")}"
          end

          cmd_parts << "--graph" if options[:graph]
          cmd_parts << "--since=#{Shellwords.escape(options[:since])}" if options[:since]
          cmd_parts << "--until=#{Shellwords.escape(options[:until])}" if options[:until]
          cmd_parts << "--author=#{Shellwords.escape(options[:author])}" if options[:author]
          cmd_parts << "--grep=#{Shellwords.escape(options[:grep])}" if options[:grep]
          cmd_parts << "-n #{options[:max_count]}" if options[:max_count]

          cmd_parts.join(" ")
        end

        def format_log_output(result, options)
          if options[:separated]
            format_separated_log(result, options)
          else
            # Default to unified format so each commit shows its repository
            format_unified_log(result, options)
          end
        end

        def format_unified_log(result, options = {})
          all_commits = []

          result[:results].each do |repo_name, repo_result|
            next unless repo_result[:success]

            output = repo_result[:stdout] || ""
            commits = parse_commits_from_output(output, repo_name)
            all_commits.concat(commits)
          end

          # Sort by commit date (newest first)
          all_commits.sort_by! { |commit| -commit[:timestamp].to_i }

          # Format output with proper padding and separation
          formatted_output = format_commits_with_padding(all_commits, options)

          result.merge(formatted_output: formatted_output)
        end

        def format_separated_log(result, options = {})
          formatted_output = []

          result[:results].each do |repo_name, repo_result|
            next unless repo_result[:success]

            output = repo_result[:stdout] || ""
            next if output.strip.empty?

            formatted_output << "[#{repo_name}] Recent commits:"
            output.lines.each { |line| formatted_output << "  #{line.rstrip}" }
            formatted_output << ""
          end

          result.merge(formatted_output: formatted_output.join("\n"))
        end

        # Format commits with proper padding and visual separation
        def format_commits_with_padding(all_commits, options = {})
          return "" if all_commits.empty?

          # Initialize color formatter
          color_formatter = CodingAgentTools::Atoms::Git::LogColorFormatter.new(options)

          # Find the longest repository name for alignment
          max_repo_length = all_commits.map { |commit| commit[:repo].length }.max

          formatted_lines = []

          all_commits.each_with_index do |commit, index|
            repo_name = commit[:repo]

            # Create padded repository name (without color for padding calculation)
            plain_repo = "[#{repo_name}]"
            padded_repo_plain = plain_repo.ljust(max_repo_length + 2)

            # Apply color to the padded repository name
            colored_repo = color_formatter.should_use_color? ?
              color_formatter.send(:colorize, padded_repo_plain, :repo_name) :
              padded_repo_plain

            # Apply color formatting to commit content
            colored_content = color_formatter.format_commit(commit)

            # Handle multi-line commits differently
            if commit[:type] == :multiline
              lines = colored_content.split("\n")
              lines.each_with_index do |line, line_index|
                if line_index == 0
                  formatted_lines << "#{colored_repo} #{line}"
                else
                  # Indent continuation lines to align with content
                  padding = " " * (max_repo_length + 3)
                  formatted_lines << "#{padding} #{line}"
                end
              end
            else
              # Single line commits
              formatted_lines << "#{colored_repo} #{colored_content}"
            end

            # Add spacing between commits for better readability
            formatted_lines << "" unless index == all_commits.length - 1
          end

          formatted_lines.join("\n")
        end

        # Parse commits from git output, handling both oneline and full formats
        def parse_commits_from_output(output, repo_name)
          commits = []

          if output.include?("TIMESTAMP:")
            # Handle full commit format with TIMESTAMP markers
            commit_blocks = output.split(/^TIMESTAMP:/)
            commit_blocks.shift if commit_blocks.first&.strip&.empty? # Remove empty first block

            commit_blocks.each do |block|
              lines = block.strip.split("\n")
              next if lines.empty?

              timestamp_str = lines.first.strip
              commit_content = lines[1..].join("\n")

              begin
                timestamp = Time.parse(timestamp_str)
                commits << {
                  repo: repo_name,
                  timestamp: timestamp,
                  display_line: commit_content,
                  type: :multiline
                }
              rescue
                # Skip commits with unparseable timestamps
              end
            end
          else
            # Handle oneline format
            output.lines.each do |line|
              next if line.strip.empty?
              commit_info = parse_commit_line(line.rstrip, repo_name)
              commits << commit_info if commit_info
            end
          end

          commits
        end

        # Parse commit line to extract timestamp for sorting (oneline format)
        def parse_commit_line(line, repo_name)
          # Handle oneline format: hash message (timestamp)
          if line =~ /^(\w+)\s+(.+?)\s+\((\d{4}-\d{2}-\d{2}\s+\d{2}:\d{2}:\d{2}\s+[+-]\d{4})\)$/
            hash_part = $1
            message_part = $2
            timestamp_str = $3

            begin
              timestamp = Time.parse(timestamp_str)
              display_line = "#{hash_part} #{message_part}"

              {
                repo: repo_name,
                timestamp: timestamp,
                display_line: display_line,
                type: :oneline
              }
            rescue
              nil # Skip unparseable lines
            end
          else
            nil # Skip non-matching lines
          end
        end

        # Add command building
        def build_add_commands(dispatch_info, options)
          commands_by_repo = {}

          dispatch_info.each do |repo_name, repo_info|
            paths = repo_info[:paths]
            next if paths.empty?

            add_cmd_parts = ["add"]
            add_cmd_parts << "--all" if options[:all]
            add_cmd_parts << "--update" if options[:update]
            add_cmd_parts << "--force" if options[:force]
            add_cmd_parts << "--patch" if options[:patch]
            add_cmd_parts.concat(paths.map { |p| Shellwords.escape(p) })

            commands_by_repo[repo_name] = [add_cmd_parts.join(" ")]
          end

          commands_by_repo
        end

        def add_all(options)
          coordinator = CodingAgentTools::Molecules::Git::MultiRepoCoordinator.new(@project_root)
          coordinator.execute_across_repositories("add --all", options)
        end

        # Commit operations
        def commit_with_message(message, options)
          coordinator = CodingAgentTools::Molecules::Git::MultiRepoCoordinator.new(@project_root)
          escaped_message = Shellwords.escape(message)
          commit_command = "commit -m #{escaped_message}"

          # Execute submodules first, then main repository for proper dependency order
          submodule_result = coordinator.execute_across_repositories(commit_command, options.merge(submodules_only: true))
          main_result = coordinator.execute_across_repositories(commit_command, options.merge(main_only: true))

          # Merge results
          combined_results = submodule_result[:results].merge(main_result[:results])
          combined_errors = submodule_result[:errors] + main_result[:errors]

          {
            success: submodule_result[:success] && main_result[:success],
            results: combined_results,
            errors: combined_errors,
            repositories_processed: (submodule_result[:repositories_processed] + main_result[:repositories_processed])
          }
        end

        def commit_with_llm_message(options)
          commands_by_repo = {}

          # Generate commit message for each repository that has staged changes
          repositories.each do |repo|
            next unless repo[:exists] && repo[:is_git_repo]

            diff = get_staged_diff(repo)
            next if diff.strip.empty?

            begin
              generator = CodingAgentTools::Molecules::Git::CommitMessageGenerator.new(options)
              message = generator.generate_message(diff)

              escaped_message = Shellwords.escape(message)
              # Default to non-interactive commits for programmatic operations
              # Only use --edit when explicitly requested AND in an interactive context
              commit_command = if options[:edit] && $stdin.tty?
                "commit --edit -m #{escaped_message}"
              else
                "commit -m #{escaped_message}"
              end

              commands_by_repo[repo[:name]] = [commit_command]
            rescue CodingAgentTools::Molecules::Git::CommitMessageGenerationError => e
              return {success: false, error: "Failed to generate commit message for #{repo[:name]}: #{e.message}"}
            end
          end

          if commands_by_repo.empty?
            return {success: false, error: "No staged changes to commit"}
          end

          if options[:concurrent]
            CodingAgentTools::Molecules::Git::ConcurrentExecutor.execute_concurrently(commands_by_repo, options)
          else
            execute_sequentially_with_submodules_first(commands_by_repo, options)
          end
        end

        def get_staged_diff(repository)
          repository_path = (repository[:name] == "main") ? nil : repository[:path]
          executor = CodingAgentTools::Atoms::Git::GitCommandExecutor.new(repository_path: repository_path)

          begin
            result = executor.execute("diff --staged")
            result[:stdout] || ""
          rescue CodingAgentTools::Atoms::Git::GitCommandError
            ""
          end
        end

        # Push/Pull operations
        def build_push_command(options)
          cmd_parts = ["push"]
          cmd_parts << "--force" if options[:force]
          cmd_parts << "--dry-run" if options[:dry_run]
          cmd_parts << "--set-upstream" if options[:set_upstream]
          cmd_parts << "--tags" if options[:tags]
          cmd_parts << options[:remote] if options[:remote]
          cmd_parts << options[:branch] if options[:branch]

          cmd_parts.join(" ")
        end

        def build_pull_command(options)
          cmd_parts = ["pull"]
          cmd_parts << "--rebase" if options[:rebase]
          cmd_parts << "--ff-only" if options[:ff_only]
          cmd_parts << "--no-commit" if options[:no_commit]
          cmd_parts << "--strategy=#{options[:strategy]}" if options[:strategy]
          cmd_parts << options[:remote] if options[:remote]
          cmd_parts << options[:branch] if options[:branch]

          cmd_parts.join(" ")
        end

        def build_diff_command(options)
          cmd_parts = ["diff"]
          cmd_parts << "--staged" if options[:staged]
          cmd_parts << "--name-only" if options[:name_only]
          cmd_parts << "--stat" if options[:stat]

          cmd_parts.join(" ")
        end

        def build_fetch_command(options)
          cmd_parts = ["fetch"]
          cmd_parts << "--all" if options[:all]
          cmd_parts << "--prune" if options[:prune]
          cmd_parts << "--tags" if options[:tags]
          cmd_parts << options[:remote] if options[:remote]

          cmd_parts.join(" ")
        end

        def build_checkout_command(branch_or_paths, options)
          cmd_parts = ["checkout"]
          cmd_parts << "--quiet" if options[:quiet]
          cmd_parts << "--force" if options[:force]
          cmd_parts << "--merge" if options[:merge]
          cmd_parts << "--detach" if options[:detach]
          cmd_parts << "--track" if options[:track]
          cmd_parts << "--no-track" if options[:no_track]

          if options[:create_branch]
            cmd_parts << "-b" << Shellwords.escape(options[:create_branch])
          elsif options[:force_create_branch]
            cmd_parts << "-B" << Shellwords.escape(options[:force_create_branch])
          elsif options[:orphan]
            cmd_parts << "--orphan" << Shellwords.escape(options[:orphan])
          end

          # Add branch or paths
          if branch_or_paths && !branch_or_paths.empty?
            branch_or_paths.each { |item| cmd_parts << Shellwords.escape(item) }
          end

          cmd_parts.join(" ")
        end

        def build_switch_command(branch, options)
          cmd_parts = ["switch"]
          cmd_parts << "--quiet" if options[:quiet]
          cmd_parts << "--force" if options[:force]
          cmd_parts << "--merge" if options[:merge]
          cmd_parts << "--detach" if options[:detach]
          cmd_parts << "--track" if options[:track]
          cmd_parts << "--no-track" if options[:no_track]
          cmd_parts << "--no-guess" if options[:no_guess]

          if options[:create]
            cmd_parts << "-c" << Shellwords.escape(options[:create])
          elsif options[:force_create]
            cmd_parts << "-C" << Shellwords.escape(options[:force_create])
          elsif options[:orphan]
            cmd_parts << "--orphan" << Shellwords.escape(options[:orphan])
          end

          # Add branch name
          cmd_parts << Shellwords.escape(branch) if branch

          cmd_parts.join(" ")
        end

        # Build mv commands grouped by repository
        def build_mv_commands(dispatch_info, sources, destination, options)
          commands_by_repo = {}

          # For mv operations, we need to handle cross-repository moves differently
          # For now, we'll only support moves within the same repository
          dispatch_info.each do |repo_name, repo_info|
            repo_sources = []
            repo_destination = nil

            # Check which sources and destination belong to this repo
            sources.each do |source|
              repo_sources << source if repo_info[:paths].include?(source)
            end

            repo_destination = destination if repo_info[:paths].include?(destination)

            # Only create command if we have sources and destination in same repo
            if repo_sources.any? && repo_destination
              mv_cmd_parts = ["mv"]
              mv_cmd_parts << "--force" if options[:force]
              mv_cmd_parts << "--dry-run" if options[:dry_run]
              mv_cmd_parts << "--verbose" if options[:verbose]

              repo_sources.each { |src| mv_cmd_parts << Shellwords.escape(src) }
              mv_cmd_parts << Shellwords.escape(repo_destination)

              commands_by_repo[repo_name] = [mv_cmd_parts.join(" ")]
            end
          end

          commands_by_repo
        end

        # Build rm commands grouped by repository
        def build_rm_commands(dispatch_info, options)
          commands_by_repo = {}

          dispatch_info.each do |repo_name, repo_info|
            paths = repo_info[:paths]
            next if paths.empty?

            rm_cmd_parts = ["rm"]
            rm_cmd_parts << "--force" if options[:force]
            rm_cmd_parts << "--dry-run" if options[:dry_run]
            rm_cmd_parts << "--recursive" if options[:recursive]
            rm_cmd_parts << "--cached" if options[:cached]
            rm_cmd_parts << "--ignore-unmatch" if options[:ignore_unmatch]
            rm_cmd_parts << "--quiet" if options[:quiet]

            paths.each { |path| rm_cmd_parts << Shellwords.escape(path) }

            commands_by_repo[repo_name] = [rm_cmd_parts.join(" ")]
          end

          commands_by_repo
        end

        # Build restore commands grouped by repository
        def build_restore_commands(dispatch_info, options)
          commands_by_repo = {}

          dispatch_info.each do |repo_name, repo_info|
            paths = repo_info[:paths]
            next if paths.empty?

            restore_cmd_parts = ["restore"]
            restore_cmd_parts << "--source=#{Shellwords.escape(options[:source])}" if options[:source]
            restore_cmd_parts << "--staged" if options[:staged]
            restore_cmd_parts << "--worktree" if options[:worktree]
            restore_cmd_parts << "--merge" if options[:merge]
            restore_cmd_parts << "--conflict=#{options[:conflict]}" if options[:conflict]
            restore_cmd_parts << "--ours" if options[:ours]
            restore_cmd_parts << "--theirs" if options[:theirs]
            restore_cmd_parts << "--patch" if options[:patch]
            restore_cmd_parts << "--quiet" if options[:quiet]
            restore_cmd_parts << "--progress" if options[:progress]

            paths.each { |path| restore_cmd_parts << Shellwords.escape(path) }

            commands_by_repo[repo_name] = [restore_cmd_parts.join(" ")]
          end

          commands_by_repo
        end

        # Repository detection
        def detect_current_repository
          current_dir = Dir.pwd

          puts "DEBUG: Current dir: #{current_dir}" if debug
          puts "DEBUG: Project root: #{@project_root}" if debug
          repositories.each do |repo|
            puts "DEBUG: Repo #{repo[:name]}: #{repo[:path]}" if debug
          end

          # Check if we're in a submodule first (more specific)
          repositories.each do |repo|
            if repo[:path] && File.expand_path(current_dir) == File.expand_path(repo[:path])
              return repo[:name]
            end
          end

          # Check if we're in the main repository
          if File.expand_path(current_dir) == File.expand_path(@project_root)
            return "main"
          end

          # Default to main if not found
          "main"
        end

        # Execution methods
        def execute_push_concurrent(command, options)
          # For concurrent push, use the MultiRepoCoordinator with concurrent option
          # but ensure submodules are executed first, then main
          coordinator = CodingAgentTools::Molecules::Git::MultiRepoCoordinator.new(@project_root)

          # Execute submodules first
          submodule_result = coordinator.execute_across_repositories(command, options.merge(submodules_only: true))

          # Then execute main repository
          main_result = coordinator.execute_across_repositories(command, options.merge(main_only: true))

          # Merge results
          combined_results = submodule_result[:results].merge(main_result[:results])
          combined_errors = submodule_result[:errors] + main_result[:errors]

          {
            success: submodule_result[:success] && main_result[:success],
            results: combined_results,
            errors: combined_errors,
            repositories_processed: (submodule_result[:repositories_processed] + main_result[:repositories_processed])
          }
        end

        def execute_push_sequential(command, options)
          coordinator = CodingAgentTools::Molecules::Git::MultiRepoCoordinator.new(@project_root)

          # Execute submodules first, then main repository for proper dependency order
          submodule_result = coordinator.execute_across_repositories(command, options.merge(submodules_only: true))
          main_result = coordinator.execute_across_repositories(command, options.merge(main_only: true))

          # Merge results
          combined_results = submodule_result[:results].merge(main_result[:results])
          combined_errors = submodule_result[:errors] + main_result[:errors]

          {
            success: submodule_result[:success] && main_result[:success],
            results: combined_results,
            errors: combined_errors,
            repositories_processed: (submodule_result[:repositories_processed] + main_result[:repositories_processed])
          }
        end

        def execute_pull_concurrent(command, options)
          coordinator = CodingAgentTools::Molecules::Git::MultiRepoCoordinator.new(@project_root)

          # Execute main repository first to get updated submodule refs
          main_result = coordinator.execute_across_repositories(command, options.merge(main_only: true))

          # Then execute submodules to update to those refs
          submodule_result = coordinator.execute_across_repositories(command, options.merge(submodules_only: true))

          # Merge results
          combined_results = main_result[:results].merge(submodule_result[:results])
          combined_errors = main_result[:errors] + submodule_result[:errors]

          {
            success: main_result[:success] && submodule_result[:success],
            results: combined_results,
            errors: combined_errors,
            repositories_processed: (main_result[:repositories_processed] + submodule_result[:repositories_processed])
          }
        end

        def execute_pull_sequential(command, options)
          coordinator = CodingAgentTools::Molecules::Git::MultiRepoCoordinator.new(@project_root)

          # Execute main repository first to get updated submodule refs
          main_result = coordinator.execute_across_repositories(command, options.merge(main_only: true))

          # Then execute submodules to update to those refs
          submodule_result = coordinator.execute_across_repositories(command, options.merge(submodules_only: true))

          # Merge results
          combined_results = main_result[:results].merge(submodule_result[:results])
          combined_errors = main_result[:errors] + submodule_result[:errors]

          {
            success: main_result[:success] && submodule_result[:success],
            results: combined_results,
            errors: combined_errors,
            repositories_processed: (main_result[:repositories_processed] + submodule_result[:repositories_processed])
          }
        end

        def execute_sequentially(commands_by_repo, options)
          results = {}
          errors = []

          commands_by_repo.each do |repo_name, commands|
            repository = repositories.find { |r| r[:name] == repo_name }
            repository_path = (repo_name == "main") ? nil : repository[:path]
            executor = CodingAgentTools::Atoms::Git::GitCommandExecutor.new(repository_path: repository_path)

            repo_results = []
            commands.each do |command|
              result = executor.execute(command, capture_output: options.fetch(:capture_output, true))
              repo_results << result
            end

            results[repo_name] = {
              success: true,
              commands: repo_results,
              repository: repo_name
            }
          rescue => e
            errors << {
              repository: repo_name,
              error: e,
              message: e.message
            }
            results[repo_name] = {success: false, error: e.message}
          end

          {
            success: errors.empty?,
            results: results,
            errors: errors
          }
        end

        def execute_sequentially_with_submodules_first(commands_by_repo, options)
          results = {}
          errors = []

          # Execute submodules first, then main repository
          execution_order = []

          # Add submodules to execution order first
          commands_by_repo.keys.each do |repo_name|
            execution_order << repo_name unless repo_name == "main"
          end

          # Add main repository last
          execution_order << "main" if commands_by_repo.key?("main")

          execution_order.each do |repo_name|
            commands = commands_by_repo[repo_name]
            next unless commands

            begin
              repository = repositories.find { |r| r[:name] == repo_name }
              repository_path = (repo_name == "main") ? nil : repository[:path]
              executor = CodingAgentTools::Atoms::Git::GitCommandExecutor.new(repository_path: repository_path)

              repo_results = []
              commands.each do |command|
                result = executor.execute(command, capture_output: options.fetch(:capture_output, true))
                repo_results << result
              end

              results[repo_name] = {
                success: true,
                commands: repo_results,
                repository: repo_name
              }
            rescue => e
              errors << {
                repository: repo_name,
                error: e,
                message: e.message
              }
              results[repo_name] = {success: false, error: e.message}
            end
          end

          {
            success: errors.empty?,
            results: results,
            errors: errors
          }
        end
      end
    end
  end
end
