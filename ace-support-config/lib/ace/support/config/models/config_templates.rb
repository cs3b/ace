# frozen_string_literal: true

require "pathname"
require "rubygems"

module Ace
  module Support
    module Config
      module Models
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

              path = (info[:source] == :gem) ? info[:path] : (info[:path] || info[:gem_path])
              resolve_defaults_dir(path)
            end

            def gem_info
              @gem_info ||= build_gem_info
            end

            def build_gem_info
              gems = {}

              parent_dir = File.expand_path("../../../../../../../", __FILE__)
              Dir.glob("#{parent_dir}/ace-*").each do |dir|
                next unless File.directory?(dir)

                gem_name = File.basename(dir)
                gems[gem_name] = {source: :local, path: dir} if has_example_dir?(dir)
              end

              begin
                Gem::Specification.each do |spec|
                  next unless spec.name.start_with?("ace-")

                  gem_path = spec.gem_dir
                  next unless has_example_dir?(gem_path)

                  if gems.key?(spec.name)
                    gems[spec.name][:source] = :both
                    gems[spec.name][:gem_path] = gem_path
                  else
                    gems[spec.name] = {source: :gem, path: gem_path}
                  end
                end
              rescue StandardError
                # Fall back to local gems only when RubyGems traversal is unavailable.
              end

              gems
            end

            def docs_file_for(gem_name)
              info = gem_info[gem_name]
              return nil unless info

              path = (info[:source] == :gem) ? info[:path] : (info[:path] || info[:gem_path])
              File.join(path, "docs", "config.md")
            end

            private

            def resolve_defaults_dir(gem_path)
              File.join(gem_path, ".ace-defaults")
            end

            def has_example_dir?(gem_dir)
              Dir.exist?(File.join(gem_dir, ".ace-defaults"))
            end
          end
        end
      end
    end
  end
end
