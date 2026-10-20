# frozen_string_literal: true

require "ace/hitl"
require_relative "../molecules/native_folder"

module Ace
  module Hitl
    module Hermes
      module Organisms
        # One reconciliation pass, called by the existing project wake. No
        # polling, Telegram token, lifecycle authority, or task-state replica.
        class NativeSync
          class OriginScope
            def initialize(root)
              @root = root
            end

            def effective_scope(_scope) = "current"
            def current_worktree_root = @root
            def worktree_roots(scope:) = [@root]
          end

          def initialize(route)
            @folder = Molecules::NativeFolder.new(route)
            @route = route
          end

          def run
            @folder.synchronize do
              result = {"replies" => 0, "instructions" => 0, "deliveries" => [], "errors" => []}
              @folder.keys("request").each do |key|
                request = @folder.read("request", key)
                next unless request["project"] == @folder.project
                begin
                  verify_request!(request)
                  delivery = @folder.read("delivery", key)
                  result["deliveries"] << {"key" => key, "state" => delivery&.fetch("state", nil) || "queued"}
                  record_delivery(request, delivery) if delivery
                  reply = @folder.read("reply", key)
                  next unless reply
                  apply_reply(request, reply, delivery)
                  @folder.ack("reply", key)
                  result["replies"] += 1
                rescue StandardError => e
                  # No frame or exception text: it can contain an OTP.
                  result["errors"] << {"key" => key, "error" => e.class.name}
                end
              end
              import_instructions(result)
              result
            end
          end

          private

          def verify_request!(request)
            origin = @folder.validate_origin!(request.fetch("origin"))
            expected = Digest::SHA256.hexdigest(JSON.generate([@folder.project, origin["file"], origin["case_id"]]))
            unless request["key"] == expected && request["channel"] == @folder.channel &&
                request["machine"] == @folder.machine && request["route"] == @folder.route_name
              raise ContractError, "native request binding differs"
            end
          end

          def current_case(request)
            origin = request.fetch("origin")
            owner = manager(origin.fetch("root"))
            event = owner.show(origin.fetch("case_id"), scope: "current")&.fetch(:event)
            unless event && event.id == origin["case_id"] && event.file_path == origin["file"] &&
                event.reply_to == request["reply_to"] && event.recipient == request["recipient"] &&
                !event.metadata["lab_request_id"]
              raise ContractError, "native original case changed"
            end
            [owner, event]
          end

          def record_delivery(request, delivery)
            owner, event = current_case(request)
            confirmed = confirmed_delivery?(delivery)
            status = confirmed ? "delivered" : "unavailable"
            detail = confirmed ? "Telegram send confirmed" : "Telegram send unconfirmed; no automatic resend"
            previous = event.metadata.dig("delivery", @folder.route_name)
            return if previous && previous["status"] == status && previous["detail"] == detail
            owner.update(event.id, scope: "current", set: {
              "delivery.#{@folder.route_name}.status" => status,
              "delivery.#{@folder.route_name}.adapter" => "hermes_native",
              "delivery.#{@folder.route_name}.detail" => detail,
              "delivery.#{@folder.route_name}.attempted_at" => Time.now.utc.iso8601
            })
          end

          def confirmed_delivery?(delivery)
            delivery && delivery["state"] == "delivered" &&
              delivery["message_ids"].is_a?(Array) && !delivery["message_ids"].empty? &&
              delivery["message_ids"].all? { |id| id.is_a?(String) && !id.empty? }
          end

          def manager(root)
            # The explicit absolute root also prevents current-cwd/main-worktree
            # discovery from redirecting a Reply into another copy of the case.
            Hitl::Organisms::HitlManager.new(root_dir: root,
              config: {"hitl" => {"root_dir" => root, "machine" => @folder.machine}},
              scope_resolver: OriginScope.new(root))
          end

          def apply_reply(request, reply, delivery)
            unless confirmed_delivery?(delivery) &&
                reply["origin"] == request["origin"] && reply["project"] == @folder.project &&
                reply["channel"] == @folder.channel && reply["machine"] == @folder.machine &&
                Array(delivery["message_ids"]).include?(reply["reply_to_message_id"]) &&
                reply["text"].is_a?(String) && !reply["text"].strip.empty?
              raise ContractError, "native Reply correlation differs"
            end
            owner, event = current_case(request)
            raise ContractError, "reports cannot receive Replies" if event.report?
            if event.answered?
              raise ContractError, "original case has a different answer" unless event.answer == reply["text"].strip
              return
            end
            owner.accept_answer(event.id, answer: reply["text"], scope: "current")
          end

          def import_instructions(result)
            root = @route["instruction_root"]
            return unless root
            raise ContractError, "instruction_root must be an explicit event root" unless @folder.event_roots.include?(root)
            @folder.validate_root!(root)
            @folder.keys("instruction").each do |key|
              item = @folder.read("instruction", key)
              next unless item["project"] == @folder.project
              begin
                unless item["channel"] == @folder.channel && item["machine"] == @folder.machine &&
                    item["text"].is_a?(String) && !item["text"].strip.empty?
                  raise ContractError, "invalid instruction"
                end
                owner = manager(root)
                tag = "hermes-instruction-#{key}"
                unless owner.list(in_folder: "all", tags: [tag], scope: "current").any?
                  owner.create("Telegram instruction", type: "report", result: "success",
                    body: [item["text"]], tags: [tag, "hermes-instruction"])
                end
                @folder.ack("instruction", key)
                result["instructions"] += 1
              rescue StandardError => e
                result["errors"] << {"key" => key, "error" => e.class.name}
              end
            end
          end
        end
      end
    end
  end
end
