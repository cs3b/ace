# frozen_string_literal: true

module CodingAgentTools
  module Organisms
    module CodeQuality
      # Base class for language-specific code quality runners
      class LanguageRunner
        attr_reader :config, :path_resolver, :language

        def initialize(config:, path_resolver:, language:)
          @config = config
          @path_resolver = path_resolver
          @language = language
        end

        def validate(paths: ["."], **options)
          raise NotImplementedError, "Subclasses must implement validate method"
        end

        def autofix(paths: ["."], **options)
          raise NotImplementedError, "Subclasses must implement autofix method"
        end

        def report(results)
          raise NotImplementedError, "Subclasses must implement report method"
        end

        protected

        def language_config
          @config[language.to_s] || {}
        end

        def language_enabled?
          language_config["enabled"] == true
        end
      end
    end
  end
end
