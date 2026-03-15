# frozen_string_literal: true

require_relative "../standard_options"

module Ace
  module Core
    module CLI
      module DryCli
        StandardOptions = ::Ace::Core::CLI::StandardOptions unless const_defined?(:StandardOptions, false)
      end
    end
  end
end
