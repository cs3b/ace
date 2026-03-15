# frozen_string_literal: true

require "ace/support/cli"
require_relative "error"
require_relative "standard_options"

module Ace
  module Core
    module CLI
      # Shared CLI helper methods and option constants used across ACE commands.
      module Base
        STANDARD_OPTIONS = %i[quiet verbose debug].freeze
        RESERVED_FLAGS = %i[h v q d o].freeze

        def verbose?(options)
          options[:verbose] == true
        end

        def quiet?(options)
          options[:quiet] == true
        end

        def debug?(options)
          options[:debug] == true
        end

        def help?(options)
          options[:help] == true || options[:h] == true
        end

        def debug_log(message, options)
          $stderr.puts "DEBUG: #{message}" if debug?(options)
        end

        def raise_cli_error(message, exit_code: 1)
          raise Ace::Core::CLI::Error.new(message, exit_code: exit_code)
        end

        def validate_required!(options, *required)
          missing = required - options.keys.select { |key| !options[key].nil? }
          return if missing.empty?

          raise ArgumentError, "Missing required options: #{missing.join(', ')}"
        end

        def format_pairs(hash)
          hash.map { |key, value| "#{key}=#{value}" }.join(" ")
        end

        # Type coercion for CLI option values.
        # Retained for backward compatibility with downstream commands still using ace-support-cli.
        def coerce_types(options, conversions)
          conversions.each do |key, type|
            next if options[key].nil?

            case type
            when :integer
              begin
                options[key] = Integer(options[key])
              rescue ArgumentError, TypeError
                raise ArgumentError, "Invalid value for --#{key.to_s.tr('_', '-')}: " \
                                     "'#{options[key]}' is not a valid integer"
              end
            when :float
              begin
                options[key] = Float(options[key])
              rescue ArgumentError, TypeError
                raise ArgumentError, "Invalid value for --#{key.to_s.tr('_', '-')}: " \
                                     "'#{options[key]}' is not a valid number"
              end
            end
          end
          options
        end
      end
    end
  end
end
