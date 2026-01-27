# frozen_string_literal: true

require "json"
require "digest"

module Ace
  module GitCommit
    module Models
      # CommitGroup represents a group of files that share the same effective config
      class CommitGroup
        attr_reader :scope_name, :source, :config, :files

        def initialize(scope_name:, source:, config:, files: [])
          @scope_name = scope_name
          @source = source
          @config = config || {}
          @files = Array(files)
        end

        def add_file(file)
          @files << file
          self
        end

        def file_count
          @files.length
        end

        def config_signature
          self.class.signature_for(@config)
        end

        def self.signature_for(config)
          normalized = normalize_config(config || {})
          Digest::SHA256.hexdigest(JSON.generate(normalized))
        end

        def self.normalize_config(value)
          case value
          when Hash
            value.keys.sort.each_with_object({}) do |key, acc|
              acc[key.to_s] = normalize_config(value[key])
            end
          when Array
            value.map { |item| normalize_config(item) }
          else
            value
          end
        end
      end
    end
  end
end
