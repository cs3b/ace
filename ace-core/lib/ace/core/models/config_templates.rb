# frozen_string_literal: true

require "pathname"
require "rubygems"

module Ace
  module Core
    class ConfigTemplates
      class << self
        def all_gems
          gem_info.keys.sort
        end

        def gem_exists?(gem_name)
          gem_info.key?(gem_name)
        end

        def example_dir_for(gem_name)
          info = gem_info[gem_name]
          return nil unless info

          # Prefer local path for development
          path = info[:source] == :gem ? info[:path] : (info[:path] || info[:gem_path])
          File.join(path, "ace.example")
        end

        def gem_info
          @gem_info ||= build_gem_info
        end

        def build_gem_info
          gems = {}

          # 1. Look in the parent directory (monorepo/development)
          parent_dir = File.expand_path("../../../../../../", __FILE__)
          Dir.glob("#{parent_dir}/ace-*").each do |dir|
            next unless File.directory?(dir)
            gem_name = File.basename(dir)
            if has_example_dir?(dir)
              gems[gem_name] = { source: :local, path: dir }
            end
          end

          # 2. Look for installed RubyGems
          begin
            Gem::Specification.each do |spec|
              next unless spec.name.start_with?("ace-")

              gem_path = spec.gem_dir
              if has_example_dir?(gem_path)
                if gems.key?(spec.name)
                  gems[spec.name][:source] = :both
                  gems[spec.name][:gem_path] = gem_path
                else
                  gems[spec.name] = { source: :gem, path: gem_path }
                end
              end
            end
          rescue StandardError
            # If we can't access installed gems, just use local ones
          end

          gems
        end

        def docs_file_for(gem_name)
          info = gem_info[gem_name]
          return nil unless info

          # Prefer local path for development
          path = info[:source] == :gem ? info[:path] : (info[:path] || info[:gem_path])
          File.join(path, "docs", "config.md")
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