# frozen_string_literal: true
require "ace/herdr/molecules/protected_native_control"
require_relative "execution_scope_observation_fixtures"

module Ace
  module Assign
    module OriginalLaunchDriverOwnerFixture
      class StreamKernel
        def initialize(kernel, me:, peer:)
          @kernel, @me, @peer = kernel, me, peer
        end
        def supported!; true; end
        def capture(pid); pid == Process.pid ? @me : @kernel.capture(pid); end
        def peer(_socket); @peer; end
        def method_missing(name, *args, **options, &block); @kernel.public_send(name, *args, **options, &block); end
        def respond_to_missing?(name, include_private = false); @kernel.respond_to?(name, include_private) || super; end
      end

      class OriginalGuardedNative < Ace::Herdr::Molecules::ProtectedNativeControl
        attr_reader :prompt_calls, :drain_calls
        attr_accessor :before_prompt_ack, :before_drain_ack, :drop_prompt_ack, :unconfirmed_drains
        def exchange(method, params = {}, **limits)
          if method == "terminal.inhibit_input"
            (@drain_calls ||= []) << params
            before_drain_ack&.call
            if (unconfirmed_drains || 0).positive?
              self.unconfirmed_drains -= 1
              return {"id" => "native-fixture", "error" => {"code" => "input_drain_unavailable", "phase" => "unconfirmed"}}
            end
            return {"id" => "native-fixture", "result" => {"type" => "terminal_input_drained", "origin" => params.fetch("expected_origin"),
              "input_state" => "inhibited", "pending_input" => 0}}
          end
          raise "Unexpected native effect" unless method == "agent.prompt"
          (@prompt_calls ||= []) << params
          before_prompt_ack&.call
          raise Ace::Runtime::RuntimeUnavailableError, "controlled native ACK loss" if drop_prompt_ack
          {"id" => "native-fixture", "result" => {"type" => "agent_prompted", "agent" => {"status" => "ready"},
            "origin" => params.fetch("expected_origin"), "submission" => "submitted"}}
        end
        private :exchange

        def request(method, params = {})
          case method
          when "ping" then {"version" => "0.9.3", "protocol" => 22, "capabilities" => {"endpoint_protocol_generation" => 1}}
          when "workspace.get" then {"workspace" => {"workspace_id" => "w1"}}
          when "layout.apply" then {"layout" => {"workspace_id" => "w1", "tab_id" => "w1:t2", "root" => {
            "type" => "pane", "pane_id" => "w1:p2", "command" => params.fetch("root").fetch("command"), "cwd" => @mapping.fetch("worker_cwd")}}}
          when "pane.get" then {"pane" => {"workspace_id" => "w1", "tab_id" => "w1:t2", "pane_id" => "w1:p2", "terminal_id" => "term_ab"}}
          when "pane.process_info" then {"process_info" => {"pane_id" => "w1:p2", "shell_pid" => 91,
            "guarded_prompt" => true, "guarded_input_drain" => true, "guarded_prompt_origin" => {
              "terminal_id" => "term_ab", "runtime_incarnation" => ExecutionScopeObservationFixtures::BOOT, "child" => @kernel.capture(91)}}}
          else raise "Unexpected source native request"
          end
        end
      end

    end
  end
end
