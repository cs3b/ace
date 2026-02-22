# frozen_string_literal: true

require_relative "command_rewriter"
require_relative "command_formatters"

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          # Convenience wrapper for Pi-style skill rewriting.
          # Delegates to CommandRewriter with PI_FORMATTER.
          #
          # Transforms `/name` → `/skill:name` for known skill names,
          # enabling Pi CLI to discover and invoke skills correctly.
          class SkillCommandRewriter
            # Rewrite skill command references in a prompt string.
            #
            # @param prompt [String] The prompt text to rewrite
            # @param skill_names [Array<String>] Known skill names (e.g. ["ace-onboard", "ace-git-commit"])
            # @return [String] Prompt with `/name` rewritten to `/skill:name`
            def self.call(prompt, skill_names:)
              CommandRewriter.call(prompt, skill_names: skill_names, formatter: CommandFormatters::PI_FORMATTER)
            end
          end
        end
      end
    end
  end
end
