# frozen_string_literal: true

module Ace
  module Nav
    module Models
      # Represents a source registration for a protocol
      class ProtocolSource
        attr_reader :name, :type, :path, :priority, :description, :origin, :config_file, :alias_name, :config_dir

        def initialize(name:, type:, path:, priority:, description: nil, origin: nil, config_file: nil, config_dir: nil)
          @name = name
          @type = type
          @path = path
          @priority = priority
          @description = description
          @origin = origin
          @config_file = config_file
          @config_dir = config_dir
          @alias_name = "@#{name}"
        end

        # Get the full path for this source
        def full_path
          # If path is already absolute, use it
          if path.start_with?('/')
            path
          elsif config_dir && path.start_with?('.ace/')
            # For .ace/ relative paths, resolve from the parent of the .ace where config was found
            # config_dir is like /path/to/project/.ace/protocols/wfi-sources/local.yml
            # We want to go up to /path/to/project/ and then add the path
            ace_dir = config_dir
            while ace_dir && !ace_dir.end_with?('/.ace')
              parent = File.dirname(ace_dir)
              break if parent == ace_dir  # Reached root
              ace_dir = parent
            end

            if ace_dir && ace_dir.end_with?('/.ace')
              project_dir = File.dirname(ace_dir)  # Get parent of .ace
              File.expand_path(File.join(project_dir, path))
            else
              File.expand_path(path)
            end
          elsif config_dir
            # Other relative paths, resolve relative to config file directory
            File.expand_path(File.join(File.dirname(config_dir), path))
          else
            # Fallback to expand from current directory
            File.expand_path(path)
          end
        end

        def exists?
          Dir.exist?(full_path)
        end

        def to_h
          {
            name: name,
            type: type,
            path: path,
            full_path: full_path,
            priority: priority,
            description: description,
            origin: origin,
            exists: exists?
          }
        end

        def to_s
          "#{name} (#{type}): #{full_path}"
        end
      end
    end
  end
end