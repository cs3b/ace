# frozen_string_literal: true

require_relative "../command_groups"

module Ace
  module Core
    module CLI
      module DryCli
        CommandGroups = ::Ace::Core::CLI::CommandGroups unless const_defined?(:CommandGroups, false)
      end
    end
  end
end
