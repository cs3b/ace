# frozen_string_literal: true

require "json"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module SessionFinders
            # Finds a Pi agent session by scanning JSONL session files.
            #
            # Pi stores sessions under ~/.pi/agent/sessions/<encoded-path>/*.jsonl
            # Path encoding: replace `/` with `-`, wrap in `--`
            # Session ID: `type:"session"` entry → `id` field
            # First user message: `message.role:"user"` + `message.content[0].text`
            class PiSessionFinder
              DEFAULT_BASE = File.expand_path("~/.pi/agent/sessions").freeze

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
                "--#{path.tr("/", "-")}--"
              end

              def self.scan_file(path, prompt)
                session_id = nil
                File.foreach(path) do |line|
                  entry = JSON.parse(line)

                  # Extract session ID from session-type entry
                  if entry["type"] == "session" && entry["id"]
                    session_id = entry["id"]
                  end

                  # Check for user message match
                  message = entry["message"]
                  next unless message.is_a?(Hash) && message["role"] == "user"

                  content = message["content"]
                  text = if content.is_a?(Array)
                    content.first&.dig("text")
                  elsif content.is_a?(String)
                    content
                  end

                  if text.is_a?(String) && text.strip == prompt.strip
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
