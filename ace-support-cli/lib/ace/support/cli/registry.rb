# frozen_string_literal: true

require_relative "errors"

module Ace
  module Support
    module Cli
      class Registry
        Node = Struct.new(:command, :children)

        attr_reader :version

        def initialize(version: nil)
          @version = version
          @root = Node.new(nil, {})
        end

        def register(name, command_class = nil)
          node = ensure_path(name)
          node.command = command_class if command_class
          yield NestedRegistry.new(node) if block_given?
          self
        end

        def resolve(args)
          raise CommandNotFoundError, "No commands registered" if @root.children.empty?

          tokens = args.dup
          node = @root
          consumed = 0

          tokens.each do |token|
            child = node.children[token]
            break unless child

            node = child
            consumed += 1
          end

          unless node.command
            attempted = tokens.first(consumed + 1).join(" ")
            raise CommandNotFoundError, "Command not found: #{attempted.strip}"
          end

          [node.command, tokens.drop(consumed)]
        end

        private

        def ensure_path(name)
          parts = name.to_s.split(" ")
          raise ArgumentError, "Command name cannot be empty" if parts.empty?

          parts.reduce(@root) do |node, part|
            node.children[part] ||= Node.new(nil, {})
          end
        end

        class NestedRegistry
          def initialize(node)
            @node = node
          end

          def register(name, command_class = nil)
            parts = name.to_s.split(" ")
            raise ArgumentError, "Command name cannot be empty" if parts.empty?

            node = parts.reduce(@node) do |current, part|
              current.children[part] ||= Node.new(nil, {})
            end
            node.command = command_class if command_class
            yield NestedRegistry.new(node) if block_given?
            self
          end
        end
      end
    end
  end
end
