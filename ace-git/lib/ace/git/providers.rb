# frozen_string_literal: true

require_relative "errors"
require_relative "providers/base"
require_relative "providers/evidence"

module Ace
  module Git
    # Registry of provider implementations owned by provider packages.
    #
    # The core never executes provider CLIs. Provider packages (ace-git-github,
    # ace-git-forgejo) register their contract implementation here when loaded;
    # higher-level consumers then obtain a provider through {Providers.for}.
    #
    # @example Registering (inside a provider package)
    #   Ace::Git::Providers.register(:github, Ace::Git::Github::Provider)
    #
    # @example Resolving (in consumers)
    #   server = Ace::Git::ServerRegistry.resolve_default
    #   provider = Ace::Git::Providers.for(server)
    #   pr = provider.pull_request(number: 25)
    module Providers
      @registry = {}
      @mutex = Mutex.new

      class << self
        # Register a provider implementation for a provider type.
        #
        # @param type [Symbol, String] provider type (e.g. :github, :forgejo)
        # @param provider_class [Class] class implementing Providers::Base;
        #   must respond to .new
        # @raise [ArgumentError] when type or provider_class is invalid
        def register(type, provider_class)
          key = normalize_type(type)
          unless provider_class.respond_to?(:new)
            raise ArgumentError, "Provider for #{key.inspect} must be a class (got #{provider_class.inspect})"
          end

          @mutex.synchronize { @registry[key] = provider_class }
          provider_class
        end

        # Build the provider implementation for a resolved server.
        #
        # @param server [ResolvedServer] exactly-resolved server identity
        # @param timeout [Integer, nil] provider operation timeout in seconds
        # @param runner [Proc, nil] optional command runner injection for tests;
        #   see Providers::Base
        # @return [Providers::Base] provider instance bound to the server
        # @raise [UnknownProviderError] when no provider is registered for the
        #   server's provider type
        def for(server, timeout: nil, runner: nil)
          key = normalize_type(server.provider)
          provider_class = @mutex.synchronize { @registry[key] }
          unless provider_class
            raise UnknownProviderError,
              "No provider registered for type #{key.inspect} (server '#{server.name}'); " \
              "install and require the provider package that owns #{key.inspect}"
          end

          provider_class.new(server: server, timeout: timeout, runner: runner)
        end

        # @param type [Symbol, String] provider type
        # @return [Boolean] true when a provider is registered for the type
        def registered?(type)
          key = normalize_type(type)
          @mutex.synchronize { @registry.key?(key) }
        end

        # @return [Array<Symbol>] registered provider types, sorted
        def types
          @mutex.synchronize { @registry.keys.sort }
        end

        # Clear all registrations (test seam).
        def reset!
          @mutex.synchronize { @registry.clear }
        end

        private

        def normalize_type(type)
          normalized = type.to_s.strip.downcase
          raise ArgumentError, "Provider type must be a non-empty symbol or string" if normalized.empty?

          normalized.to_sym
        end
      end
    end
  end
end
