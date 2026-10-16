# frozen_string_literal: true
require "uri"
module Ace
  module Design
    module Atoms
      module Contracts
        module_function
        def surface(value)
          raise Error, "surface must be site or app" unless %w[site app].include?(value)
          value
        end
        def kind(value)
          raise Error, "kind must be view or component" unless %w[view component].include?(value)
          value
        end
        def url(value)
          parsed = URI.parse(value.to_s)
          unless %w[http https].include?(parsed.scheme) && !parsed.host.to_s.empty? && !parsed.userinfo
            raise Error, "URL must be http(s), with a host and no embedded credentials"
          end
          value
        rescue URI::InvalidURIError
          raise Error, "URL must be a valid http(s) address"
        end
        def object(value, name)
          raise Error, "#{name} must be a JSON object" unless value.is_a?(Hash)
          value
        end
        def text(value, name)
          raise Error, "#{name} must be nonempty text" unless value.is_a?(String) && !value.strip.empty?
          value
        end
      end
    end
  end
end
