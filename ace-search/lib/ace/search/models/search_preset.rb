# frozen_string_literal: true

module Ace
  module Search
    module Models
      # SearchPreset represents a named search configuration
      # This is a model - pure data structure
      class SearchPreset
        attr_reader :name, :description, :options

        def initialize(name, description: nil, **options)
          @name = name
          @description = description
          @options = options
        end

        def to_h
          {
            name: @name,
            description: @description
          }.merge(@options)
        end

        def self.from_hash(data)
          name = data[:name] || data["name"]
          description = data[:description] || data["description"]
          options = data.reject { |k, _v| [:name, :description, "name", "description"].include?(k) }

          new(name, description: description, **options)
        end
      end
    end
  end
end
