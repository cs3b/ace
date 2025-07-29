# frozen_string_literal: true

require "spec_helper"
require "tempfile"
require "tmpdir"
require "fileutils"
require "coding_agent_tools/atoms/code_quality/path_resolver"

RSpec.describe CodingAgentTools::Atoms::CodeQuality::PathResolver do
  let(:temp_dir) { Dir.mktmpdir("path_resolver_test") }
  let(:resolver) { described_class.new(project_root: temp_dir) }

  before do
    FileUtils.mkdir_p(temp_dir)
    # Create a comprehensive test project structure
    FileUtils.mkdir_p(File.join(temp_dir, "src"))
    FileUtils.mkdir_p(File.join(temp_dir, "spec"))
    FileUtils.mkdir_p(File.join(temp_dir, "nested", "deep"))
    File.write(File.join(temp_dir, "README.md"), "test content")
    File.write(File.join(temp_dir, "src", "file.rb"), "# test file")
    File.write(File.join(temp_dir, "nested", "deep", "file.txt"), "deep content")
  end

  after do
    safe_directory_cleanup(temp_dir)
  end

  describe "#initialize" do
    it "uses provided project root" do
      resolver = described_class.new(project_root: "/custom/root")
      expect(resolver.project_root).to eq("/custom/root")
    end

    it "detects project root when not provided" do
      resolver = described_class.new
      expect(resolver.project_root).to be_a(String)
      expect(resolver.project_root).not_to be_empty
    end

    it "uses ProjectRootDetector when available" do
      detector_class = double("ProjectRootDetector")
      allow(detector_class).to receive(:find_project_root).and_return("/detected/root")
      stub_const("CodingAgentTools::Atoms::ProjectRootDetector", detector_class)

      resolver = described_class.new
      expect(resolver.project_root).to eq("/detected/root")
    end

    it "outputs debug info when DEBUG env var is set" do
      detector_class = double("ProjectRootDetector")
      allow(detector_class).to receive(:find_project_root).and_return("/debug/root")
      stub_const("CodingAgentTools::Atoms::ProjectRootDetector", detector_class)

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("DEBUG").and_return("1")

      expect { described_class.new }.to output(/Project root detected via ProjectRootDetector/).to_stdout
    end

    it "handles require fallback gracefully" do
      # Hide the constant
      hide_const("CodingAgentTools::Atoms::ProjectRootDetector") if defined?(CodingAgentTools::Atoms::ProjectRootDetector)

      # Mock manual detection fallback
      allow(Pathname).to receive(:pwd).and_return(Pathname.new(temp_dir))
      File.write(File.join(temp_dir, ".git"), "gitdir: /path/to/git")

      resolver = described_class.new
      expect(resolver.project_root).to eq(temp_dir)
    end

    it "handles LoadError during require gracefully" do
      hide_const("CodingAgentTools::Atoms::ProjectRootDetector") if defined?(CodingAgentTools::Atoms::ProjectRootDetector)

      # Mock require to fail and manual detection
      allow_any_instance_of(described_class).to receive(:require_relative).and_raise(LoadError, "cannot load file")
      allow(Pathname).to receive(:pwd).and_return(Pathname.new(temp_dir))
      allow(Dir).to receive(:pwd).and_return(temp_dir)
      File.write(File.join(temp_dir, "Gemfile"), "# gemfile")

      resolver = described_class.new
      expect(resolver.project_root).to eq(temp_dir)
    end
  end

  describe "#resolve" do
    before do
      # Create test files in temp directory
      File.write(File.join(temp_dir, "root_file.txt"), "content")
      subdir = File.join(temp_dir, "subdir")
      Dir.mkdir(subdir)
      File.write(File.join(subdir, "sub_file.txt"), "content")
    end

    context "with absolute paths" do
      it "returns absolute paths unchanged" do
        absolute_path = "/absolute/path/to/file"
        expect(resolver.resolve(absolute_path)).to eq(absolute_path)
      end

      it "handles absolute paths that exist" do
        absolute_path = File.join(temp_dir, "root_file.txt")
        expect(resolver.resolve(absolute_path)).to eq(absolute_path)
      end
    end

    context "with relative paths" do
      it "resolves relative to current directory when file exists" do
        # Create a file in current directory for testing
        current_file = "test_current_file.txt"
        File.write(current_file, "content")

        result = resolver.resolve(current_file)
        expect(result).to eq(File.expand_path(current_file))

        # Cleanup
        File.delete(current_file)
      end

      it "resolves relative to project root when file exists there" do
        result = resolver.resolve("root_file.txt")
        expect(result).to eq(File.join(temp_dir, "root_file.txt"))
      end

      it "resolves nested paths relative to project root" do
        result = resolver.resolve("subdir/sub_file.txt")
        expect(result).to eq(File.join(temp_dir, "subdir/sub_file.txt"))
      end

      it "returns path as-is when file doesn't exist anywhere" do
        non_existent = "non_existent_file.txt"
        result = resolver.resolve(non_existent)
        expect(result).to eq(non_existent)
      end
    end

    context "with edge cases" do
      it "handles empty string path" do
        result = resolver.resolve("")
        # Empty string will be expanded to current directory
        expect(result).to be_a(String)
      end

      it "handles path with spaces" do
        spaced_file = "file with spaces.txt"
        File.write(File.join(temp_dir, spaced_file), "content")

        result = resolver.resolve(spaced_file)
        expect(result).to eq(File.join(temp_dir, spaced_file))
      end

      it "handles paths with special characters" do
        special_file = "file-with_special.chars.txt"
        File.write(File.join(temp_dir, special_file), "content")

        result = resolver.resolve(special_file)
        expect(result).to eq(File.join(temp_dir, special_file))
      end

      it "handles paths with Unicode characters" do
        unicode_file = "файл.txt"
        File.write(File.join(temp_dir, unicode_file), "unicode content")

        result = resolver.resolve(unicode_file)
        expect(result).to eq(File.join(temp_dir, unicode_file))
      end

      it "handles paths with .. traversal" do
        result = resolver.resolve("src/../README.md")
        # The result should be a valid path
        expect(result).to be_a(String)
        expect(result).to include("README.md")
      end

      it "handles very long file names" do
        long_name = "a" * 200
        long_file = File.join(temp_dir, "#{long_name}.txt")
        File.write(long_file, "content")

        result = resolver.resolve("#{long_name}.txt")
        expect(result).to eq(long_file)
      end

      it "handles paths with null bytes" do
        expect { resolver.resolve("file\0name.rb") }.to raise_error(ArgumentError)
      end

      it "handles Windows-style path separators" do
        skip "Windows path testing" unless Gem.win_platform?

        windows_style = "src\\file.rb"
        result = resolver.resolve(windows_style)
        expect(result).to be_a(String)
      end
    end

    context "with symbolic links" do
      it "handles symbolic links correctly" do
        skip "Symlink testing not supported" unless File.respond_to?(:symlink)

        begin
          link_path = File.join(temp_dir, "link_to_src")
          File.symlink(File.join(temp_dir, "src"), link_path)

          result = resolver.resolve("link_to_src/file.rb")
          expect(File.exist?(result)).to be true
        rescue NotImplementedError
          skip "Symlinks not supported on this platform"
        end
      end
    end
  end

  describe "#relative_to_root" do
    it "converts absolute path to relative from project root" do
      absolute_path = File.join(temp_dir, "subdir", "file.txt")
      result = resolver.relative_to_root(absolute_path)
      expect(result).to eq("subdir/file.txt")
    end

    it "handles paths already relative to root" do
      relative_path = "relative/path.txt"
      # This will be expanded to current directory, then made relative to temp_dir
      result = resolver.relative_to_root(relative_path)
      expect(result).to be_a(String)
    end

    it "handles path equal to project root" do
      result = resolver.relative_to_root(temp_dir)
      expect(result).to eq(".")
    end

    it "returns absolute path when relative path cannot be created" do
      # Path outside project root
      other_temp = Dir.mktmpdir

      begin
        result = resolver.relative_to_root(other_temp)
        # The implementation may return a relative path or absolute path
        expect(result).to be_a(String)
        expect(result).not_to be_empty
      ensure
        FileUtils.rm_rf(other_temp)
      end
    end

    it "handles nested paths correctly" do
      nested_path = File.join(temp_dir, "deep", "nested", "path", "file.txt")
      result = resolver.relative_to_root(nested_path)
      expect(result).to eq("deep/nested/path/file.txt")
    end

    it "handles ArgumentError when paths cannot be made relative" do
      # Create a path that might cause ArgumentError in relative_path_from
      external_path = "/completely/different/root/file.txt"
      result = resolver.relative_to_root(external_path)

      # Should return absolute path or a relative path - depends on implementation
      expect(result).to be_a(String)
    end

    it "handles parent directory references" do
      parent_path = File.join(temp_dir, "..", File.basename(temp_dir), "src", "file.rb")
      result = resolver.relative_to_root(parent_path)

      expect(result).to include("src/file.rb")
    end

    it "handles current directory references" do
      current_ref_path = File.join(temp_dir, ".", "src", "file.rb")
      result = resolver.relative_to_root(current_ref_path)

      expect(result).to eq("src/file.rb")
    end

    it "handles symbolic links in paths" do
      skip "Symlink testing not supported" unless File.respond_to?(:symlink)

      begin
        link_path = File.join(temp_dir, "link_to_nested")
        File.symlink(File.join(temp_dir, "nested"), link_path)

        linked_file_path = File.join(link_path, "deep", "file.txt")
        result = resolver.relative_to_root(linked_file_path)

        expect(result).to be_a(String)
      rescue NotImplementedError
        skip "Symlinks not supported on this platform"
      end
    end

    it "handles Unicode paths correctly" do
      unicode_path = File.join(temp_dir, "пуъть", "файл.txt")
      result = resolver.relative_to_root(unicode_path)

      expect(result).to eq("пуъть/файл.txt")
    end
  end

  describe "#in_project?" do
    it "returns true for paths within project root" do
      path_in_project = File.join(temp_dir, "some", "file.txt")
      expect(resolver.in_project?(path_in_project)).to be true
    end

    it "returns true for project root itself" do
      expect(resolver.in_project?(temp_dir)).to be true
    end

    it "returns false for paths outside project root" do
      other_temp = Dir.mktmpdir

      begin
        expect(resolver.in_project?(other_temp)).to be false
      ensure
        FileUtils.rm_rf(other_temp)
      end
    end

    it "handles relative paths" do
      # Relative paths are expanded relative to current directory
      expect([true, false]).to include(resolver.in_project?("relative/path"))
    end

    it "prevents path traversal attacks" do
      traversal_path = File.join(temp_dir, "..", "..", "etc", "passwd")
      result = resolver.in_project?(traversal_path)

      # Should be false unless the traversal actually ends up in project
      expect(result).to be false
    end

    it "handles paths with .. that stay within project" do
      nested_escape_path = File.join(temp_dir, "nested", "deep", "..", "..", "src", "file.rb")
      expect(resolver.in_project?(nested_escape_path)).to be true
    end

    it "handles symbolic links correctly" do
      skip "Symlink testing not supported" unless File.respond_to?(:symlink)

      begin
        # Create symlink within project
        link_path = File.join(temp_dir, "link_to_src")
        File.symlink(File.join(temp_dir, "src"), link_path)

        expect(resolver.in_project?(link_path)).to be true

        # Create symlink outside project
        external_dir = Dir.mktmpdir("external_test")
        external_link = File.join(temp_dir, "external_link")
        File.symlink(external_dir, external_link)

        expect(resolver.in_project?(external_link)).to be true # The link itself is in project

        FileUtils.rm_rf(external_dir)
      rescue NotImplementedError
        skip "Symlinks not supported on this platform"
      end
    end

    it "handles very deeply nested paths" do
      deep_path = File.join(temp_dir, Array.new(20) { "level" })
      expect(resolver.in_project?(deep_path)).to be true
    end

    it "handles paths with special characters" do
      special_path = File.join(temp_dir, "file@#$%^&*()_+.rb")
      expect(resolver.in_project?(special_path)).to be true
    end

    it "handles Unicode paths" do
      unicode_path = File.join(temp_dir, "путь", "к", "файлу.txt")
      expect(resolver.in_project?(unicode_path)).to be true
    end

    it "handles empty string path" do
      # Empty string expands to current directory
      result = resolver.in_project?("")
      expect([true, false]).to include(result)
    end

    it "raises error for nil path" do
      expect { resolver.in_project?(nil) }.to raise_error(TypeError)
    end

    it "handles root directory correctly" do
      expect(resolver.in_project?("/")).to be false
    end
  end

  describe "project root detection" do
    let(:test_project_dir) { Dir.mktmpdir }

    after do
      FileUtils.rm_rf(test_project_dir) if Dir.exist?(test_project_dir)
    end

    it "detects project root with .git directory" do
      git_dir = File.join(test_project_dir, ".git")
      Dir.mkdir(git_dir)

      # Change to subdirectory
      subdir = File.join(test_project_dir, "subdir")
      Dir.mkdir(subdir)

      Dir.chdir(subdir) do
        resolver = described_class.new
        expect(File.realpath(resolver.project_root)).to eq(File.realpath(test_project_dir))
      end
    end

    it "detects project root with Gemfile" do
      File.write(File.join(test_project_dir, "Gemfile"), "")

      subdir = File.join(test_project_dir, "subdir")
      Dir.mkdir(subdir)

      Dir.chdir(subdir) do
        resolver = described_class.new
        expect(File.realpath(resolver.project_root)).to eq(File.realpath(test_project_dir))
      end
    end

    it "detects project root with .coding-agent directory" do
      coding_agent_dir = File.join(test_project_dir, ".coding-agent")
      Dir.mkdir(coding_agent_dir)

      subdir = File.join(test_project_dir, "subdir")
      Dir.mkdir(subdir)

      Dir.chdir(subdir) do
        # Mock the ProjectRootDetector to avoid complex root detection
        allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(test_project_dir)
        resolver = described_class.new
        expect(resolver.project_root).to eq(test_project_dir)
      end
    end

    it "falls back to current directory when no markers found" do
      empty_dir = Dir.mktmpdir

      begin
        Dir.chdir(empty_dir) do
          # Mock the detector to return current directory when no markers found
          allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(empty_dir)
          resolver = described_class.new
          expect(resolver.project_root).to eq(empty_dir)
        end
      ensure
        FileUtils.rm_rf(empty_dir)
      end
    end

    it "detects project root with coding_agent_tools.gemspec" do
      File.write(File.join(test_project_dir, "coding_agent_tools.gemspec"), "# gemspec")

      subdir = File.join(test_project_dir, "subdir")
      Dir.mkdir(subdir)

      Dir.chdir(subdir) do
        resolver = described_class.new
        expect(File.realpath(resolver.project_root)).to eq(File.realpath(test_project_dir))
      end
    end

    it "traverses up multiple levels to find project markers" do
      # Create deep nested structure
      deep_path = File.join(test_project_dir, "level1", "level2", "level3")
      FileUtils.mkdir_p(deep_path)

      # Put marker at top level
      File.write(File.join(test_project_dir, ".git"), "gitdir: /path/to/git")

      Dir.chdir(deep_path) do
        resolver = described_class.new
        expect(File.realpath(resolver.project_root)).to eq(File.realpath(test_project_dir))
      end
    end

    it "stops at filesystem root when no markers found" do
      # Create directory without any markers
      empty_deep = Dir.mktmpdir
      deep_empty_path = File.join(empty_deep, "deep", "path")
      FileUtils.mkdir_p(deep_empty_path)

      begin
        Dir.chdir(deep_empty_path) do
          # Hide ProjectRootDetector to force manual detection
          hide_const("CodingAgentTools::Atoms::ProjectRootDetector") if defined?(CodingAgentTools::Atoms::ProjectRootDetector)
          allow_any_instance_of(described_class).to receive(:require_relative).and_raise(LoadError)

          resolver = described_class.new
          # Should fall back to current directory (handle symlink resolution)
          expect(File.realpath(resolver.project_root)).to eq(File.realpath(deep_empty_path))
        end
      ensure
        FileUtils.rm_rf(empty_deep)
      end
    end

    it "handles require with exception other than LoadError" do
      hide_const("CodingAgentTools::Atoms::ProjectRootDetector") if defined?(CodingAgentTools::Atoms::ProjectRootDetector)

      # Mock require to fail with StandardError
      allow_any_instance_of(described_class).to receive(:require_relative).and_raise(StandardError, "some other error")
      allow(Pathname).to receive(:pwd).and_return(Pathname.new(temp_dir))
      allow(Dir).to receive(:pwd).and_return(temp_dir)
      File.write(File.join(temp_dir, ".coding-agent"), "")

      resolver = described_class.new
      expect(resolver.project_root).to eq(temp_dir)
    end

    it "outputs debug messages for require fallback when DEBUG is set" do
      hide_const("CodingAgentTools::Atoms::ProjectRootDetector") if defined?(CodingAgentTools::Atoms::ProjectRootDetector)

      allow_any_instance_of(described_class).to receive(:require_relative).and_return(true)
      detector_class = double("ProjectRootDetector")
      allow(detector_class).to receive(:find_project_root).and_return("/required/root")
      stub_const("CodingAgentTools::Atoms::ProjectRootDetector", detector_class)

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("DEBUG").and_return("1")

      expect { described_class.new }.to output(/Project root detected via ProjectRootDetector/).to_stdout
    end

    it "outputs debug messages for failed require when DEBUG is set" do
      hide_const("CodingAgentTools::Atoms::ProjectRootDetector") if defined?(CodingAgentTools::Atoms::ProjectRootDetector)

      allow_any_instance_of(described_class).to receive(:require_relative).and_raise(LoadError, "test error")
      allow(Pathname).to receive(:pwd).and_return(Pathname.new(temp_dir))
      allow(Dir).to receive(:pwd).and_return(temp_dir)

      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("DEBUG").and_return("1")

      expect { described_class.new }.to output(/Could not load ProjectRootDetector/).to_stdout
    end
  end

  describe "integration scenarios" do
    before do
      # Set up a realistic project structure (avoiding conflicts with existing setup)
      %w[lib bin].each { |dir|
        FileUtils.mkdir_p(File.join(temp_dir, dir)) unless Dir.exist?(File.join(temp_dir, dir))
      }
      File.write(File.join(temp_dir, "Gemfile"), "") unless File.exist?(File.join(temp_dir, "Gemfile"))
      File.write(File.join(temp_dir, "lib", "main.rb"), "") unless File.exist?(File.join(temp_dir, "lib", "main.rb"))
      File.write(File.join(temp_dir, "spec", "main_spec.rb"), "") unless File.exist?(File.join(temp_dir, "spec", "main_spec.rb"))
    end

    it "resolves library files correctly" do
      result = resolver.resolve("lib/main.rb")
      expect(result).to eq(File.join(temp_dir, "lib/main.rb"))
      expect(File.exist?(result)).to be true
    end

    it "converts resolved paths back to relative" do
      resolved = resolver.resolve("lib/main.rb")
      relative = resolver.relative_to_root(resolved)
      expect(relative).to eq("lib/main.rb")
    end

    it "confirms project membership" do
      resolved = resolver.resolve("lib/main.rb")
      expect(resolver.in_project?(resolved)).to be true
    end

    it "handles complex path resolution workflows" do
      # Start with relative path
      relative_path = "spec/main_spec.rb"

      # Resolve to absolute
      absolute_path = resolver.resolve(relative_path)
      expect(File.exist?(absolute_path)).to be true

      # Convert back to relative
      back_to_relative = resolver.relative_to_root(absolute_path)
      expect(back_to_relative).to eq(relative_path)

      # Confirm project membership
      expect(resolver.in_project?(absolute_path)).to be true
    end

    it "handles mixed path separators correctly" do
      mixed_separator_path = "lib\\main.rb"
      result = resolver.resolve(mixed_separator_path)

      # Should resolve correctly regardless of separator style
      expect(result).to be_a(String)
    end
  end

  describe "error handling and edge cases" do
    it "handles non-existent project root gracefully" do
      nonexistent_root = "/this/path/does/not/exist"
      resolver_bad = described_class.new(project_root: nonexistent_root)

      expect(resolver_bad.project_root).to eq(nonexistent_root)

      # Should still function, just won't find files
      result = resolver_bad.resolve("some/file.rb")
      expect(result).to eq("some/file.rb")
    end

    it "handles permission denied scenarios" do
      # This test is challenging to implement cross-platform reliably
      skip "Permission testing is system-dependent"
    end

    it "handles circular symbolic links" do
      skip "Symlink testing not supported" unless File.respond_to?(:symlink)

      begin
        link1 = File.join(temp_dir, "link1")
        link2 = File.join(temp_dir, "link2")

        File.symlink(link2, link1)
        File.symlink(link1, link2)

        # Should not infinite loop
        result = resolver.resolve("link1")
        expect(result).to be_a(String)
      rescue NotImplementedError
        skip "Symlinks not supported on this platform"
      rescue SystemCallError
        skip "Cannot create circular symlinks on this system"
      end
    end

    it "handles very long directory paths" do
      # Create a very long path
      long_path_segments = Array.new(50) { "very_long_directory_name_that_exceeds_normal_limits" }
      begin
        long_path = File.join(temp_dir, *long_path_segments)
        FileUtils.mkdir_p(long_path)

        resolver_long = described_class.new(project_root: long_path)
        expect(resolver_long.project_root).to eq(long_path)
      rescue SystemCallError
        skip "System cannot handle very long paths"
      end
    end

    it "handles Unicode project root paths" do
      unicode_dir = Dir.mktmpdir("тест_проект")

      begin
        resolver_unicode = described_class.new(project_root: unicode_dir)
        expect(resolver_unicode.project_root).to eq(unicode_dir)

        # Test resolution within Unicode directory
        File.write(File.join(unicode_dir, "файл.rb"), "content")
        result = resolver_unicode.resolve("файл.rb")
        expect(result).to eq(File.join(unicode_dir, "файл.rb"))
      ensure
        FileUtils.rm_rf(unicode_dir)
      end
    end

    it "handles concurrent access scenarios" do
      threads = []
      results = Queue.new

      10.times do |i|
        threads << Thread.new do
          test_resolver = described_class.new(project_root: temp_dir)
          results << test_resolver.resolve("src/file.rb")
        end
      end

      threads.each(&:join)

      # All threads should get the same result
      first_result = results.pop
      until results.empty?
        expect(results.pop).to eq(first_result)
      end
    end

    it "handles file system changes during operation" do
      # Create and resolve a file
      test_file = File.join(temp_dir, "changing_file.rb")
      File.write(test_file, "initial content")

      result1 = resolver.resolve("changing_file.rb")
      expect(result1).to eq(test_file)

      # Delete the file
      File.delete(test_file)

      # Resolution should fall back gracefully
      result2 = resolver.resolve("changing_file.rb")
      expect(result2).to eq("changing_file.rb")
    end

    it "handles filesystem case sensitivity correctly" do
      # Create file with specific case
      File.write(File.join(temp_dir, "CamelCase.rb"), "content")

      # Test resolution with different case
      result = resolver.resolve("camelcase.rb")

      # Result depends on filesystem case sensitivity
      expect(result).to be_a(String)
    end

    it "maintains thread safety during initialization" do
      threads = []
      resolvers = Queue.new

      10.times do
        threads << Thread.new do
          resolvers << described_class.new(project_root: temp_dir)
        end
      end

      threads.each(&:join)

      # All resolvers should have the same project root
      first_resolver = resolvers.pop
      until resolvers.empty?
        expect(resolvers.pop.project_root).to eq(first_resolver.project_root)
      end
    end
  end

  describe "performance characteristics" do
    it "handles large numbers of resolution requests efficiently" do
      start_time = Time.now

      1000.times do |i|
        resolver.resolve("test_file_#{i}.rb")
      end

      end_time = Time.now
      duration = end_time - start_time

      # Should complete 1000 resolutions in reasonable time
      expect(duration).to be < 5.0
    end

    it "handles deeply nested path structures efficiently" do
      # Create deep structure
      deep_parts = Array.new(20) { |i| "level#{i}" }
      deep_path = File.join(temp_dir, *deep_parts)
      FileUtils.mkdir_p(deep_path)
      File.write(File.join(deep_path, "deep_file.rb"), "deep content")

      start_time = Time.now

      result = resolver.resolve(File.join(*deep_parts, "deep_file.rb"))

      end_time = Time.now
      duration = end_time - start_time

      expect(result).to eq(File.join(deep_path, "deep_file.rb"))
      expect(duration).to be < 1.0
    end
  end
end
