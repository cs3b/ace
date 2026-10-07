# frozen_string_literal: true
require "ace/git/atoms/delivery_parameters"

module Ace
  module Assign
    module Atoms
      # Assignment configuration consumes the shared forge-neutral owner.
      module DeliveryParameters
        def self.validate(input)
          Ace::Git::Atoms::DeliveryParameters.validate(input)
        end

        def self.validate_url!(url)
          Ace::Git::Atoms::DeliveryParameters.validate_url!(url)
        end
      end
    end
  end
end
