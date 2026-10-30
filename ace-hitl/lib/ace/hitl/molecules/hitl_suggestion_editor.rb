# frozen_string_literal: true

module Ace
  module Hitl
    module Molecules
      # Marked-suggestion editor (task 8xs.t.pu0.b): a suggestion is its
      # OWN section in the canonical case file — never the Answer. It is
      # inserted BEFORE the `## Answer` section (or appended at the end
      # when no answer exists), so the Answer editor's tail replacement
      # can never remove a suggestion, and an answer written after a
      # suggestion preserves it. Pure string surgery — atomicity and
      # locking belong to the manager's transition helper.
      class HitlSuggestionEditor
        ANSWER_HEADER = /^## Answer\s*$/m
        SUGGESTION_HEADER = "## Suggestion"

        # @param body [String] current case body (frontmatter stripped)
        # @param suggestion [Hash] {"id","author","text","rationale",
        #   "refs","at"}
        # @return [String] the updated body
        def self.apply(body, suggestion)
          block = render(suggestion)
          source = body.to_s.rstrip
          return block if source.empty?

          if source.match?(ANSWER_HEADER)
            # Insert strictly before the Answer section: the answer tail
            # replacement never touches what precedes it.
            source.sub(ANSWER_HEADER) { "#{block}\n\n## Answer" }
          else
            "#{source}\n\n#{block}"
          end
        end

        # @return [String] the rendered marked suggestion block
        def self.render(suggestion)
          lines = [SUGGESTION_HEADER]
          lines << "author: #{suggestion.fetch("author")}"
          lines << "at: #{suggestion.fetch("at")}"
          lines << "refs: #{Array(suggestion["refs"]).join(", ")}" if suggestion["refs"]
          lines << "" << "proposal: #{suggestion.fetch("text")}" << ""
          lines << "rationale: #{suggestion.fetch("rationale")}"
          lines.join("\n") + "\n"
        end
      end
    end
  end
end
