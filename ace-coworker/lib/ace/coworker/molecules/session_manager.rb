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
          # Ensure cache base directory exists before generate_session_id
          FileUtils.mkdir_p(@cache_base)

          session_id = generate_session_id
          cache_dir = File.join(@cache_base, session_id)

          # Create directories
          FileUtils.mkdir_p(cache_dir)
          FileUtils.mkdir_p(File.join(cache_dir, "jobs"))
          FileUtils.mkdir_p(File.join(cache_dir, "reports"))

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

          # Update .latest symlink for O(1) active session lookup
          update_latest_symlink(session_id)

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

          # Fast path: use .latest symlink if it exists
          latest_symlink = File.join(@cache_base, ".latest")
          if File.symlink?(latest_symlink)
            session_id = File.basename(File.readlink(latest_symlink))
            session = load(session_id)
            return session if session
          end

          # Fallback: find all session directories
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

          # Update .latest symlink since this session was just updated
          update_latest_symlink(session.id)

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
          max_attempts = 100

          # Handle collision by appending suffix
          suffix = 0
          max_attempts.times do
            dir_path = File.join(@cache_base, candidate)
            # Atomic directory creation using Dir.mkdir - fails if exists
            begin
              Dir.mkdir(dir_path)
              return candidate
            rescue Errno::EEXIST
              # Directory already exists, try next candidate
              suffix += 1
              candidate = "#{base_id}#{suffix.to_s(36)}"
            end
          end

          # Max attempts exceeded - this should never happen in practice
          raise Error, "Failed to generate unique session ID after #{max_attempts} attempts. Cache directory may be corrupted."
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

        # Update .latest symlink to point to the specified session
        # Provides O(1) active session lookup
        #
        # @param session_id [String] Session ID to link as .latest
        def update_latest_symlink(session_id)
          latest_symlink = File.join(@cache_base, ".latest")
          target_dir = File.join(@cache_base, session_id)

          # Remove old symlink if it exists
          File.delete(latest_symlink) if File.symlink?(latest_symlink)

          # Create new symlink
          File.symlink(target_dir, latest_symlink)
        rescue StandardError => e
          warn "Failed to update .latest symlink: #{e.message}" if Ace::Coworker.debug?
          # Non-fatal: continue without symlink
        end
      end
    end
  end
end
