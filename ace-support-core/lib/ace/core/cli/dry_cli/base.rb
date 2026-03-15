# frozen_string_literal: true

require_relative "../base"

module Ace
  module Core
    module CLI
      module DryCli
        Base = ::Ace::Core::CLI::Base unless const_defined?(:Base, false)
      end
    end
  end
end
