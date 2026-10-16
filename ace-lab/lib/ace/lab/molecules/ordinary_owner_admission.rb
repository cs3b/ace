# frozen_string_literal: true

require "ace/assign/authority/ordinary_peer"
require "ace/assign/molecules/execution_identity_resolver"
require "ace/herdr"
require_relative "ordinary_owner_config"
require_relative "ordinary_native_read"
require_relative "ordinary_worktree_read"

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
        def verify_listener!
          @config.verify_listener!
          OrdinaryNativeRead.new(config: @config, deadline: default_deadline, peer: @peer).preflight!
        end
        def peer(socket, deadline:) = @peer.capture(socket, deadline: deadline)

        def authorize!(request:, peer:, deadline: default_deadline)
          @peer.live!(peer, deadline: deadline)
          unless request.fetch("project_id") == @config.project
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "ordinary request belongs to another project"
          end
          @config.participant!(peer)
          pane = request.fetch("params", {})["pane"]
          # Reads need project visibility only. Every mutating lifecycle route
          # validates a pane; supervisor authority additionally requires actual
          # caller ancestry in one of the root-installed native placements.
          return :worker unless pane
          identity!(peer: peer, pane: pane, deadline: deadline).role == "coordinator" ? :supervisor : :worker
        end

        def identity!(peer:, pane:, deadline: default_deadline)
          observe_identity(peer: peer, pane: pane, deadline: deadline, with_cwd: false).first
        end

        # The caller's claimed head is only a comparison. The accepted start
        # uses the observed worker's checkout and process, never daemon cwd.
        def execution!(peer:, pane:, head:, deadline: default_deadline)
          unless head.is_a?(String) && head.match?(/\A[0-9a-f]{40}\z/)
            raise ArgumentError, "ordinary start HEAD is invalid"
          end
          identity, cwd = observe_identity(peer: peer, pane: pane, deadline: deadline, with_cwd: true)
          checkout = OrdinaryWorktreeRead.new(root: @config.worktrees.fetch("root"),
            common_dir: @config.worktrees.fetch("common_dir"), deadline: deadline).observe(cwd)
          after, after_cwd = observe_identity(peer: peer, pane: pane, deadline: deadline, with_cwd: true)
          unless after == identity && after_cwd == cwd && checkout.fetch("head") == head
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "ordinary worker process, working directory or HEAD changed"
          end
          {identity: identity, checkout: checkout}
        end

        # Read the original canonical native owner for a trusted consumer.
        # The binding must come from accepted history, never requester fields.
        # This observes ownership; it does not grant the target's privileges to
        # the caller or manufacture a kernel-authenticated connection identity.
        def recorded_binding!(binding:, caller_pid: nil, deadline: default_deadline)
          observe_recorded_binding(binding, caller_pid, deadline).first
        end

        def recorded_execution!(binding:, head:, deadline: default_deadline)
          before, cwd = observe_recorded_binding(binding, nil, deadline)
          checkout = OrdinaryWorktreeRead.new(root: @config.worktrees.fetch("root"),
            common_dir: @config.worktrees.fetch("common_dir"), deadline: deadline).observe(cwd)
          after, after_cwd = observe_recorded_binding(binding, nil, deadline)
          unless before == after && cwd == after_cwd && checkout.fetch("head") == head
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "ordinary recorded worker or HEAD changed"
          end
          {runtime_binding: after, checkout: checkout}
        end

        private

        def observe_recorded_binding(binding, caller_pid, deadline)
          @config.verify_selection!
          uid = binding.fetch("process_identity").fetch("uid")
          participant = @config.selected_principal!(uid)
          unless participant && binding["runtime"] == participant.fetch("runtime") && binding["session"] == participant.fetch("workspace")
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "ordinary recorded participant is no longer selected"
          end
          native, runtime = native_runtime(deadline)
          actual = runtime.process_binding(pane: binding.fetch("pane"), caller_pid: caller_pid || binding.fetch("process_identity").fetch("pid"))
          unless actual == binding
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "ordinary recorded native owner is unavailable or changed"
          end
          cwd = native.process_cwd(binding.fetch("process_identity").fetch("pid"))
          @config.selected_principal!(uid)
          [actual, cwd]
        end

        def native_runtime(deadline)
          return [@runtime, @runtime] if @runtime
          observation = Ace::Herdr::Molecules::BoundedObservation.new(deadline: deadline, binary: @config.runtime_binary)
          native = OrdinaryNativeRead.new(config: @config, deadline: deadline, peer: @peer)
          native.preflight!
          [native, Ace::Herdr::Organisms::RuntimeAdapter.new(executor: native, env: {},
            process_identity: Ace::Runtime::Molecules::ProcessIdentity.new(executor: observation))]
        end

        def observe_identity(peer:, pane:, deadline:, with_cwd:)
          @peer.live!(peer, deadline: deadline)
          participant = @config.participant!(peer)
          unless pane.is_a?(String) && pane.bytesize.between?(1, 128) && !pane.include?("\0")
            raise ArgumentError, "ordinary native pane selector is invalid"
          end
          native, runtime = native_runtime(deadline)
          binding = runtime.process_binding(pane: pane, caller_pid: peer.fetch("pid"))
          unless binding && binding["runtime"] == participant.fetch("runtime") &&
              binding["session"] == participant.fetch("workspace") && binding["pane"] == pane &&
              binding.dig("process_identity", "uid") == peer.fetch("uid")
            raise Ace::Assign::AttemptErrors::UnauthorizedIdentity, "ordinary native owner is unavailable or differs"
          end
          @peer.live!(peer, deadline: deadline)
          @config.participant!(peer)
          # Ordinary native agents may share an OS account. Preserve that actor
          # for HITL attribution; privilege follows observed native placement,
          # not a claimed role or an invented per-agent account alias.
          role = participant.fetch("supervisor_panes").include?(binding.fetch("pane")) ? "coordinator" : "worker"
          identity = Ace::Assign::Molecules::ExecutionIdentityResolver::Identity.new(
            actor: participant.fetch("actor"), role: role, runtime: participant.fetch("runtime"),
            adapter: "ordinary", process_pid: binding.fetch("process_identity").fetch("pid"), runtime_binding: binding)
          [identity, with_cwd ? native.process_cwd(identity.process_pid) : nil]
        end

        def default_deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + 30
      end
    end
  end
end
