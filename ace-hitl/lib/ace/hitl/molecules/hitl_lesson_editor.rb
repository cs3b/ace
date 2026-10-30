# frozen_string_literal: true

module Ace
  module Hitl
    module Molecules
      # Lesson editor (task 8xs.t.pu0.c): the takeaway the advisory agent
      # draws from comparing the human decision with its suggestion — its
      # OWN `## Lesson` section at the same case, inserted BEFORE the
      # `## Answer` section like the suggestion (answer rewrites can never
      # remove history). A lesson references the exact question/suggestion/
      # decision revisions it compared; it is not a new decision and never
      # changes the answer's authorship.
      class HitlLessonEditor
        ANSWER_HEADER = /^## Answer\s*$/m

        # @param body [String] current case body
        # @param lesson [Hash] {"id","author","relation","takeaway",
        #   "refs","at"}
        def self.apply(body, lesson)
          block = render(lesson)
          source = body.to_s.rstrip
          return block if source.empty?

          if source.match?(ANSWER_HEADER)
            source.sub(ANSWER_HEADER) { "#{block}\n\n## Answer" }
          else
            "#{source}\n\n#{block}"
          end
        end

        def self.render(lesson)
          lines = ["## Lesson"]
          lines << "author: #{lesson.fetch("author")}"
          lines << "at: #{lesson.fetch("at")}"
          lines << "relation: #{lesson.fetch("relation")}"
          lines << "refs: #{Array(lesson["refs"]).join(", ")}" if lesson["refs"]
          lines << "" << "takeaway: #{lesson.fetch("takeaway")}"
          lines.join("\n") + "\n"
        end
      end
    end
  end
end
