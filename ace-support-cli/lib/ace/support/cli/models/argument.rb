# frozen_string_literal: true

module Ace
  module Support
    module Cli
      module Models
        class Argument
          VALID_TYPES = %i[string integer float boolean array].freeze

          attr_reader :name, :type, :required, :desc

          def initialize(name:, type: :string, required: true, desc: "")
            @name = name.to_sym
            @type = type.to_sym
            @required = required
            @desc = desc
            validate!
          end

          private

          def validate!
            return if VALID_TYPES.include?(type)

            raise ArgumentError, "Invalid argument type: #{type.inspect}"
          end
        end
      end
    end
  end
end
