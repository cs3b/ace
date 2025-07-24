# frozen_string_literal: true

require_relative "ruby_runner"
require_relative "markdown_runner"

module CodingAgentTools
  module Organisms
    module CodeQuality
      # Factory for creating language-specific runners
      class LanguageRunnerFactory
        class << self
          def create_runner(language, config:, path_resolver:)
            case language.to_s.downcase
            when "ruby"
              RubyRunner.new(config: config, path_resolver: path_resolver)
            when "markdown"
              MarkdownRunner.new(config: config, path_resolver: path_resolver)
            else
              raise ArgumentError, "Unsupported language: #{language}"
            end
          end

          def create_all_runners(config:, path_resolver:)
            {
              ruby: RubyRunner.new(config: config, path_resolver: path_resolver),
              markdown: MarkdownRunner.new(config: config, path_resolver: path_resolver)
            }
          end

          def supported_languages
            %w[ruby markdown]
          end

          def language_supported?(language)
            supported_languages.include?(language.to_s.downcase)
          end
        end
      end
    end
  end
end