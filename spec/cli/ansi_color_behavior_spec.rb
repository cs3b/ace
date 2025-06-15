# frozen_string_literal: true

require "spec_helper"
require_relative "../support/ansi_color_testing_helper"

RSpec.describe "ANSI Color Behavior Matrix" do
  include AnsiColorTestingHelper::RSpecMatchers if defined?(AnsiColorTestingHelper::RSpecMatchers)

  describe "StringIO behavior with ANSI codes" do
    it "captures ANSI escape sequences as literal strings" do
      output = AnsiColorTestingHelper.capture_output do
        puts AnsiColorTestingHelper.red("Hello World")
      end

      expect(output.stdout_content).to include("\033[31m")
      expect(output.stdout_content).to include("\033[0m")
      expect(output.stdout_clean).to eq("Hello World\n")
      expect(output.stdout_has_ansi?).to be true
    end

    it "preserves all ANSI codes in captured output" do
      colored_text = AnsiColorTestingHelper.colorize("Bold Red", :bold, :red)

      output = AnsiColorTestingHelper.capture_output do
        puts colored_text
      end

      codes = output.stdout_ansi_codes
      expect(codes).to include("\033[1m")  # bold
      expect(codes).to include("\033[31m") # red
      expect(codes).to include("\033[0m")  # reset
      expect(codes.length).to eq(3)
    end
  end

  describe "Environment variable behavior" do
    it "captures ANSI codes regardless of FORCE_COLOR setting with StringIO" do
      # With FORCE_COLOR=1
      output_forced = AnsiColorTestingHelper.capture_with_color do
        puts AnsiColorTestingHelper.green("Forced Color")
      end

      # Without FORCE_COLOR (default StringIO)
      output_default = AnsiColorTestingHelper.capture_output do
        puts AnsiColorTestingHelper.green("Default")
      end

      expect(output_forced.stdout_has_ansi?).to be true
      expect(output_default.stdout_has_ansi?).to be true
      expect(output_forced.stdout_clean).to eq("Forced Color\n")
      expect(output_default.stdout_clean).to eq("Default\n")
    end

    it "preserves FORCE_COLOR environment variable after testing" do
      original_force_color = ENV["FORCE_COLOR"]

      AnsiColorTestingHelper.capture_with_color do
        puts "test"
      end

      expect(ENV["FORCE_COLOR"]).to eq(original_force_color)
    end
  end

  describe "TTY simulation behavior" do
    it "captures ANSI codes with TTY simulation" do
      output = AnsiColorTestingHelper.capture_with_tty do
        puts AnsiColorTestingHelper.blue("TTY Blue Text")
      end

      expect(output.stdout_has_ansi?).to be true
      expect(output.stdout_clean).to eq("TTY Blue Text\n")

      # Verify the ANSI codes are present
      expect(output.stdout_ansi_codes).to include("\033[34m") # blue
      expect(output.stdout_ansi_codes).to include("\033[0m")  # reset
    end
  end

  describe "Behavior matrix comparison" do
    let(:test_text) { "Test Message" }
    let(:colored_test) { AnsiColorTestingHelper.yellow(test_text) }

    it "demonstrates consistent ANSI capture across all scenarios" do
      results = AnsiColorTestingHelper.test_behavior_matrix do
        puts colored_test
      end

      # All scenarios should capture ANSI codes with StringIO
      expect(results[:stringio_default].stdout_has_ansi?).to be true
      expect(results[:forced_color].stdout_has_ansi?).to be true
      expect(results[:tty_simulation].stdout_has_ansi?).to be true

      # All should produce the same clean text
      clean_texts = results.values.map(&:stdout_clean)
      expect(clean_texts.uniq).to eq(["#{test_text}\n"])

      # All should have the same ANSI codes
      ansi_codes = results.values.map(&:stdout_ansi_codes)
      expect(ansi_codes.uniq.length).to eq(1) # All identical
      expect(ansi_codes.first).to include("\033[33m") # yellow
      expect(ansi_codes.first).to include("\033[0m")  # reset
    end

    it "captures stderr ANSI codes correctly" do
      output = AnsiColorTestingHelper.capture_output do
        warn AnsiColorTestingHelper.red("Error Message")
      end

      expect(output.stderr_has_ansi?).to be true
      expect(output.stderr_clean).to eq("Error Message\n")
      expect(output.stderr_ansi_codes).to include("\033[31m") # red
    end
  end

  describe "Helper utility methods" do
    it "correctly identifies ANSI codes" do
      plain_text = "Hello World"
      colored_text = AnsiColorTestingHelper.red("Hello World")

      expect(AnsiColorTestingHelper.has_ansi_codes?(plain_text)).to be false
      expect(AnsiColorTestingHelper.has_ansi_codes?(colored_text)).to be true
    end

    it "strips ANSI codes correctly" do
      colored_text = AnsiColorTestingHelper.colorize("Multi", :bold, :green, :underline)
      clean_text = AnsiColorTestingHelper.strip_ansi(colored_text)

      expect(clean_text).to eq("Multi")
      expect(AnsiColorTestingHelper.has_ansi_codes?(clean_text)).to be false
    end

    it "extracts ANSI codes correctly" do
      text_with_codes = "\033[1m\033[32mBold Green\033[0m"
      codes = AnsiColorTestingHelper.extract_ansi_codes(text_with_codes)

      expect(codes).to eq(["\033[1m", "\033[32m", "\033[0m"])
    end
  end

  describe "Complex ANSI scenarios" do
    it "handles nested and multiple color codes" do
      complex_text = "#{AnsiColorTestingHelper.bold("Bold")} and #{AnsiColorTestingHelper.red("Red")} text"

      output = AnsiColorTestingHelper.capture_output do
        puts complex_text
      end

      expect(output.stdout_has_ansi?).to be true
      expect(output.stdout_clean).to eq("Bold and Red text\n")

      codes = output.stdout_ansi_codes
      expect(codes.count("\033[1m")).to eq(1)  # bold
      expect(codes.count("\033[31m")).to eq(1) # red
      expect(codes.count("\033[0m")).to eq(2)  # reset (2 times)
    end

    it "handles background colors and combinations" do
      bg_text = "\033[42m\033[31mRed on Green\033[0m"

      output = AnsiColorTestingHelper.capture_output do
        puts bg_text
      end

      codes = output.stdout_ansi_codes
      expect(codes).to include("\033[42m") # green background
      expect(codes).to include("\033[31m") # red foreground
      expect(codes).to include("\033[0m")  # reset
      expect(output.stdout_clean).to eq("Red on Green\n")
    end
  end

  describe "Side-effect management" do
    it "restores original stdout/stderr after capture" do
      original_stdout = $stdout
      original_stderr = $stderr

      AnsiColorTestingHelper.capture_output do
        puts "test output"
      end

      expect($stdout).to be(original_stdout)
      expect($stderr).to be(original_stderr)
    end

    it "handles exceptions during capture gracefully" do
      original_stdout = $stdout

      expect {
        AnsiColorTestingHelper.capture_output do
          raise StandardError, "test error"
        end
      }.to raise_error(StandardError, "test error")

      # stdout should still be restored
      expect($stdout).to be(original_stdout)
    end
  end

  describe "Performance characteristics" do
    it "captures large amounts of colored output efficiently" do
      large_text = (1..100).map { |i| AnsiColorTestingHelper.colorize("Line #{i}", :green) }.join("\n")

      start_time = Time.now
      output = AnsiColorTestingHelper.capture_output do
        puts large_text
      end
      end_time = Time.now

      expect(end_time - start_time).to be < 1.0 # Should complete in under 1 second
      expect(output.stdout_has_ansi?).to be true
      expect(output.stdout_ansi_codes.length).to eq(200) # 100 color + 100 reset codes
    end
  end

  describe "Integration with existing test patterns" do
    it "works with RSpec output matchers if available" do
      skip "RSpec matchers not available" unless defined?(AnsiColorTestingHelper::RSpecMatchers)

      colored_output = AnsiColorTestingHelper.red("Test Output")
      expect(colored_output).to have_ansi_codes
      expect(colored_output).to have_clean_text("Test Output")
    end

    it "provides behavior summary for debugging" do
      output = AnsiColorTestingHelper.capture_output do
        puts AnsiColorTestingHelper.blue("Summary Test")
        warn AnsiColorTestingHelper.red("Error")
      end

      summary = output.behavior_summary
      expect(summary[:stdout_has_ansi]).to be true
      expect(summary[:stderr_has_ansi]).to be true
      expect(summary[:ansi_codes_count]).to eq(4) # 2 colors + 2 resets
      expect(summary[:stdout_clean_length]).to be > 0
      expect(summary[:stderr_clean_length]).to be > 0
    end
  end

  describe "Real-world CLI simulation scenarios" do
    it "simulates typical CLI command output with colors" do
      # Simulate a CLI command that might output colored status messages
      output = AnsiColorTestingHelper.capture_output do
        puts "#{AnsiColorTestingHelper.green("✓")} Success: Operation completed"
        puts "#{AnsiColorTestingHelper.yellow("!")} Warning: Minor issue detected"
        puts "#{AnsiColorTestingHelper.red("✗")} Error: Critical failure"

        warn "#{AnsiColorTestingHelper.red("DEBUG:")} Detailed error information"
      end

      # Verify we can test both the visual markers and clean text
      expect(output.stdout_clean).to include("✓ Success: Operation completed")
      expect(output.stdout_clean).to include("! Warning: Minor issue detected")
      expect(output.stdout_clean).to include("✗ Error: Critical failure")
      expect(output.stderr_clean).to include("DEBUG: Detailed error information")

      # Verify colors are preserved for manual inspection if needed
      expect(output.stdout_has_ansi?).to be true
      expect(output.stderr_has_ansi?).to be true
    end

    it "handles mixed plain and colored output" do
      output = AnsiColorTestingHelper.capture_output do
        puts "Plain text line"
        puts AnsiColorTestingHelper.blue("Colored line")
        puts "Another plain line"
      end

      expect(output.stdout_has_ansi?).to be true
      expect(output.stdout_clean).to eq("Plain text line\nColored line\nAnother plain line\n")

      # Should have exactly 2 ANSI codes (blue + reset)
      expect(output.stdout_ansi_codes.length).to eq(2)
    end
  end
end
