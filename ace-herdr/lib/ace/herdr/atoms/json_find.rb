# frozen_string_literal: true

module Ace
  module Herdr
    module Atoms
      # Shared recursive extraction from herdr's native JSON responses
      # (ids nest under result.*; native shapes vary slightly between
      # commands). Pure functions — no side effects.
      module JsonFind
        module_function

        # Walk a path of hash keys; nil unless every hop is a Hash. A hop
        # resolves only to a non-empty String.
        def dig_value(json, path)
          current = json
          path.each do |key|
            return nil unless current.is_a?(Hash)

            current = current[key]
          end
          current.is_a?(String) && !current.empty? ? current : nil
        end

        # Depth-first search for the first non-empty String under any of
        # the given keys (tolerant extraction of ids from native shapes).
        def find_value(json, keys)
          case json
          when Hash
            keys.each { |key| return json[key] if json[key].is_a?(String) && !json[key].empty? }
            json.each_value do |value|
              found = find_value(value, keys)
              return found if found
            end
            nil
          when Array
            json.each do |value|
              found = find_value(value, keys)
              return found if found
            end
            nil
          end
        end
      end
    end
  end
end
