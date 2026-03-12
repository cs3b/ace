# frozen_string_literal: true

module Ace
  module LLM
    module Providers
      module CLI
        module Atoms
          # Resolves filesystem execution context for CLI-backed providers.
          module ExecutionContext
            module_function

            def resolve_working_dir(working_dir: nil, subprocess_env: nil)
              explicit = working_dir.to_s.strip
              return File.expand_path(explicit) unless explicit.empty?

              env = subprocess_env.respond_to?(:to_h) ? subprocess_env.to_h : {}
              project_root = env["PROJECT_ROOT_PATH"] || env[:PROJECT_ROOT_PATH]
              project_root = project_root.to_s.strip
              return File.expand_path(project_root) unless project_root.empty?

              Dir.pwd
            end
          end
        end
      end
    end
  end
end
