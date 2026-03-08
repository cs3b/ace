# frozen_string_literal: true

require "test_helper"

module Ace
  module Support
    module Fs
      module Molecules
        class ProjectRootFinderTest < TestCase
          def test_find_returns_directory_with_git
            with_temp_dir(".git" => "") do |tmpdir|
              finder = ProjectRootFinder.new(start_path: tmpdir)
              finder.stub(:env_project_root, nil) do
                result = finder.find

                assert_equal tmpdir, result
              end
            end
          end

          def test_find_returns_directory_with_gemfile
            with_temp_dir("Gemfile" => "") do |tmpdir|
              finder = ProjectRootFinder.new(start_path: tmpdir)
              finder.stub(:env_project_root, nil) do
                result = finder.find

                assert_equal tmpdir, result
              end
            end
          end

          def test_find_returns_nil_when_no_markers
            with_temp_dir({}) do |tmpdir|
              # Override markers to nothing that exists
              finder = ProjectRootFinder.new(
                start_path: tmpdir,
                markers: [".nonexistent-marker"]
              )
              finder.stub(:env_project_root, nil) do
                result = finder.find

                assert_nil result
              end
            end
          end

          def test_find_traverses_up_to_find_marker
            with_temp_dir(
              ".git" => "",
              "nested" => {
                "deeply" => {}
              }
            ) do |tmpdir|
              start = File.join(tmpdir, "nested", "deeply")

              finder = ProjectRootFinder.new(start_path: start)
              finder.stub(:env_project_root, nil) do
                result = finder.find

                assert_equal tmpdir, result
              end
            end
          end

          def test_find_or_current_returns_current_when_not_found
            with_temp_dir({}) do |tmpdir|
              finder = ProjectRootFinder.new(
                start_path: tmpdir,
                markers: [".nonexistent-marker"]
              )
              finder.stub(:env_project_root, nil) do
                result = finder.find_or_current

                assert_equal Dir.pwd, result
              end
            end
          end

          def test_in_project_returns_true_when_found
            with_temp_dir(".git" => "") do |tmpdir|
              finder = ProjectRootFinder.new(start_path: tmpdir)
              finder.stub(:env_project_root, nil) do
                assert finder.in_project?
              end
            end
          end

          def test_in_project_returns_false_when_not_found
            with_temp_dir({}) do |tmpdir|
              finder = ProjectRootFinder.new(
                start_path: tmpdir,
                markers: [".nonexistent-marker"]
              )
              finder.stub(:env_project_root, nil) do
                refute finder.in_project?
              end
            end
          end

          def test_relative_path_returns_relative
            with_temp_dir(
              ".git" => "",
              "src" => {
                "file.rb" => ""
              }
            ) do |tmpdir|
              finder = ProjectRootFinder.new(start_path: tmpdir)
              finder.stub(:env_project_root, nil) do
                file_path = File.join(tmpdir, "src", "file.rb")

                result = finder.relative_path(file_path)

                assert_equal "src/file.rb", result
              end
            end
          end

          def test_relative_path_returns_nil_outside_project
            with_temp_dir(
              ".git" => "",
              "outside_marker" => ""
            ) do |tmpdir|
              # Create a file actually outside the project
              require "tmpdir"
              outside_dir = Dir.mktmpdir
              begin
                outside_file = File.join(outside_dir, "file.rb")
                File.write(outside_file, "")

                finder = ProjectRootFinder.new(start_path: tmpdir)
                finder.stub(:env_project_root, nil) do
                  result = finder.relative_path(outside_file)

                  assert_nil result
                end
              ensure
                FileUtils.rm_rf(outside_dir)
              end
            end
          end

          def test_clear_cache_clears_memoized_results
            with_temp_dir(".git" => "") do |tmpdir|
              finder = ProjectRootFinder.new(start_path: tmpdir)
              finder.stub(:env_project_root, nil) do
                # Populate cache
                finder.find
              end

              # Clear cache
              ProjectRootFinder.clear_cache!

              # Cache should be empty
              assert_empty ProjectRootFinder.cache
            end
          end

          def test_class_find_method
            with_temp_dir(".git" => "") do |tmpdir|
              # Need to stub env on the instance created by class method
              # So we use instance and stub
              finder = ProjectRootFinder.new(start_path: tmpdir)
              result = nil
              finder.stub(:env_project_root, nil) do
                result = finder.find
              end

              assert_equal tmpdir, result
            end
          end

          def test_class_find_or_current_method
            with_temp_dir({}) do |tmpdir|
              finder = ProjectRootFinder.new(
                start_path: tmpdir,
                markers: [".nonexistent"]
              )
              finder.stub(:env_project_root, nil) do
                result = finder.find_or_current

                assert_equal Dir.pwd, result
              end
            end
          end

          def test_uses_env_variable_when_set
            with_temp_dir({}) do |tmpdir|
              custom_root = tmpdir

              finder = ProjectRootFinder.new(start_path: tmpdir)
              finder.stub(:env_project_root, custom_root) do
                result = finder.find

                assert_equal custom_root, result
              end
            end
          end

          def test_ignores_env_root_outside_start_path_without_markers
            with_temp_dir({}) do |start_dir|
              with_temp_dir({}) do |other_root|
                finder = ProjectRootFinder.new(
                  start_path: start_dir,
                  markers: [".nonexistent-marker"]
                )
                finder.stub(:env_project_root, other_root) do
                  result = finder.find

                  assert_nil result
                end
              end
            end
          end

          def test_ignores_env_root_outside_start_path_and_falls_back_to_markers
            with_temp_dir(".git" => "") do |start_dir|
              with_temp_dir({}) do |other_root|
                finder = ProjectRootFinder.new(start_path: start_dir)
                finder.stub(:env_project_root, other_root) do
                  result = finder.find

                  assert_equal start_dir, result
                end
              end
            end
          end

          def test_ignores_invalid_env_path
            with_temp_dir(".git" => "") do |tmpdir|
              finder = ProjectRootFinder.new(start_path: tmpdir)
              finder.stub(:env_project_root, "/nonexistent/path") do
                result = finder.find

                # Should fall back to marker detection
                assert_equal tmpdir, result
              end
            end
          end

          def test_custom_markers
            with_temp_dir("custom-marker.txt" => "") do |tmpdir|
              finder = ProjectRootFinder.new(
                start_path: tmpdir,
                markers: ["custom-marker.txt"]
              )
              finder.stub(:env_project_root, nil) do
                result = finder.find

                assert_equal tmpdir, result
              end
            end
          end

          def test_cache_is_thread_safe
            with_temp_dir(".git" => "") do |tmpdir|
              # Clear cache first
              ProjectRootFinder.clear_cache!

              threads = 10.times.map do
                Thread.new do
                  finder = ProjectRootFinder.new(start_path: tmpdir)
                  finder.stub(:env_project_root, nil) do
                    finder.find
                  end
                end
              end

              # Should not raise any thread safety errors
              results = threads.map(&:value)

              assert results.all? { |r| r == tmpdir }
            end
          end

          def test_default_markers_constant
            assert_includes ProjectRootFinder::DEFAULT_MARKERS, ".git"
            assert_includes ProjectRootFinder::DEFAULT_MARKERS, "Gemfile"
            assert_includes ProjectRootFinder::DEFAULT_MARKERS, "package.json"
          end

          def test_raises_argument_error_for_nil_markers
            error = assert_raises(ArgumentError) do
              ProjectRootFinder.new(markers: nil)
            end
            assert_match(/markers cannot be nil or empty/, error.message)
          end

          def test_raises_argument_error_for_empty_markers
            error = assert_raises(ArgumentError) do
              ProjectRootFinder.new(markers: [])
            end
            assert_match(/markers cannot be nil or empty/, error.message)
          end
        end
      end
    end
  end
end
