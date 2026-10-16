# frozen_string_literal: true

module Ace
  module Hitl
    module Lifecycle
      # The client request surface of the scoped store boundary (spec
      # 8wq.t.34i), shared verbatim by the Unix client and the
      # mutual-TLS Hermes client (spec 8xa.t.nh0): the existing bounded
      # lifecycle frames are exchanged unchanged on both transports.
      # The includer implements `#request(op, params, deadline:)`.
      module LifecycleRequests
        def operator_question(**params)
          request("operator-question", params.transform_keys(&:to_s))
        end

        def proposal_create(**params)
          request("proposal-create", params)
        end

        def proposal_show(id, project:, history_after: 0)
          request("proposal-show", {"id" => id, "project" => project, "history_after" => history_after})
        end

        def proposal_revise(id, project:, expected_revision:, operation_id:, document:)
          request("proposal-revise", {"id" => id, "project" => project, "expected_revision" => expected_revision, "operation_id" => operation_id, "document" => document})
        end

        def proposal_acknowledge(id, project:, submitted_at:)
          request("proposal-ack", {"id" => id, "project" => project, "submitted_at" => submitted_at})
        end

        def proposal_reply(id, project:, **params)
          request("proposal-reply", {"id" => id, "project" => project}.merge(params))
        end

        def proposal_reconcile(id, project:, checkpoint:)
          request("proposal-reconcile", {"id" => id, "project" => project, "checkpoint" => checkpoint})
        end

        def proposal_wake(project:, after: nil)
          request("proposal-wake", {"project" => project, "after" => after}.compact)
        end

        def proposal_due(project:, after: nil)
          request("proposal-due", {"project" => project, "after" => after}.compact)
        end

        def proposal_history(project:, query: "", after: nil)
          request("proposal-history", {"project" => project, "query" => query, "after" => after}.compact)
        end

        def create(deadline: nil, **params)
          request("create", params.transform_keys(&:to_s), deadline: deadline)
        end

        def read(id, deadline: nil)
          request("read", {"id" => id}, deadline: deadline)
        end

        def deliver(id, answer)
          request("deliver", {"id" => id, "answer" => answer.to_s})
        end

        def consume(id, timeout: 0, operation: nil, native_delivery: false, deadline: nil)
          params = {"id" => id, "timeout" => Integer(timeout)}
          params["operation"] = operation if operation
          params["native_delivery"] = true if native_delivery
          request("consume", params, deadline: deadline)
        end

        def cancel(id, reason: "", deadline: nil)
          request("cancel", {"id" => id, "reason" => reason.to_s}, deadline: deadline)
        end

        def pending(project: nil)
          items = []
          after = nil
          loop do
            page = pending_page(project: project, after: after)
            items.concat(page.fetch("items"))
            cursor = page.fetch("next")
            break unless cursor
            unless cursor.is_a?(String) && (after.nil? || cursor > after)
              raise TransportError, "pending cursor did not advance"
            end
            after = cursor
          end
          items
        end

        def pending_page(project: nil, after: nil)
          request("pending", {"project" => project, "after" => after}.compact)
        end

        def states
          request("states")
        end

        def ping
          request("ping")
        end
      end
    end
  end
end
