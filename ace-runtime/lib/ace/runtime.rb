# frozen_string_literal: true

require_relative "runtime/version"
require "ace/support/config"

# Define the error hierarchy before loading components (they raise these)
require_relative "runtime/errors"

require_relative "runtime/atoms/detector"
require_relative "runtime/atoms/name_sanitizer"
require_relative "runtime/atoms/send_contract"
require_relative "runtime/registry"
require_relative "runtime/molecules/runtime_selector"
require_relative "runtime/molecules/process_identity"
require_relative "runtime/molecules/network_installation_evidence"

module Ace
  module Runtime
    class << self
      # Register a duck-typed adapter factory under a runtime name.
      # Adapter packages call this from their
      # lib/ace/runtime/adapters/<name>.rb entrypoint.
      def register(name, factory = nil, &block)
        registry.register(name, factory, &block)
      end

      def registry
        @registry ||= Registry.new
      end

      def reset_registry!
        @registry = Registry.new
      end

      def available
        registry.available
      end

      def registered?(name)
        registry.registered?(name)
      end

      # Resolve a runtime name to a registered adapter. Unknown names
      # fail closed with UnknownRuntimeError listing the available
      # runtimes.
      def resolve(name)
        registry.resolve(name)
      end

      # Side-effect-free detection: :tmux, :herdr, or nil. tmux wins
      # when both environments are live.
      def detect(env: ENV)
        Atoms::Detector.detect(env: env)
      end

      # Shared window/tab naming policy.
      def sanitize_name(name, fallback: Atoms::NameSanitizer::FALLBACK)
        Atoms::NameSanitizer.call(name, fallback: fallback)
      end

      def gem_root
        @gem_root ||= ::Gem.loaded_specs["ace-runtime"]&.gem_dir ||
          File.expand_path("../..", __dir__)
      end

      def debug?
        ENV["ACE_DEBUG"] == "1" || ENV["DEBUG"] == "1"
      end

      # Configured runtime selection (key: `runtime`), merged through the
      # ACE config cascade (project .ace/ > user ~/.ace/ > gem defaults).
      def config
        @config_mutex.synchronize do
          @config ||= load_config
        end
      end

      def reset_config!
        @config_mutex.synchronize do
          @config = nil
        end
      end

      private

      def load_config
        resolver = Ace::Support::Config.create(
          config_dir: ".ace",
          defaults_dir: ".ace-defaults",
          gem_path: gem_root
        )

        resolver.resolve_namespace("runtime").data
      rescue StandardError => e
        warn "ace-runtime: Could not load config: #{e.class} - #{e.message}" if debug?
        {}
      end
    end

    @config_mutex = Mutex.new
  end
end

require_relative "runtime/cli"
