# frozen_string_literal: true

module Ace
  module Support
    module Config
      module Molecules
        # Scan project tree downward to find all config folders (.ace)
        #
        # Complements ConfigFinder's upward traversal by scanning the entire project
        # tree for all config directories. Useful for monorepos where multiple packages
        # have distributed configurations.
        #
        # @example Scan all .ace folders
        #   scanner = ProjectConfigScanner.new(project_root: Dir.pwd)
        #   scanner.scan
        #   # => { "." => ["git/commit.yml"], "ace-bundle" => ["git/commit.yml"] }
        #
        # @example Find specific config across project
        #   scanner.find_all(namespace: "git", filename: "commit")
        #   # => { "." => "/project/.ace/git/commit.yml" }
        class ProjectConfigScanner
          # Directories to skip during traversal
          SKIP_DIRS = %w[.git .cache vendor node_modules tmp coverage].freeze

          # @param project_root [String, nil] Root directory to scan (default: Dir.pwd)
          # @param config_dir [String] Config folder name (default: ".ace")
          def initialize(project_root: nil, config_dir: ".ace")
            @project_root = File.expand_path(project_root || Dir.pwd)
            @config_dir = config_dir
          end

          # Scan project tree for all config folders and their files
          #
          # @return [Hash{String => Array<String>}] Map of relative location => config file list
          def scan
            return {} unless Dir.exist?(@project_root)

            result = {}

            find_ace_dirs.each do |ace_dir_abs|
              location = relative_location(ace_dir_abs)
              result[location] = enumerate_config_files(ace_dir_abs)
            end

            result
          end

          # Find all instances of a specific config file across the project
          #
          # @param namespace [String] Config namespace (e.g., "git")
          # @param filename [String] Config filename without extension (e.g., "commit")
          # @return [Hash{String => String}] Map of relative location => absolute file path
          def find_all(namespace:, filename:)
            result = {}

            scan.each do |location, files|
              yml_target = "#{namespace}/#{filename}.yml"
              yaml_target = "#{namespace}/#{filename}.yaml"

              matched = if files.include?(yml_target)
                          yml_target
                        elsif files.include?(yaml_target)
                          yaml_target
                        end

              next unless matched

              ace_dir = location_to_ace_dir(location)
              result[location] = File.join(ace_dir, matched)
            end

            result
          end

          private

          # Find all .ace directories in the project tree
          def find_ace_dirs
            dirs = []

            # Check root config dir first
            root_ace = File.join(@project_root, @config_dir)
            dirs << root_ace if Dir.exist?(root_ace)

            # Find nested config dirs (Dir.glob with FNM_DOTMATCH to match hidden dirs)
            begin
              Dir.glob("**/#{@config_dir}", base: @project_root, flags: File::FNM_DOTMATCH).sort.each do |rel|
                next if rel == @config_dir # already handled root
                next if skip_path?(rel)

                abs = File.join(@project_root, rel)
                dirs << abs if Dir.exist?(abs)
              end
            rescue Errno::EACCES
              # Permission denied on some path - return what we have
            end

            dirs
          end

          # Enumerate config files within an .ace directory
          def enumerate_config_files(ace_dir_abs)
            return [] unless Dir.exist?(ace_dir_abs)

            begin
              Dir.glob("**/*", base: ace_dir_abs).select do |f|
                File.file?(File.join(ace_dir_abs, f))
              end.sort
            rescue Errno::EACCES
              []
            end
          end

          # Convert absolute .ace dir path to relative location key
          def relative_location(ace_dir_abs)
            parent = File.dirname(ace_dir_abs)
            rel = parent.delete_prefix(@project_root).delete_prefix("/")
            rel.empty? ? "." : rel
          end

          # Convert relative location key back to absolute .ace dir path
          def location_to_ace_dir(location)
            if location == "."
              File.join(@project_root, @config_dir)
            else
              File.join(@project_root, location, @config_dir)
            end
          end

          # Check if a relative path should be skipped
          def skip_path?(rel_path)
            components = rel_path.split(File::SEPARATOR)
            components.any? { |c| SKIP_DIRS.include?(c) }
          end
        end
      end
    end
  end
end
