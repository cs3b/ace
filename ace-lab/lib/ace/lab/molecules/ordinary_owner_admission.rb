# frozen_string_literal: true

require "ace/assign/authority/ordinary_peer"
require "ace/assign/molecules/execution_identity_resolver"
require "ace/herdr"
require_relative "ordinary_owner_config"

module Ace
  module Lab
    module Molecules
      # The source-selected ordinary peer policy. Native selectors are hints;
      # only actual ancestry in the installed project's Herdr grants attribution.
      class OrdinaryOwnerAdmission
        def initialize(config:, peer: Ace::Assign::Authority::OrdinaryPeer.new, runtime: nil)
          raise ArgumentError, "ordinary owner requires validated installed selection" unless config.is_a?(OrdinaryOwnerConfig)
          @config, @peer = config, peer
          @runtime = runtime
        end

        def service = @config.service
        def verify_listener! = @config.verify_listener!
        def peer(socket, deadline:) = @peer.capture(socket, deadline: deadline)

        def authorize!(request:, peer:, deadline: default_deadline)
          @peer.live!(peer, deadline: deadline)
          unless request.fetch("project_id") == @config.project
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "ordinary request belongs to another project"
          end
          @config.participant!(peer).fetch("role").to_sym
        end

        def identity!(peer:, pane:, deadline: default_deadline)
          @peer.live!(peer, deadline: deadline)
          participant = @config.participant!(peer)
          unless pane.is_a?(String) && pane.bytesize.between?(1, 128) && !pane.include?("\0")
            raise ArgumentError, "ordinary native pane selector is invalid"
          end
          observation = Ace::Herdr::Molecules::BoundedObservation.new(deadline: deadline, binary: @config.runtime_binary)
          runtime = @runtime || Ace::Herdr::Organisms::RuntimeAdapter.new(executor: observation, env: {},
            process_identity: Ace::Runtime::Molecules::ProcessIdentity.new(executor: observation))
          binding = runtime.process_binding(pane: pane, caller_pid: peer.fetch("pid"))
          unless binding && binding["runtime"] == participant.fetch("runtime") &&
              binding["session"] == participant.fetch("workspace") && binding["pane"] == pane &&
              binding.dig("process_identity", "uid") == peer.fetch("uid")
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "ordinary native owner is unavailable or differs"
          end
          @peer.live!(peer, deadline: deadline)
          @config.participant!(peer)
          # A reviewer still submits evidence as a worker; independent acceptance
          # is a separately authorized lifecycle transition, never this role label.
          role = participant.fetch("role") == "supervisor" ? "coordinator" : "worker"
          Ace::Assign::Molecules::ExecutionIdentityResolver::Identity.new(
            actor: participant.fetch("actor"), role: role, runtime: participant.fetch("runtime"),
            adapter: "ordinary", process_pid: binding.fetch("process_identity").fetch("pid"), runtime_binding: binding)
        end

        private

        def default_deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30
      end
    end
  end
end
