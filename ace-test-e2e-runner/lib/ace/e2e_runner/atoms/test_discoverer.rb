# frozen_string_literal: true

module Ace
  module E2eRunner
    module Atoms
      class TestDiscoverer
        def find_tests(package: nil, test_id: nil, root: Dir.pwd)
          patterns = []

          if package
            patterns << File.join(root, package, "test", "e2e", "*.mt.md")
          else
            patterns << File.join(root, "test", "e2e", "*.mt.md")
          end

          tests = patterns.flat_map { |pattern| Dir.glob(pattern) }
          tests = filter_by_test_id(tests, test_id) if test_id
          tests.sort
        end

        def find_all_tests(root: Dir.pwd)
          patterns = [
            File.join(root, "*", "test", "e2e", "*.mt.md"),
            File.join(root, "test", "e2e", "*.mt.md")
          ]

          patterns.flat_map { |pattern| Dir.glob(pattern) }.uniq.sort
        end

        private

        def filter_by_test_id(paths, test_id)
          paths.select { |path| File.basename(path).include?(test_id) }
        end
      end
    end
  end
end
