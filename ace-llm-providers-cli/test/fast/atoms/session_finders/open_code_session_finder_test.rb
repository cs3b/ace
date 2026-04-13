# frozen_string_literal: true

require_relative "../../../test_helper"
require_relative "../../../../lib/ace/llm/providers/cli/atoms/session_finders/open_code_session_finder"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module SessionFinders
            class OpenCodeSessionFinderTest < Minitest::Test
              PROMPT = "/ace-assign-drive abc123@010.01"
              WORKING_DIR = "/home/mc/project"

              def test_finds_session_when_prompt_matches
                Dir.mktmpdir do |base|
                  setup_opencode_structure(base,
                    session_id: "ses_001",
                    message_id: "msg_001",
                    prompt_text: PROMPT)

                  result = OpenCodeSessionFinder.call(
                    working_dir: WORKING_DIR,
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert result
                  assert_equal "ses_001", result[:session_id]
                end
              end

              def test_returns_nil_when_prompt_does_not_match
                Dir.mktmpdir do |base|
                  setup_opencode_structure(base,
                    session_id: "ses_001",
                    message_id: "msg_001",
                    prompt_text: "different prompt")

                  result = OpenCodeSessionFinder.call(
                    working_dir: WORKING_DIR,
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert_nil result
                end
              end

              def test_returns_nil_when_no_project_matches
                Dir.mktmpdir do |base|
                  # Create project pointing to different worktree
                  project_dir = File.join(base, "project")
                  FileUtils.mkdir_p(project_dir)
                  File.write(
                    File.join(project_dir, "proj1.json"),
                    {"id" => "proj_001", "worktree" => "/other/path"}.to_json
                  )

                  result = OpenCodeSessionFinder.call(
                    working_dir: WORKING_DIR,
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert_nil result
                end
              end

              def test_returns_nil_when_no_files_exist
                Dir.mktmpdir do |base|
                  result = OpenCodeSessionFinder.call(
                    working_dir: WORKING_DIR,
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert_nil result
                end
              end

              def test_handles_malformed_json_gracefully
                Dir.mktmpdir do |base|
                  project_dir = File.join(base, "project")
                  FileUtils.mkdir_p(project_dir)
                  File.write(File.join(project_dir, "bad.json"), "not json")

                  result = OpenCodeSessionFinder.call(
                    working_dir: WORKING_DIR,
                    prompt: PROMPT,
                    base_path: base
                  )

                  assert_nil result
                end
              end

              private

              def setup_opencode_structure(base, session_id:, message_id:, prompt_text:)
                # Project file
                project_dir = File.join(base, "project")
                FileUtils.mkdir_p(project_dir)
                File.write(
                  File.join(project_dir, "proj1.json"),
                  {"id" => "proj_001", "worktree" => WORKING_DIR}.to_json
                )

                # Session file
                session_dir = File.join(base, "session", "hash1")
                FileUtils.mkdir_p(session_dir)
                File.write(
                  File.join(session_dir, "#{session_id}.json"),
                  {"id" => session_id}.to_json
                )

                # Message file
                message_dir = File.join(base, "message", session_id)
                FileUtils.mkdir_p(message_dir)
                File.write(
                  File.join(message_dir, "#{message_id}.json"),
                  {"id" => message_id, "role" => "user"}.to_json
                )

                # Part file
                part_dir = File.join(base, "part", message_id)
                FileUtils.mkdir_p(part_dir)
                File.write(
                  File.join(part_dir, "part1.json"),
                  {"text" => prompt_text}.to_json
                )
              end
            end
          end
        end
      end
    end
  end
end
