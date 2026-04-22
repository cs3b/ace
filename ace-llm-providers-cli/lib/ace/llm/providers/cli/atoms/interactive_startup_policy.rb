# frozen_string_literal: true

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          module InteractiveStartupPolicy
            module_function

            def codex_trust_override(working_dir:)
              path = working_dir.to_s.strip
              return nil if path.empty?

              %{projects."#{escape_toml_basic_string(path)}".trust_level="trusted"}
            end

            def escape_toml_basic_string(value)
              value.to_s.gsub("\\", "\\\\\\\\").gsub("\"", "\\\\\"")
            end
          end
        end
      end
    end
  end
end
