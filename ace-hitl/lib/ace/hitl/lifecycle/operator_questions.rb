# frozen_string_literal: true
require "ace/hitl/contract/request_envelope"

module Ace
  module Hitl
    module Lifecycle
      module OperatorQuestions
        def operator_question(id:, project:, question:, plan: "", options: [])
          unless @identity.uid.is_a?(Integer) && @policy.operator_question?(uid: @identity.uid, project: project)
            raise PermissionError, "operator question requires an installed UID and exact project grant"
          end
          unless project.is_a?(String) && Contract::ManagedEnvelope::TOKEN.match?(project) &&
              question.is_a?(String) && question.valid_encoding? && !question.strip.empty? &&
              question.length <= Store::MAX_PLAN_QUESTION && !question.include?("\0") &&
              plan.is_a?(String) && plan.valid_encoding? && plan.length <= Store::MAX_PLAN_QUESTION &&
              !plan.include?("\0") && options.is_a?(Array) && options.length <= Store::MAX_OPTIONS &&
              options.all? { |item| item.is_a?(String) && item.valid_encoding? && !item.strip.empty? &&
                item.length <= Store::MAX_OPTION && !item.include?("\0") }
            raise StateError, "invalid nonsecret operator question content"
          end
          [question, plan, *options].each { |text| Kinds.check_answer!("question", text) }
          question, plan = question.strip, plan.strip
          options = options.map(&:strip)
          input_digest = Digest::SHA256.hexdigest(JSON.generate([plan, question, options]))
          # The authority binds the actual Captain-visible question, including
          # its optional context/choices. Hermes publishes these exact bytes.
          question += "\n\nContext: #{plan}" unless plan.empty?
          unless options.empty?
            question += "\n\nOptions:\n" + options.each_with_index.map { |item, index| "#{index + 1}. #{item}" }.join("\n")
          end
          request_id = safe_id(id)
          incarnation = SecureRandom.hex(8)
          envelope = Contract::OperatorEnvelope.load({
            "schema" => Contract::OperatorEnvelope::SCHEMA, "context" => "operator-question",
            "request_id" => request_id, "request_incarnation" => incarnation, "project" => project,
            "requester" => @identity.username, "requester_uid" => @identity.uid,
            "correlation_id" => request_id, "kind" => "question",
            "payload_sha256" => Digest::SHA256.hexdigest(question),
            "input_sha256" => input_digest})
          value = {"id" => request_id, "project" => project, "requester" => @identity.username,
            "requester_uid" => @identity.uid, "harness" => "operator", "kind" => "question", "sensitive" => false,
            "plan" => plan, "question" => question, "options" => options, "created_at" => Time.now.to_i,
            "incarnation" => incarnation, "envelope" => envelope}
          with_request_lock(request_id) do
            operator_authority!(value)
            terminal = load_terminal(request_id)
            previous = terminal
            previous ||= load_request(request_id) if request_path(request_id).exist?
            if previous
              requester_gate!(previous)
              old = Contract::RequestEnvelope.from_facts(previous)
              unless old["schema"] == Contract::OperatorEnvelope::SCHEMA &&
                  old.except("request_incarnation") == envelope.except("request_incarnation")
                raise StateError, "operator question retry changed immutable content or context"
              end
              initialize_projection_locked!(previous) unless terminal
              return {"id" => request_id, "requested" => true, "replay" => true, "envelope" => old}
            end
            persist_request_locked!(value)
          end
        rescue Contract::InvalidEnvelope => e
          raise StateError, e.message
        end

        private

        def operator_request?(value)
          value.dig("envelope", "schema") == Contract::OperatorEnvelope::SCHEMA
        end

        def operator_authority!(value)
          envelope = Contract::RequestEnvelope.from_facts(value)
          unless envelope["schema"] == Contract::OperatorEnvelope::SCHEMA &&
              @policy.operator_question?(uid: envelope.fetch("requester_uid"), project: envelope.fetch("project"))
            raise PermissionError, "operator requester project grant is unavailable or revoked"
          end
          envelope
        rescue Contract::InvalidEnvelope => e
          raise StateError, e.message
        end
      end
    end
  end
end
