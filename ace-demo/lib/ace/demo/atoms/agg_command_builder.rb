# frozen_string_literal: true

module Ace
  module Demo
    module Atoms
      module AggCommandBuilder
        module_function

        def build(input_path:, output_path:, font_size: nil, theme: nil, font_family: nil, agg_bin: "agg")
          cmd = [agg_bin]
          cmd.concat(["--font-size", font_size.to_s]) unless font_size.nil?
          cmd.concat(["--theme", theme.to_s]) if present?(theme)
          cmd.concat(["--font-family", font_family.to_s]) if present?(font_family)
          cmd.concat([input_path, output_path])
          cmd
        end

        def present?(value)
          !value.nil? && !value.to_s.strip.empty?
        end
        private_class_method :present?
      end
    end
  end
end
