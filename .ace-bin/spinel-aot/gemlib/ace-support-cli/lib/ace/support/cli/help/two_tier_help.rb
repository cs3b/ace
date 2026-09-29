# frozen_string_literal: true

module Ace
  module Support
    module Cli
      module Help
        module TwoTierHelp
          def self.concise?(args)
            values = Array(args)
            values.include?("-h") && !values.include?("--help")
          end

          def self.render(command, name, args:)
            if concise?(args)
              Concise.call(command, name)
            else
              Banner.call(command, name)
            end
          end
        end
      end
    end
  end
end
