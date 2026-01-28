# frozen_string_literal: true

require "yaml"
require "fileutils"
require "ace/support/timestamp"

module Ace
  module Coworker
    module Molecules
      # Manages session YAML file operations.
      #
      # Handles creation, loading, and updating of session.yaml files.
      # Uses ace-support-timestamp for session ID generation.
      class SessionManager
        # @param cache_base [String] Base cache directory
        def initialize(cache_base: nil)
          @cache_base = cache_base || Ace::Coworker.cache_dir
        end

        # Create a new session
        #
        # @param name [String] Session name
        # @param description [String, nil] Session description
        # @param source_config [String] Path to source config file
        # @return [Models::Session] Created session
        def create(name:, description: nil, source_config:)
          session_id = generate_session_id
          cache_dir = File.join(@cache_base, session_id)

          # Create directories
          FileUtils.mkdir_p(cache_dir)
          FileUtils.mkdir_p(File.join(cache_dir, "jobs"))

          now = Time.now.utc

          session = Models::Session.new(
            id: session_id,
            name: name,
            description: description,
            created_at: now,
            updated_at: now,
            source_config: source_config,
            cache_dir: cache_dir
          )

          # Write session.yaml
          write_session_file(session)

          session
        end

        # Load an existing session by ID
        #
        # @param session_id [String] Session ID
        # @return [Models::Session, nil] Loaded session or nil
        def load(session_id)
          cache_dir = File.join(@cache_base, session_id)
          session_file = File.join(cache_dir, "session.yaml")

          return nil unless File.exist?(session_file)

          data = YAML.safe_load_file(session_file, permitted_classes: [Time, Date])
          Models::Session.from_h(data, cache_dir: cache_dir)
        end

        # Find the most recent active session
        #
        # @return [Models::Session, nil] Most recent session or nil
        def find_active
          return nil unless File.directory?(@cache_base)

          # Find all session directories
          sessions = Dir.glob(File.join(@cache_base, "*", "session.yaml"))
                        .map { |f| load_from_file(f) }
                        .compact
                        .sort_by(&:updated_at)
                        .reverse

          sessions.first
        end

        # Update session metadata
        #
        # @param session [Models::Session] Session to update
        # @return [Models::Session] Updated session
        def update(session)
          # Create new session with updated timestamp
          updated = Models::Session.new(
            id: session.id,
            name: session.name,
            description: session.description,
            created_at: session.created_at,
            updated_at: Time.now.utc,
            source_config: session.source_config,
            cache_dir: session.cache_dir
          )

          write_session_file(updated)
          updated
        end

        # List all sessions
        #
        # @return [Array<Models::Session>] All sessions
        def list
          return [] unless File.directory?(@cache_base)

          Dir.glob(File.join(@cache_base, "*", "session.yaml"))
             .map { |f| load_from_file(f) }
             .compact
             .sort_by(&:updated_at)
             .reverse
        end

        private

        def generate_session_id
          base_id = Ace::Support::Timestamp.now
          candidate = base_id

          # Handle collision by appending suffix
          suffix = 0
          while File.exist?(File.join(@cache_base, candidate))
            suffix += 1
            candidate = "#{base_id}#{suffix.to_s(36)}"
          end

          candidate
        end

        def write_session_file(session)
          session_file = File.join(session.cache_dir, "session.yaml")
          File.write(session_file, session.to_h.to_yaml)
        end

        def load_from_file(session_file)
          cache_dir = File.dirname(session_file)
          data = YAML.safe_load_file(session_file, permitted_classes: [Time, Date])
          Models::Session.from_h(data, cache_dir: cache_dir)
        rescue StandardError => e
          warn "Failed to load session from #{session_file}: #{e.message}" if Ace::Coworker.debug?
          nil
        end
      end
    end
  end
end
