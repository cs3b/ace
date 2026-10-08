# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/llm/providers/cli/codex_client"
require "ace/llm/providers/cli/molecules/safe_capture"

module Ace
  module Assign
    class PreparedCliProviderTest < AceAssignTestCase
      def input
        Object.new.tap do |input|
          input.define_singleton_method(:descriptor) do
            {"assignment_id" => "assignment", "scope" => "010", "attempt_id" => "attempt",
              "mapping_id" => "mapping", "project_id" => "project", "task_context_entry" => {"manifest" => {"schema" => "captured"}}}
          end
          input.define_singleton_method(:drive_prompt) { "Drive the exact authenticated captured subtree." }
          input.define_singleton_method(:working_directory) { "/tmp" }
        end
      end

      def with_provider_capture(success: true)
        client = Ace::LLM::Providers::CLI::CodexClient.new(model: "gpt-5.1")
        registry = Ace::LLM::Molecules::ClientRegistry.new
        calls = []
        status = Object.new
        status.define_singleton_method(:success?) { success }
        status.define_singleton_method(:exitstatus) { success ? 0 : 1 }
        status.define_singleton_method(:termsig) { nil }
        capture = lambda do |command, **options|
          calls << [command, options]
          File.write(command[command.index("--output-last-message") + 1], "Executed prepared work.") if success
          Ace::LLM::Providers::CLI::Models::CaptureResult.new(outcome: :completed, status: status,
            stdout: success ? "Executed prepared work." : "", stderr: success ? "" : "provider refused", provider_name: "Codex")
        end
        client.stub(:validate_codex_availability!, nil) do
          client.stub(:resolve_skills_dir, nil) do
            registry.stub(:get_client, client) do
              Ace::LLM::Molecules::ClientRegistry.stub(:new, registry) do
                Ace::LLM::Providers::CLI::Molecules::SafeCapture.stub(:call, capture) { yield calls }
              end
            end
          end
        end
      end

      def launcher
        Molecules::ForkSessionLauncher.new(config: {})
      end

      def test_prepared_codex_reaches_existing_provider_cli_with_captured_scope_and_cwd
        with_provider_capture do |calls|
          result = launcher.launch_provider_session(assignment_id: "assignment", fork_root: "010",
            provider: "codex:gpt-5.1", prepared_input: input)
          assert_equal 1, calls.size
          command, options = calls.first
          assert_equal ["codex", "exec"], command.first(2)
          refute_includes command, "--remote"
          refute_includes command, "resume"
          assert_includes options.fetch(:stdin_data), input.drive_prompt
          assert_equal "/tmp", options.fetch(:chdir)
          assert_equal "assignment@010", options.fetch(:env).fetch("ACE_ASSIGN_DEFAULT_TARGET")
          assert_equal "mapping", options.fetch(:env).fetch("ACE_ASSIGN_LAUNCH_MAPPING")
          assert_equal "attempt", options.fetch(:env).fetch("ACE_ASSIGN_ATTEMPT_ID")
          assert_equal({"schema" => "captured"}, JSON.parse(options.fetch(:env).fetch("ACE_ASSIGN_TASK_CONTEXT_ENTRY")))
          assert_equal "Executed prepared work.", result.fetch(:text)
        end
      end

      def test_provider_failure_has_no_fallback_and_wrong_scope_never_runs
        with_provider_capture(success: false) do |calls|
          assert_raises(Error) do
            launcher.launch_provider_session(assignment_id: "assignment", fork_root: "010",
              provider: "codex:gpt-5.1", prepared_input: input)
          end
          assert_equal 1, calls.size
          assert_raises(Error) do
            launcher.launch_provider_session(assignment_id: "another", fork_root: "010",
              provider: "codex:gpt-5.1", prepared_input: input)
          end
          assert_equal 1, calls.size
        end
      end
    end
  end
end
