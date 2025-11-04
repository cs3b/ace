# frozen_string_literal: true

module Ace
  module Git
    module Worktree
      module Models
        # Model representing worktree metadata to be stored in task frontmatter
        class WorktreeMetadata
          attr_reader :branch, :path, :created_at

          def initialize(branch:, path:, created_at: nil)
            @branch = branch
            @path = path
            @created_at = created_at || Time.now.strftime("%Y-%m-%d %H:%M:%S")
          end

          # Convert to YAML-friendly hash
          def to_yaml_hash
            {
              "branch" => branch,
              "path" => path,
              "created_at" => created_at
            }
          end

          # Convert to hash
          def to_h
            {
              branch: branch,
              path: path,
              created_at: created_at
            }
          end

          # Generate YAML string for frontmatter insertion
          def to_yaml_string
            # Generate properly indented YAML for frontmatter
            <<~YAML.chomp
              worktree:
                branch: "#{branch}"
                path: "#{path}"
                created_at: "#{created_at}"
            YAML
          end

          # Check equality
          def ==(other)
            return false unless other.is_a?(WorktreeMetadata)
            branch == other.branch && path == other.path
          end

          # Create from hash (for parsing existing metadata)
          def self.from_hash(hash)
            return nil unless hash

            new(
              branch: hash["branch"] || hash[:branch],
              path: hash["path"] || hash[:path],
              created_at: hash["created_at"] || hash[:created_at]
            )
          end

          # Parse from task frontmatter
          def self.from_frontmatter(frontmatter)
            return nil unless frontmatter

            require 'yaml'
            data = YAML.safe_load(frontmatter, permitted_classes: [Symbol])

            return nil unless data && data["worktree"]

            from_hash(data["worktree"])
          end
        end
      end
    end
  end
end