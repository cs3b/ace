# frozen_string_literal: true

require "fileutils"

module Ace
  module Test
    module EndToEndRunner
      module Molecules
        # Copies fixture files from a scenario's fixtures/ directory into a sandbox
        #
        # Preserves the full directory tree structure. Used by SetupExecutor
        # to populate sandboxes with test data files.
        #
        # Note: This is a Molecule (not an Atom) because it performs filesystem
        # I/O via FileUtils.cp_r and Dir.glob.
        class FixtureCopier
          # Copy fixture tree into target directory
          #
          # @param source_dir [String] Path to the fixtures/ directory
          # @param target_dir [String] Path to the sandbox directory
          # @return [Array<String>] Relative paths of copied files and directories
          # @raise [ArgumentError] If source_dir does not exist
          def copy(source_dir:, target_dir:)
            raise ArgumentError, "Fixture source directory not found: #{source_dir}" unless Dir.exist?(source_dir)

            FileUtils.mkdir_p(target_dir)
            FileUtils.cp_r("#{source_dir}/.", target_dir)

            Dir.glob("**/*", base: target_dir).sort
          end
        end
      end
    end
  end
end
