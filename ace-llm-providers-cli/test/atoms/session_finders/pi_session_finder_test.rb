# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../lib/ace/llm/providers/cli/atoms/session_finders/pi_session_finder"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module SessionFinders
            class PiSessionFinderTest < Minitest::Test
              PROMPT = "/ace-assign-drive abc123@010.01"

              def test_finds_session_when_prompt_matches
                Dir.mktmpdir do |base|
                  encoded = PiSessionFinder.send(:encode_path, "/home/mc/project")
                  project_dir = File.join(base, encoded)
                  FileUtils.mkdir_p(project_dir)

                  session_file = File.join(project_dir, "session1.jsonl")
                  lines = [
                    {"type" => "session", "id" => "pi-001"}.to_json,
                    {"message" => {"role" => "user", "content" => [{"text" => PROMPT}]}}.to_json,
                    {"message" => {"role" => "assistant", "content" => [{"text" => "ok"}]}}.to_json
                  ]
                  File.write(session_file, lines.join("\n") + "\n")

                  result = PiSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert result
                  assert_equal "pi-001", result[:session_id]
                  assert_equal session_file, result[:session_path]
                end
              end

              def test_handles_string_content_format
                Dir.mktmpdir do |base|
                  project_dir = File.join(base, PiSessionFinder.send(:encode_path, "/home/mc/project"))
                  FileUtils.mkdir_p(project_dir)

                  session_file = File.join(project_dir, "session1.jsonl")
                  lines = [
                    {"type" => "session", "id" => "pi-002"}.to_json,
                    {"message" => {"role" => "user", "content" => PROMPT}}.to_json
                  ]
                  File.write(session_file, lines.join("\n") + "\n")

                  result = PiSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert result
                  assert_equal "pi-002", result[:session_id]
                end
              end

              def test_returns_nil_when_prompt_does_not_match
                Dir.mktmpdir do |base|
                  project_dir = File.join(base, PiSessionFinder.send(:encode_path, "/home/mc/project"))
                  FileUtils.mkdir_p(project_dir)

                  session_file = File.join(project_dir, "session1.jsonl")
                  lines = [
                    {"type" => "session", "id" => "pi-001"}.to_json,
                    {"message" => {"role" => "user", "content" => [{"text" => "wrong"}]}}.to_json
                  ]
                  File.write(session_file, lines.join("\n") + "\n")

                  result = PiSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert_nil result
                end
              end

              def test_returns_nil_when_no_session_files_exist
                Dir.mktmpdir do |base|
                  result = PiSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert_nil result
                end
              end

              def test_handles_malformed_json_gracefully
                Dir.mktmpdir do |base|
                  project_dir = File.join(base, PiSessionFinder.send(:encode_path, "/home/mc/project"))
                  FileUtils.mkdir_p(project_dir)

                  session_file = File.join(project_dir, "session1.jsonl")
                  lines = [
                    "corrupt",
                    {"type" => "session", "id" => "pi-003"}.to_json,
                    {"message" => {"role" => "user", "content" => [{"text" => PROMPT}]}}.to_json
                  ]
                  File.write(session_file, lines.join("\n") + "\n")

                  result = PiSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert result
                  assert_equal "pi-003", result[:session_id]
                end
              end

              def test_encodes_path_correctly
                assert_equal "---home-mc-ace-task.076--",
                  PiSessionFinder.send(:encode_path, "/home/mc/ace-task.076")
              end
            end
          end
        end
      end
    end
  end
end
