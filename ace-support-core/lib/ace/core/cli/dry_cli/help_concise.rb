# frozen_string_literal: true

require_relative "../help_concise"

module Ace
  module Core
    module CLI
      module DryCli
        HelpConcise = ::Ace::Core::CLI::HelpConcise unless const_defined?(:HelpConcise, false)
      end
    end
  end
end
