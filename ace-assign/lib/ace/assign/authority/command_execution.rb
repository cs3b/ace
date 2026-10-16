# frozen_string_literal: true

require "json"
require "digest"
require_relative "../molecules/evidence_journal"

module Ace
  module Assign
    module Authority
      # Project commands share the installed journal, without manufacturing a
      # managed task or projecting command exit as completed product delivery.
      class CommandExecution
        OPERATIONS = %w[command_admit command_status command_claim command_bind command_complete].freeze
        ID = /\A[a-zA-Z0-9][a-zA-Z0-9_.-]{0,63}\z/
        SHA = /\A[0-9a-f]{64}\z/

        def initialize(project:, journal:, admission:)
          @project, @journal, @admission = project, journal, admission
        end

        attr_reader :journal

        def dispatch(request:, peer:, role:, deadline:)
          operation = request.fetch("operation")
          params = request.fetch("params")
          raise ArgumentError, "invalid command project" unless request.fetch("project_id") == @project
          id = params.fetch("execution_id")
          raise ArgumentError, "invalid command reference" unless id.is_a?(String) && ID.match?(id)
          if operation == "command_status"
            strict!(params, %w[execution_id])
            raise ArgumentError, "status mutation must be null" unless request.fetch("mutation_id").nil?
            commit = @journal.ref_value
            data = projection(id, commit)
            @admission.command_reader!(peer: peer, definition: data.fetch("definition"), deadline: deadline)
            return {data: data.merge("journal_commit" => commit), replayed: false}
          end
          strict!(params, case operation
          when "command_admit" then %w[execution_id selection]
          when "command_claim" then %w[execution_id caller]
          when "command_bind" then %w[execution_id child]
          when "command_complete" then %w[execution_id result]
          else raise ArgumentError, "unknown command operation"
          end)
          authenticated_peer = peer
          launcher = nil
          plan = if operation == "command_admit"
            @admission.command_request!(selection: params.fetch("selection"), peer: peer, deadline: deadline)
          else
            launcher = @admission.command_launcher!(peer: authenticated_peer, deadline: deadline)
            nil
          end
          authenticate = lambda do
            if operation == "command_admit"
              unless @admission.command_request!(selection: params.fetch("selection"), peer: peer, deadline: deadline) == plan
                raise AttemptErrors::UnauthorizedIdentity, "command admission changed"
              end
            else
              unless @admission.command_launcher!(peer: authenticated_peer, deadline: deadline) == launcher
                raise AttemptErrors::UnauthorizedIdentity, "installed command launcher changed"
              end
            end
          end
          peer = launcher if launcher
          expected = {"command_admit" => 0, "command_claim" => 1, "command_bind" => 2, "command_complete" => 3}.fetch(operation)
          digest = Atoms::EvidenceDigest.digest({"project" => @project, "params" => params, "peer" => peer, "plan" => plan})
          @journal.mutate(assignment_id: namespace(id), attempt_id: namespace(id),
            mutation_id: request.fetch("mutation_id"), operation: operation, parameters_digest: digest,
            expected_generation: expected, with_replay: true, deadline: deadline,
            replay_authorizer: authenticate) do |_events, commit, _generation|
            authenticate.call
            prior = projection(id, commit, missing: true)
            data = transition(operation, id, params, plan, prior, peer, deadline)
            {events: [], data: data}
          end
        end

        # Read only the accepted launcher-owned four-stage execution at the
        # caller's held CAS prefix. Arbitrary allowed commands are not tests.
        def test_evidence_at!(execution_id:, commit:, head:, tree:, deadline:)
          unless execution_id.is_a?(String) && ID.match?(execution_id) && commit && @journal.ref_value == commit
            raise AttemptErrors::EvidenceUnavailable, "test execution prefix or selector differs"
          end
          data = projection(execution_id, commit)
          definition = data.fetch("definition")
          events = @journal.read_events(namespace(execution_id), commit: commit)
          accepted = events.select { |event| event["type"] == "authority_mutation" }
          stages = accepted.map { |event| event.fetch("payload").fetch("data") }
          unless accepted.size == 4 && data["phase"] == "exited" && data["result"] == {"exit_status" => 0, "signal" => nil} &&
              definition["purpose"] == "test" && definition["source"] == {"head" => head, "tree" => tree} &&
              [head, tree].all? { |value| value.is_a?(String) && value.match?(/\A[0-9a-f]{40}\z/) } &&
              stages.all? { |stage| stage.fetch("definition") == definition } &&
              stages.map { |stage| stage.fetch("phase") } == %w[admitted claimed running exited] &&
              stages.drop(1).all? { |stage| stage.fetch("launcher") == data.fetch("launcher") } &&
              stages[2].fetch("child") == data.fetch("child") && data.dig("launcher", "uid") == 0 &&
              data.dig("child", "witnessed_by") == data.fetch("launcher") &&
              data.dig("child", "kernel_identity") == data.dig("child", "root_witness")&.slice("pid", "uid", "started_at", "host") &&
              data.dig("child", "root_witness", "cwd") == definition.dig("executor", "cwd") &&
              data.dig("child", "kernel_identity", "uid") == definition.dig("executor", "uid")
            raise AttemptErrors::ReceiptRejected, "candidate requires an exact successful executed test command"
          end
          @admission.command_test_evidence!(definition: definition, deadline: deadline)
          command = JSON.generate(definition.fetch("argv"))
          raise AttemptErrors::ReceiptRejected, "executed test command reference is oversized" if command.bytesize > 2048
          {"schema" => "ace.test.execution-reference/v1", "reference" => execution_id,
            "candidate_head" => head, "command" => command, "result" => "passed",
            "recorded_at" => accepted.last.fetch("recorded_at"), "receipt_sha256" => Atoms::EvidenceDigest.digest(data)}
        rescue KeyError, TypeError
          raise AttemptErrors::EvidenceUnavailable, "canonical test execution is incomplete"
        end

        private

        def transition(operation, id, params, plan, prior, peer, deadline)
          base = {"schema" => "project-command/v1", "execution_id" => id, "project_id" => @project}
          case operation
          when "command_admit"
            raise AttemptErrors::Conflict, "command already admitted" if prior
            # Plan contains references and nonsecret context; its closed schema
            # is owned by the installed Lab admission, never requester input.
            base.merge("phase" => "admitted", "definition" => plan)
          when "command_claim"
            phase!(prior, "admitted")
            @admission.command_claim!(definition: prior.fetch("definition"), caller: params.fetch("caller"),
              launcher: peer, deadline: deadline)
            prior.merge("phase" => "claimed", "launcher" => peer)
          when "command_bind"
            phase!(prior, "claimed")
            launcher!(prior, peer)
            child = @admission.command_child!(definition: prior.fetch("definition"), child: params.fetch("child"),
              launcher: peer, deadline: deadline)
            prior.merge("phase" => "running", "child" => child)
          when "command_complete"
            phase!(prior, "running")
            launcher!(prior, peer)
            result = params.fetch("result")
            strict!(result, %w[exit_status signal])
            exit_status, signal = result.values_at("exit_status", "signal")
            unless (exit_status.is_a?(Integer) && exit_status.between?(0, 255) && signal.nil?) ||
                (exit_status.nil? && signal.is_a?(Integer) && signal.between?(1, 127))
              raise ArgumentError, "invalid command termination"
            end
            prior.merge("phase" => "exited", "result" => result)
          end
        end

        def projection(id, commit, missing: false)
          events = @journal.read_events(namespace(id), commit: commit)
          unless Models::EvidenceEvent.chain_valid?(events)
            raise AttemptErrors::EvidenceUnavailable, "command history is corrupt"
          end
          accepted = events.select { |event| event["type"] == "authority_mutation" }
          if accepted.empty?
            return nil if missing
            raise AttemptErrors::NotFound, "command reference is unknown"
          end
          operations = accepted.map { |event| event.dig("payload", "operation") }
          unless operations == OPERATIONS.reject { |name| name == "command_status" }.take(operations.size) && operations.size <= 4
            raise AttemptErrors::EvidenceUnavailable, "command lifecycle is corrupt"
          end
          data = accepted.last.fetch("payload").fetch("data")
          unless data.values_at("schema", "project_id", "execution_id") == ["project-command/v1", @project, id]
            raise AttemptErrors::EvidenceUnavailable, "command association differs"
          end
          data
        end

        def namespace(id) = "command-#{id}"
        def strict!(value, keys)
          raise ArgumentError, "invalid command fields" unless value.is_a?(Hash) && value.keys.sort == keys.sort
        end
        def phase!(prior, phase)
          raise AttemptErrors::Conflict, "command phase differs; inspect original execution" unless prior && prior["phase"] == phase
        end
        def launcher!(prior, peer)
          raise AttemptErrors::UnauthorizedIdentity, "command launcher changed" unless prior.fetch("launcher") == peer
        end
      end
    end
  end
end
