# frozen_string_literal: true

require_relative "../default_routing"

module Ace
  module Core
    module CLI
      module DryCli
        DefaultRouting = ::Ace::Core::CLI::DefaultRouting unless const_defined?(:DefaultRouting, false)
      end
    end
  end
end
