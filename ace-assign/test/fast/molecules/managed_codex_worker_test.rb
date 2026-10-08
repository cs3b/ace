# frozen_string_literal: true
require_relative "../../test_helper"
require "ace/herdr/molecules/codex_runtime_selection"
require "ace/llm/providers/cli/codex_client"

module Ace
  module Assign
    class ManagedCodexWorkerTest < AceAssignTestCase
      def input
        Object.new.tap do |input|
          input.define_singleton_method(:descriptor) do
            {"assignment_id" => "assignment", "scope" => "010", "attempt_id" => "attempt",
              "mapping_id" => "mapping", "project_id" => "project", "task_context_entry" => {"manifest" => {}}}
          end
          input.define_singleton_method(:drive_prompt) { "Drive exact captured subtree." }
          input.define_singleton_method(:working_directory) { "/tmp" }
        end
      end

      def runtime
        Ace::Herdr::Molecules::CodexRuntimeSelection.allocate.tap do |runtime|
          # Controlled retained-proof boundary; no filesystem/kernel/socket probe.
          runtime.define_singleton_method(:verify!) { true }
          runtime.instance_variable_set(:@intent, {"codex" => {"path" => "/accepted/codex", "sha256" => "a" * 64, "bytes" => 123}, "thread_configuration" => {"model" => "gpt-5.1"}})
          runtime.instance_variable_set(:@data, {"project_id" => "project", "native_mapping_id" => "mapping",
            "socket_path" => "/native/control.sock", "thread_id" => "exact-thread"})
        end
      end

      def launch(runtime, terminal)
        query = Object.new
        query.define_singleton_method(:interactive_invocation) do |**options|
          Ace::LLM::QueryInterface.interactive_invocation(**options)
        end
        query.define_singleton_method(:query) { |*| raise "headless must not execute" }
        launcher = Molecules::ForkSessionLauncher.new(config: {}, query_interface: query, terminal_runner: terminal)
        launcher.launch_provider_session(assignment_id: "assignment", fork_root: "010", provider: "codex:gpt-5.1",
          prepared_input: input, codex_runtime: runtime)
      end

      def test_exact_held_selection_reaches_real_provider_command_and_terminal
        commands = []
        result = launch(runtime, ->(invocation) { commands << invocation })
        assert_equal ["/accepted/codex", "resume", "--remote", "unix:///native/control.sock", "exact-thread",
          "User: Drive exact captured subtree."], commands.one? && commands.first.fetch(:command)
        assert_equal "attempt", commands.first.fetch(:env).fetch("ACE_ASSIGN_ATTEMPT_ID")
        assert_equal "exact-thread", result.fetch(:metadata).fetch(:session_id)
        assert result.fetch(:terminal)
        refute result.key?(:text)
      end

      def test_missing_untrusted_wrong_mapping_and_expired_runtime_refuse_before_terminal
        wrong = runtime
        wrong.instance_variable_get(:@data)["native_mapping_id"] = "another"
        expired = runtime
        expired.define_singleton_method(:verify!) { raise Ace::Herdr::ValidationError, "expired" }
        [nil, {"socket_path" => "/evil", "thread_id" => "evil"}, wrong, expired].each do |selection|
          assert_raises(StandardError) { launch(selection, ->(_) { flunk "terminal must not run" }) }
        end
      end

      def test_original_terminal_refuses_missing_tty_and_failed_child_exit
        launcher = Molecules::ForkSessionLauncher.new(config: {})
        invocation = {command: ["/accepted/codex", "resume"], env: {}, working_dir: "/tmp"}
        $stdin.stub(:tty?, false) do
          assert_raises(Error) { launcher.send(:run_original_terminal, invocation) }
        end
        status = Object.new
        status.define_singleton_method(:success?) { false }
        spawn = lambda do |env, *argv, **options|
          assert_equal invocation.fetch(:command), argv
          assert_same $stdin, options.fetch(:in)
          assert_same $stdout, options.fetch(:out)
          123
        end
        $stdin.stub(:tty?, true) do
          $stdout.stub(:tty?, true) do
            Process.stub(:spawn, spawn) do
              Process.stub(:wait2, [123, status]) do
                assert_raises(Error) { launcher.send(:run_original_terminal, invocation) }
              end
            end
          end
        end
      end

      def test_provider_refuses_headless_runtime_and_command_override
        client = Ace::LLM::Providers::CLI::CodexClient.new(model: "gpt-5.1")
        assert_raises(Ace::LLM::ProviderError) { client.generate("prompt", codex_runtime: runtime) }
        assert_raises(Ace::Herdr::ValidationError) do
          Ace::LLM::Providers::CLI::CodexClient.new(model: "another").build_interactive_invocation("prompt", codex_runtime: runtime)
        end
        assert_raises(Ace::LLM::ProviderError) do
          client.build_interactive_invocation("prompt", codex_runtime: runtime, cli_args: ["--last"])
        end
      end
    end
  end
end
