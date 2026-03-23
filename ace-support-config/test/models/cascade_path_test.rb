# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Config
      module Models
        class CascadePathTest < TestCase
          def test_initialize
            path = CascadePath.new(path: "/some/path", priority: 10, exists: true, type: :local)

            assert_equal "/some/path", path.path
            assert_equal 10, path.priority
            assert path.exists
            assert_equal :local, path.type
          end

          def test_comparison
            path1 = CascadePath.new(path: "/a", priority: 10)
            path2 = CascadePath.new(path: "/b", priority: 20)
            path3 = CascadePath.new(path: "/c", priority: 10)

            assert_equal(-1, path1 <=> path2)
            assert_equal 1, path2 <=> path1
            assert_equal 0, path1 <=> path3
          end

          def test_overrides
            higher = CascadePath.new(path: "/a", priority: 10)
            lower = CascadePath.new(path: "/b", priority: 20)

            assert higher.overrides?(lower)
            refute lower.overrides?(higher)
          end

          def test_to_s
            path = CascadePath.new(path: "/some/path")

            assert_equal "/some/path", path.to_s
          end

          def test_pathname
            path = CascadePath.new(path: "/some/path")

            assert_instance_of Pathname, path.pathname
            assert_equal "/some/path", path.pathname.to_s
          end

          def test_absolute_and_relative
            abs = CascadePath.new(path: "/absolute/path")
            rel = CascadePath.new(path: "relative/path")

            assert abs.absolute?
            refute abs.relative?

            refute rel.absolute?
            assert rel.relative?
          end

          def test_equality
            path1 = CascadePath.new(path: "/a", priority: 10, type: :local)
            path2 = CascadePath.new(path: "/a", priority: 10, type: :local)
            path3 = CascadePath.new(path: "/b", priority: 10, type: :local)

            assert_equal path1, path2
            refute_equal path1, path3
          end

          def test_frozen
            path = CascadePath.new(path: "/a")

            assert path.frozen?
          end
        end
      end
    end
  end
end
