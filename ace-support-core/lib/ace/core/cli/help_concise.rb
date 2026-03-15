# frozen_string_literal: true

require "ace/support/cli"

module Ace
  module Core
    module CLI
      module HelpConcise
        def self.call(command, name)
          Ace::Support::Cli::HelpConcise.call(command, name)
        end
      end
    end
  end
end
