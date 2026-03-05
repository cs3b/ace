# frozen_string_literal: true

module Ace
  module Demo
    module Atoms
      module TapeSearchDirs
        module_function

        def build(cwd:, home_dir:, gem_root:)
          [
            File.join(cwd, ".ace", "demo", "tapes"),
            File.join(home_dir, ".ace", "demo", "tapes"),
            File.join(gem_root, ".ace-defaults", "demo", "tapes")
          ]
        end
      end
    end
  end
end
