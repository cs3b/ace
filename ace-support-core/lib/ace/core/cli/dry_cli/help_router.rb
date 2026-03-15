# frozen_string_literal: true

require_relative "../help_router"

module Ace
  module Core
    module CLI
      module DryCli
        HelpRouter = ::Ace::Core::CLI::HelpRouter unless const_defined?(:HelpRouter, false)
      end
    end
  end
end
