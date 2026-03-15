# frozen_string_literal: true

require "optparse"
require_relative "errors"

module Ace
  module Support
    module Cli
      class Parser
        def initialize(command_class)
          @command_class = command_class
        end

        def parse(args)
          options = build_defaults
          parser = OptionParser.new
          parser.banner = "Usage: #{File.basename($0)} #{command_label} [options]"

          configure_options(parser, options)

          remaining = args.dup
          parser.parse!(remaining)
          remaining = remaining.reject { |token| token == "--" }

          apply_positionals(options, remaining)
          validate_required_options!(options)

          options
        rescue OptionParser::ParseError => e
          raise ParseError, parse_error_message(e)
        rescue ArgumentError => e
          raise ParseError, e.message
        end

        private

        attr_reader :command_class

        def build_defaults
          command_class.options.each_with_object({}) do |option, hash|
            hash[option.name] = duplicate_default(option.default)
          end
        end

        def duplicate_default(value)
          case value
          when Array then value.dup
          when Hash then value.dup
          else value
          end
        end

        def configure_options(parser, options)
          command_class.options.each do |option|
            desc = option.desc.to_s

            case option.type
            when :boolean
              parser.on(*option.aliases, "--[no-]#{option.name.to_s.tr('_', '-')}", desc) do |value|
                options[option.name] = value
              end
            when :integer
              switches = value_switches(option, "N")
              parser.on(*switches, Integer, desc) { |value| options[option.name] = value }
            when :float
              switches = value_switches(option, "N")
              parser.on(*switches, Float, desc) { |value| options[option.name] = value }
            when :array
              switches = value_switches(option, "A,B")
              parser.on(*switches, Array, desc) do |value|
                current = Array(options[option.name])
                parsed_values = value.nil? ? [] : Array(value)
                options[option.name] = current + parsed_values
              end
            when :hash
              switches = value_switches(option, "KEY:VALUE")
              parser.on(*switches, String, desc) do |value|
                key, parsed_value = parse_hash_pair(value, option)
                current = options[option.name] || {}
                options[option.name] = current.merge(key => parsed_value)
              end
            else
              switches = value_switches(option, "VALUE")
              parser.on(*switches, String, desc) { |value| options[option.name] = value }
            end
          end
        end

        def value_switches(option, value_label)
          (option.aliases + [option.long_switch]).map do |switch|
            "#{switch} #{value_label}"
          end
        end

        def parse_hash_pair(value, option)
          parts = value.split(":", 2)
          raise ArgumentError, "Invalid value for #{option.long_switch}: expected key:value" if parts.length < 2

          parts
        end

        def apply_positionals(options, remaining)
          cursor = 0
          command_class.arguments.each do |argument|
            if argument.type == :array
              values = remaining.drop(cursor)
              if values.empty? && argument.required
                raise ArgumentError, "Missing required argument: #{argument.name}"
              end

              options[argument.name] = values
              cursor = remaining.length
              break
            end

            raw_value = remaining[cursor]
            if raw_value.nil?
              raise ArgumentError, "Missing required argument: #{argument.name}" if argument.required
              next
            end

            options[argument.name] = coerce_argument(raw_value, argument)
            cursor += 1
          end

          return unless remaining.length > cursor
          if accepts_args_keyword?
            options[:args] = remaining.drop(cursor)
            return
          end

          extra = remaining.drop(cursor).join(" ")
          raise ArgumentError, "Unexpected arguments: #{extra}"
        end

        def accepts_args_keyword?
          command_class.instance_method(:call).parameters.any? { |kind, name| kind == :key && name == :args }
        rescue NameError
          false
        end

        def coerce_argument(value, argument)
          case argument.type
          when :integer
            Integer(value)
          when :float
            Float(value)
          when :boolean
            coerce_boolean(value)
          else
            value
          end
        rescue ArgumentError
          raise ArgumentError, "Invalid value for argument #{argument.name}: expected #{argument.type}"
        end

        def coerce_boolean(value)
          return true if value == true || value.to_s.casecmp("true").zero?
          return false if value == false || value.to_s.casecmp("false").zero?

          raise ArgumentError
        end

        def validate_required_options!(options)
          missing = command_class.options.select do |option|
            option.required && (options[option.name].nil? || options[option.name] == "")
          end
          return if missing.empty?

          flags = missing.map(&:long_switch).join(", ")
          raise ArgumentError, "Missing required options: #{flags}"
        end

        def command_label
          raw = command_class.name.to_s
          token = raw.empty? ? "command" : (raw.split("::").last || "command")
          token.gsub(/([a-z])([A-Z])/, '\1-\2').downcase
        end

        def parse_error_message(error)
          return "#{error.message}. Did you mean: #{suggest_for(error)}" if error.is_a?(OptionParser::InvalidOption)

          error.message
        end

        def suggest_for(error)
          token = error.args.first.to_s
          return "(no suggestion)" if token.empty?

          candidates = command_class.options.flat_map do |option|
            option.aliases + [option.long_switch]
          end

          ranked = candidates.sort_by do |candidate|
            levenshtein(token, candidate)
          end

          ranked.first || "(no suggestion)"
        end

        def levenshtein(source, target)
          m = source.length
          n = target.length
          return n if m.zero?
          return m if n.zero?

          matrix = Array.new(m + 1) { |i| [i] + [0] * n }
          (0..n).each { |j| matrix[0][j] = j }

          (1..m).each do |i|
            (1..n).each do |j|
              cost = source[i - 1] == target[j - 1] ? 0 : 1
              matrix[i][j] = [
                matrix[i - 1][j] + 1,
                matrix[i][j - 1] + 1,
                matrix[i - 1][j - 1] + cost
              ].min
            end
          end

          matrix[m][n]
        end
      end
    end
  end
end
