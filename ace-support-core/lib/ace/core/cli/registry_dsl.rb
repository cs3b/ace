# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Core
    module CLI
      # DSL adapter allowing existing CLI modules to keep `register` semantics
      # while using Ace::Support::Cli::Registry under the hood.
      module RegistryDsl
        def self.extended(base)
          base.instance_variable_set(:@registry, Ace::Support::Cli::Registry.new)
        end

        def register(name, command_class = nil, *_args, aliases: nil, **_kwargs)
          registry.register(name, normalize_command(command_class))
          Array(aliases).each do |aliaz|
            registry.register(aliaz, normalize_command(command_class))
          end
          self
        end

        def resolve(args)
          return registry.resolve(args) unless args.empty?

          registry.resolve(["--help"])
        rescue Ace::Support::Cli::CommandNotFoundError
          raise Ace::Core::CLI::Error.new("unknown command", exit_code: 1)
        end

        private

        def registry
          @registry ||= Ace::Support::Cli::Registry.new
        end

        def normalize_command(command_class)
          return command_class.class unless command_class.is_a?(Class)

          command_class
        end
      end
    end
  end
end
