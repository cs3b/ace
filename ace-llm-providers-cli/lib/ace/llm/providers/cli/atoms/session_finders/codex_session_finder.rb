# frozen_string_literal: true

require "json"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module SessionFinders
            # Finds a Codex session by scanning JSONL session files.
            #
            # Codex stores sessions under ~/.codex/sessions/YYYY/MM/DD/*.jsonl
            # Session ID: `session_meta.payload.id`
            # First user message: `payload.role:"user"` + `payload.content[0].text`
            class CodexSessionFinder
              DEFAULT_BASE = File.expand_path("~/.codex/sessions").freeze

              # @param working_dir [String] project directory (unused for path encoding, kept for interface)
              # @param prompt [String] expected first user message
              # @param base_path [String] override base path for testing
              # @param max_candidates [Integer] max files to scan
              # @return [Hash, nil] { session_id:, session_path: } or nil
              def self.call(working_dir:, prompt:, base_path: DEFAULT_BASE, max_candidates: 5)
                candidates = recent_session_files(base_path)
                  .first(max_candidates)

                candidates.each do |path|
                  result = scan_file(path, prompt)
                  return result if result
                end

                nil
              rescue StandardError
                nil
              end

              def self.recent_session_files(base_path)
                return [] unless File.directory?(base_path)

                Dir.glob(File.join(base_path, "**", "*.jsonl"))
                  .sort_by { |f| -File.mtime(f).to_f }
              end

              def self.scan_file(path, prompt)
                session_id = nil
                File.foreach(path) do |line|
                  entry = JSON.parse(line)

                  # Extract session ID from session_meta entry
                  if entry.dig("session_meta", "payload", "id")
                    session_id = entry.dig("session_meta", "payload", "id")
                  end

                  # Check for user message match
                  payload = entry["payload"] || entry
                  next unless payload["role"] == "user"

                  content = payload["content"]
                  text = if content.is_a?(Array)
                    content.first&.dig("text")
                  elsif content.is_a?(String)
                    content
                  end

                  if text.is_a?(String) && text.strip == prompt.strip
                    return { session_id: session_id, session_path: path }
                  end
                rescue JSON::ParserError
                  next
                end
                nil
              rescue StandardError
                nil
              end

              private_class_method :recent_session_files, :scan_file
            end
          end
        end
      end
    end
  end
end
