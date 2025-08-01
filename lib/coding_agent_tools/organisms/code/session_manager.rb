# frozen_string_literal: true

require_relative '../../molecules/code/session_directory_builder'
require_relative '../../molecules/file_io_handler'
require_relative '../../atoms/code/file_content_reader'
require 'fileutils'
require 'tmpdir'
require 'time'

module CodingAgentTools
  module Organisms
    module Code
      # Manages review session lifecycle
      # This is an organism - it orchestrates molecules for session management
      class SessionManager
        def initialize
          @session_builder = Molecules::Code::SessionDirectoryBuilder.new
          @file_handler = Molecules::FileIoHandler.new
          @file_reader = Atoms::Code::FileContentReader.new
        end

        # Create a new review session
        # @param params [Hash] session parameters
        # @option params [String] :focus review focus
        # @option params [String] :target review target
        # @option params [String] :context_mode context mode
        # @option params [String] :base_path base path for sessions
        # @return [Models::Code::ReviewSession] created session
        def create_session(params)
          focus = params[:focus] || raise(ArgumentError, 'focus is required')
          target = params[:target] || raise(ArgumentError, 'target is required')
          context_mode = params[:context_mode] || 'auto'
          base_path = params[:base_path] || default_base_path

          # Build session with full parameters
          session = @session_builder.build_full_session(
            focus,
            target,
            context_mode,
            base_path
          )

          # Create additional session files
          create_session_files(session)

          session
        end

        # Load existing session
        # @param session_id [String] session ID
        # @param base_path [String] base path to search
        # @return [Models::Code::ReviewSession, nil] loaded session or nil
        def load_session(session_id, base_path = nil)
          base_path ||= default_base_path

          # Find session directory
          session_dir = find_session_directory(session_id, base_path)
          return nil unless session_dir

          # Load metadata
          metadata_path = File.join(session_dir, 'session.meta')
          return nil unless File.exist?(metadata_path)

          # Parse metadata
          metadata = parse_session_metadata(metadata_path)
          return nil unless metadata

          # Reconstruct session
          Models::Code::ReviewSession.new(
            session_id: session_id,
            session_name: File.basename(session_dir),
            timestamp: metadata[:timestamp],
            directory_path: session_dir,
            focus: metadata[:focus],
            target: metadata[:target],
            context_mode: metadata[:context],
            metadata: metadata
          )
        end

        # List all sessions
        # @param base_path [String] base path to search
        # @return [Array<Hash>] session summaries
        def list_sessions(base_path = nil)
          base_path ||= default_base_path
          sessions = []

          # Find all session directories
          Dir.glob(File.join(base_path, '*-*-*')).each do |dir|
            next unless File.directory?(dir)

            metadata_path = File.join(dir, 'session.meta')
            next unless File.exist?(metadata_path)

            metadata = parse_session_metadata(metadata_path)
            next unless metadata

            sessions << {
              session_name: File.basename(dir),
              timestamp: metadata[:timestamp],
              focus: metadata[:focus],
              target: metadata[:target],
              path: dir
            }
          end

          # Sort by timestamp descending
          sessions.sort_by { |s| s[:timestamp] }.reverse
        end

        # Clean up old sessions
        # @param days [Integer] sessions older than this many days
        # @param base_path [String] base path to search
        # @return [Array<String>] removed session paths
        def cleanup_old_sessions(days, base_path = nil)
          base_path ||= default_base_path
          cutoff_time = Time.now - (days * 24 * 60 * 60)
          removed = []

          list_sessions(base_path).each do |session|
            session_time = Time.parse(session[:timestamp])
            if session_time < cutoff_time
              FileUtils.rm_rf(session[:path])
              removed << session[:path]
            end
          end

          removed
        end

        private

        # Get default base path for sessions
        # @return [String] default base path
        def default_base_path
          current_release = find_current_release
          File.join(current_release, 'code_review')
        end

        # Find current release directory
        # @return [String] current release path
        def find_current_release
          # Look for current release in taskflow
          current_dir = 'dev-taskflow/current'
          if File.exist?(current_dir) && File.directory?(current_dir)
            # Find the release directory
            release_dirs = Dir.glob(File.join(current_dir, 'v.*'))
            release_dirs.first || current_dir
          else
            # Fallback to temp directory
            Dir.tmpdir
          end
        end

        # Find session directory by ID
        # @param session_id [String] session ID
        # @param base_path [String] base path
        # @return [String, nil] session directory path or nil
        def find_session_directory(session_id, base_path)
          # Look for directories containing the session ID
          pattern = File.join(base_path, "*#{session_id}*")
          dirs = Dir.glob(pattern).select { |d| File.directory?(d) }
          dirs.first
        end

        # Parse session metadata file
        # @param path [String] metadata file path
        # @return [Hash, nil] parsed metadata or nil
        def parse_session_metadata(path)
          content = File.read(path)
          metadata = {}

          content.each_line do |line|
            next unless line =~ /^(\w+):\s*(.+)$/

            key = ::Regexp.last_match(1).to_sym
            value = ::Regexp.last_match(2).strip
            metadata[key] = value
          end

          metadata.empty? ? nil : metadata
        rescue StandardError
          nil
        end

        # Create additional session files
        # @param session [Models::Code::ReviewSession] session
        def create_session_files(session)
          # Create README
          readme_content = <<~README
            # Code Review Session: #{session.session_name}

            **Generated**: #{session.timestamp}
            **Target**: #{session.target}
            **Focus**: #{session.focus}
            **Context**: #{session.context_mode_with_default}

            ## Session Files

            - `session.meta` - Session metadata
            - `input.diff` or `input.xml` - Target content
            - `input.meta` - Target metadata
            - `prompt.md` - Combined review prompt
            - `cr-report-*.md` - Review reports

            ## Next Steps

            Use the code-review command to execute the review.
          README

          readme_path = File.join(session.directory_path, 'README.md')
          File.write(readme_path, readme_content)
        end
      end
    end
  end
end
