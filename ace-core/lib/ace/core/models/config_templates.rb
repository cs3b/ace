# frozen_string_literal: true

require "pathname"

module Ace
  module Core
    class ConfigTemplates
      class << self
        def all_gems
          # Discover all ace-* gems by looking for directories
          gem_dirs = []

          # Look in the parent directory of ace-core
          parent_dir = File.expand_path("../../../../../../", __FILE__)

          Dir.glob("#{parent_dir}/ace-*").each do |dir|
            next unless File.directory?(dir)
            gem_name = File.basename(dir)
            gem_dirs << gem_name if has_example_dir?(dir)
          end

          gem_dirs.sort
        end

        def gem_exists?(gem_name)
          parent_dir = File.expand_path("../../../../../../", __FILE__)
          gem_dir = File.join(parent_dir, gem_name)
          File.directory?(gem_dir) && has_example_dir?(gem_dir)
        end

        def example_dir_for(gem_name)
          parent_dir = File.expand_path("../../../../../../", __FILE__)
          gem_dir = File.join(parent_dir, gem_name)
          File.join(gem_dir, "ace.example")
        end

        def docs_file_for(gem_name)
          parent_dir = File.expand_path("../../../../../../", __FILE__)
          gem_dir = File.join(parent_dir, gem_name)
          File.join(gem_dir, "docs", "config.md")
        end

        private

        def has_example_dir?(gem_dir)
          example_dir = File.join(gem_dir, "ace.example")
          File.directory?(example_dir)
        end
      end
    end
  end
end