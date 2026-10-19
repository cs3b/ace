# frozen_string_literal: true

module Ace
  module Overseer
    module Molecules
      # Read-only gateway to the overseer's incoming ace-hitl events
      # (L6.5). ace-hitl owns its files; this molecule only lists events
      # and normalizes them into plain hashes for the interpretation
      # atom. Reports carry status "recorded", questions stay "pending"
      # until answered — both are the overseer's inbox.
      class HitlInbox
        # @param manager [Ace::Hitl::Organisms::HitlManager, nil]
        def initialize(manager: nil)
          @manager = manager || Ace::Hitl::Organisms::HitlManager.new
        end

        # @return [Array<Hash>] {"id","type","result","task","assignment",
        #   "step","title"} sorted oldest-first
        def incoming_events
          reports = @manager.list(in_folder: "next", type: "report")
          questions = @manager.list(in_folder: "next", type: "question", status: "pending")

          (reports + questions).sort_by { |event| event.created_at || Time.now }.map { |event| normalize(event) }
        end

        private

        def normalize(event)
          {
            "id" => event.id,
            "type" => event.type,
            "result" => event.result,
            "task" => event.metadata["task"],
            "assignment" => event.metadata["assignment"],
            "step" => event.metadata["step"],
            "title" => event.title
          }
        end
      end
    end
  end
end
