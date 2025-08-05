# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Atoms::Git::LogColorFormatter do
  let(:formatter) { described_class.new }
  let(:formatter_no_color) { described_class.new(no_color: true) }
  let(:formatter_force_color) { described_class.new(force_color: true) }

  describe '.format_commit' do
    it 'creates new instance and formats commit' do
      commit = {
        type: :oneline,
        display_line: 'abc123 Initial commit'
      }

      result = described_class.format_commit(commit)
      expect(result).to be_a(String)
      expect(result).to include('abc123')
      expect(result).to include('Initial commit')
    end

    it 'passes options to new instance' do
      commit = {
        type: :oneline,
        display_line: 'abc123 Initial commit'
      }

      result_with_color = described_class.format_commit(commit)
      result_no_color = described_class.format_commit(commit, no_color: true)

      expect(result_with_color).not_to eq(result_no_color)
      expect(result_no_color).to eq('abc123 Initial commit')
    end
  end

  describe '.should_use_color?' do
    it 'creates new instance and checks color usage' do
      result_default = described_class.should_use_color?
      result_no_color = described_class.should_use_color?(no_color: true)

      expect(result_default).to be true
      expect(result_no_color).to be false
    end
  end

  describe '#initialize' do
    context 'with default options' do
      it 'enables color by default' do
        formatter = described_class.new
        expect(formatter.should_use_color?).to be true
      end
    end

    context 'with no_color option' do
      it 'disables color when no_color is true' do
        formatter = described_class.new(no_color: true)
        expect(formatter.should_use_color?).to be false
      end

      it 'enables color when no_color is false' do
        formatter = described_class.new(no_color: false)
        expect(formatter.should_use_color?).to be true
      end
    end

    context 'with force_color option' do
      it 'enables color when force_color is true' do
        formatter = described_class.new(force_color: true)
        expect(formatter.should_use_color?).to be true
      end

      it 'enables color when force_color is false' do
        formatter = described_class.new(force_color: false)
        expect(formatter.should_use_color?).to be true
      end
    end

    context 'with environment variables' do
      before do
        @original_no_color = ENV['NO_COLOR']
        @original_force_color = ENV['FORCE_COLOR']
      end

      after do
        ENV['NO_COLOR'] = @original_no_color
        ENV['FORCE_COLOR'] = @original_force_color
      end

      it 'disables color when NO_COLOR is set' do
        ENV['NO_COLOR'] = '1'
        formatter = described_class.new
        expect(formatter.should_use_color?).to be false
      end

      it 'enables color when FORCE_COLOR is set' do
        ENV['NO_COLOR'] = nil
        ENV['FORCE_COLOR'] = '1'
        formatter = described_class.new
        expect(formatter.should_use_color?).to be true
      end

      it 'prioritizes no_color option over environment variables' do
        ENV['FORCE_COLOR'] = '1'
        formatter = described_class.new(no_color: true)
        expect(formatter.should_use_color?).to be false
      end

      it 'prioritizes NO_COLOR env var over FORCE_COLOR env var' do
        ENV['NO_COLOR'] = '1'
        ENV['FORCE_COLOR'] = '1'
        formatter = described_class.new
        expect(formatter.should_use_color?).to be false
      end
    end
  end

  describe '#format_commit' do
    context 'with color disabled' do
      it 'returns original display_line for any commit type' do
        oneline_commit = {
          type: :oneline,
          display_line: 'abc123 Initial commit'
        }

        multiline_commit = {
          type: :multiline,
          display_line: "commit abc123\nAuthor: Test User\nDate: Mon Jan 1 12:00:00 2024\n\n    Initial commit"
        }

        expect(formatter_no_color.format_commit(oneline_commit)).to eq('abc123 Initial commit')
        expect(formatter_no_color.format_commit(multiline_commit)).to eq(multiline_commit[:display_line])
      end
    end

    context 'with oneline commit type' do
      it 'formats simple hash and message' do
        commit = {
          type: :oneline,
          display_line: 'abc123 Initial commit'
        }

        result = formatter.format_commit(commit)
        expect(result).to include("\033[33mabc123\033[0m") # Yellow hash
        expect(result).to include("\033[37mInitial commit\033[0m") # White message
      end

      it 'handles commit with longer hash' do
        commit = {
          type: :oneline,
          display_line: 'a1b2c3d4e5f6 Add new feature with tests'
        }

        result = formatter.format_commit(commit)
        expect(result).to include("\033[33ma1b2c3d4e5f6\033[0m")
        expect(result).to include("\033[37mAdd new feature with tests\033[0m")
      end

      it 'handles commit with complex message' do
        commit = {
          type: :oneline,
          display_line: 'abc123 feat(api): add user authentication (#123)'
        }

        result = formatter.format_commit(commit)
        expect(result).to include("\033[33mabc123\033[0m")
        expect(result).to include("\033[37mfeat(api): add user authentication (#123)\033[0m")
      end

      it 'handles malformed display line' do
        commit = {
          type: :oneline,
          display_line: 'not-a-valid-format'
        }

        result = formatter.format_commit(commit)
        expect(result).to eq("\033[37mnot-a-valid-format\033[0m")
      end

      it 'handles empty display line' do
        commit = {
          type: :oneline,
          display_line: ''
        }

        result = formatter.format_commit(commit)
        expect(result).to eq("\033[37m\033[0m")
      end

      it 'handles display line with only hash' do
        commit = {
          type: :oneline,
          display_line: 'abc123'
        }

        result = formatter.format_commit(commit)
        expect(result).to eq("\033[37mabc123\033[0m")
      end
    end

    context 'with multiline commit type' do
      let(:multiline_commit) do
        {
          type: :multiline,
          display_line: <<~COMMIT.chomp
            commit a1b2c3d4e5f67890abcdef1234567890abcdef12
            Author: John Doe <john@example.com>
            Date:   Mon Jan 1 12:00:00 2024 +0000

                Initial commit

                This is the commit body with more details.
                It spans multiple lines.
          COMMIT
        }
      end

      it 'formats commit hash line' do
        result = formatter.format_commit(multiline_commit)
        expect(result).to include("\033[1mcommit\033[0m \033[33ma1b2c3d4e5f67890abcdef1234567890abcdef12\033[0m")
      end

      it 'formats author line' do
        result = formatter.format_commit(multiline_commit)
        expect(result).to include("\033[1mAuthor:\033[0m \033[36mJohn Doe <john@example.com>\033[0m")
      end

      it 'formats date line' do
        result = formatter.format_commit(multiline_commit)
        expect(result).to include("\033[1mDate:\033[0m   \033[32mMon Jan 1 12:00:00 2024 +0000\033[0m")
      end

      it 'formats indented commit message lines' do
        result = formatter.format_commit(multiline_commit)
        expect(result).to include("\033[37m    Initial commit\033[0m")
        expect(result).to include("\033[37m    This is the commit body with more details.\033[0m")
        expect(result).to include("\033[37m    It spans multiple lines.\033[0m")
      end

      it 'handles commit with minimal indentation' do
        minimal_commit = {
          type: :multiline,
          display_line: <<~COMMIT.chomp
            commit abc123
            Author: Test User
            Date: Mon Jan 1 12:00:00 2024

                Minimal commit
          COMMIT
        }

        result = formatter.format_commit(minimal_commit)
        expect(result).to include("\033[1mcommit\033[0m \033[33mabc123\033[0m")
        expect(result).to include("\033[37m    Minimal commit\033[0m")
      end

      it 'handles commit with extra metadata lines' do
        extended_commit = {
          type: :multiline,
          display_line: <<~COMMIT.chomp
            commit abc123
            Merge: def456 789abc
            Author: Jane Smith <jane@example.com>
            Date: Tue Jan 2 15:30:00 2024 -0500

                Merge branch 'feature' into main
          COMMIT
        }

        result = formatter.format_commit(extended_commit)
        expect(result).to include("\033[1mcommit\033[0m \033[33mabc123\033[0m")
        expect(result).to include("\033[37mMerge: def456 789abc\033[0m") # Other lines as commit_body
        expect(result).to include("\033[1mAuthor:\033[0m \033[36mJane Smith <jane@example.com>\033[0m")
      end

      it 'handles empty commit message' do
        empty_message_commit = {
          type: :multiline,
          display_line: <<~COMMIT.chomp
            commit abc123
            Author: Test User
            Date: Mon Jan 1 12:00:00 2024
          COMMIT
        }

        result = formatter.format_commit(empty_message_commit)
        expect(result).to include("\033[1mcommit\033[0m \033[33mabc123\033[0m")
        expect(result).not_to include("\033[37m    ") # No indented message
      end
    end

    context 'with unknown commit type' do
      it 'returns original display_line' do
        commit = {
          type: :unknown,
          display_line: 'some unknown format'
        }

        result = formatter.format_commit(commit)
        expect(result).to eq('some unknown format')
      end

      it 'handles nil commit type' do
        commit = {
          type: nil,
          display_line: 'no type specified'
        }

        result = formatter.format_commit(commit)
        expect(result).to eq('no type specified')
      end
    end

    context 'with missing or malformed commit data' do
      it 'handles commit without display_line' do
        commit = { type: :oneline }

        expect { formatter.format_commit(commit) }.not_to raise_error
      end

      it 'handles nil commit' do
        expect { formatter.format_commit(nil) }.to raise_error(NoMethodError)
      end

      it 'handles empty commit hash' do
        commit = {}

        expect { formatter.format_commit(commit) }.not_to raise_error
      end
    end
  end

  describe 'COLORS constant' do
    it 'defines all required color codes' do
      expected_colors = [
        :reset, :repo_name, :commit_hash, :author, :date,
        :commit_subject, :commit_body, :bold, :dim
      ]

      expected_colors.each do |color|
        expect(described_class::COLORS).to have_key(color)
        expect(described_class::COLORS[color]).to be_a(String)
        expect(described_class::COLORS[color]).to start_with("\033[")
      end
    end

    it 'has valid ANSI escape sequences' do
      described_class::COLORS.each do |name, code|
        expect(code).to match(/\A\033\[\d+(;\d+)*m\z/), "#{name} should be valid ANSI escape sequence"
      end
    end

    it 'is frozen to prevent modification' do
      expect(described_class::COLORS).to be_frozen
    end
  end

  describe 'comprehensive edge cases and error handling' do
    context 'with malformed git log output' do
      it 'handles corrupted commit hash lines' do
        malformed_commit = {
          type: :multiline,
          display_line: <<~COMMIT.chomp
            commit 
            Author: Test User
            Date: Invalid Date Format

                Commit with issues
          COMMIT
        }

        result = formatter.format_commit(malformed_commit)
        # "commit " line doesn't match the commit pattern, so gets treated as commit_body
        expect(result).to include("\033[37mcommit \033[0m")
      end

      it 'handles missing author information' do
        no_author_commit = {
          type: :multiline,
          display_line: <<~COMMIT.chomp
            commit abc123
            Date: Mon Jan 1 12:00:00 2024

                Commit without author
          COMMIT
        }

        result = formatter.format_commit(no_author_commit)
        expect(result).to include("\033[1mcommit\033[0m \033[33mabc123\033[0m")
        expect(result).not_to include('Author:')
      end

      it 'handles malformed author lines' do
        malformed_author_commit = {
          type: :multiline,
          display_line: <<~COMMIT.chomp
            commit abc123
            Author:
            Date: Mon Jan 1 12:00:00 2024

                Commit with empty author
          COMMIT
        }

        result = formatter.format_commit(malformed_author_commit)
        # "Author:" line doesn't match the author pattern, so gets treated as commit_body
        expect(result).to include("\033[37mAuthor:\033[0m")
      end

      it 'handles very long commit messages' do
        long_message = 'Very long commit message ' * 100
        long_commit = {
          type: :oneline,
          display_line: "abc123 #{long_message}"
        }

        result = formatter.format_commit(long_commit)
        expect(result).to include(long_message)
        expect(result.length).to be > 2000
      end
    end

    context 'with special characters and encoding' do
      it 'handles Unicode characters in commit messages' do
        unicode_commit = {
          type: :oneline,
          display_line: 'abc123 Add 🚀 emoji and 中文 characters'
        }

        result = formatter.format_commit(unicode_commit)
        expect(result).to include('🚀')
        expect(result).to include('中文')
      end

      it 'handles special characters in author names' do
        special_author_commit = {
          type: :multiline,
          display_line: <<~COMMIT.chomp
            commit abc123
            Author: José María García <josé@example.com>
            Date: Mon Jan 1 12:00:00 2024

                Commit with special characters in author
          COMMIT
        }

        result = formatter.format_commit(special_author_commit)
        expect(result).to include('José María García')
      end

      it 'handles newlines and control characters in commit data' do
        newline_commit = {
          type: :oneline,
          display_line: 'abc123 Commit\\nwith\\nembedded\\nnewlines'
        }

        result = formatter.format_commit(newline_commit)
        expect(result).to include('\\n')
      end
    end

    context 'with color edge cases' do
      it 'handles nested color codes safely' do
        commit_with_colors = {
          type: :oneline,
          display_line: "abc123 Message with \033[31mexisting\033[0m colors"
        }

        result = formatter.format_commit(commit_with_colors)
        expect(result).to include("\033[31mexisting\033[0m")
        expect(result).to include("\033[33mabc123\033[0m")
      end

      it 'handles unknown color keys gracefully' do
        # Test the colorize method directly with invalid color
        result = formatter.send(:colorize, 'test text', :invalid_color)
        expect(result).to eq('test text') # Should return text unchanged for invalid color
      end
    end

    context 'with performance considerations' do
      it 'handles many commits efficiently' do
        commits = 1000.times.map do |i|
          {
            type: :oneline,
            display_line: "commit#{i} Message for commit #{i}"
          }
        end

        start_time = Time.now
        results = commits.map { |commit| formatter.format_commit(commit) }
        end_time = Time.now

        expect(results.size).to eq(1000)
        expect(end_time - start_time).to be < 1.0 # Should be fast
      end

      it 'handles very large multiline commits efficiently' do
        large_body = (1..100).map { |i| "    Line #{i} of the commit message" }.join("\n")
        large_commit = {
          type: :multiline,
          display_line: <<~COMMIT.chomp
            commit abc123
            Author: Test User
            Date: Mon Jan 1 12:00:00 2024

            #{large_body}
          COMMIT
        }

        start_time = Time.now
        result = formatter.format_commit(large_commit)
        end_time = Time.now

        expect(result).to include('Line 1 of')
        expect(result).to include('Line 100 of')
        expect(end_time - start_time).to be < 0.1
      end
    end

    context 'with concurrent access' do
      it 'maintains thread safety during formatting' do
        commit = {
          type: :oneline,
          display_line: 'abc123 Thread safety test'
        }

        threads = []
        results = Queue.new

        10.times do
          threads << Thread.new do
            local_formatter = described_class.new
            results << local_formatter.format_commit(commit)
          end
        end

        threads.each(&:join)

        # All results should be identical
        first_result = results.pop
        until results.empty?
          expect(results.pop).to eq(first_result)
        end
      end
    end

    context 'with environment variable edge cases' do
      before do
        @original_env = ENV.to_hash
      end

      after do
        ENV.clear
        ENV.update(@original_env)
      end

      it 'handles empty environment variables' do
        ENV['NO_COLOR'] = ''
        ENV['FORCE_COLOR'] = ''

        formatter = described_class.new
        # Empty string for NO_COLOR is still truthy in Ruby, so color is disabled
        expect(formatter.should_use_color?).to be false
      end

      it 'handles unusual environment variable values' do
        ENV['NO_COLOR'] = 'false' # String "false" is truthy
        formatter = described_class.new
        expect(formatter.should_use_color?).to be false

        ENV['NO_COLOR'] = nil
        ENV['FORCE_COLOR'] = '0' # String "0" is truthy
        formatter = described_class.new
        expect(formatter.should_use_color?).to be true
      end
    end
  end

  describe 'algorithm correctness verification' do
    context 'color code application' do
      it 'properly wraps text with color codes' do
        commit = {
          type: :oneline,
          display_line: 'abc123 Test message'
        }

        result = formatter.format_commit(commit)

        # Should have opening color code, text, and reset code for each colored element
        expect(result.scan(/\033\[33m/).length).to eq(1) # One yellow (hash)
        expect(result.scan(/\033\[37m/).length).to eq(1) # One white (message)
        expect(result.scan(/\033\[0m/).length).to eq(2)  # Two resets
      end

      it 'applies correct colors to multiline elements' do
        commit = {
          type: :multiline,
          display_line: <<~COMMIT.chomp
            commit abc123
            Author: Test User
            Date: Mon Jan 1 12:00:00 2024

                Test message
          COMMIT
        }

        result = formatter.format_commit(commit)

        # Check for specific color applications
        expect(result).to include("\033[1mcommit\033[0m")      # Bold "commit"
        expect(result).to include("\033[33mabc123\033[0m")     # Yellow hash
        expect(result).to include("\033[1mAuthor:\033[0m")     # Bold "Author:"
        expect(result).to include("\033[36mTest User\033[0m")  # Cyan author
        expect(result).to include("\033[1mDate:\033[0m")       # Bold "Date:"
        expect(result).to include("\033[32mMon Jan 1")         # Green date
        expect(result).to include("\033[37m    Test message")  # White message
      end
    end

    context 'pattern matching accuracy' do
      it 'correctly identifies commit hash patterns' do
        test_cases = [
          'abc123 Message',
          'a1b2c3d4e5f6 Longer hash',
          '1234567890abcdef Message with numbers',
          'short Message'  # Edge case: very short hash
        ]

        test_cases.each do |display_line|
          commit = { type: :oneline, display_line: display_line }
          result = formatter.format_commit(commit)

          # Should always contain yellow color for hash part
          expect(result).to include("\033[33m")
        end
      end

      it 'correctly identifies multiline patterns' do
        patterns_to_test = [
          ['commit abc123', 'commit', 'abc123'],
          ['Author: John Doe', 'Author:', 'John Doe'],
          ['Date:   Mon Jan 1 12:00:00 2024', 'Date:', 'Mon Jan 1 12:00:00 2024']
        ]

        patterns_to_test.each do |line, label, value|
          commit = { type: :multiline, display_line: line }
          result = formatter.format_commit(commit)

          expect(result).to include(label) if label
          expect(result).to include(value) if value
        end
      end
    end

    context 'output format consistency' do
      it 'maintains consistent formatting across similar commits' do
        commits = [
          { type: :oneline, display_line: 'abc123 First commit' },
          { type: :oneline, display_line: 'def456 Second commit' },
          { type: :oneline, display_line: '789abc Third commit' }
        ]

        results = commits.map { |commit| formatter.format_commit(commit) }

        # All should have same structure: yellow hash, space, white message
        results.each do |result|
          expect(result).to match(/\033\[33m\w+\033\[0m \033\[37m.+\033\[0m/)
        end
      end
    end
  end
end
