# frozen_string_literal: true

require_relative "../../test_helper"
require_relative "../../../lib/ace/llm/providers/cli/atoms/session_finders/claude_session_finder"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module SessionFinders
            class ClaudeSessionFinderTest < Minitest::Test
              PROMPT = "/ace-assign-drive abc123@010.01"

              def test_finds_session_when_prompt_matches
                Dir.mktmpdir do |base|
                  project_dir = File.join(base, "-home-mc-project")
                  FileUtils.mkdir_p(project_dir)

                  session_file = File.join(project_dir, "session1.jsonl")
                  lines = [
                    { "sessionId" => "sess-001", "type" => "system" }.to_json,
                    { "type" => "user", "message" => { "content" => PROMPT } }.to_json,
                    { "type" => "assistant", "message" => { "content" => "ok" } }.to_json
                  ]
                  File.write(session_file, lines.join("\n") + "\n")

                  result = ClaudeSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert result
                  assert_equal "sess-001", result[:session_id]
                  assert_equal session_file, result[:session_path]
                end
              end

              def test_handles_array_content_format
                Dir.mktmpdir do |base|
                  project_dir = File.join(base, "-home-mc-project")
                  FileUtils.mkdir_p(project_dir)

                  session_file = File.join(project_dir, "session1.jsonl")
                  lines = [
                    { "sessionId" => "sess-002", "type" => "system" }.to_json,
                    { "type" => "user", "message" => { "content" => [{ "text" => PROMPT }] } }.to_json
                  ]
                  File.write(session_file, lines.join("\n") + "\n")

                  result = ClaudeSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert result
                  assert_equal "sess-002", result[:session_id]
                end
              end

              def test_returns_nil_when_prompt_does_not_match
                Dir.mktmpdir do |base|
                  project_dir = File.join(base, "-home-mc-project")
                  FileUtils.mkdir_p(project_dir)

                  session_file = File.join(project_dir, "session1.jsonl")
                  lines = [
                    { "sessionId" => "sess-001", "type" => "system" }.to_json,
                    { "type" => "user", "message" => { "content" => "different prompt" } }.to_json
                  ]
                  File.write(session_file, lines.join("\n") + "\n")

                  result = ClaudeSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert_nil result
                end
              end

              def test_returns_nil_when_no_session_files_exist
                Dir.mktmpdir do |base|
                  result = ClaudeSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert_nil result
                end
              end

              def test_handles_malformed_json_gracefully
                Dir.mktmpdir do |base|
                  project_dir = File.join(base, "-home-mc-project")
                  FileUtils.mkdir_p(project_dir)

                  session_file = File.join(project_dir, "session1.jsonl")
                  lines = [
                    "not valid json",
                    { "sessionId" => "sess-003", "type" => "system" }.to_json,
                    { "type" => "user", "message" => { "content" => PROMPT } }.to_json
                  ]
                  File.write(session_file, lines.join("\n") + "\n")

                  result = ClaudeSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert result
                  assert_equal "sess-003", result[:session_id]
                end
              end

              def test_matches_content_with_user_prefix
                Dir.mktmpdir do |base|
                  project_dir = File.join(base, "-home-mc-project")
                  FileUtils.mkdir_p(project_dir)

                  session_file = File.join(project_dir, "session1.jsonl")
                  lines = [
                    { "sessionId" => "sess-004", "type" => "system" }.to_json,
                    { "type" => "user", "message" => { "content" => "User: #{PROMPT}" } }.to_json
                  ]
                  File.write(session_file, lines.join("\n") + "\n")

                  result = ClaudeSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert result
                  assert_equal "sess-004", result[:session_id]
                end
              end

              def test_encodes_path_correctly
                assert_equal "-home-mc-ace-task-076",
                  ClaudeSessionFinder.send(:encode_path, "/home/mc/ace-task.076")
              end
            end
          end
        end
      end
    end
  end
end
