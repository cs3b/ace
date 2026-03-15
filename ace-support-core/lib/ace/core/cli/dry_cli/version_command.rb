# frozen_string_literal: true

require_relative "../version_command"

module Ace
  module Core
    module CLI
      module DryCli
        VersionCommand = ::Ace::Core::CLI::VersionCommand unless const_defined?(:VersionCommand, false)
      end
    end
  end
end
