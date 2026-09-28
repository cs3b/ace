# frozen_string_literal: true

module Ace
  module Runtime
    module Molecules
      # Runtime selection precedence: explicit name > ACE_RUNTIME >
      # configured runtime > side-effect-free environment detection.
      # Resolution happens only after selection. An explicitly selected
      # runtime that turns out unknown or unavailable fails closed via
      # the registry — never headless, never a silent switch to another
      # runtime. Only the assign auto launch mode selects headless
      # outside any runtime; that decision lives above this selector.
      class RuntimeSelector
        ENV_RUNTIME_KEY = "ACE_RUNTIME"

        attr_reader :selected_name

        def initialize(config: nil, registry: nil, env: ENV)
          @config = config
          @registry = registry
          @env = env
          @selected_name = nil
        end

        def resolve(explicit: nil)
          name = select_name(explicit: explicit)

          if name.nil? || name.empty?
            raise RuntimeUnavailableError,
              "no terminal runtime selected: pass --runtime, set #{ENV_RUNTIME_KEY}, " \
              "configure runtime under the ace-runtime config namespace, or run inside tmux/herdr"
          end

          @selected_name = name
          registry.resolve(name)
        end

        private

        attr_reader :config, :env

        def registry
          @registry || Ace::Runtime.registry
        end

        def select_name(explicit:)
          name = explicit.to_s.strip
          name = env_value(ENV_RUNTIME_KEY) if name.empty?
          name = configured_runtime if name.empty?
          name = detected_name if name.empty?

          name
        end

        def env_value(key)
          env[key].to_s.strip
        end

        def configured_runtime
          return "" unless config.is_a?(Hash)

          value = config.key?("runtime") ? config["runtime"] : config[:runtime]
          value.to_s.strip
        end

        def detected_name
          detected = Atoms::Detector.detect(env: env)
          detected ? detected.to_s : ""
        end
      end
    end
  end
end
