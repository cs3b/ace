# frozen_string_literal: true
require "digest"
require "json"
require "securerandom"
require "ace/herdr/molecules/protected_native_control"
require_relative "client"
require_relative "launch_control_channel"

module Ace
  module Assign
    module Authority
      class LaunchDriver
        def initialize(mapping_id:, deployment: Deployment.load,
          kernel: Ace::Runtime::Molecules::ProtectedLinux.new, client: nil, native: nil)
          @mapping_id, @deployment, @kernel = mapping_id, deployment, kernel
          @map = deployment.mapping(mapping_id)
          @client = client || Client.new(mapping_id: mapping_id, deployment: deployment, kernel: kernel)
          @native = native
        end

        def preflight
          @deployment.verify!(@mapping_id, kernel: @kernel)
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
          inspected = @client.call("inspect_launch", state.slice("assignment_id", "attempt_id")).data
          state = inspected
          origin = inspected.fetch("native_binding")
          return close_before_native_release(state, mutation_id) unless origin
          fixed = JSON.parse(JSON.generate(@map))
          fixed.fetch("native").merge!(origin.slice("server_identity", "socket_identity", "workspace_id"))
          @native ||= Ace::Herdr::Molecules::ProtectedNativeControl.new(mapping: fixed, kernel: @kernel)
          binding = @native.create(mapping_id: @mapping_id, ticket: state.fetch("launch_ticket"))
          child_handle = @kernel.pin(binding.fetch("process_identity"))
          guarded = @native.guarded_binding!(binding)
          unless guarded.reject { |key, _| key == "guarded_origin" } == binding
            raise AttemptErrors::EvidenceUnavailable, "original native capture changed launch binding"
          end
          recorded = @client.call("record_launch", lifecycle_params(state, binding).merge("guarded_origin" => guarded.fetch("guarded_origin")), mutation_id: "#{mutation_id}-record").data
          bound = @client.call("bind_process", lifecycle_params(recorded, binding), mutation_id: "#{mutation_id}-bind").data
          # Exact original child is reobserved after canonical bind, before release.
          @native.observe(binding.fetch("native_origin").merge("process_binding" => binding))
          @kernel.live!(binding.fetch("process_identity"))
          issued = @client.call("release_launch", lifecycle_params(bound, binding), mutation_id: "#{mutation_id}-release").data
          @issued_state = issued
          @steering_binding = binding.merge("guarded_origin" => recorded.fetch("guarded_origin"))
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

        # The same original launcher remains foreground. A transient channel
        # failure reconnects this process and never repeats native issuance.
        def serve_control!(state:)
          unless state.equal?(@issued_state) && state["phase"] == "issued" && @steering_binding
            raise AttemptErrors::EvidenceUnavailable, "Only the fresh original launcher may retain control"
          end
          @seen_prompt_intents ||= {}
          @prompt_issuance_refs ||= {}
          @reported_prompt_completions ||= {}
          announced = false
          until @control_cancelled
            begin
              break if announced && authenticated_control_release?(state)
              report_retained_prompt_completions!(state)
              report_retained_input_inhibition!(state)
              @client.with_launch_control(state: state) do |socket, codec, ready|
                if @control_original_binding_digest && ready.fetch("original_binding_digest") != @control_original_binding_digest
                  raise AttemptErrors::EvidenceUnavailable, "Original launcher control binding changed"
                end
                @control_original_binding_digest ||= ready.fetch("original_binding_digest")
                unless announced
                  yield({"version" => 1, "type" => "launch_ready", "mapping_id" => @mapping_id,
                    "assignment_id" => state.fetch("assignment_id"), "attempt_id" => state.fetch("attempt_id"),
                    "generation" => ready.fetch("generation"), "journal_commit" => ready.fetch("journal_commit"),
                    "original_binding_digest" => ready.fetch("original_binding_digest")})
                  announced = true
                end
                original_prompt_loop(socket, codec, state, ready)
              end
            rescue Ace::Runtime::RuntimeUnavailableError, AttemptErrors::EvidenceUnavailable, AttemptErrors::UnauthorizedIdentity, IOError, SystemCallError
              # Endpoint refusal also cannot authenticate terminal release.
              # EOF does not prove the actor drained or justify a second send.
              sleep(0.25) unless @control_cancelled
            end
          end
        end

        def request_control_cancel
          @control_cancelled = true
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

        # Status is queried before reopening a private stream: synchronous
        # canonical reads cannot consume the original channel's heartbeat wait.
        def authenticated_control_release?(state)
          params = state.slice("assignment_id", "attempt_id")
          composition = @deployment.authority(@map.fetch("authority_id")).fetch("composition")
          params["result_candidate_generation"] = nil if composition == "services"
          data = @client.call("attempt_status", params, mutation_id: nil, timeout: 30).data
          unless data.is_a?(Hash) && data.values_at("mapping_id", "assignment_id", "attempt_id") ==
              [@mapping_id, state.fetch("assignment_id"), state.fetch("attempt_id")] &&
              data["original_binding_digest"] == @control_original_binding_digest &&
              data["process_binding"] == @steering_binding.reject { |key, _| key == "guarded_origin" } &&
              data["launcher_identity"] == state.fetch("launcher_identity") &&
              data["state"].is_a?(String) && %w[reserved running uncertain succeeded failed stopped].include?(data["state"]) &&
              data["generation"].is_a?(Integer) && data["generation"] >= 0 &&
              data["journal_commit"].is_a?(String) && data["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/)
            raise AttemptErrors::EvidenceUnavailable, "Original launcher canonical status differs"
          end
          terminal = data.fetch("terminal_event_id")
          release = data.fetch("reservation_release_event_id")
          unless [terminal, release].all? { |value| value.nil? || value.is_a?(String) && value.match?(/\A[0-9a-f]{64}\z/) } &&
              (release.nil? || !terminal.nil? && %w[succeeded failed stopped].include?(data.fetch("state")))
            raise AttemptErrors::EvidenceUnavailable, "Original launcher terminal release metadata differs"
          end
          %w[succeeded failed stopped].include?(data.fetch("state")) && !terminal.nil? && !release.nil?
        rescue KeyError, TypeError, NoMethodError
          raise AttemptErrors::EvidenceUnavailable, "Original launcher canonical status is malformed"
        end

        def report_retained_prompt_completions!(state)
          @seen_prompt_intents.each do |id, evidence|
            next if @reported_prompt_completions[id]
            next unless %w[submitted not_issued].include?(evidence["outcome"])
            reference = @prompt_issuance_refs.fetch(id)
            accepted = @client.call("launch_prompt_completion", state.slice("assignment_id", "attempt_id").merge(reference).merge(
              "guarded_evidence" => evidence), mutation_id: nil, timeout: 30).data
            unless accepted.keys.sort == %w[intent_event_id journal_commit outcome] && accepted["intent_event_id"] == id && accepted["outcome"] == evidence.fetch("outcome") &&
                accepted["journal_commit"].is_a?(String) && accepted["journal_commit"].match?(/\A(?:[0-9a-f]{40}|[0-9a-f]{64})\z/)
              raise AttemptErrors::EvidenceUnavailable, "Retained native completion acknowledgement differs"
            end
            @reported_prompt_completions[id] = accepted.fetch("journal_commit")
          end
        end
        def original_prompt_loop(socket, codec, state, ready)
          wire = Ace::Runtime::Molecules::ProtectedSocket
          until @control_cancelled
            deadline = wire.deadline(30)
            frame = wire.read(socket, deadline: deadline, limit: 16_384)
            if frame.is_a?(Hash) && frame.keys.sort == %w[nonce type version] && frame["type"] == "launch_control_idle" &&
                frame["version"].is_a?(Integer) && frame["version"] == 1 && frame["nonce"].is_a?(String) && frame["nonce"].match?(/\A[0-9a-f]{32}\z/)
              wire.write(socket, frame.merge("type" => "launch_control_idle_ack"), deadline: deadline, limit: 16_384)
              next
            end
            if frame.is_a?(Hash) && frame["type"] == "launch_input_inhibit"
              original_input_inhibit!(socket, state, ready, frame, deadline)
              next
            end
            raise AttemptErrors::EvidenceUnavailable, "Original launcher input is inhibited" if @input_inhibited
            LaunchControlChannel.validate_prompt!(frame)
            unless frame["attempt_id"] == state.fetch("attempt_id") && frame["original_binding_digest"] == ready.fetch("original_binding_digest")
              raise AttemptErrors::EvidenceUnavailable, "Private prompt does not join original launcher"
            end
            evidence = codec.receive_launch_prompt(socket, descriptor: frame.fetch("text_descriptor"),
              transfer_id: frame.fetch("transfer_id"), deadline: deadline) do |input|
              expected = @client.call("launch_prompt_intent", state.slice("assignment_id", "attempt_id").merge(
                frame.slice("mutation_id", "intent_event_id", "journal_commit")), mutation_id: nil).data
              binding = expected.fetch("binding")
              Ace::Herdr::Molecules::GuardedNativeOrigin.verify!(expected.fetch("origin"),
                terminal_id: @steering_binding.fetch("terminal_id"), child: @steering_binding.fetch("process_identity"))
              unless expected["intent_event_id"] == frame["intent_event_id"] && expected["origin"] == @steering_binding.fetch("guarded_origin") &&
                  binding.is_a?(Hash) && binding["text_bytes"].is_a?(Integer) &&
                  binding.values_at("mapping_id", "assignment_id", "attempt_id", "mutation_id") ==
                    [@mapping_id, state.fetch("assignment_id"), state.fetch("attempt_id"), frame.fetch("mutation_id")] &&
                  binding["original_binding_digest"] == frame["original_binding_digest"] && binding["text_bytes"] == input.bytes.bytesize &&
                  binding["text_sha256"] == Digest::SHA256.hexdigest(input.bytes)
                raise AttemptErrors::EvidenceUnavailable, "Private prompt immutable intent differs"
              end
              id = frame.fetch("intent_event_id")
              @prompt_issuance_refs[id] = frame.slice("mutation_id", "intent_event_id", "original_binding_digest")
              if @seen_prompt_intents.key?(id)
                @seen_prompt_intents.fetch(id)
              else
                @seen_prompt_intents[id] = {"outcome" => "uncertain", "origin" => @steering_binding.fetch("guarded_origin")}
                @native.prompt_preflight!(@steering_binding)
                @seen_prompt_intents[id] = @native.prompt(binding: @steering_binding, text: input.bytes)
              end
            end
            result = frame.slice("mutation_id", "intent_event_id", "original_binding_digest").merge("version" => 1,
              "type" => "prompt_dispatch_outcome", "guarded_evidence" => evidence)
            wire.write(socket, result, deadline: deadline, limit: 16_384)
            recorded = wire.read(socket, deadline: deadline, limit: 16_384)
            LaunchControlChannel.validate_recorded!(recorded, frame, evidence)
            @reported_prompt_completions[frame.fetch("intent_event_id")] = recorded.fetch("journal_commit") if %w[submitted not_issued].include?(evidence.fetch("outcome"))
          end
        end

        def original_input_inhibit!(socket, state, ready, frame, deadline)
          LaunchControlChannel.validate_inhibit!(frame)
          unless frame["attempt_id"] == state.fetch("attempt_id") && frame["original_binding_digest"] == ready.fetch("original_binding_digest")
            raise AttemptErrors::EvidenceUnavailable, "Input inhibition does not join original launcher"
          end
          selectors = frame.slice("original_binding_digest", "seal_event_id", "journal_commit")
          selected = @client.call("launch_input_inhibit_selection", state.slice("assignment_id", "attempt_id").merge(selectors), mutation_id: nil).data
          unless selected == frame.slice("attempt_id", "original_binding_digest", "seal_event_id", "journal_commit")
            raise AttemptErrors::EvidenceUnavailable, "Input inhibition original seal selection differs"
          end
          @input_inhibited = true
          @input_inhibition_refs = frame.slice("original_binding_digest", "seal_event_id")
          evidence = @retained_input_inhibition || @native.inhibit_input(binding: @steering_binding)
          if evidence.is_a?(Hash) && evidence["outcome"] == "inhibited"
            @retained_input_inhibition = evidence
          end
          wire = Ace::Runtime::Molecules::ProtectedSocket
          result = @input_inhibition_refs.merge("version" => 1, "type" => "launch_input_inhibit_outcome", "guarded_evidence" => evidence)
          wire.write(socket, result, deadline: deadline, limit: 16_384)
          recorded = wire.read(socket, deadline: deadline, limit: 16_384)
          LaunchControlChannel.validate_inhibit_recorded!(recorded, frame)
          unless @retained_input_inhibition
            raise AttemptErrors::EvidenceUnavailable, "Unconfirmed drain cannot receive positive canonical acknowledgement"
          end
          @reported_input_inhibition = recorded.fetch("journal_commit")
        end

        def report_retained_input_inhibition!(state)
          return unless @retained_input_inhibition && !@reported_input_inhibition
          accepted = @client.call("launch_input_inhibit_completion", state.slice("assignment_id", "attempt_id").merge(@input_inhibition_refs).merge(
            "guarded_evidence" => @retained_input_inhibition), mutation_id: nil, timeout: 30).data
          frame = @input_inhibition_refs.merge("version" => 1, "type" => "launch_input_inhibit")
          unless accepted.is_a?(Hash) && accepted.keys.sort == %w[journal_commit original_binding_digest seal_event_id]
            raise AttemptErrors::EvidenceUnavailable, "Retained input inhibition acknowledgement differs"
          end
          LaunchControlChannel.validate_inhibit_recorded!(accepted.merge("version" => 1, "type" => "launch_input_inhibit_recorded"), frame)
          @reported_input_inhibition = accepted.fetch("journal_commit")
        end

        def close_before_native_release(state, mutation_id)
          unless state["scope_binding_event_id"]
            return state.merge("required_action" => "inspect_exact_scope")
          end
          selectors = state.slice("assignment_id", "attempt_id")
          sealed = @client.call("close_execution_scope", selectors.merge("expected_generation" => state.fetch("generation")),
            mutation_id: "#{mutation_id}-scope-seal").data
          closed = @client.call("close_execution_scope", selectors.merge("expected_generation" => sealed.fetch("generation")),
            mutation_id: "#{mutation_id}-scope-proof").data
          unless closed["state"] == "closed_no_writers"
            return state.merge("required_action" => "inspect_exact_scope")
          end
          inspected = @client.call("inspect_launch", selectors).data
          failure = inspected.fetch("scope_failure_evidence")
          raise AttemptErrors::EvidenceUnavailable, "canonical scope failure selectors unavailable" unless failure
          bytes = JSON.generate(failure)
          @client.call("abort_launch", selectors.merge("launch_ticket" => state.fetch("launch_ticket"),
            "expected_generation" => inspected.fetch("generation"), "failure_evidence" => bytes,
            "failure_digest" => Digest::SHA256.hexdigest(bytes)), mutation_id: "#{mutation_id}-scope-abort").data
        end

        def lifecycle_params(state, binding)
          state.slice("assignment_id", "attempt_id", "launch_ticket").merge("process_binding" => binding,
            "expected_generation" => state.fetch("generation"))
        end
      end
    end
  end
end
