# frozen_string_literal: true

module Ace
  module Runtime
    # Duck-typed adapter registry (ace-hitl Providers pattern). Runtime
    # adapters register a factory under a simple name; resolution is
    # fail-closed: an unknown name raises UnknownRuntimeError carrying
    # the sorted available list. There is no base class — an adapter is
    # whatever object implements the published intent operations.
    class Registry
      # Only identifier-shaped names may trigger the convention-based
      # entrypoint load, so a hostile runtime name can never traverse
      # the Ruby load path.
      NAME_PATTERN = /\A[a-z][a-z0-9_]*\z/

      ADAPTER_ENTRYPOINT_FORMAT = "ace/runtime/adapters/%s"

      def initialize
        @factories = {}
      end

      def register(name, factory = nil, &block)
        key = name.to_s
        callable = factory || block
        raise ArgumentError, "adapter factory for '#{key}' must respond to #call" unless callable.respond_to?(:call)

        @factories[key] = callable
        nil
      end

      def registered?(name)
        @factories.key?(name.to_s)
      end

      def available
        @factories.keys.sort
      end

      def resolve(name)
        key = name.to_s
        load_adapter_entrypoint(key) unless @factories.key?(key)

        factory = @factories[key]
        raise UnknownRuntimeError.new(requested: key, available: available) unless factory

        factory.call
      end

      private

      # Convention: adapter packages ship a lib/ace/runtime/adapters/<name>.rb
      # entrypoint that calls Ace::Runtime.register. It is attempted
      # lazily on first resolve so the contract gem keeps no dependency
      # on either adapter package; a LoadError simply means the adapter
      # is not installed.
      def load_adapter_entrypoint(name)
        return unless name.match?(NAME_PATTERN)

        require format(ADAPTER_ENTRYPOINT_FORMAT, name)
      rescue LoadError
        nil
      end
    end
  end
end
