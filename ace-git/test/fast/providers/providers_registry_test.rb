# frozen_string_literal: true

require "test_helper"

module Providers
  class ProvidersRegistryTest < AceGitTestCase
    def teardown
      Ace::Git::Providers.reset!
      super
    end

    def test_registered_provider_is_returned_for_server
      server = Ace::Git::ResolvedServer.new(name: "s", provider: :fakeforge, url: "https://s.example.com")
      provider_class = Class.new(Ace::Git::Providers::Base)
      Ace::Git::Providers.register(:fakeforge, provider_class)

      provider = Ace::Git::Providers.for(server)
      assert_instance_of provider_class, provider
      assert_equal server, provider.server
    end

    def test_for_passes_timeout_and_runner_through
      server = Ace::Git::ResolvedServer.new(name: "s", provider: :fakeforge, url: "https://s.example.com")
      provider_class = Class.new(Ace::Git::Providers::Base) do
        attr_reader :injected_timeout, :injected_runner

        def initialize(server:, timeout: nil, runner: nil)
          super(server: server, timeout: timeout, runner: runner)
          @injected_timeout = timeout
          @injected_runner = runner
        end
      end
      Ace::Git::Providers.register(:fakeforge, provider_class)
      runner = ->(**_kwargs) { {} }

      provider = Ace::Git::Providers.for(server, timeout: 7, runner: runner)
      assert_equal 7, provider.injected_timeout
      assert_equal runner, provider.injected_runner
    end

    def test_for_unknown_provider_type_raises
      server = Ace::Git::ResolvedServer.new(name: "s", provider: :unregistered, url: "https://s.example.com")
      error = assert_raises(Ace::Git::UnknownProviderError) { Ace::Git::Providers.for(server) }
      assert_match(/unregistered/, error.message)
      assert_match(/s/, error.message)
    end

    def test_registered_and_types
      refute Ace::Git::Providers.registered?(:fakeforge)
      Ace::Git::Providers.register(:fakeforge, Class.new(Ace::Git::Providers::Base))
      assert Ace::Git::Providers.registered?(:fakeforge)
      assert_includes Ace::Git::Providers.types, :fakeforge
    end

    def test_register_normalizes_type
      Ace::Git::Providers.register("FakeForge", Class.new(Ace::Git::Providers::Base))
      assert Ace::Git::Providers.registered?(:fakeforge)
    end

    def test_register_rejects_invalid_type
      assert_raises(ArgumentError) { Ace::Git::Providers.register("", Class) }
      assert_raises(ArgumentError) { Ace::Git::Providers.register(nil, Class) }
    end

    def test_register_rejects_non_class
      assert_raises(ArgumentError) { Ace::Git::Providers.register(:fakeforge, "not-a-class") }
    end

    def test_reset_clears_registrations
      Ace::Git::Providers.register(:fakeforge, Class.new(Ace::Git::Providers::Base))
      Ace::Git::Providers.reset!
      refute Ace::Git::Providers.registered?(:fakeforge)
    end
  end
end
