# frozen_string_literal: true

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module CommandFormatters
            # Pi CLI: `/ace:commit` → `/skill:ace:commit`
            PI_FORMATTER = ->(name) { "/skill:#{name}" }

            # Codex CLI: `/ace:commit` → `$ace:commit`
            CODEX_FORMATTER = ->(name) { "$#{name}" }
          end
        end
      end
    end
  end
end
