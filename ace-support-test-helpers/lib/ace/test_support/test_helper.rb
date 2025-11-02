# frozen_string_literal: true

module Ace
  module TestSupport
    # Test helper methods for all ace-* gems
    module TestHelper
      def with_temp_dir
        Dir.mktmpdir do |dir|
          original_pwd = Dir.pwd
          Dir.chdir(dir)
          yield dir
        ensure
          Dir.chdir(original_pwd)
        end
      end

      def with_temp_file(content = "")
        Tempfile.create do |file|
          file.write(content)
          file.flush
          yield file.path
        end
      end

      def create_config_file(path, content)
        FileUtils.mkdir_p(File.dirname(path))
        File.write(path, content)
      end

      def assert_file_exists(path, message = nil)
        assert File.exist?(path), message || "Expected file #{path} to exist"
      end

      def assert_file_content(path, expected_content, message = nil)
        assert_file_exists(path, message)
        actual = File.read(path)
        assert_equal expected_content, actual, message || "File #{path} content mismatch"
      end

      def assert_directory_exists(path, message = nil)
        assert Dir.exist?(path), message || "Expected directory #{path} to exist"
      end

      def capture_subprocess_io
        require 'stringio'

        captured_stdout = StringIO.new
        captured_stderr = StringIO.new

        orig_stdout = $stdout
        orig_stderr = $stderr

        $stdout = captured_stdout
        $stderr = captured_stderr

        yield

        [captured_stdout.string, captured_stderr.string]
      ensure
        $stdout = orig_stdout
        $stderr = orig_stderr
      end

      # Capture only stdout and return as string (convenience wrapper)
      def capture_stdout
        require 'stringio'

        original_stdout = $stdout
        $stdout = StringIO.new
        yield
        $stdout.string
      ensure
        $stdout = original_stdout
      end
    end
  end
end