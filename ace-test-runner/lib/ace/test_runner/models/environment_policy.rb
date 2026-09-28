# frozen_string_literal: true

module Ace
  module TestRunner
    # Deterministic setup failure: names the missing or invalid key, never its value.
    class EnvironmentSetupError < Error; end

    module Models
      # Immutable declaration of the hermetic subprocess environment contract.
      #
      # Deterministic test children start from an empty environment and receive only:
      # - preserved toolchain/process keys (PATH, locale, temp directories)
      # - fixture-owned HOME/XDG replacements (applied by Molecules::FixtureEnvironment)
      # - explicit fixture overrides supplied through runner configuration
      #
      # Everything else - ambient LAB_* and ACE_* runtime/provider configuration,
      # credentials, sockets, proxy and project-selection variables - never reaches
      # a deterministic test child.
      class EnvironmentPolicy
        # Toolchain/process keys preserved from the parent environment.
        PRESERVED_KEYS = %w[PATH LANG LC_ALL TMPDIR TMP TEMP].freeze

        # Key prefixes never allowed in deterministic children or preserve lists.
        BLOCKED_PREFIXES = %w[
          ACE_ ANTHROPIC_ AWS_ AZURE_ BUNDLE_ COHERE_ DEEPSEEK_ FIREWORKS_ GEM_
          GEMINI_ GLM_ GOOGLE_ GROQ_ HF_ HUGGINGFACE_ LAB_ MISTRAL_ MOONSHOT_
          OPENAI_ OPENROUTER_ TOGETHER_ XAI_ ZAI_ ZHIPU_
        ].freeze

        # Exact keys never allowed in deterministic children or preserve lists.
        BLOCKED_KEYS = %w[
          ALL_PROXY BASH_ENV DATABASE_URL DOCKER_HOST ENV GITHUB_TOKEN
          GITLAB_TOKEN HTTP_PROXY HTTPS_PROXY NO_PROXY PYTHONPATH
          PYTHONSTARTUP RUBYLIB RUBYOPT SSH_AUTH_SOCK
          all_proxy http_proxy https_proxy no_proxy
        ].freeze

        # Keys replaced with fixture-owned directories instead of parent values.
        FIXTURE_HOME_KEYS = %w[HOME XDG_CONFIG_HOME XDG_CACHE_HOME XDG_DATA_HOME].freeze

        attr_reader :preserved_keys, :blocked_prefixes, :blocked_keys,
          :fixture_home_keys, :overrides, :required_keys

        def initialize(preserved_keys: PRESERVED_KEYS, blocked_prefixes: BLOCKED_PREFIXES,
          blocked_keys: BLOCKED_KEYS, fixture_home_keys: FIXTURE_HOME_KEYS,
          overrides: {}, required_keys: [])
          @preserved_keys = preserved_keys.map(&:to_s).freeze
          @blocked_prefixes = blocked_prefixes.map(&:to_s).freeze
          @blocked_keys = blocked_keys.map(&:to_s).freeze
          @fixture_home_keys = fixture_home_keys.map(&:to_s).freeze
          @overrides = overrides.each_with_object({}) { |(key, value), hash| hash[key.to_s] = value.to_s }.freeze
          @required_keys = required_keys.map(&:to_s).freeze
          validate_contract!
        end

        # Build a policy from runner or suite configuration:
        #
        #   environment:
        #     preserve: [EXTRA_TOOLCHAIN_KEY]
        #     overrides:
        #       MY_ENDPOINT: "http://127.0.0.1:1"
        #     require: [MY_ENDPOINT]
        def self.from_config(config)
          normalized = (config || {}).transform_keys(&:to_sym)
          new(
            preserved_keys: PRESERVED_KEYS + Array(normalized[:preserve]),
            overrides: normalized[:overrides] || {},
            required_keys: Array(normalized[:require])
          )
        end

        def preserved_key?(key)
          @preserved_keys.include?(key)
        end

        def blocked_key?(key)
          @blocked_keys.include?(key) || @blocked_prefixes.any? { |prefix| key.start_with?(prefix) }
        end

        def credential_like?(key)
          key.match?(/token|secret|password|passwd|credential|api_?key|_key\z|private_?key|_sock(?:et)?\z|_url\z|_endpoint\z/i)
        end

        # Diagnostic-safe value for a key; credential-like values are never exposed.
        def redacted_value(key, value)
          credential_like?(key) ? "[redacted]" : value
        end

        private

        def validate_contract!
          @preserved_keys.each do |key|
            next unless blocked_key?(key)

            raise EnvironmentSetupError,
              "Environment policy: cannot preserve blocked ambient key '#{key}'"
          end

          @required_keys.each do |key|
            next unless key.empty?

            raise EnvironmentSetupError, "Environment policy: required key names must not be empty"
          end
        end
      end
    end
  end
end
