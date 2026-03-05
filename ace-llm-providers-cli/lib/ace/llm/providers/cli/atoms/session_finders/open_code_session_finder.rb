# frozen_string_literal: true

require "json"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module SessionFinders
            # Finds an OpenCode session by scanning its JSON storage.
            #
            # OpenCode stores data under ~/.local/share/opencode/storage/
            # Project mapping: `project/*.json` with `worktree` field matching working_dir
            # Session: `session/<hash>/*.json` with `id` (ses_ prefix)
            # Messages: 3-level chain: `message/<sid>/` -> `part/<mid>/` -> text content
            class OpenCodeSessionFinder
              DEFAULT_BASE = File.expand_path("~/.local/share/opencode/storage").freeze

              # @param working_dir [String] project directory to match
              # @param prompt [String] expected first user message
              # @param base_path [String] override base path for testing
              # @param max_candidates [Integer] max sessions to scan
              # @return [Hash, nil] { session_id:, session_path: } or nil
              def self.call(working_dir:, prompt:, base_path: DEFAULT_BASE, max_candidates: 5)
                # Verify the working_dir is a known OpenCode project (nil-gate).
                # OpenCode sessions don't store a project reference, so we can't filter
                # sessions by project — prompt matching is the primary identification.
                project_id = find_project_id(base_path, working_dir)
                return nil unless project_id

                sessions = find_sessions(base_path, max_candidates)

                sessions.each do |session_path, session_data|
                  session_id = session_data["id"]
                  next unless session_id

                  if first_message_matches?(base_path, session_id, prompt)
                    return { session_id: session_id, session_path: session_path }
                  end
                end

                nil
              rescue StandardError
                nil
              end

              def self.find_project_id(base_path, working_dir)
                project_dir = File.join(base_path, "project")
                return nil unless File.directory?(project_dir)

                expanded = File.expand_path(working_dir)
                Dir.glob(File.join(project_dir, "*.json")).each do |path|
                  data = JSON.parse(File.read(path))
                  return data["id"] if data["worktree"] == expanded
                rescue StandardError
                  next
                end
                nil
              end

              def self.find_sessions(base_path, max_candidates)
                session_base = File.join(base_path, "session")
                return [] unless File.directory?(session_base)

                Dir.glob(File.join(session_base, "**", "*.json"))
                  .sort_by { |f| -File.mtime(f).to_f }
                  .first(max_candidates)
                  .filter_map do |path|
                    data = JSON.parse(File.read(path))
                    [path, data]
                  rescue StandardError
                    nil
                  end
              end

              def self.first_message_matches?(base_path, session_id, prompt)
                message_dir = File.join(base_path, "message", session_id)
                return false unless File.directory?(message_dir)

                # Find the earliest message file
                message_files = Dir.glob(File.join(message_dir, "*.json"))
                  .sort_by { |f| File.mtime(f).to_f }

                message_files.each do |msg_path|
                  msg_data = JSON.parse(File.read(msg_path))
                  next unless msg_data["role"] == "user"

                  message_id = msg_data["id"]
                  next unless message_id

                  # Check parts for text content
                  part_dir = File.join(base_path, "part", message_id)
                  next unless File.directory?(part_dir)

                  Dir.glob(File.join(part_dir, "*.json")).each do |part_path|
                    part_data = JSON.parse(File.read(part_path))
                    text = part_data["text"]
                    return true if text.is_a?(String) && text.strip == prompt.strip
                  end

                  return false
                rescue StandardError
                  next
                end

                false
              rescue StandardError
                false
              end

              private_class_method :find_project_id, :find_sessions, :first_message_matches?
            end
          end
        end
      end
    end
  end
end
