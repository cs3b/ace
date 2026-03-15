# frozen_string_literal: true

require_relative "parser"

module Ace
  module Support
    module Cli
      class Runner
        def initialize(registry, parser_class: Parser)
          @registry = registry
          @parser_class = parser_class
        end

        def call(args: ARGV)
          command_target, remaining = resolve_target(args)
          command_class = command_target.is_a?(Class) ? command_target : command_target.class
          parsed = @parser_class.new(command_class).parse(remaining)
          result = if command_target.is_a?(Class)
            command_target.new.call(**parsed)
          else
            command_target.call(**parsed)
          end
          result.nil? ? 0 : result
        rescue Ace::Support::Cli::ParseError => e
          if defined?(Ace::Core::CLI::Error)
            raise Ace::Core::CLI::Error.new(e.message)
          end
          raise
        end

        private

        def resolve_target(args)
          if @registry.respond_to?(:resolve)
            @registry.resolve(args)
          else
            normalized = args.dup
            token = @registry.name.to_s.split("::").last.gsub(/([a-z])([A-Z])/, '\1-\2').downcase
            normalized.shift if !token.empty? && normalized.first == token
            [@registry, normalized]
          end
        end
      end
    end
  end
end
