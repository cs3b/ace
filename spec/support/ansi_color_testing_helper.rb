# frozen_string_literal: true

module AnsiColorTestingHelper
  # Standard ANSI color codes for testing
  ANSI_CODES = {
    reset: "\033[0m",
    bold: "\033[1m",
    dim: "\033[2m",
    italic: "\033[3m",
    underline: "\033[4m",
    blink: "\033[5m",
    reverse: "\033[7m",
    strikethrough: "\033[9m",
    black: "\033[30m",
    red: "\033[31m",
    green: "\033[32m",
    yellow: "\033[33m",
    blue: "\033[34m",
    magenta: "\033[35m",
    cyan: "\033[36m",
    white: "\033[37m",
    bright_black: "\033[90m",
    bright_red: "\033[91m",
    bright_green: "\033[92m",
    bright_yellow: "\033[93m",
    bright_blue: "\033[94m",
    bright_magenta: "\033[95m",
    bright_cyan: "\033[96m",
    bright_white: "\033[97m",
    bg_black: "\033[40m",
    bg_red: "\033[41m",
    bg_green: "\033[42m",
    bg_yellow: "\033[43m",
    bg_blue: "\033[44m",
    bg_magenta: "\033[45m",
    bg_cyan: "\033[46m",
    bg_white: "\033[47m"
  }.freeze

  # Canonical regex for matching ANSI escape sequences
  ANSI_REGEX = /\033\[[0-9;]*m/

  # Helper methods for creating colored text
  def self.colorize(text, *codes)
    codes_str = codes.map { |code| ANSI_CODES[code] || code }.join
    "#{codes_str}#{text}#{ANSI_CODES[:reset]}"
  end

  def self.red(text)
    colorize(text, :red)
  end

  def self.green(text)
    colorize(text, :green)
  end

  def self.yellow(text)
    colorize(text, :yellow)
  end

  def self.blue(text)
    colorize(text, :blue)
  end

  def self.bold(text)
    colorize(text, :bold)
  end

  # Strip ANSI codes from text
  def self.strip_ansi(text)
    text.gsub(ANSI_REGEX, '')
  end

  # Extract only ANSI codes from text
  def self.extract_ansi_codes(text)
    text.scan(ANSI_REGEX)
  end

  # Check if text contains ANSI codes
  def self.has_ansi_codes?(text)
    !!(text =~ ANSI_REGEX)
  end

  # Capture output scenarios for behavior matrix testing
  class OutputCapture
    attr_reader :stdout_content, :stderr_content, :stdout_raw, :stderr_raw

    def initialize
      @original_stdout = $stdout
      @original_stderr = $stderr
      @stdout_stringio = StringIO.new
      @stderr_stringio = StringIO.new
    end

    # Capture with StringIO (default behavior - no TTY)
    def capture_with_stringio(&block)
      $stdout = @stdout_stringio
      $stderr = @stderr_stringio

      yield

      @stdout_content = @stdout_stringio.string
      @stderr_content = @stderr_stringio.string
      @stdout_raw = @stdout_content
      @stderr_raw = @stderr_content

      self
    ensure
      $stdout = @original_stdout
      $stderr = @original_stderr
    end

    # Capture with forced color (FORCE_COLOR=1)
    def capture_with_forced_color(&block)
      original_force_color = ENV['FORCE_COLOR']
      ENV['FORCE_COLOR'] = '1'

      capture_with_stringio(&block)
    ensure
      if original_force_color
        ENV['FORCE_COLOR'] = original_force_color
      else
        ENV.delete('FORCE_COLOR')
      end
    end

    # Capture with TTY simulation (mock $stdout.tty? to return true)
    def capture_with_tty_simulation(&block)
      # Create a custom StringIO that responds to tty? as true
      tty_stdout = StringIO.new
      tty_stderr = StringIO.new

      # Define singleton methods to make them behave like TTY
      def tty_stdout.tty?
        true
      end

      def tty_stderr.tty?
        true
      end

      $stdout = tty_stdout
      $stderr = tty_stderr

      yield

      @stdout_content = tty_stdout.string
      @stderr_content = tty_stderr.string
      @stdout_raw = @stdout_content
      @stderr_raw = @stderr_content

      self
    ensure
      $stdout = @original_stdout
      $stderr = @original_stderr
    end

    # Check if captured output contains ANSI codes
    def stdout_has_ansi?
      AnsiColorTestingHelper.has_ansi_codes?(@stdout_content)
    end

    def stderr_has_ansi?
      AnsiColorTestingHelper.has_ansi_codes?(@stderr_content)
    end

    # Get clean text without ANSI codes
    def stdout_clean
      AnsiColorTestingHelper.strip_ansi(@stdout_content)
    end

    def stderr_clean
      AnsiColorTestingHelper.strip_ansi(@stderr_content)
    end

    # Get only the ANSI codes from output
    def stdout_ansi_codes
      AnsiColorTestingHelper.extract_ansi_codes(@stdout_content)
    end

    def stderr_ansi_codes
      AnsiColorTestingHelper.extract_ansi_codes(@stderr_content)
    end

    # Behavior matrix results
    def behavior_summary
      {
        stdout_has_ansi: stdout_has_ansi?,
        stderr_has_ansi: stderr_has_ansi?,
        stdout_length: @stdout_content.length,
        stderr_length: @stderr_content.length,
        stdout_clean_length: stdout_clean.length,
        stderr_clean_length: stderr_clean.length,
        ansi_codes_count: (stdout_ansi_codes + stderr_ansi_codes).length
      }
    end
  end

  # Convenience methods for quick testing
  def self.capture_output(&block)
    OutputCapture.new.capture_with_stringio(&block)
  end

  def self.capture_with_color(&block)
    OutputCapture.new.capture_with_forced_color(&block)
  end

  def self.capture_with_tty(&block)
    OutputCapture.new.capture_with_tty_simulation(&block)
  end

  # Behavior matrix testing - runs the same block with different capture methods
  def self.test_behavior_matrix(&block)
    {
      stringio_default: capture_output(&block),
      forced_color: capture_with_color(&block),
      tty_simulation: capture_with_tty(&block)
    }
  end

  # RSpec matchers integration
  module RSpecMatchers
    def self.define_matchers
      return unless defined?(RSpec)

      RSpec::Matchers.define :have_ansi_codes do
        match do |text|
          AnsiColorTestingHelper.has_ansi_codes?(text)
        end

        failure_message do |text|
          "expected #{text.inspect} to contain ANSI color codes"
        end

        failure_message_when_negated do |text|
          "expected #{text.inspect} not to contain ANSI color codes, but found: #{AnsiColorTestingHelper.extract_ansi_codes(text)}"
        end
      end

      RSpec::Matchers.define :have_clean_text do |expected|
        match do |text|
          AnsiColorTestingHelper.strip_ansi(text) == expected
        end

        failure_message do |text|
          clean = AnsiColorTestingHelper.strip_ansi(text)
          "expected clean text to be #{expected.inspect}, but got #{clean.inspect}"
        end
      end

      RSpec::Matchers.define :output_with_ansi do |expected_clean_text|
        supports_block_expectations

        match do |block|
          capture = AnsiColorTestingHelper.capture_output(&block)
          @actual_clean = capture.stdout_clean
          @has_ansi = capture.stdout_has_ansi?

          @actual_clean == expected_clean_text && @has_ansi
        end

        failure_message do
          messages = []
          messages << 'expected output to contain ANSI codes' unless @has_ansi
          messages << "expected clean text to be #{expected_clean_text.inspect}, but got #{@actual_clean.inspect}" if @actual_clean != expected_clean_text
          messages.join(' and ')
        end
      end
    end
  end
end

# Auto-define matchers in RSpec if available
AnsiColorTestingHelper::RSpecMatchers.define_matchers if defined?(RSpec)

# Integration with existing CLI test patterns
module AnsiColorTestingHelper
  module CliIntegration
    # Helper for testing CLI commands with color output
    def with_color_capture(scenario: :default, &block)
      case scenario
      when :default
        AnsiColorTestingHelper.capture_output(&block)
      when :force_color
        AnsiColorTestingHelper.capture_with_color(&block)
      when :tty
        AnsiColorTestingHelper.capture_with_tty(&block)
      else
        raise ArgumentError, "Unknown scenario: #{scenario}"
      end
    end

    # Test a command across all color scenarios
    def test_command_color_matrix(command_proc)
      {
        no_color: with_color_capture(scenario: :default, &command_proc),
        force_color: with_color_capture(scenario: :force_color, &command_proc),
        tty_color: with_color_capture(scenario: :tty, &command_proc)
      }
    end

    # Verify color consistency across scenarios
    def expect_consistent_clean_output(results, expected_clean_text)
      results.each do |scenario, output|
        expect(output.stdout_clean).to eq(expected_clean_text),
          "Clean output mismatch in #{scenario} scenario"
      end
    end

    # Example CLI color implementation pattern
    def self.example_colorized_output(text, color, options = {})
      use_color = should_use_color?(options)
      if use_color
        AnsiColorTestingHelper.colorize(text, color)
      else
        text
      end
    end

    private_class_method

    def self.should_use_color?(options = {})
      # Example color detection logic for CLI apps
      return false if ENV['NO_COLOR']
      return true if ENV['FORCE_COLOR'] || options[:force_color]
      return options[:tty] if options.key?(:tty)
      $stdout.tty?
    end
  end
end

# Include integration helpers in RSpec if available
if defined?(RSpec)
  RSpec.configure do |config|
    config.include AnsiColorTestingHelper::CliIntegration
  end
end
