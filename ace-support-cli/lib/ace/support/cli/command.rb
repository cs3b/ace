# frozen_string_literal: true

require_relative "models/option"
require_relative "models/argument"

module Ace
  module Support
    module Cli
      class Command
        class << self
          attr_reader :description

          def inherited(subclass)
            super
            subclass.instance_variable_set(:@description, description)
            subclass.instance_variable_set(:@options, options.dup)
            subclass.instance_variable_set(:@arguments, arguments.dup)
            subclass.instance_variable_set(:@examples, examples.dup)
          end

          def desc(text)
            @description = text
          end

          def option(name, type: :string, default: nil, desc: "", aliases: [], values: nil, required: false, **_extra)
            @options ||= []
            @options << Models::Option.new(
              name: name,
              type: type,
              default: default,
              desc: desc,
              aliases: aliases,
              values: values,
              required: required
            )
          end

          def argument(name, type: :string, required: true, desc: "")
            @arguments ||= []
            @arguments << Models::Argument.new(name: name, type: type, required: required, desc: desc)
          end

          def example(lines)
            @examples ||= []
            @examples.concat(Array(lines).map(&:to_s))
          end

          def options
            @options ||= []
          end

          def arguments
            @arguments ||= []
          end

          def examples
            @examples ||= []
          end
        end

        def call(**_params)
          raise NotImplementedError, "#{self.class} must implement #call"
        end
      end
    end
  end
end
