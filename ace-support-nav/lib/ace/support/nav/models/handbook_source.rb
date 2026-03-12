# frozen_string_literal: true

module Ace
  module Support
    module Nav
      module Models
        # Represents a source of handbook resources
        class HandbookSource
          attr_reader :name, :path, :alias_name, :type, :priority, :resource_root

          def initialize(name:, path:, alias_name: nil, type: :gem, priority: 100, resource_root: nil)
            @name = name
            @path = path
            @alias_name = alias_name || derive_alias(name, type)
            @type = type # :project, :user, :gem, :custom
            @priority = priority
            @resource_root = resource_root || default_resource_root
          end

          def project?
            type == :project
          end

          def user?
            type == :user
          end

          def gem?
            type == :gem
          end

          def custom?
            type == :custom
          end

          def handbook_path
            resource_root
          end

          def exists?
            Dir.exist?(handbook_path)
          end

          def to_h
            {
              name: name,
              path: path,
              alias: alias_name,
              type: type,
              priority: priority,
              exists: exists?
            }
          end

          private

          def default_resource_root
            gem? ? File.join(path, "handbook") : path
          end

          def derive_alias(name, type)
            case type
            when :project then "@project"
            when :user then "@user"
            when :gem then "@#{name}"
            else "@#{name.downcase.gsub(/[^a-z0-9-]/, "-")}"
            end
          end
        end
      end
    end
  end
end
