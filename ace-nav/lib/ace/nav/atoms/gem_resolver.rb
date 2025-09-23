# frozen_string_literal: true

require "rubygems"

module Ace
  module Nav
    module Atoms
      # Discovers ace-* gems and their handbook paths
      class GemResolver
        def find_ace_gems
          ace_gems = []

          Gem::Specification.each do |spec|
            next unless spec.name.start_with?("ace-")

            gem_info = {
              name: spec.name,
              version: spec.version.to_s,
              path: spec.gem_dir,
              handbook_path: File.join(spec.gem_dir, "handbook")
            }

            # Check if handbook exists
            gem_info[:has_handbook] = Dir.exist?(gem_info[:handbook_path])

            ace_gems << gem_info
          end

          ace_gems
        end

        def find_gem_by_name(gem_name)
          spec = Gem::Specification.find_by_name(gem_name)
          return nil unless spec

          {
            name: spec.name,
            version: spec.version.to_s,
            path: spec.gem_dir,
            handbook_path: File.join(spec.gem_dir, "handbook"),
            has_handbook: Dir.exist?(File.join(spec.gem_dir, "handbook"))
          }
        rescue Gem::LoadError
          nil
        end

        def gem_handbook_path(gem_name)
          gem_info = find_gem_by_name(gem_name)
          return nil unless gem_info
          return nil unless gem_info[:has_handbook]

          gem_info[:handbook_path]
        end
      end
    end
  end
end