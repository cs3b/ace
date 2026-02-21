# frozen_string_literal: true

require "date"
require "yaml"

module Ace
  module LLM
    module Providers
      module CLI
        module Molecules
          # Reads skill names from SKILL.md frontmatter in a skills directory.
          #
          # Scans `#{skills_dir}/*/SKILL.md` for YAML frontmatter with a `name:` field.
          # Results are cached per directory path since skills don't change during a session.
          class SkillNameReader
            def initialize
              @cache = {}
            end

            # Read skill names from a skills directory.
            #
            # @param skills_dir [String] Path to the skills directory
            # @return [Array<String>] Array of skill names (e.g. ["ace_onboard", "ace_git_commit"])
            def call(skills_dir)
              return [] unless skills_dir && Dir.exist?(skills_dir)

              @cache[skills_dir] ||= read_skill_names(skills_dir)
            end

            private

            def read_skill_names(skills_dir)
              skill_files = Dir.glob(File.join(skills_dir, "*", "SKILL.md"))
              names = []

              skill_files.each do |path|
                name = extract_skill_name(path)
                names << name if name
              end

              names.sort
            end

            def extract_skill_name(path)
              content = File.read(path, encoding: "utf-8")

              # Parse YAML frontmatter (between --- delimiters)
              return nil unless content.start_with?("---")

              end_index = content.index("---", 3)
              return nil unless end_index

              frontmatter = content[3...end_index].strip
              data = YAML.safe_load(frontmatter, permitted_classes: [Date])
              data["name"] if data.is_a?(Hash)
            rescue Errno::ENOENT, Psych::SyntaxError
              nil
            end
          end
        end
      end
    end
  end
end
