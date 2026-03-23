# frozen_string_literal: true

require "json"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module SessionFinders
            # Finds a Claude Code session by scanning JSONL session files.
            #
            # Claude stores sessions under ~/.claude/projects/<encoded-path>/*.jsonl
            # Path encoding: replace `/` and `.` with `-`
            # Session ID: `sessionId` field on conversation entries
            # First user message: `type:"user"` with `message.content` string
            class ClaudeSessionFinder
              DEFAULT_BASE = File.expand_path("~/.claude/projects").freeze

              # @param working_dir [String] project directory to match
              # @param prompt [String] expected first user message
              # @param base_path [String] override base path for testing
              # @param max_candidates [Integer] max files to scan
              # @return [Hash, nil] { session_id:, session_path: } or nil
              def self.call(working_dir:, prompt:, base_path: DEFAULT_BASE, max_candidates: 5)
                encoded = encode_path(working_dir)
                project_dir = File.join(base_path, encoded)
                return nil unless File.directory?(project_dir)

                candidates = Dir.glob(File.join(project_dir, "*.jsonl"))
                  .sort_by { |f| -File.mtime(f).to_f }
                  .first(max_candidates)

                candidates.each do |path|
                  result = scan_file(path, prompt)
                  return result if result
                end

                nil
              rescue
                nil
              end

              def self.encode_path(path)
                path.gsub(%r{[/.]}, "-")
              end

              def self.scan_file(path, prompt)
                session_id = nil
                File.foreach(path) do |line|
                  entry = JSON.parse(line)
                  session_id ||= entry["sessionId"]

                  next unless entry["type"] == "user"

                  content = entry.dig("message", "content")
                  content = content.first["text"] if content.is_a?(Array)

                  # Substring match: Claude wraps user input with prefixes (e.g. "User: "),
                  # so exact equality would miss valid sessions.
                  if content.is_a?(String) && content.include?(prompt.strip)
                    return {session_id: session_id, session_path: path}
                  end
                rescue JSON::ParserError
                  next
                end
                nil
              rescue
                nil
              end

              private_class_method :encode_path, :scan_file
            end
          end
        end
      end
    end
  end
end
