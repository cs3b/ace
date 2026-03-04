# frozen_string_literal: true

module Ace
  module Task
    module Molecules
      # Shared path utilities for task plan components.
      module PathUtils
        module_function

        def relative_path(path)
          absolute = File.expand_path(path)
          cwd = File.expand_path(Dir.pwd)
          return absolute unless absolute.start_with?("#{cwd}/")

          absolute.delete_prefix("#{cwd}/")
        end
      end
    end
  end
end
