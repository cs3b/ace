# frozen_string_literal: true

module Ace
  module Git
    module Atoms
      # Pure functions for fetching git status information
      # Uses git status -sb for compact, familiar output
      module GitStatusFetcher
        class << self
          # Fetch git status in short branch format
          # @param executor [CommandExecutor] Command executor (default: CommandExecutor)
          # @return [Hash] Result with :success, :output, :error
          def fetch_status_sb(executor: CommandExecutor)
            # Disable color to ensure clean output for LLM context
            result = executor.execute("git", "-c", "color.status=false", "status", "-sb")

            if result[:success]
              {success: true, output: result[:output].strip}
            else
              {success: false, output: "", error: result[:error]}
            end
          rescue => e
            {success: false, output: "", error: e.message}
          end
        end
      end
    end
  end
end
