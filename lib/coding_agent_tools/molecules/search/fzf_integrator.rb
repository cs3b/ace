# frozen_string_literal: true

require_relative "../../atoms/taskflow_management/shell_command_executor"

module CodingAgentTools
  module Molecules
    module Search
      # Integrates fzf for interactive file and result selection with preview
      class FzfIntegrator
        # Initialize fzf integrator
        # @param options [Hash] Configuration options
        def initialize(options = {})
          @options = options
          @executor = Atoms::TaskflowManagement::ShellCommandExecutor.new
        end

        # Check if fzf is available
        # @return [Boolean] True if fzf is installed
        def available?
          @executor.execute("which fzf")[:success]
        end

        # Launch interactive selection with fzf
        # @param items [Array<String>] Items to select from
        # @param prompt [String] Prompt to display
        # @param preview_cmd [String, nil] Preview command template
        # @return [Hash] Result hash with selected items
        def select_interactive(items, prompt: "Select", preview_cmd: nil)
          return error_response("fzf not available") unless available?
          return error_response("No items to select") if items.empty?

          input = items.join("\n")
          fzf_cmd = build_fzf_command(prompt, preview_cmd)
          
          result = @executor.execute(fzf_cmd, stdin: input)
          
          if result[:success]
            selected = result[:output].strip.split("\n")
            {
              success: true,
              selected: selected,
              count: selected.size
            }
          else
            {
              success: false,
              error: "Selection cancelled or failed",
              exit_code: result[:exit_code]
            }
          end
        end

        # Select files with preview
        # @param files [Array<String>] File paths to select from
        # @param prompt [String] Prompt to display
        # @return [Hash] Result with selected files
        def select_files(files, prompt: "Select files")
          preview_cmd = build_file_preview_command
          select_interactive(files, prompt: prompt, preview_cmd: preview_cmd)
        end

        # Select search results with context preview
        # @param results [Array<Hash>] Search results with file and line info
        # @param prompt [String] Prompt to display
        # @return [Hash] Result with selected items
        def select_search_results(results, prompt: "Select results")
          # Format results for display
          items = results.map do |r|
            "#{r[:file]}:#{r[:line]}:#{r[:column]}: #{r[:text]}"
          end
          
          preview_cmd = build_search_preview_command
          select_interactive(items, prompt: prompt, preview_cmd: preview_cmd)
        end

        private

        # Build fzf command with options
        def build_fzf_command(prompt, preview_cmd)
          cmd_parts = ["fzf"]
          
          # Add standard options
          cmd_parts << "--multi" if @options[:multi]
          cmd_parts << "--reverse" if @options[:reverse] != false
          cmd_parts << "--height=#{@options[:height] || '50%'}"
          cmd_parts << "--prompt='#{prompt}> '"
          
          # Add preview if specified
          if preview_cmd
            cmd_parts << "--preview='#{preview_cmd}'"
            cmd_parts << "--preview-window=#{@options[:preview_window] || 'right:50%'}"
          end
          
          # Add custom options
          if @options[:fzf_options]
            cmd_parts << @options[:fzf_options]
          end
          
          cmd_parts.join(" ")
        end

        # Build preview command for files
        def build_file_preview_command
          # Try to use bat for syntax highlighting, fall back to cat
          if @executor.execute("which bat")[:success]
            "bat --color=always --style=numbers --line-range=:500 {}"
          else
            "head -n 100 {}"
          end
        end

        # Build preview command for search results
        def build_search_preview_command
          # Extract file and line from result format
          if @executor.execute("which bat")[:success]
            "echo {} | cut -d: -f1-2 | xargs -I@ sh -c 'file=$(echo @ | cut -d: -f1); line=$(echo @ | cut -d: -f2); bat --color=always --highlight-line=$line --line-range=$((line-5)):$((line+5)) --style=numbers $file'"
          else
            "echo {} | cut -d: -f1-2 | xargs -I@ sh -c 'file=$(echo @ | cut -d: -f1); line=$(echo @ | cut -d: -f2); sed -n \"$((line-5)),$((line+5))p\" $file'"
          end
        end

        # Generate error response
        def error_response(message)
          {
            success: false,
            error: message,
            selected: []
          }
        end
      end
    end
  end
end