# frozen_string_literal: true

$LOAD_PATH.unshift File.expand_path("../lib", __dir__)

require "minitest/autorun"
require "ace/config"

module Ace
  module Config
    # Base test case for ace-config tests
    class TestCase < Minitest::Test
      # Clear any caches before each test
      def setup
        Molecules::ProjectRootFinder.clear_cache!
        super
      end

      # Helper to create a temporary directory structure for testing
      def with_temp_config(structure = {})
        require "tmpdir"
        require "fileutils"

        Dir.mktmpdir do |tmpdir|
          create_structure(tmpdir, structure)
          Dir.chdir(tmpdir) do
            yield tmpdir
          end
        end
      end

      # Create directory structure from hash
      def create_structure(base, structure)
        structure.each do |key, value|
          path = File.join(base, key.to_s)
          if value.is_a?(Hash)
            FileUtils.mkdir_p(path)
            create_structure(path, value)
          else
            FileUtils.mkdir_p(File.dirname(path))
            File.write(path, value.to_s)
          end
        end
      end

      # Helper to get fixtures path
      def fixtures_path
        File.expand_path("fixtures", __dir__)
      end
    end
  end
end
