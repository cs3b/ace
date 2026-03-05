# frozen_string_literal: true

module Ace
  module Demo
    module Atoms
      module DemoNameSanitizer
        MAX_LENGTH = 55
        module_function

        def sanitize(name)
          slug = name.to_s.downcase
                     .gsub(/[^a-z0-9\-]/, "-")
                     .gsub(/-+/, "-")
                     .gsub(/\A-+|-+\z/, "")
          slug = slug[0, MAX_LENGTH].sub(/-+\z/, "") if slug.length > MAX_LENGTH
          slug.empty? ? "demo" : slug
        end
      end
    end
  end
end
