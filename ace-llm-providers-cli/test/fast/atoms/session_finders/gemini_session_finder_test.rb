# frozen_string_literal: true

require_relative "../../../test_helper"
require_relative "../../../../lib/ace/llm/providers/cli/atoms/session_finders/gemini_session_finder"
require "digest"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module SessionFinders
            class GeminiSessionFinderTest < Minitest::Test
              PROMPT = "/ace-assign-drive abc123@010.01"
              WORKING_DIR = "/home/mc/project"

              def test_finds_session_when_prompt_matches
                Dir.mktmpdir do |base|
                  dir_hash = Digest::SHA256.hexdigest(WORKING_DIR)
                  chats_dir = File.join(base, dir_hash, "chats")
                  FileUtils.mkdir_p(chats_dir)

                  chat_file = File.join(chats_dir, "chat1.json")
                  data = {
                    "sessionId" => "gem-001",
                    "messages" => [
                      {"content" => [{"text" => PROMPT}]},
                      {"content" => [{"text" => "ok"}]}
                    ]
                  }
                  File.write(chat_file, data.to_json)

                  result = GeminiSessionFinder.call(
                    working_dir: WORKING_DIR,
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert result
                  assert_equal "gem-001", result[:session_id]
                  assert_equal chat_file, result[:session_path]
                end
              end

              def test_returns_nil_when_prompt_does_not_match
                Dir.mktmpdir do |base|
                  dir_hash = Digest::SHA256.hexdigest(WORKING_DIR)
                  chats_dir = File.join(base, dir_hash, "chats")
                  FileUtils.mkdir_p(chats_dir)

                  chat_file = File.join(chats_dir, "chat1.json")
                  data = {
                    "sessionId" => "gem-001",
                    "messages" => [
                      {"content" => [{"text" => "different"}]}
                    ]
                  }
                  File.write(chat_file, data.to_json)

                  result = GeminiSessionFinder.call(
                    working_dir: WORKING_DIR,
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert_nil result
                end
              end

              def test_returns_nil_when_no_session_files_exist
                Dir.mktmpdir do |base|
                  result = GeminiSessionFinder.call(
                    working_dir: WORKING_DIR,
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert_nil result
                end
              end

              def test_handles_malformed_json_gracefully
                Dir.mktmpdir do |base|
                  dir_hash = Digest::SHA256.hexdigest(WORKING_DIR)
                  chats_dir = File.join(base, dir_hash, "chats")
                  FileUtils.mkdir_p(chats_dir)

                  bad_file = File.join(chats_dir, "bad.json")
                  File.write(bad_file, "not json")

                  result = GeminiSessionFinder.call(
                    working_dir: WORKING_DIR,
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert_nil result
                end
              end

              def test_uses_sha256_of_working_dir
                dir_hash = Digest::SHA256.hexdigest("/home/mc/ace-task.076")
                assert_equal 64, dir_hash.length
              end
            end
          end
        end
      end
    end
  end
end
