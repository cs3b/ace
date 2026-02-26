# frozen_string_literal: true

module Ace
  module Core
    module CLI
      module DryCli
        # Preprocesses ARGV to coalesce repeated flags into comma-separated values.
        #
        # dry-cli's `type: :array` uses Ruby's OptionParser Array converter which
        # overwrites on each repeated flag instead of accumulating. This means
        # `--task 288 --task 287` only captures 287. Only the comma-separated form
        # (`--task 288,287`) works correctly.
        #
        # This module provides a generic, reusable ARGV preprocessor that merges
        # repeated flag occurrences into the comma-separated form that dry-cli expects.
        #
        # @example Basic usage
        #   ArgvCoalescer.call(
        #     ["--task", "288", "--task", "287"],
        #     flags: { "--task" => ["-t"] }
        #   )
        #   # => ["--task", "288,287"]
        #
        # @example With interleaved flags
        #   ArgvCoalescer.call(
        #     ["--task", "288", "--quiet", "--task", "287"],
        #     flags: { "--task" => ["-t"] }
        #   )
        #   # => ["--quiet", "--task", "288,287"]
        #
        module ArgvCoalescer
          # Coalesce repeated flag occurrences into comma-separated values.
          #
          # @param argv [Array<String>] Original argument list
          # @param flags [Hash{String => Array<String>}] Map of canonical long flag to its aliases
          #   e.g. { "--task" => ["-t"], "--model" => ["-m"] }
          # @param separator [String] Separator for joining values (default: ",")
          # @return [Array<String>] Transformed argument list with repeated flags merged
          def self.call(argv, flags:, separator: ",")
            # Build a lookup from any flag form to its canonical name
            flag_lookup = {}
            flags.each do |canonical, aliases|
              flag_lookup[canonical] = canonical
              aliases.each { |a| flag_lookup[a] = canonical }
            end

            accumulated = flags.keys.each_with_object({}) { |k, h| h[k] = [] }
            passthrough = []
            i = 0

            while i < argv.length
              arg = argv[i]

              # Check for --flag=value form
              bare_flag = arg.include?("=") ? arg.split("=", 2)[0] : arg
              canonical = flag_lookup[bare_flag]

              if canonical
                value = extract_value(arg, argv, i)
                accumulated[canonical] << value unless value.empty?
                i = next_index(arg, argv, i)
              else
                passthrough << arg
                i += 1
              end
            end

            # Append coalesced flags at end of passthrough args
            result = passthrough.dup
            accumulated.each do |flag, values|
              next if values.empty?
              result.push(flag, values.join(separator))
            end

            result
          end

          # Extract value from a flag argument.
          #
          # @param arg [String] Current argument (may be --flag=value or just --flag)
          # @param argv [Array<String>] Full argument list
          # @param index [Integer] Current index
          # @return [String] Extracted value
          def self.extract_value(arg, argv, index)
            if arg.include?("=")
              arg.split("=", 2)[1]
            elsif index + 1 < argv.length && !argv[index + 1].start_with?("-")
              argv[index + 1]
            else
              ""
            end
          end
          private_class_method :extract_value

          # Calculate next index after consuming a flag and its value.
          #
          # @param arg [String] Current argument
          # @param argv [Array<String>] Full argument list
          # @param index [Integer] Current index
          # @return [Integer] Next index to process
          def self.next_index(arg, argv, index)
            if arg.include?("=")
              index + 1
            elsif index + 1 < argv.length && !argv[index + 1].start_with?("-")
              index + 2
            else
              index + 1
            end
          end
          private_class_method :next_index
        end
      end
    end
  end
end
