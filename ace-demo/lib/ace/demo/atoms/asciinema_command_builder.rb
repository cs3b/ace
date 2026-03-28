# frozen_string_literal: true

require "shellwords"

module Ace
  module Demo
    module Atoms
      module AsciinemaCommandBuilder
        module_function

        # cast_compatibility is accepted to keep the interface aligned with task
        # requirements; v3 passthrough is currently the proven production path.
        def build(output_path:, script_path: nil, shell_command: nil, tty_size: "80x24", cast_compatibility: :v2, asciinema_bin: "asciinema")
          validate_cast_compatibility!(cast_compatibility)

          command = shell_command.to_s.strip
          if command.empty?
            escaped_script_path = Shellwords.escape(script_path.to_s)
            command = "bash #{escaped_script_path}"
          end

          cmd = [asciinema_bin, "rec", "--overwrite", "--command", command]
          cmd.concat(tty_size_flags(tty_size))
          cmd << output_path
          cmd
        end

        def tty_size_flags(tty_size)
          return [] if tty_size.nil? || tty_size.to_s.strip.empty?

          cols, rows = tty_size.to_s.split("x", 2)
          if cols.to_s.empty? || rows.to_s.empty? || cols !~ /\A\d+\z/ || rows !~ /\A\d+\z/
            raise ArgumentError, "tty_size must be formatted as <cols>x<rows> (e.g. 80x24)"
          end

          ["--cols", cols, "--rows", rows]
        end
        private_class_method :tty_size_flags

        def validate_cast_compatibility!(cast_compatibility)
          return if %i[v2 v3 auto].include?(cast_compatibility)

          raise ArgumentError, "cast_compatibility must be one of: :v2, :v3, :auto"
        end
        private_class_method :validate_cast_compatibility!
      end
    end
  end
end
