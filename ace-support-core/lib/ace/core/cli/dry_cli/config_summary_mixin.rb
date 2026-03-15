# frozen_string_literal: true

require_relative "../config_summary_mixin"

module Ace
  module Core
    module CLI
      module DryCli
        ConfigSummaryMixin = ::Ace::Core::CLI::ConfigSummaryMixin unless const_defined?(:ConfigSummaryMixin, false)
      end
    end
  end
end
