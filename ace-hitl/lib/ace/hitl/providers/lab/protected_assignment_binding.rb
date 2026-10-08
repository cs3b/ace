# frozen_string_literal: true
require "etc"
require_relative "../../lifecycle/binding"

module Ace
  module Hitl
    module Providers
      class Lab
        # The deployed shared service uses the original protected launch owner;
        # standalone ordinary HITL continues to select its explicit coordinator.
        class ProtectedAssignmentBinding < Lifecycle::Binding
          def initialize(authority:, kernel:, journals:)
            @authority, @kernel = authority, kernel
            @journals = journals.dup.freeze
          end

          def validate_request(assignment:, attempt:, project:, requester:, caller_pid: nil)
            peer = actual_peer!(caller_pid)
            unless Etc.getpwuid(peer.fetch("uid")).name == requester
              raise Lifecycle::BindingError, "HITL requester differs from kernel principal"
            end
            selected(assignment, attempt, project, peer.fetch("uid"), peer) { |reverse| reverse }
          end

          def reverse_address(assignment:, attempt:, project:, caller_pid:)
            peer = actual_peer!(caller_pid)
            selected(assignment, attempt, project, peer.fetch("uid"), peer) { |reverse| reverse }
          end

          def with_active(assignment:, attempt:, project:, requester:)
            uid = Etc.getpwnam(requester).uid
            selected(assignment, attempt, project, uid, nil) { yield }
          rescue ArgumentError
            raise Lifecycle::BindingError, "HITL requester is unavailable"
          end

          def proposal_journal(project:)
            @journals.fetch(project)
          rescue KeyError
            raise Lifecycle::BindingError, "HITL project journal is not installed"
          end

          def proposal_projects
            @journals.keys.sort.freeze
          end

          private

          def actual_peer!(pid)
            unless pid.is_a?(Integer) && pid.positive?
              raise Lifecycle::BindingError, "HITL kernel requester is unavailable"
            end
            peer = @kernel.capture(pid)
            @kernel.live!(peer)
            peer
          end

          def selected(assignment, attempt, project, uid, peer, &block)
            proposal_journal(project: project)
            verifying = true
            @authority.with_worker_hitl!(assignment: assignment, attempt: attempt,
              project: project, requester_uid: uid, peer: peer) do |reverse|
              verifying = false
              block.call(reverse)
            end
          rescue Ace::Assign::AttemptErrors::InvalidState, Ace::Assign::AttemptErrors::NotFound => error
            raise verifying ? Lifecycle::EndedAttemptError.new(error.message) : error
          rescue Ace::Assign::Error, Ace::Runtime::RuntimeUnavailableError => error
            raise verifying ? Lifecycle::BindingError.new("protected HITL owner unavailable (#{error.class.name})") : error
          end
        end
      end
    end
  end
end
