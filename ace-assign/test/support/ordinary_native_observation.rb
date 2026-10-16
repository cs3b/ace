# frozen_string_literal: true

require "ace/assign/authority/ordinary_peer"
require "ace/assign/molecules/execution_identity_resolver"

module Ace
  module Assign
      # Actual Unix/Git/transfer/receipts; only installed native observation is
      # controlled. Two real OS generations are not an installed agent proof.
      class OrdinaryNativeObservation
        attr_reader :service
        attr_accessor :selected, :bindings, :head, :revoked
        def initialize(service)
          @service, @selected, @bindings = service, "supervisor", {}
          @peer = Authority::OrdinaryPeer.new
        end
        def verify_listener! = true
        def peer(socket, deadline:) = @peer.capture(socket, deadline: deadline)
        def authorize!(request:, peer:, deadline:)
          @peer.live!(peer, deadline: deadline)
          raise AttemptErrors::UnauthorizedIdentity if @revoked || request["project_id"] != "atlas"
          @selected == "supervisor" ? :supervisor : :worker
        end
        def identity!(peer:, pane:, deadline:)
          authorize!(request: {"project_id" => "atlas"}, peer: peer, deadline: deadline)
          binding = @bindings.fetch(@selected)
          raise AttemptErrors::UnauthorizedIdentity unless pane == binding.fetch("pane")
          Molecules::ExecutionIdentityResolver::Identity.new(actor: Etc.getpwuid(peer.fetch("uid")).name,
            role: @selected == "supervisor" ? "coordinator" : "worker", runtime: "herdr", adapter: "ordinary",
            process_pid: binding.dig("process_identity", "pid"), runtime_binding: binding)
        end
        def execution!(peer:, pane:, head:, deadline:)
          identity = identity!(peer: peer, pane: pane, deadline: deadline)
          raise AttemptErrors::UnauthorizedIdentity unless head == @head
          {identity: identity, checkout: {"cwd" => "/observed/#{@selected}", "head" => head}}
        end
        def recorded_binding!(binding:, deadline:)
          raise AttemptErrors::UnauthorizedIdentity unless !@revoked && @bindings.values.include?(binding)
          binding
        end
        def recorded_execution!(binding:, head:, deadline:)
          raise AttemptErrors::UnauthorizedIdentity unless !@revoked && @bindings.values.include?(binding) && head == @head
          {runtime_binding: binding, checkout: {"cwd" => "/observed/reviewer", "head" => head}}
        end
      end

  end
end
