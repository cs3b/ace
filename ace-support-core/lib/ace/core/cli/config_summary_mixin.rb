# frozen_string_literal: true

require_relative "../atoms/config_summary"
require_relative "base"

module Ace
  module Core
    module CLI
      module ConfigSummaryMixin
        include Base

        def display_config_summary(command_name, options, summary_keys: nil)
          return if quiet?(options)

          Ace::Core::Atoms::ConfigSummary.display(
            command: command_name,
            config: gem_config,
            defaults: gem_defaults,
            options: options,
            quiet: false,
            summary_keys: summary_keys
          )
        end

        def help_requested?(options)
          help?(options)
        end

        private

        def gem_config
          raise NotImplementedError, "#{self.class} must implement #gem_config"
        end

        def gem_defaults
          raise NotImplementedError, "#{self.class} must implement #gem_defaults"
        end

        module GemClassMixin
          include ConfigSummaryMixin

          private

          def gem_config
            self.class.gem_class.config
          end

          def gem_defaults
            self.class.gem_class.default_config
          end
        end
      end
    end
  end
end
