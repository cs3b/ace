# frozen_string_literal: true

module Ace
  module Support
    module Cli
      module Models
        class Option
          VALID_TYPES = %i[string integer float boolean array hash].freeze

          attr_reader :name, :type, :default, :desc, :aliases, :values, :required

          def initialize(name:, type: :string, default: nil, desc: "", aliases: [], values: nil, required: false)
            @name = name.to_sym
            @type = type.to_sym
            @default = default
            @desc = desc
            @aliases = normalize_aliases(Array(aliases))
            @values = values
            @required = required
            validate!
          end

          def long_switch
            "--#{name.to_s.tr('_', '-')}"
          end

          private

          def validate!
            return if VALID_TYPES.include?(type)

            raise ArgumentError, "Invalid option type: #{type.inspect}"
          end

          def normalize_aliases(aliases)
            aliases.map do |entry|
              alias_name = entry.to_s
              if alias_name.start_with?("-")
                alias_name
              elsif alias_name.length == 1
                "-#{alias_name}"
              else
                "--#{alias_name.tr('_', '-')}"
              end
            end
          end
        end
      end
    end
  end
end
