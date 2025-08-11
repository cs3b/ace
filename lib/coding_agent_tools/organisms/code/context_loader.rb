# frozen_string_literal: true

require_relative "../../molecules/code/project_context_loader"
require_relative "../../molecules/file_io_handler"
require "yaml"

module CodingAgentTools
  module Organisms
    module Code
      # Loads and prepares project context
      # This is an organism - it orchestrates molecules for context loading
      class ContextLoader
        def initialize
          @context_loader = Molecules::Code::ProjectContextLoader.new
          @file_handler = Molecules::FileIoHandler.new
        end

        # Load context based on mode and session
        # @param mode [String] context mode
        # @param session [Models::Code::ReviewSession] review session
        # @return [Models::Code::ReviewContext] loaded context
        def load_context(mode, session)
          # Handle special case where mode is a file path
          custom_path = nil
          if mode != "auto" && mode != "none" && File.exist?(mode)
            custom_path = mode
            mode = "custom"
          end

          # Load context
          context = @context_loader.load_context(mode, custom_path)

          # Log context loading to session
          log_context_loading(context, session)

          context
        end

        # Save context to session directory
        # @param context [Models::Code::ReviewContext] context to save
        # @param session_dir [String] session directory path
        # @return [Hash] {success: Boolean, error: String}
        def save_context(context, session_dir)
          return {success: true, error: nil} unless context.loaded?

          context_file = File.join(session_dir, "context.yaml")

          begin
            # Prepare context data for saving
            context_data = {
              "mode" => context.mode,
              "loaded_at" => context.loaded_at.iso8601,
              "document_count" => context.document_count,
              "documents" => context.documents.map do |doc|
                {
                  "type" => doc[:type],
                  "path" => doc[:path],
                  "size" => doc[:content].size
                }
              end
            }

            # Save context metadata
            File.write(context_file, context_data.to_yaml)

            # Save individual context documents
            context.documents.each do |doc|
              doc_file = File.join(session_dir, "context-#{doc[:type]}.txt")
              File.write(doc_file, doc[:content])
            end

            {success: true, error: nil}
          rescue => e
            {success: false, error: "Failed to save context: #{e.message}"}
          end
        end

        # Check project context availability
        # @return [Hash] availability information
        def check_availability
          @context_loader.check_auto_availability
        end

        # Get context summary for display
        # @param context [Models::Code::ReviewContext] context
        # @return [String] human-readable summary
        def get_context_summary(context)
          return "No context loaded (mode: none)" unless context.loaded?

          lines = ["Project Context (mode: #{context.mode}):"]

          if context.using_auto_defaults?
            lines << "  Using standard project documents"
          elsif context.mode == "custom"
            lines << "  Using custom context file"
          end

          lines << "  Documents loaded: #{context.document_count}"
          lines << "  Total size: #{format_size(context.total_size)}"

          context.documents.each do |doc|
            lines << "  - #{doc[:type]}: #{doc[:path]} (#{format_size(doc[:content].size)})"
          end

          lines.join("\n")
        end

        private

        # Log context loading to session
        # @param context [Models::Code::ReviewContext] loaded context
        # @param session [Models::Code::ReviewSession] review session
        def log_context_loading(context, session)
          log_file = File.join(session.directory_path, "session.log")

          log_entry = <<~LOG
            [#{Time.now.iso8601}] Context Loading
            Mode: #{context.mode}
            Documents: #{context.document_count}
            Total Size: #{context.total_size} bytes
            #{context.documents.map { |d| "  - #{d[:type]}: #{d[:path]}" }.join("\n")}

          LOG

          File.open(log_file, "a") { |f| f.write(log_entry) }
        rescue
          # Ignore logging errors
        end

        # Format size for display
        # @param bytes [Integer] size in bytes
        # @return [String] formatted size
        def format_size(bytes)
          if bytes < 1024
            "#{bytes} bytes"
          elsif bytes < 1024 * 1024
            "#{(bytes / 1024.0).round(1)} KB"
          else
            "#{(bytes / (1024.0 * 1024)).round(1)} MB"
          end
        end
      end
    end
  end
end
