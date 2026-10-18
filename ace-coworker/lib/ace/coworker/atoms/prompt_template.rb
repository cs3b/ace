# frozen_string_literal: true

module Ace
  module Coworker
    module Atoms
      # Pure start-prompt template rendering. Substitutes the known
      # placeholders from a context hash; unknown placeholders stay literal.
      # No IO.
      class PromptTemplate
        PLACEHOLDERS = %w[task assignment role overseer].freeze

        # @param template [String] preset start_prompt with {{placeholders}}
        # @param context [Hash{String => String}] commission identity values
        # @return [String] rendered prompt
        def self.render(template, context)
          rendered = template.to_s
          PLACEHOLDERS.each do |key|
            # Block form: the replacement is treated literally, so values
            # containing backslashes or gsub escape sequences (\1, \0, \&)
            # are interpolated verbatim instead of being expanded.
            rendered = rendered.gsub("{{#{key}}}") { context.fetch(key, "").to_s }
          end
          rendered.strip
        end
      end
    end
  end
end
