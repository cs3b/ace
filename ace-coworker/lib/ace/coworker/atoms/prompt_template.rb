# frozen_string_literal: true

module Ace
  module Coworker
    module Atoms
      # Pure start-prompt template rendering. Substitutes the known
      # placeholders from a context hash; unknown placeholders stay literal.
      # No IO.
      class PromptTemplate
        PLACEHOLDERS = %w[task assignment role overseer].freeze
        PLACEHOLDER_PATTERN = /\{\{(#{PLACEHOLDERS.map { |p| Regexp.escape(p) }.join('|')})\}\}/.freeze

        # @param template [String] preset start_prompt with {{placeholders}}
        # @param context [Hash{String => String}] commission identity values
        # @return [String] rendered prompt
        def self.render(template, context)
          # Single pass over PLACEHOLDER_PATTERN: only known placeholders
          # match, and substituted values are never re-expanded (a value
          # shaped like a later placeholder stays literal). Block form: the
          # replacement is treated literally, so values containing
          # backslashes or gsub escape sequences (\1, \0, \&) interpolate
          # verbatim.
          template.to_s.gsub(PLACEHOLDER_PATTERN) { context.fetch(Regexp.last_match(1), "").to_s }.strip
        end
      end
    end
  end
end
