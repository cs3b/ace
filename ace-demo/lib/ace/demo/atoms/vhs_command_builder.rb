# frozen_string_literal: true

module Ace
  module Demo
    module Atoms
      module VhsCommandBuilder
        module_function

        def build(tape_path:, output_path:, vhs_bin: "vhs")
          [vhs_bin, tape_path, "--output", output_path]
        end
      end
    end
  end
end
