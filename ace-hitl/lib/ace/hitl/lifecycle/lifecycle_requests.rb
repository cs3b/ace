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
