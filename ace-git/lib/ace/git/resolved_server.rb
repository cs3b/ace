# frozen_string_literal: true

module Ace
  module Git
    # An exactly-resolved forge server identity.
    #
    # Produced by ServerRegistry (by explicit name, by default resolution, or by
    # remote URL matching). Carries the configured server name, the provider
    # type that owns its behavior, and the configured base URL.
    #
    # @example
    #   ResolvedServer.new(name: "forge-lab", provider: :acme, url: "https://forge.example.com")
    ResolvedServer = Data.define(:name, :provider, :url) do
      # @return [Hash] Plain hash representation
      def to_h
        {name: name, provider: provider, url: url}
      end
    end
  end
end
