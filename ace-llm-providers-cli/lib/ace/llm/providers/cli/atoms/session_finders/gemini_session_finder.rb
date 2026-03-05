# frozen_string_literal: true

require "json"
require "digest"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module SessionFinders
            # Finds a Gemini CLI session by scanning JSON chat files.
            #
            # Gemini stores sessions under ~/.gemini/tmp/<sha256>/chats/*.json
            # Directory name: SHA256 of the absolute working directory path
            # Session ID: `sessionId` field in the JSON file
            # First user message: `messages[0].content[0].text`
            class GeminiSessionFinder
              DEFAULT_BASE = File.expand_path("~/.gemini/tmp").freeze

              # @param working_dir [String] project directory to match
              # @param prompt [String] expected first user message
              # @param base_path [String] override base path for testing
              # @param max_candidates [Integer] max files to scan
              # @return [Hash, nil] { session_id:, session_path: } or nil
              def self.call(working_dir:, prompt:, base_path: DEFAULT_BASE, max_candidates: 5)
                dir_hash = Digest::SHA256.hexdigest(File.expand_path(working_dir))
                chats_dir = File.join(base_path, dir_hash, "chats")
                return nil unless File.directory?(chats_dir)

                candidates = Dir.glob(File.join(chats_dir, "*.json"))
                  .sort_by { |f| -File.mtime(f).to_f }
                  .first(max_candidates)

                candidates.each do |path|
                  result = scan_file(path, prompt)
                  return result if result
                end

                nil
              rescue StandardError
                nil
              end

              def self.scan_file(path, prompt)
                data = JSON.parse(File.read(path))
                session_id = data["sessionId"]

                first_message = data.dig("messages", 0, "content", 0, "text")
                if first_message.is_a?(String) && first_message.strip == prompt.strip
                  return { session_id: session_id, session_path: path }
                end

                nil
              rescue StandardError
                nil
              end

              private_class_method :scan_file
            end
          end
        end
      end
    end
  end
end
