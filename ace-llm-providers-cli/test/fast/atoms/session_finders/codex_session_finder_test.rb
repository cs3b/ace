# frozen_string_literal: true

require_relative "../../../test_helper"
require_relative "../../../../lib/ace/llm/providers/cli/atoms/session_finders/codex_session_finder"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module SessionFinders
            class CodexSessionFinderTest < Minitest::Test
              PROMPT = "/ace-assign-drive abc123@010.01"

              def test_finds_session_when_prompt_matches
                Dir.mktmpdir do |base|
                  date_dir = File.join(base, "2026", "03", "05")
                  FileUtils.mkdir_p(date_dir)

                  session_file = File.join(date_dir, "session1.jsonl")
                  lines = [
                    {"session_meta" => {"payload" => {"id" => "cdx-001"}}}.to_json,
                    {"payload" => {"role" => "user", "content" => [{"text" => PROMPT}]}}.to_json,
                    {"payload" => {"role" => "assistant", "content" => [{"text" => "ok"}]}}.to_json
                  ]
                  File.write(session_file, lines.join("\n") + "\n")

                  result = CodexSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert result
                  assert_equal "cdx-001", result[:session_id]
                  assert_equal session_file, result[:session_path]
                end
              end

              def test_matches_string_content_format
                Dir.mktmpdir do |base|
                  date_dir = File.join(base, "2026", "03", "05")
                  FileUtils.mkdir_p(date_dir)

                  session_file = File.join(date_dir, "session1.jsonl")
                  lines = [
                    {"session_meta" => {"payload" => {"id" => "cdx-002"}}}.to_json,
                    {"payload" => {"role" => "user", "content" => PROMPT}}.to_json
                  ]
                  File.write(session_file, lines.join("\n") + "\n")

                  result = CodexSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert result
                  assert_equal "cdx-002", result[:session_id]
                end
              end

              def test_returns_nil_when_prompt_does_not_match
                Dir.mktmpdir do |base|
                  date_dir = File.join(base, "2026", "03", "05")
                  FileUtils.mkdir_p(date_dir)

                  session_file = File.join(date_dir, "session1.jsonl")
                  lines = [
                    {"session_meta" => {"payload" => {"id" => "cdx-001"}}}.to_json,
                    {"payload" => {"role" => "user", "content" => [{"text" => "wrong"}]}}.to_json
                  ]
                  File.write(session_file, lines.join("\n") + "\n")

                  result = CodexSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert_nil result
                end
              end

              def test_returns_nil_when_no_session_files_exist
                Dir.mktmpdir do |base|
                  result = CodexSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert_nil result
                end
              end

              def test_handles_malformed_json_gracefully
                Dir.mktmpdir do |base|
                  date_dir = File.join(base, "2026", "03", "05")
                  FileUtils.mkdir_p(date_dir)

                  session_file = File.join(date_dir, "session1.jsonl")
                  lines = [
                    "bad json",
                    {"session_meta" => {"payload" => {"id" => "cdx-003"}}}.to_json,
                    {"payload" => {"role" => "user", "content" => [{"text" => PROMPT}]}}.to_json
                  ]
                  File.write(session_file, lines.join("\n") + "\n")

                  result = CodexSessionFinder.call(
                    working_dir: "/home/mc/project",
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert result
                  assert_equal "cdx-003", result[:session_id]
                end
              end
            end
          end
        end
      end
    end
  end
end
