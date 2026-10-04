# frozen_string_literal: true

require "securerandom"
require_relative "errors"
require_relative "lab/daemon_binding"
require_relative "lab/assignment_binding"
require_relative "lab/composite_binding"
require_relative "../lifecycle/store"
require_relative "../lifecycle/policy"
require_relative "../lifecycle/client"
require_relative "../organisms/hitl_manager"

module Ace
  module Hitl
    module Providers
      # provider=lab adapter (spec 8wm.t.vrz §1; lifecycle migration
      # spec 8wm.t.y21 §1; scoped boundary 8wq.t.34i): ONE ask operation
      # = local HITL event + relay request created through the scoped
      # store boundary with the lab-backed binding policy. Owns every
      # lab-specific seam; agent-facing ace-hitl paths must never bypass
      # it (guard-tested).
      class Lab
        DEFAULT_PROJECT = "ace"
        DEFAULT_HARNESS = "lab-admin"
        DEFAULT_PLAN = "ace-hitl ask"
        DEFAULT_STORE_ROOT = "/run/lab/hitl"
        STORE_ROOT_ENV = "ACE_HITL_STORE_ROOT"
        DEFAULT_SOCKET_PATH = "/run/lab/hitl.sock"
        SOCKET_PATH_ENV = "ACE_HITL_SOCKET"
        # The trusted deployment grants document, shared with ace-lab's
        # GrantResolver (same format, same trust rules). The PATH may be
        # overridden for tests; the document's trust is verified
        # absolutely (root-owned, protected traversal), so an override
        # cannot inject authority.
        DEFAULT_GRANTS_PATH = "/etc/lab/ace-lab/authorization.yml"
        GRANTS_PATH_ENV = "ACE_HITL_GRANTS_PATH"

        PROVIDER_NAME = "lab"

        def initialize(manager: nil, store: nil, binding: nil)
          @manager = manager
          @store = store
          @binding = binding
        end

        # The lifecycle store configured for the lab deployment: native
        # generic core + labd-backed binding policy (spec 8wm.t.y21 §1).
        # The operator/broker CLI surface builds its store here, inside
        # the provider seam.
        def self.lifecycle_store(store: nil, binding: nil)
          return store if store

          Lifecycle::Store.new(
            root: ENV.fetch(STORE_ROOT_ENV, DEFAULT_STORE_ROOT),
            binding: binding || DaemonBinding.new
          )
        end

        # The managed binding authority (spec 8wq.t.34i): assignment
        # attempts verified through the ace-assign coordinator.
        def self.assignment_binding(repo_root: nil)
          AssignmentBinding.new(repo_root: repo_root)
        end

        # The transport/service authorization policy from the trusted
        # grants document (ace-lab supplies the deployment facts).
        def self.grants_policy(grants_path: nil, document: nil)
          Lifecycle::GrantsPolicy.new(
            grants_path: grants_path || ENV[GRANTS_PATH_ENV] || DEFAULT_GRANTS_PATH,
            document: document
          )
        end

        # The authenticated boundary client for CLI operations. The
        # service identity comes ONLY from the trusted grants document;
        # without it the boundary is unconfigured and every lifecycle
        # operation fails closed with a visible transport error.
        def self.boundary_client(socket_path: nil, policy: nil)
          policy ||= grants_policy
          service_uid = policy.service_uid
          unless service_uid
            raise ProviderUnavailableError,
              "the HITL service is not configured: #{ENV[GRANTS_PATH_ENV] || DEFAULT_GRANTS_PATH} " \
              "must define hitl.service_uid"
          end

          Lifecycle::Client.new(
            socket_path: socket_path || ENV[SOCKET_PATH_ENV] || DEFAULT_SOCKET_PATH,
            service_uid: service_uid
          )
        end

        # Local event + relay request in ONE operation. The ref is
        # REQUIRED and must be validated by the caller before this call.
        def ask(question:, ref:, attempt:, work: nil, assignment: nil, title: nil,
          kind: "text", otp: nil, project: DEFAULT_PROJECT, harness: DEFAULT_HARNESS,
          plan: DEFAULT_PLAN, effect: {})
          effect = effect.to_h
          request_id = "hitl-#{SecureRandom.hex(8)}"
          manager = build_manager
          event = manager.create(title || question, questions: [question])

          # The ask reaches the store through the AUTHENTICATED BOUNDARY
          # (spec 8wq.t.34i): requesters never write shared store files.
          # An injected store stays available for unit-level wiring.
          begin
            boundary.create(
              id: request_id,
              work: work,
              assignment: assignment,
              attempt: attempt,
              kind: kind,
              otp: otp,
              project: project,
              harness: harness,
              plan: plan,
              question: question,
              ace_hitl_id: event.id,
              effect: effect_declared?(effect) ? effect : nil
            )
          rescue Lifecycle::Error => e
            raise ProviderUnavailableError,
              "#{e.message}; local HITL event #{event.id} was created but never bound to a " \
              "Lab request (orphan) - inspect it with ace-hitl show #{event.id} and delete " \
              "or re-ask as needed"
          end

          manager.update(event.id, set: {
            "provider" => PROVIDER_NAME,
            "ref_schema" => ref.to_h[:schema],
            "ref_session" => ref.session,
            "ref_pane" => ref.pane,
            "lab_request_id" => request_id,
            "lab_request_state" => "created",
            "lab_request_effect" => effect_declared?(effect) ? "declared" : "none"
          })

          AskResult.new(event_id: event.id, request_id: request_id)
        end

        # Contract defined in spec §1.2; the herdr push delivery itself
        # lands with ace-herdr (8wm.t.vs0) + the provider=lab integration
        # (8wm.t.vs2). Operator-side answering of a relay request is the
        # lifecycle deliver path (`ace-hitl deliver`), not this method.
        def deliver(ref, _answer)
          raise UnsupportedOperationError,
            "provider 'lab' does not deliver yet: push delivery lands with ace-herdr " \
            "(8wm.t.vs0) and the provider=lab integration (8wm.t.vs2); the relay answer " \
            "is consumed lab-side for now"
        end

        # Optional operation (spec §1.3): the ace-hitl wait command is the
        # pane-less script path and does not poll through the adapter.
        def wait(*)
          raise UnsupportedOperationError,
            "provider 'lab' does not poll through the adapter; use the ace-hitl wait command"
        end

        private

        def effect_declared?(effect)
          !!(effect[:match] || effect[:effect_cwd] || effect[:effect_timeout] ||
            Array(effect[:effect_args]).any?)
        end

        def boundary
          @store || self.class.boundary_client
        end

        def build_manager
          @manager || Organisms::HitlManager.new
        end
      end
    end
  end
end
