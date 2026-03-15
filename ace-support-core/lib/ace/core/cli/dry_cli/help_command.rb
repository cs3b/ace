# frozen_string_literal: true

require_relative "../help_command"

module Ace
  module Core
    module CLI
      module DryCli
        HelpCommand = ::Ace::Core::CLI::HelpCommand unless const_defined?(:HelpCommand, false)
      end
    end
  end
end
