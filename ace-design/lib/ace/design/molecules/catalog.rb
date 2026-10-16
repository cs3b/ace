# frozen_string_literal: true
require "date"
module Ace
  module Design
    module Molecules
      class Catalog
        REQUIRED = %w[id surface title use_when avoid_when source verified_at].freeze
        def validate(path)
          files = Dir.glob(File.join(path, "**/*.md")).sort
          raise Error, "Catalog contains no cards: #{path}" if files.empty?
          errors = []
          ids = []
          files.each do |file|
            begin
              content = File.read(file)
              match = content.match(/\A---\s*\n(.*?)\n---\s*\n(.*)\z/m)
              raise Error, "missing frontmatter or body" unless match && !match[2].strip.empty?
              card = YAML.safe_load(match[1], permitted_classes: [Date])
              raise Error, "frontmatter must be a mapping" unless card.is_a?(Hash)
              REQUIRED.each { |key| raise Error, "missing #{key}" if card[key].nil? || card[key].to_s.strip.empty? }
              (REQUIRED - ["verified_at"]).each { |key| Atoms::Contracts.text(card[key], key) }
              raise Error, "invalid surface" unless %w[shared site app].include?(card["surface"])
              raise Error, "duplicate id #{card['id']}" if ids.include?(card["id"])
              ids << card["id"]
              Atoms::Contracts.url(card["source"])
              Date.iso8601(card["verified_at"].to_s)
            rescue Error, Psych::Exception, Date::Error => e
              errors << "#{file}: #{e.message}"
            end
          end
          {"cards" => files.length, "errors" => errors}
        end
      end
    end
  end
end
