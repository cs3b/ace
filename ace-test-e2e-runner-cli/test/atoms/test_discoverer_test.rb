# frozen_string_literal: true

require "test_helper"
require "fileutils"
require "tmpdir"

module Ace
  module E2eRunner
    class TestDiscovererTest < AceE2eRunnerTestCase
      def test_find_tests_in_package
        Dir.mktmpdir do |dir|
          package_dir = File.join(dir, "ace-sample", "test", "e2e")
          FileUtils.mkdir_p(package_dir)

          file1 = File.join(package_dir, "MT-SAMPLE-001-test.mt.md")
          file2 = File.join(package_dir, "MT-SAMPLE-002-test.mt.md")
          File.write(file1, "---\n---\n")
          File.write(file2, "---\n---\n")

          discoverer = Atoms::TestDiscoverer.new
          results = discoverer.find_tests(package: "ace-sample", root: dir)

          assert_equal [file1, file2], results
        end
      end

      def test_find_all_tests_across_repo
        Dir.mktmpdir do |dir|
          FileUtils.mkdir_p(File.join(dir, "ace-one", "test", "e2e"))
          FileUtils.mkdir_p(File.join(dir, "ace-two", "test", "e2e"))

          file1 = File.join(dir, "ace-one", "test", "e2e", "MT-ONE-001.mt.md")
          file2 = File.join(dir, "ace-two", "test", "e2e", "MT-TWO-001.mt.md")
          File.write(file1, "---\n---\n")
          File.write(file2, "---\n---\n")

          discoverer = Atoms::TestDiscoverer.new
          results = discoverer.find_all_tests(root: dir)

          assert_equal [file1, file2], results
        end
      end
    end
  end
end
