# frozen_string_literal: true

require "securerandom"
require_relative "errors"
require_relative "lab/daemon_binding"
require_relative "../lifecycle/store"
require_relative "../organisms/hitl_manager"

module Ace
  module Hitl
    module Providers
      # provider=lab adapter (spec 8wm.t.vrz §1; lifecycle migration
      # spec 8wm.t.y21 §1): ONE ask operation = local HITL event + relay
      # request created through the NATIVE generic lifecycle store with
      # the labd-backed binding policy. Owns every lab-specific seam;
      # agent-facing ace-hitl paths must never bypass it (guard-tested).
      class Lab
        DEFAULT_PROJECT = "ace"
        DEFAULT_HARNESS = "lab-admin"
        DEFAULT_PLAN = "ace-hitl ask"
        DEFAULT_STORE_ROOT = "/run/lab/hitl"
        STORE_ROOT_ENV = "ACE_HITL_STORE_ROOT"

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

        # Local event + relay request in ONE operation. The ref is
        # REQUIRED and must be validated by the caller before this call.
        def ask(question:, ref:, work:, attempt:, title: nil,
          project: DEFAULT_PROJECT, harness: DEFAULT_HARNESS,
          plan: DEFAULT_PLAN, effect: {})
          effect = effect.to_h
          request_id = "hitl-#{SecureRandom.hex(8)}"
          manager = build_manager
          event = manager.create(title || question, questions: [question])

          begin
            build_store.create(
              id: request_id,
              work: work,
              attempt: attempt,
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

        def build_store
          return @store if @store

          self.class.lifecycle_store(store: nil, binding: @binding)
        end

        def build_manager
          @manager || Organisms::HitlManager.new
        end
      end
    end
  end
end
