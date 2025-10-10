# frozen_string_literal: true

require_relative "../../atoms/code/directory_creator"
require_relative "../../atoms/code/session_timestamp_generator"
require_relative "../../atoms/code/session_name_builder"
require_relative "../../models/code/review_session"
require_relative "../path_resolver"

module CodingAgentTools
  module Molecules
    module Code
      # Creates and structures session directories for code reviews
      # This is a molecule - it composes atoms to provide session directory functionality
      class SessionDirectoryBuilder
        def initialize
          @directory_creator = Atoms::Code::DirectoryCreator.new
          @timestamp_generator = Atoms::Code::SessionTimestampGenerator.new
          @name_builder = Atoms::Code::SessionNameBuilder.new
          @path_resolver = PathResolver.new
        end

        # Build a complete session directory
        # @param focus [String] review focus
        # @param target [String] review target
        # @param base_path [String] base path for sessions (optional, nav-path will determine path)
        # @return [Models::Code::ReviewSession] created session
        def build_session_directory(focus, target, base_path = nil)
          timestamp = @timestamp_generator.generate
          iso_timestamp = @timestamp_generator.generate_iso8601

          # Generate session name for nav-path (focus-target format for slug)
          sanitized_target = @name_builder.send(:sanitize_target, target)
          session_slug = "#{focus}-#{sanitized_target}"

          # Use nav-path to generate the directory path
          path_result = @path_resolver.resolve_path(session_slug, type: :code_review_new)
          raise "Failed to generate session path: #{path_result[:error]}" unless path_result[:success]

          directory_path = path_result[:path]

          # Extract session name from generated path for consistency
          session_name = File.basename(directory_path)
          session_id = "review-#{timestamp}"

          # Create the directory
          result = @directory_creator.create(directory_path)
          raise "Failed to create session directory: #{result[:error]}" unless result[:success]

          # Create session metadata
          session = Models::Code::ReviewSession.new(
            session_id: session_id,
            session_name: session_name,
            timestamp: iso_timestamp,
            directory_path: directory_path,
            focus: focus,
            target: target,
            context_mode: nil, # Will be set later
            metadata: {
              created_at: Time.now,
              base_path: base_path
            }
          )

          # Write session metadata file
          write_session_metadata(session)

          session
        end

        # Create session with specific context mode
        # @param focus [String] review focus
        # @param target [String] review target
        # @param context_mode [String] context mode
        # @param base_path [String] base path for sessions (optional, nav-path will determine path)
        # @return [Models::Code::ReviewSession] created session
        def build_full_session(focus, target, context_mode, base_path = nil)
          session = build_session_directory(focus, target, base_path)
          session.context_mode = context_mode

          # Update metadata file with context mode
          write_session_metadata(session)

          session
        end

        # Check if session directory exists
        # @param session [Models::Code::ReviewSession] session to check
        # @return [Boolean] true if directory exists
        def session_exists?(session)
          @directory_creator.exists?(session.directory_path)
        end

        private

        # Write session metadata to file
        # @param session [Models::Code::ReviewSession] session data
        def write_session_metadata(session)
          metadata_path = File.join(session.directory_path, "session.meta")

          content = <<~METADATA
            command: @review-code #{session.focus} #{session.target} #{session.context_mode_with_default}
            timestamp: #{session.timestamp}
            target: #{session.target}
            focus: #{session.focus}
            context: #{session.context_mode_with_default}
          METADATA

          File.write(metadata_path, content)
        end
      end
    end
  end
end
