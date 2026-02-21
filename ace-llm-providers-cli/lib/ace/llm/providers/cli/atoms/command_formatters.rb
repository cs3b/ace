# frozen_string_literal: true

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module CommandFormatters
            # Pi CLI: `/ace_git_commit` → `/skill:ace_git_commit`
            PI_FORMATTER = ->(name) { "/skill:#{name}" }

            # Codex CLI: `/ace_git_commit` → `$ace_git_commit`
            CODEX_FORMATTER = ->(name) { "$#{name}" }
          end
        end
      end
    end
  end
end
