# frozen_string_literal: true

require "ace/support/fs"

module Ace
  module Review
    module CLI
      module Commands
        module FeedbackSubcommands
          # Shared session discovery logic for feedback CLI commands
          #
          # This module provides common methods for resolving review sessions
          # from options or finding the latest session in the cache.
          module SessionDiscovery
            # Resolve feedback path from session context
            #
            # Priority:
            # 1. --session flag (explicit session directory)
            # 2. Most recent session in cache directory (default)
            #
            # @param options [Hash] Command options
            # @return [String, nil] Base path for feedback directory
            def resolve_feedback_path(options)
              # Check explicit session flag first
              if options[:session]
                session_path = File.expand_path(options[:session])
                return session_path if Dir.exist?(session_path)

                raise Ace::Support::Cli::Error.new("Session not found: #{session_path}")
              end

              # Default: use most recent session
              find_latest_session
            end

            # Resolve session directory from options
            #
            # @param options [Hash] Command options
            # @return [String, nil] Session directory path
            def resolve_session_dir(options)
              resolve_feedback_path(options)
            end

            # Find the most recent session directory
            #
            # @return [String, nil] Path to latest session or nil
            def find_latest_session
              sessions = find_all_sessions
              sessions.first
            end

            # Find all session directories
            #
            # @return [Array<String>] All session directory paths, sorted by mtime (newest first)
            def find_all_sessions
              root = Ace::Support::Fs::Molecules::ProjectRootFinder.find_or_current
              cache_dir = File.join(root, ".ace-local", "review", "sessions")
              cache_dir = File.join(root, ".cache", "ace-review", "sessions") unless Dir.exist?(cache_dir)
              return [] unless Dir.exist?(cache_dir)

              Dir.glob(File.join(cache_dir, "review-*"))
                .select { |p| File.directory?(p) }
                .sort_by { |p| -File.mtime(p).to_i }
            end
          end
        end
      end
    end
  end
end
