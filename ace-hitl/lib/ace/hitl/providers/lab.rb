# frozen_string_literal: true

require_relative "errors"
require_relative "lab/transport"
require_relative "../organisms/hitl_manager"

module Ace
  module Hitl
    module Providers
      # provider=lab adapter (spec 8wm.t.vrz §1): ONE ask operation =
      # local HITL event + relay transport send. Owns every lab transport
      # invocation; agent-facing ace-hitl paths must never bypass it
      # (guard-tested, spec §8).
      class Lab
        DEFAULT_PROJECT = "ace"
        DEFAULT_HARNESS = "lab-admin"
        DEFAULT_PLAN = "ace-hitl ask"

        PROVIDER_NAME = "lab"

        def initialize(manager: nil, transport: nil)
          @manager = manager
          @transport = transport || Transport.new
        end

        # Local event + transport send in ONE operation. The ref is
        # REQUIRED and must be validated by the caller before this call.
        def ask(question:, ref:, work:, attempt:, title: nil,
          project: DEFAULT_PROJECT, harness: DEFAULT_HARNESS,
          plan: DEFAULT_PLAN, effect: {})
          effect = effect.to_h
          request_id = @transport.generate_request_id
          manager = build_manager
          event = manager.create(title || question, questions: [question])

          begin
            lab_request_id = @transport.submit(@transport.build_argv(
              request_id: request_id,
              work: work,
              attempt: attempt,
              project: project,
              harness: harness,
              plan: plan,
              question: question,
              ace_hitl_id: event.id,
              **effect
            ))
          rescue ProviderUnavailableError => e
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
            "lab_request_id" => lab_request_id,
            "lab_request_state" => "created",
            "lab_request_effect" => effect_declared?(effect) ? "declared" : "none"
          })

          AskResult.new(event_id: event.id, request_id: lab_request_id)
        end

        # Contract defined in spec §1.2; the herdr push delivery itself
        # lands with ace-herdr (8wm.t.vs0) + the provider=lab integration
        # (8wm.t.vs2).
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

        def build_manager
          @manager || Organisms::HitlManager.new
        end
      end
    end
  end
end
