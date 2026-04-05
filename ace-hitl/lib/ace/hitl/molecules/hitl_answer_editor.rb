# frozen_string_literal: true

module Ace
  module Hitl
    module Molecules
      class HitlAnswerEditor
        ANSWER_HEADER = /^## Answer\s*$/

        def self.apply(body, answer)
          answer_text = answer.to_s.strip
          replacement = "## Answer\n\n#{answer_text}\n"
          source = body.to_s.rstrip

          if source.match?(ANSWER_HEADER)
            source.sub(/^## Answer[ \t]*(?:\n.*)?\z/m, replacement)
          elsif source.empty?
            replacement
          else
            "#{source}\n\n#{replacement}"
          end
        end
      end
    end
  end
end
