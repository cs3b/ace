# frozen_string_literal: true

require "concurrent-ruby"

module CodingAgentTools
  module Molecules
    module Git
      class ConcurrentExecutionError < StandardError; end

      class ConcurrentExecutor
        DEFAULT_THREAD_POOL_SIZE = 4
        DEFAULT_TIMEOUT = 30 # seconds

        def self.execute_concurrently(commands_by_repo, options = {})
          new(options).execute_concurrently(commands_by_repo)
        end

        def initialize(options = {})
          @thread_pool_size = options.fetch(:thread_pool_size, DEFAULT_THREAD_POOL_SIZE)
          @timeout = options.fetch(:timeout, DEFAULT_TIMEOUT)
          @capture_output = options.fetch(:capture_output, true)
        end

        def execute_concurrently(commands_by_repo)
          return { success: true, results: {}, errors: [] } if commands_by_repo.empty?

          # Separate main repository for sequential execution
          main_commands = commands_by_repo.delete("main")
          submodule_commands = commands_by_repo

          results = {}
          errors = []

          # Execute submodules concurrently
          if submodule_commands.any?
            submodule_results = execute_submodules_concurrently(submodule_commands)
            results.merge!(submodule_results[:results])
            errors.concat(submodule_results[:errors])
          end

          # Execute main repository after submodules (if specified)
          if main_commands
            begin
              main_result = execute_main_repository(main_commands)
              results["main"] = main_result
            rescue => e
              errors << {
                repository: "main",
                error: e,
                message: e.message
              }
              results["main"] = { success: false, error: e.message }
            end
          end

          {
            success: errors.empty?,
            results: results,
            errors: errors
          }
        end

        private

        attr_reader :thread_pool_size, :timeout, :capture_output

        def execute_submodules_concurrently(submodule_commands)
          results = {}
          errors = []
          
          # Create thread pool for concurrent execution
          pool = Concurrent::FixedThreadPool.new(thread_pool_size)
          futures = []

          submodule_commands.each do |repo_name, commands|
            future = Concurrent::Future.execute(executor: pool) do
              execute_repository_commands(repo_name, commands)
            end
            futures << { repo_name: repo_name, future: future }
          end

          # Wait for all futures to complete with timeout
          futures.each do |future_info|
            begin
              result = future_info[:future].value(timeout)
              results[future_info[:repo_name]] = result
            rescue Concurrent::TimeoutError
              error_info = {
                repository: future_info[:repo_name],
                error: "Timeout after #{timeout} seconds",
                message: "Repository operation timed out"
              }
              errors << error_info
              results[future_info[:repo_name]] = { success: false, error: "Timeout" }
            rescue => e
              error_info = {
                repository: future_info[:repo_name],
                error: e,
                message: e.message
              }
              errors << error_info
              results[future_info[:repo_name]] = { success: false, error: e.message }
            end
          end

          # Shutdown thread pool gracefully
          pool.shutdown
          unless pool.wait_for_termination(30)
            # If threads don't finish within 30 seconds, force kill
            pool.kill
          end

          {
            results: results,
            errors: errors
          }
        end

        def execute_main_repository(commands)
          execute_repository_commands("main", commands)
        end

        def execute_repository_commands(repo_name, commands)
          return { success: true, commands: [], outputs: [] } if commands.empty?

          repository_path = repo_name == "main" ? nil : repo_name
          executor = CodingAgentTools::Atoms::Git::GitCommandExecutor.new(repository_path: repository_path)
          
          command_results = []
          
          commands.each do |command|
            begin
              result = executor.execute(command, capture_output: capture_output)
              command_results << {
                command: command,
                success: true,
                output: result[:stdout],
                stderr: result[:stderr]
              }
            rescue CodingAgentTools::Atoms::Git::GitCommandError => e
              command_results << {
                command: command,
                success: false,
                error: e.message,
                stderr: e.stderr_output
              }
              # Stop processing further commands on error
              break
            end
          end

          {
            success: command_results.all? { |cr| cr[:success] },
            repository: repo_name,
            commands: command_results,
            total_commands: commands.length,
            successful_commands: command_results.count { |cr| cr[:success] }
          }
        end
      end
    end
  end
end