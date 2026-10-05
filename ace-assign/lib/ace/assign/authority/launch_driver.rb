# frozen_string_literal: true
require "digest"
require "securerandom"
require "ace/herdr/molecules/protected_native_control"
require_relative "client"

module Ace
  module Assign
    module Authority
      class LaunchDriver
        def initialize(mapping_id:, deployment: Deployment.load,
          kernel: Ace::Runtime::Molecules::ProtectedLinux.new, client: nil, native: nil)
          @mapping_id, @deployment, @kernel = mapping_id, deployment, kernel
          @map = deployment.mapping(mapping_id)
          @client = client || Client.new(mapping_id: mapping_id, deployment: deployment, kernel: kernel)
          @native = native || Ace::Herdr::Molecules::ProtectedNativeControl.new(mapping: @map, kernel: kernel)
        end

        def preflight
          @deployment.verify!(@mapping_id, kernel: @kernel)
          @native.preflight!
          @client.call("launch_preflight", {}).data
        end

        def launch(assignment_id:, definition_bytes:, scope:, base_head:, mutation_id: SecureRandom.hex(16))
          preflight
          registration = @client.call("registration_status", {"assignment_id" => assignment_id}).data
          digest = Digest::SHA256.hexdigest(definition_bytes)
          registered = if registration["definition_digest"] == digest
            registration
          else
            @client.call("register_assignment", {"assignment_id" => assignment_id,
              "definition_bytes" => definition_bytes, "definition_digest" => digest,
              "expected_generation" => registration.fetch("generation", 0)}, mutation_id: "#{mutation_id}-register").data
          end
          reserved = @client.call("reserve_attempt", {"assignment_id" => assignment_id, "scope" => scope,
            "worker_uid" => @map.fetch("worker_uid"), "runtime" => "herdr", "base_head" => base_head,
            "launcher_process_binding" => @kernel.capture(Process.pid),
            "expected_generation" => registered.fetch("definition_generation")}, mutation_id: "#{mutation_id}-reserve")
          # Only this actual CAS winner may create. A cached canonical reply is
          # evidence of ownership, never evidence that native creation is fresh.
          return reserved.data.merge("required_action" => "inspect_retained_reservation_no_creation_permission") if reserved.replayed
          state = reserved.data
          binding = @native.create(mapping_id: @mapping_id, ticket: state.fetch("launch_ticket"))
          child_handle = @kernel.pin(binding.fetch("process_identity"))
          recorded = @client.call("record_launch", lifecycle_params(state, binding), mutation_id: "#{mutation_id}-record").data
          bound = @client.call("bind_process", lifecycle_params(recorded, binding), mutation_id: "#{mutation_id}-bind").data
          # Exact original child is reobserved after canonical bind, before release.
          @native.observe(binding.fetch("native_origin").merge("process_binding" => binding))
          @kernel.live!(binding.fetch("process_identity"))
          issued = @client.call("release_launch", lifecycle_params(bound, binding), mutation_id: "#{mutation_id}-release").data
          issued
        rescue StandardError
          # Response loss or partial creation never retries native creation.
          # Canonical state is retained by the authority. Expose its ticket if
          # it was received, but do not fabricate an accepted abort/termination.
          raise if state.nil?
          state.slice("assignment_id", "attempt_id", "launch_ticket", "journal_commit", "generation").merge(
            "phase" => "uncertain", "required_action" => "inspect_exact_native_child_and_canonical_release_state")
        ensure
          child_handle&.close
        end

        def terminate(state:, binding:, evidence:, mutation_id: SecureRandom.hex(16))
          observed = state["termination_observation"]
          unless observed.is_a?(Hash) && observed["status"] == "exited" && observed["process_identity"] == binding["process_identity"]
            handle = @kernel.pin(binding.fetch("process_identity"))
            exited = @native.terminate(binding, handle: handle)
            raise AttemptErrors::EvidenceUnavailable, "native close did not prove exact child exit" unless exited
          end
          @client.call("abort_launch", {"assignment_id" => state.fetch("assignment_id"), "attempt_id" => state.fetch("attempt_id"),
            "launch_ticket" => state.fetch("launch_ticket"), "expected_generation" => state.fetch("generation"),
            "failure_evidence" => evidence, "failure_digest" => Digest::SHA256.hexdigest(evidence)}, mutation_id: mutation_id).data
        ensure
          handle&.close
        end

        private
        def lifecycle_params(state, binding)
          state.slice("assignment_id", "attempt_id", "launch_ticket").merge("process_binding" => binding,
            "expected_generation" => state.fetch("generation"))
        end
      end
    end
  end
end
