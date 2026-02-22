# frozen_string_literal: true

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module CommandFormatters
            # Pi CLI: `/ace-git-commit` → `/skill:ace-git-commit`
            PI_FORMATTER = ->(name) { "/skill:#{name}" }

            # Codex CLI: `/ace-git-commit` → `$ace-git-commit`
            CODEX_FORMATTER = ->(name) { "$#{name}" }
          end
        end
      end
    end
  end
end
