# frozen_string_literal: true

require "ace/core"
require_relative "llm/version"

module Ace
  module LLM
    class Error < StandardError; end
    class ProviderError < Error; end
    class ConfigurationError < Error; end
    class AuthenticationError < Error; end

    # Autoloader configuration
    def self.setup_autoloader
      @loader ||= begin
        loader = Zeitwerk::Loader.for_gem_extension(Ace::LLM)

        # Configure inflections for technical acronyms
        loader.inflector.inflect(
          "llm" => "LLM",
          "xdg" => "XDG",
          "http" => "HTTP",
          "api" => "API",
          "json" => "JSON",
          "openai" => "OpenAI",
          "lmstudio" => "LMStudio",
          "togetherai" => "TogetherAI"
        )

        loader.push_dir(File.expand_path("llm", __dir__))
        loader.ignore("#{__dir__}/llm/version.rb")
        loader
      end
    end

    def self.load!
      setup_autoloader.setup
    end

    def self.eager_load!
      setup_autoloader.eager_load
    end
  end
end

# Load the gem
Ace::LLM.load!