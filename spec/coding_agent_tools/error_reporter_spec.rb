# frozen_string_literal: true

require "spec_helper"
require "stringio"

RSpec.describe CodingAgentTools::ErrorReporter do
  let(:test_exception) { StandardError.new("Test error message") }
  let(:log_output) { StringIO.new }

  describe ".call" do
    context "with basic error reporting" do
      it "reports error message to default logger" do
        expect($stderr).to receive(:puts).with("ERROR: Test error message")

        described_class.call(test_exception)
      end

      it "reports error message to custom logger" do
        described_class.call(test_exception, logger: log_output)

        log_output.rewind
        output = log_output.read
        expect(output).to eq("ERROR: Test error message\n")
      end

      it "handles exceptions with empty messages" do
        empty_exception = StandardError.new("")
        described_class.call(empty_exception, logger: log_output)

        log_output.rewind
        output = log_output.read
        expect(output).to eq("ERROR: \n")
      end

      it "handles exceptions with nil message" do
        nil_message_exception = StandardError.new(nil)
        described_class.call(nil_message_exception, logger: log_output)

        log_output.rewind
        output = log_output.read
        expect(output).to eq("ERROR: StandardError\n")
      end
    end

    context "with debug mode disabled (default)" do
      it "does not include backtrace when debug is false" do
        exception_with_backtrace = StandardError.new("Error with backtrace")
        exception_with_backtrace.set_backtrace([
          "/path/to/file1.rb:10:in `method1'",
          "/path/to/file2.rb:20:in `method2'"
        ])

        described_class.call(exception_with_backtrace, debug: false, logger: log_output)

        log_output.rewind
        output = log_output.read
        expect(output).to eq("ERROR: Error with backtrace\n")
        expect(output).not_to include("Backtrace:")
        expect(output).not_to include("file1.rb")
        expect(output).not_to include("file2.rb")
      end

      it "does not include backtrace when debug is not specified" do
        exception_with_backtrace = StandardError.new("Error with backtrace")
        exception_with_backtrace.set_backtrace(["/path/to/file.rb:5:in `test'"])

        described_class.call(exception_with_backtrace, logger: log_output)

        log_output.rewind
        output = log_output.read
        expect(output).to eq("ERROR: Error with backtrace\n")
        expect(output).not_to include("Backtrace:")
      end
    end

    context "with debug mode enabled" do
      it "includes backtrace when debug is true and backtrace is available" do
        exception_with_backtrace = StandardError.new("Error with backtrace")
        exception_with_backtrace.set_backtrace([
          "/path/to/file1.rb:10:in `method1'",
          "/path/to/file2.rb:20:in `method2'",
          "/path/to/file3.rb:30:in `method3'"
        ])

        described_class.call(exception_with_backtrace, debug: true, logger: log_output)

        log_output.rewind
        output = log_output.read

        expected_output = [
          "ERROR: Error with backtrace",
          "Backtrace:",
          "  /path/to/file1.rb:10:in `method1'",
          "  /path/to/file2.rb:20:in `method2'",
          "  /path/to/file3.rb:30:in `method3'",
          ""
        ].join("\n")

        expect(output).to eq(expected_output)
      end

      it "does not include backtrace when debug is true but backtrace is nil" do
        exception_without_backtrace = StandardError.new("Error without backtrace")
        # Don't set a backtrace, leaving it as nil

        described_class.call(exception_without_backtrace, debug: true, logger: log_output)

        log_output.rewind
        output = log_output.read
        expect(output).to eq("ERROR: Error without backtrace\n")
        expect(output).not_to include("Backtrace:")
      end

      it "includes backtrace header when debug is true but backtrace is empty" do
        exception_with_empty_backtrace = StandardError.new("Error with empty backtrace")
        exception_with_empty_backtrace.set_backtrace([])

        described_class.call(exception_with_empty_backtrace, debug: true, logger: log_output)

        log_output.rewind
        output = log_output.read

        expected_output = [
          "ERROR: Error with empty backtrace",
          "Backtrace:",
          ""
        ].join("\n")

        expect(output).to eq(expected_output)
      end

      it "handles single line backtrace" do
        exception_with_single_line = StandardError.new("Single line error")
        exception_with_single_line.set_backtrace(["/path/to/file.rb:42:in `single_method'"])

        described_class.call(exception_with_single_line, debug: true, logger: log_output)

        log_output.rewind
        output = log_output.read

        expected_output = [
          "ERROR: Single line error",
          "Backtrace:",
          "  /path/to/file.rb:42:in `single_method'",
          ""
        ].join("\n")

        expect(output).to eq(expected_output)
      end
    end

    context "with different logger implementations" do
      it "works with StringIO logger" do
        string_logger = StringIO.new
        described_class.call(test_exception, logger: string_logger)

        string_logger.rewind
        output = string_logger.read
        expect(output).to eq("ERROR: Test error message\n")
      end

      it "works with file logger" do
        require "tempfile"

        Tempfile.create("error_reporter_test") do |tempfile|
          described_class.call(test_exception, logger: tempfile)
          tempfile.rewind
          output = tempfile.read
          expect(output).to eq("ERROR: Test error message\n")
        end
      end

      it "works with custom logger that responds to puts" do
        custom_logger = double("CustomLogger")
        expect(custom_logger).to receive(:puts).with("ERROR: Test error message")

        described_class.call(test_exception, logger: custom_logger)
      end

      it "works with logger that captures multiple puts calls in debug mode" do
        custom_logger = double("CustomLogger")
        exception_with_backtrace = StandardError.new("Debug error")
        exception_with_backtrace.set_backtrace([
          "/path/to/file1.rb:10:in `method1'",
          "/path/to/file2.rb:20:in `method2'"
        ])

        expect(custom_logger).to receive(:puts).with("ERROR: Debug error")
        expect(custom_logger).to receive(:puts).with("Backtrace:")
        expect(custom_logger).to receive(:puts).with("  /path/to/file1.rb:10:in `method1'")
        expect(custom_logger).to receive(:puts).with("  /path/to/file2.rb:20:in `method2'")

        described_class.call(exception_with_backtrace, debug: true, logger: custom_logger)
      end
    end

    context "with different exception types" do
      it "handles RuntimeError" do
        runtime_error = RuntimeError.new("Runtime error occurred")
        described_class.call(runtime_error, logger: log_output)

        log_output.rewind
        output = log_output.read
        expect(output).to eq("ERROR: Runtime error occurred\n")
      end

      it "handles ArgumentError" do
        argument_error = ArgumentError.new("Invalid argument provided")
        described_class.call(argument_error, logger: log_output)

        log_output.rewind
        output = log_output.read
        expect(output).to eq("ERROR: Invalid argument provided\n")
      end

      it "handles custom exception classes" do
        custom_exception_class = Class.new(StandardError)
        custom_exception = custom_exception_class.new("Custom exception message")

        described_class.call(custom_exception, logger: log_output)

        log_output.rewind
        output = log_output.read
        expect(output).to eq("ERROR: Custom exception message\n")
      end

      it "handles exceptions with complex messages including newlines" do
        complex_message = "Error occurred:\nMultiple lines\nof error details"
        complex_exception = StandardError.new(complex_message)

        described_class.call(complex_exception, logger: log_output)

        log_output.rewind
        output = log_output.read
        expect(output).to eq("ERROR: #{complex_message}\n")
      end
    end

    context "error conditions and edge cases" do
      it "handles logger that raises exception on puts" do
        failing_logger = double("FailingLogger")
        allow(failing_logger).to receive(:puts).and_raise(IOError, "Logger failed")

        expect {
          described_class.call(test_exception, logger: failing_logger)
        }.to raise_error(IOError, "Logger failed")
      end

      it "handles logger that doesn't respond to puts" do
        invalid_logger = Object.new

        expect {
          described_class.call(test_exception, logger: invalid_logger)
        }.to raise_error(NoMethodError)
      end
    end

    context "parameter combinations" do
      it "accepts all parameters explicitly" do
        exception_with_backtrace = StandardError.new("Full parameter test")
        exception_with_backtrace.set_backtrace(["/path/to/file.rb:1:in `test'"])

        described_class.call(
          exception_with_backtrace,
          debug: true,
          logger: log_output
        )

        log_output.rewind
        output = log_output.read

        expect(output).to include("ERROR: Full parameter test")
        expect(output).to include("Backtrace:")
        expect(output).to include("  /path/to/file.rb:1:in `test'")
      end

      it "works with only exception parameter" do
        expect($stderr).to receive(:puts).with("ERROR: Test error message")
        described_class.call(test_exception)
      end

      it "works with exception and debug parameters" do
        expect($stderr).to receive(:puts).with("ERROR: Test error message")
        described_class.call(test_exception, debug: false)
      end

      it "works with exception and logger parameters" do
        described_class.call(test_exception, logger: log_output)

        log_output.rewind
        output = log_output.read
        expect(output).to eq("ERROR: Test error message\n")
      end
    end
  end
end
