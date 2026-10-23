# frozen_string_literal: true
require "digest"
require "json"

module Ace
  module Hitl
    module Molecules
      # Read-only semantic projection. No private text is emitted; delivery
      # timestamps, filesystem metadata and observer acknowledgements are not
      # decision changes. Canonical HITL remains the only event owner.
      class EventObservation
        def initialize(manager: Organisms::HitlManager.new)
          @manager = manager
        end

        def call(scope: "current", limit: 500, owner: nil)
          raise ArgumentError, "invalid observation limit" unless (1..2000).cover?(limit)
          events = @manager.list(in_folder: "next", scope: scope, limit: limit, strict: true)
          raise ArgumentError, "observation exceeds configured event budget" if events.size > limit
          address = owner && Molecules::HitlAddressResolver.new(config: @manager.config).resolve(owner)
          events = events.select { |event| incoming?(event, address) } if address
          rows = events.map do |event|
            semantic = [event.id, event.type, event.status, event.result, event.kind,
              event.title, event.content, event.answer, event.questions,
              Array(event.tags).sort, canonical(event.recipient), canonical(event.reply_to),
              event.metadata.values_at("task", "assignment", "step", "step_name", "resume_instructions")]
            {"key" => Digest::SHA256.hexdigest(event.file_path.to_s),
             "id" => event.id, "revision" => Digest::SHA256.hexdigest(JSON.generate(canonical(semantic))),
             "type" => event.type, "status" => event.status, "result" => event.result,
             "task" => event.metadata["task"], "assignment" => event.metadata["assignment"]}
          end
          {"schema" => "ace.hitl.observation/v1", "events" => rows.sort_by { |row| row["key"] }}
        end

        private

        # Questions created locally are outbound until actually answered. A
        # worker's reply belongs to that worker, not every linked-worktree actor.
        # Native instructions have no recipient; their explicit import root owns them.
        def incoming?(event, address)
          local = File.expand_path(event.file_path).start_with?(File.expand_path(@manager.root_dir) + File::SEPARATOR)
          return local if Array(event.tags).include?("hermes-instruction")
          if event.question? && event.answered?
            return local && event.reply_to &&
              event.reply_to["machine"] == @manager.config.dig("hitl", "machine") &&
              File.expand_path(event.reply_to["folder"].to_s) == File.expand_path(@manager.root_dir)
          end
          recipient = event.recipient
          recipient && address.all? { |key, value| recipient[key] == value }
        end

        def canonical(value)
          case value
          when Hash then value.sort.to_h.transform_values { |item| canonical(item) }
          when Array then value.map { |item| canonical(item) }
          else value
          end
        end
      end
    end
  end
end
