# frozen_string_literal: true

require_relative "../../atoms/editor/editor_detector"
require_relative "../../atoms/editor/editor_launcher"
require_relative "../../molecules/editor/editor_config_manager"

module CodingAgentTools
  module Organisms
    module Editor
      # Main editor integration orchestrator
      class EditorIntegration
        def initialize
          @detector = Atoms::Editor::EditorDetector.new
          @launcher = Atoms::Editor::EditorLauncher.new
          @config_manager = Molecules::Editor::EditorConfigManager.new
        end

        # Open search results in editor
        # @param search_results [Hash] Search results from UnifiedSearcher
        # @param options [Hash] Editor options
        # @option options [String] :editor Explicit editor to use
        # @option options [Symbol] :strategy Strategy for multiple files (:all, :interactive, :limit)
        # @option options [Boolean] :line_numbers Whether to use line numbers
        # @option options [Integer] :limit Maximum files to open
        # @return [Hash] Operation result
        def open_search_results(search_results, options = {})
          # Extract files from search results
          files_to_open = extract_files_from_results(search_results, options)

          if files_to_open.empty?
            return {
              success: false,
              error: "No files found in search results"
            }
          end

          # Get editor configuration
          editor_config = get_editor_config(options[:editor])

          # Validate editor availability
          unless @launcher.validate_availability(editor_config)
            return {
              success: false,
              error: "Editor not available: #{editor_config[:name]} (#{editor_config[:command]})",
              suggestion: "Install the editor or configure a different one with: search config --editor <editor_name>"
            }
          end

          # Open files
          open_files(files_to_open, editor_config, options)
        end

        # Configure editor settings
        # @param editor_command [String, nil] Editor command to set as default
        # @param options [Hash] Configuration options
        # @return [Hash] Configuration result
        def configure_editor(editor_command = nil, options = {})
          if editor_command
            # Set specific editor as default
            success = @config_manager.set_default_editor(editor_command, options)

            if success
              config = get_editor_config(editor_command)
              {
                success: true,
                message: "Default editor set to #{config[:name]} (#{config[:command]})",
                config: config
              }
            else
              {
                success: false,
                error: "Failed to save editor configuration"
              }
            end
          else
            # Show current configuration
            current_config = @config_manager.load_config
            editor_config = get_editor_config

            {
              success: true,
              current_editor: editor_config,
              configuration: current_config,
              available_editors: @detector.available_editors
            }
          end
        end

        # Get list of available editors
        # @return [Array<Hash>] Available editors
        def available_editors
          @detector.available_editors
        end

        private

        # Extract files from search results
        # @param search_results [Hash] Search results
        # @param options [Hash] Options
        # @return [Array<Hash>] Files with metadata
        def extract_files_from_results(search_results, options)
          files = []

          # Handle unified search results structure
          search_results[:results]&.each do |result|
            file_path = result[:file] || result[:path]
            next unless file_path

            file_info = {
              path: file_path,
              line: nil,
              text: nil
            }

            # Add line number if available and requested
            if options[:line_numbers] != false && result[:line]
              file_info[:line] = result[:line]
              file_info[:text] = result[:text]
            end

            files << file_info
          end

          # Handle legacy repository structure
          search_results[:repositories]&.each do |repo_name, repo_data|
            next unless repo_data[:results]

            case repo_data[:results]
            when Array
              repo_data[:results].each do |result|
                file_path = result[:file] || result[:path] || result
                next unless file_path

                file_info = {
                  path: file_path.to_s,
                  line: result.is_a?(Hash) ? result[:line] : nil,
                  text: result.is_a?(Hash) ? result[:text] : nil
                }

                files << file_info
              end
            when Hash
              # Handle hybrid results
              repo_data[:results][:files]&.each do |file|
                files << {path: file.to_s, line: nil, text: nil}
              end

              repo_data[:results][:content]&.each do |result|
                file_info = {
                  path: result[:file] || result[:path],
                  line: result[:line],
                  text: result[:text]
                }
                files << file_info if file_info[:path]
              end
            end
          end

          # Deduplicate by path
          seen_paths = Set.new
          files.select do |file|
            next false if seen_paths.include?(file[:path])
            seen_paths.add(file[:path])
            true
          end
        end

        # Get editor configuration
        # @param explicit_editor [String, nil] Explicitly specified editor
        # @return [Hash] Editor configuration
        def get_editor_config(explicit_editor = nil)
          config_data = @config_manager.load_config
          @detector.detect_editor(explicit_editor: explicit_editor, config: {"editor" => config_data})
        end

        # Open files with the configured editor
        # @param files [Array<Hash>] Files to open with metadata
        # @param editor_config [Hash] Editor configuration
        # @param options [Hash] Opening options
        # @return [Hash] Operation result
        def open_files(files, editor_config, options)
          strategy = options[:strategy] || determine_strategy(files.size)
          limit = options[:limit] || 10

          # Group files by whether they have line numbers
          files_with_lines = files.select { |f| f[:line] }
          files_without_lines = files.reject { |f| f[:line] }

          results = []

          # Open files with line numbers individually (to preserve line positioning)
          files_with_lines.each do |file|
            line_number = (options[:line_numbers] != false) ? file[:line] : nil
            result = @launcher.launch_file(file[:path], editor_config, line: line_number)
            result[:file] = file[:path]
            results << result
          end

          # Open files without line numbers in batch
          unless files_without_lines.empty?
            file_paths = files_without_lines.map { |f| f[:path] }
            result = @launcher.launch_files(file_paths, editor_config, strategy: strategy, limit: limit)
            results << result
          end

          # Aggregate results
          aggregate_open_results(results, files.size, editor_config[:name])
        end

        # Determine opening strategy based on number of files
        # @param file_count [Integer] Number of files to open
        # @return [Symbol] Strategy to use
        def determine_strategy(file_count)
          case file_count
          when 1
            :all
          when 2..5
            :all
          when 6..15
            :limit
          else
            :interactive
          end
        end

        # Aggregate results from multiple open operations
        # @param results [Array<Hash>] Individual operation results
        # @param total_files [Integer] Total number of files attempted
        # @param editor_name [String] Name of editor used
        # @return [Hash] Aggregated result
        def aggregate_open_results(results, total_files, editor_name)
          successful_results = results.select { |r| r[:success] }
          failed_results = results.reject { |r| r[:success] }

          total_opened = successful_results.sum { |r| r[:files_opened] || 1 }
          total_failed = failed_results.size + successful_results.sum { |r| r[:files_failed] || 0 }

          if total_failed == 0
            {
              success: true,
              message: "Successfully opened #{total_opened} file#{"s" if total_opened != 1} in #{editor_name}",
              files_opened: total_opened,
              editor: editor_name
            }
          else
            errors = failed_results.map { |r| r[:error] }.compact
            errors += successful_results.flat_map { |r| r[:errors] || [] }

            {
              success: total_opened > 0,
              message: "Opened #{total_opened} file#{"s" if total_opened != 1}, failed to open #{total_failed}",
              files_opened: total_opened,
              files_failed: total_failed,
              errors: errors.uniq,
              editor: editor_name
            }
          end
        end
      end
    end
  end
end
