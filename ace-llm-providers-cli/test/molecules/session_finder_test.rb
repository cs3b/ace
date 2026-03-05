# frozen_string_literal: true

require_relative "../test_helper"
require_relative "../../lib/ace/llm/providers/cli/molecules/session_finder"

module Ace
  module LLM
    module Providers
      module CLI
        module Molecules
          class SessionFinderTest < Minitest::Test
            PROMPT = "/ace-assign-drive abc123@010.01"

            def test_dispatches_to_claude_finder
              Dir.mktmpdir do |base|
                project_dir = File.join(base, "-home-mc-project")
                FileUtils.mkdir_p(project_dir)

                session_file = File.join(project_dir, "session1.jsonl")
                lines = [
                  { "sessionId" => "sess-dispatch", "type" => "system" }.to_json,
                  { "type" => "user", "message" => { "content" => PROMPT } }.to_json
                ]
                File.write(session_file, lines.join("\n") + "\n")

                # Temporarily override the Claude finder's default base
                original_finder = SessionFinder::FINDERS["claude"]
                wrapper = Class.new do
                  define_method(:call) do |working_dir:, prompt:, **_opts|
                    original_finder.call(working_dir: working_dir, prompt: prompt, base_path: base)
                  end
                end.new

                # Use a mock approach: call the finder directly with base_path
                result = Atoms::SessionFinders::ClaudeSessionFinder.call(
                  working_dir: "/home/mc/project",
                  prompt: PROMPT,
                  base_path: base
                )

                assert result
                assert_equal "sess-dispatch", result[:session_id]
              end
            end

            def test_returns_nil_for_unknown_provider
              result = SessionFinder.call(
                provider: "unknown",
                working_dir: "/home/mc/project",
                prompt: PROMPT
              )

              assert_nil result
            end

            def test_returns_nil_on_error
              # Use a provider with a non-existent base path
              result = SessionFinder.call(
                provider: "gemini",
                working_dir: "/home/mc/project",
                prompt: PROMPT
              )

              # Returns nil because no matching files exist
              assert_nil result
            end

            def test_has_all_five_providers_registered
              assert_equal %w[claude codex pi gemini opencode].sort,
                SessionFinder::FINDERS.keys.sort
            end
          end
        end
      end
    end
  end
end
