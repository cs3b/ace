# frozen_string_literal: true

module CodingAgentTools
  module Models
    # Model for linting configuration
    LintingConfig = Struct.new(
      :ruby,
      :markdown,
      :error_distribution,
      :global_settings,
      keyword_init: true
    ) do
      def initialize(*)
        super
        self.ruby ||= default_ruby_config
        self.markdown ||= default_markdown_config
        self.error_distribution ||= default_error_distribution
        self.global_settings ||= {}
      end

      def enabled_linters
        linters = []

        if ruby[:enabled]
          ruby[:linters].each do |name, config|
            linters << "ruby_#{name}" if config[:enabled]
          end
        end

        if markdown[:enabled]
          markdown[:linters].each do |name, config|
            linters << "markdown_#{name}" if config[:enabled]
          end
        end

        linters
      end

      private

      def default_ruby_config
        {
          enabled: true,
          linters: {
            standardrb: { enabled: true, autofix: true },
            security: { enabled: true },
            cassettes: { enabled: true }
          }
        }
      end

      def default_markdown_config
        {
          enabled: true,
          linters: {
            styleguide: { enabled: true, autofix: true },
            link_validation: { enabled: true },
            template_embedding: { enabled: true },
            task_metadata: { enabled: true }
          }
        }
      end

      def default_error_distribution
        {
          enabled: true,
          max_files: 4,
          one_issue_per_file: true
        }
      end
    end
  end
end
