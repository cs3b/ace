# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/atoms/git/status_color_formatter'

RSpec.describe CodingAgentTools::Atoms::Git::StatusColorFormatter do
  let(:formatter) { described_class.new }
  let(:repo_name) { 'test-repo' }

  describe 'COLORS constant' do
    it 'defines all necessary color codes' do
      expect(described_class::COLORS).to include(
        :reset, :red, :green, :yellow, :blue, :bold,
        :staged_new, :staged_modified, :staged_deleted,
        :modified, :deleted, :untracked, :branch, :header, :meta
      )
    end

    it 'uses valid ANSI escape codes' do
      described_class::COLORS.each do |name, code|
        expect(code).to match(/\A\033\[\d+m\z/), "#{name} should be a valid ANSI escape code"
      end
    end
  end

  describe '.format_repository_status' do
    context 'with clean repository' do
      let(:clean_status) { '' }

      it 'returns clean repository message with color' do
        result = described_class.format_repository_status(repo_name, clean_status)

        expect(result).to include("[#{repo_name}]")
        expect(result).to include('Clean working directory')
        expect(result).to include("\033[32m") # Green color
      end

      it 'respects no_color option' do
        result = described_class.format_repository_status(repo_name, clean_status, no_color: true)

        expect(result).to include("[#{repo_name}]")
        expect(result).to include('Clean working directory')
        expect(result).not_to include("\033[")
      end
    end

    context 'with repository changes' do
      let(:status_with_changes) do
        <<~STATUS
          On branch main
          Changes to be committed:
            modified:   file1.rb
            new file:   file2.rb
          
          Changes not staged for commit:
            modified:   file3.rb
            deleted:    file4.rb
        STATUS
      end

      it 'formats repository with changes' do
        result = described_class.format_repository_status(repo_name, status_with_changes)

        expect(result).to include('Status:')
        expect(result).to include('On branch')
        expect(result).to include('Changes to be committed')
        expect(result).to include('modified:')
        expect(result).to include('new file:')
      end

      it 'adds indentation to status lines' do
        result = described_class.format_repository_status(repo_name, status_with_changes)
        lines = result.split("\n")

        # Check that status lines are indented
        status_lines = lines[1..-1] # Skip the header line
        status_lines.each do |line|
          expect(line).to start_with('  ')
        end
      end
    end

    context 'with untracked files' do
      let(:status_with_untracked) do
        <<~STATUS
          On branch main
          Untracked files:
            new_file.rb
            another_file.txt
        STATUS
      end

      it 'formats untracked files with appropriate color' do
        result = described_class.format_repository_status(repo_name, status_with_untracked)

        expect(result).to include('Untracked files:')
        expect(result).to include('new_file.rb')
        expect(result).to include("\033[33m") # Yellow color for header
      end
    end
  end

  describe '.should_use_color?' do
    it 'respects options parameter' do
      expect(described_class.should_use_color?(no_color: true)).to be false
      expect(described_class.should_use_color?(force_color: true)).to be true
    end
  end

  describe '#initialize' do
    context 'with default options' do
      it 'enables colors by default' do
        formatter = described_class.new

        expect(formatter.should_use_color?).to be true
      end
    end

    context 'with no_color option' do
      it 'disables colors when no_color is true' do
        formatter = described_class.new(no_color: true)

        expect(formatter.should_use_color?).to be false
      end
    end

    context 'with force_color option' do
      it 'enables colors when force_color is true' do
        formatter = described_class.new(force_color: true)

        expect(formatter.should_use_color?).to be true
      end
    end

    context 'with environment variables' do
      before do
        allow(ENV).to receive(:[]).and_call_original
      end

      it 'respects NO_COLOR environment variable' do
        allow(ENV).to receive(:[]).with('NO_COLOR').and_return('1')
        formatter = described_class.new

        expect(formatter.should_use_color?).to be false
      end

      it 'respects FORCE_COLOR environment variable' do
        allow(ENV).to receive(:[]).with('FORCE_COLOR').and_return('1')
        allow(ENV).to receive(:[]).with('NO_COLOR').and_return(nil)
        formatter = described_class.new

        expect(formatter.should_use_color?).to be true
      end

      it 'prioritizes NO_COLOR over FORCE_COLOR' do
        allow(ENV).to receive(:[]).with('NO_COLOR').and_return('1')
        allow(ENV).to receive(:[]).with('FORCE_COLOR').and_return('1')
        formatter = described_class.new

        expect(formatter.should_use_color?).to be false
      end
    end
  end

  describe '#format_repository_status' do
    let(:formatter_with_color) { described_class.new(force_color: true) }
    let(:formatter_no_color) { described_class.new(no_color: true) }

    context 'with different status types' do
      it 'determines clean status correctly' do
        result = formatter_with_color.format_repository_status(repo_name, '')

        expect(result).to include('Clean working directory')
        expect(result).to include("\033[32m") # Green
      end

      it 'determines changes status correctly' do
        status = 'modified:   file.rb'
        result = formatter_with_color.format_repository_status(repo_name, status)

        expect(result).to include('Status:')
        expect(result).to include("\033[31m") # Red for changes
      end

      it 'determines untracked status correctly' do
        status = "Untracked files:\n  file.rb"
        result = formatter_with_color.format_repository_status(repo_name, status)

        expect(result).to include("\033[33m") # Yellow for untracked
      end
    end
  end

  describe 'private methods' do
    let(:formatter_with_color) { described_class.new(force_color: true) }
    let(:formatter_no_color) { described_class.new(no_color: true) }

    describe '#determine_color_usage' do
      it 'returns false when no_color option is set' do
        options = { no_color: true }
        result = formatter_with_color.send(:determine_color_usage, options)

        expect(result).to be false
      end

      it 'returns true when force_color option is set' do
        options = { force_color: true }
        result = formatter_no_color.send(:determine_color_usage, options)

        expect(result).to be true
      end

      it 'returns true by default' do
        options = {}
        result = formatter_with_color.send(:determine_color_usage, options)

        expect(result).to be true
      end
    end

    describe '#determine_status_type' do
      it 'recognizes clean status' do
        result = formatter_with_color.send(:determine_status_type, '')

        expect(result).to eq(:clean)
      end

      it 'recognizes conflict status' do
        status = 'both modified: file.rb'
        result = formatter_with_color.send(:determine_status_type, status)

        expect(result).to eq(:conflict)
      end

      it 'recognizes changes status' do
        status = 'modified: file.rb'
        result = formatter_with_color.send(:determine_status_type, status)

        expect(result).to eq(:changes)
      end

      it 'recognizes untracked status' do
        status = "Untracked files:\n  file.rb"
        result = formatter_with_color.send(:determine_status_type, status)

        expect(result).to eq(:untracked)
      end

      it 'defaults to changes for non-empty unknown status' do
        status = 'some unknown status output'
        result = formatter_with_color.send(:determine_status_type, status)

        expect(result).to eq(:changes)
      end
    end

    describe '#color_for_status' do
      it 'maps status types to correct colors' do
        expect(formatter_with_color.send(:color_for_status, :clean)).to eq(:green)
        expect(formatter_with_color.send(:color_for_status, :changes)).to eq(:red)
        expect(formatter_with_color.send(:color_for_status, :conflict)).to eq(:red)
        expect(formatter_with_color.send(:color_for_status, :untracked)).to eq(:yellow)
        expect(formatter_with_color.send(:color_for_status, :unknown)).to eq(:blue)
        expect(formatter_with_color.send(:color_for_status, :invalid)).to eq(:reset)
      end
    end

    describe '#format_clean_repository' do
      it 'formats clean repository with color' do
        result = formatter_with_color.send(:format_clean_repository, repo_name, :green)

        expect(result).to include("[#{repo_name}]")
        expect(result).to include('Clean working directory')
        expect(result).to include("\033[32m") # Green
        expect(result).to include("\033[0m")  # Reset
      end

      it 'formats clean repository without color' do
        result = formatter_no_color.send(:format_clean_repository, repo_name, :green)

        expect(result).to include("[#{repo_name}]")
        expect(result).to include('Clean working directory')
        expect(result).not_to include("\033[")
      end
    end

    describe '#format_repository_with_changes' do
      let(:status_output) { "modified:   file.rb\nnew file:   another.rb" }

      it 'formats repository with changes and color' do
        result = formatter_with_color.send(:format_repository_with_changes, repo_name, status_output, :red)

        expect(result).to include('Status:')
        expect(result).to include('modified:')
        expect(result).to include('new file:')
        expect(result).to include("\033[31m") # Red
      end

      it 'formats repository with changes without color' do
        result = formatter_no_color.send(:format_repository_with_changes, repo_name, status_output, :red)

        expect(result).to include('Status:')
        expect(result).not_to include("\033[")
      end

      it 'indents all status lines' do
        result = formatter_with_color.send(:format_repository_with_changes, repo_name, status_output, :red)
        lines = result.split("\n")

        status_lines = lines[1..-1] # Skip header
        status_lines.each do |line|
          expect(line).to start_with('  ')
        end
      end
    end

    describe '#colorize_status_line' do
      it 'colorizes branch information' do
        line = 'On branch main'
        result = formatter_with_color.send(:colorize_status_line, line)

        expect(result).to include('On branch')
        expect(result).to include("\033[32m") # Green for branch name
      end

      it 'colorizes branch status with quotes' do
        line = "Your branch is ahead of 'origin/main' by 1 commit."
        result = formatter_with_color.send(:colorize_status_line, line)

        expect(result).to include("'origin/main'")
        expect(result).to include("\033[32m") # Green for quoted parts
      end

      it 'colorizes section headers' do
        headers = [
          'Changes to be committed:',
          'Changes not staged for commit:',
          'Untracked files:'
        ]

        headers.each do |header|
          result = formatter_with_color.send(:colorize_status_line, header)
          expect(result).to include("\033[1m") # Bold
        end
      end

      it 'colorizes file status lines with tabs' do
        status_lines = [
          "\tnew file:   file.rb",
          "\tmodified:   file.rb",
          "\tdeleted:    file.rb",
          "\trenamed:    old.rb -> new.rb",
          "\tcopied:     file.rb -> copy.rb"
        ]

        status_lines.each do |line|
          result = formatter_with_color.send(:colorize_status_line, line)
          expect(result).to include("\033[") # Some color code
        end
      end

      it 'colorizes meta information' do
        meta_lines = [
          "\t(use \"git add <file>...\" to update what will be committed)",
          'nothing to commit, working tree clean',
          'no changes added to commit (use "git add" and/or "git commit -a")'
        ]

        meta_lines.each do |line|
          result = formatter_with_color.send(:colorize_status_line, line)
          expect(result).to include("\033[2m") # Dim
        end
      end

      it 'colorizes untracked files' do
        line = "\tuntracked_file.rb"
        result = formatter_with_color.send(:colorize_status_line, line)

        expect(result).to include("\033[31m") # Red for untracked
      end

      it 'returns line as-is for unrecognized patterns' do
        line = 'Some unrecognized status line'
        result = formatter_with_color.send(:colorize_status_line, line)

        expect(result).to eq(line)
      end
    end

    describe '#colorize' do
      it 'adds color codes when color is enabled' do
        result = formatter_with_color.send(:colorize, 'text', :red)

        expect(result).to eq("\033[31mtext\033[0m")
      end

      it 'returns text as-is when color is disabled' do
        result = formatter_no_color.send(:colorize, 'text', :red)

        expect(result).to eq('text')
      end

      it "returns text as-is when color code doesn't exist" do
        result = formatter_with_color.send(:colorize, 'text', :nonexistent)

        expect(result).to eq('text')
      end
    end
  end

  describe 'integration tests' do
    context 'with real git status output' do
      let(:realistic_status) do
        <<~STATUS
          On branch feature/test
          Your branch is ahead of 'origin/main' by 2 commits.
            (use "git push" to publish your local commits)

          Changes to be committed:
            (use "git restore --staged <file>..." to unstage)
          	modified:   lib/file1.rb
          	new file:   lib/file2.rb
          	deleted:    old_file.rb

          Changes not staged for commit:
            (use "git add <file>..." to update what will be committed)
            (use "git restore <file>..." to discard changes in working directory)
          	modified:   lib/file3.rb

          Untracked files:
            (use "git add <file>..." to include in what will be committed)
          	temp_file.rb
          	another_temp.txt
        STATUS
      end

      it 'formats complex status output correctly' do
        result = described_class.format_repository_status(repo_name, realistic_status)

        expect(result).to include('Status:')
        expect(result).to include('feature/test')
        expect(result).to include('Changes to be committed:')
        expect(result).to include('Changes not staged for commit:')
        expect(result).to include('Untracked files:')
        expect(result).to include('modified:')
        expect(result).to include('new file:')
        expect(result).to include('deleted:')
      end

      it 'properly indents all lines' do
        result = described_class.format_repository_status(repo_name, realistic_status)
        lines = result.split("\n")

        # First line is the header
        expect(lines.first).to include('Status:')

        # All other lines should be indented
        lines[1..-1].each do |line|
          expect(line).to start_with('  ')
        end
      end

      it 'applies appropriate colors throughout' do
        result = described_class.format_repository_status(repo_name, realistic_status)

        # Should contain various color codes
        expect(result).to include("\033[31m") # Red
        expect(result).to include("\033[32m") # Green
        expect(result).to include("\033[1m")  # Bold
        expect(result).to include("\033[2m")  # Dim
        expect(result).to include("\033[0m")  # Reset
      end
    end

    context 'with edge cases' do
      it 'handles empty lines gracefully' do
        status_with_empty_lines = "modified:   file.rb\n\n\ndeleted:    another.rb"
        result = described_class.format_repository_status(repo_name, status_with_empty_lines)

        expect(result).to include('modified:')
        expect(result).to include('deleted:')
      end

      it 'handles very long file names' do
        long_filename = 'a' * 200
        status = "modified:   #{long_filename}.rb"
        result = described_class.format_repository_status(repo_name, status)

        expect(result).to include(long_filename)
      end

      it 'handles special characters in filenames' do
        special_filename = "file with spaces & symbols!@\#$%.rb"
        status = "modified:   #{special_filename}"
        result = described_class.format_repository_status(repo_name, status)

        expect(result).to include(special_filename)
      end

      it 'handles merge conflict status' do
        conflict_status = 'both modified: conflicted_file.rb'
        result = described_class.format_repository_status(repo_name, conflict_status)

        expect(result).to include('both modified:')
        expect(result).to include("\033[31m") # Red for conflict
      end

      it 'handles renamed files' do
        renamed_status = "\trenamed:    old_name.rb -> new_name.rb"
        formatter = described_class.new(force_color: true)
        result = formatter.send(:colorize_status_line, renamed_status)

        expect(result).to include('renamed:')
        expect(result).to include("\033[32m") # Green for staged
      end

      it 'handles status with merge conflict indicators' do
        merge_status = 'merge conflict in file.rb'
        formatter = described_class.new
        result = formatter.send(:determine_status_type, merge_status)

        expect(result).to eq(:conflict)
      end

      it 'handles status with all change types' do
        complex_status = <<~STATUS
          Changes not staged for commit:
            modified:   file1.rb
          Changes to be committed:
            new file:   file2.rb
            renamed:    old.rb -> new.rb
            deleted:    removed.rb
        STATUS
        formatter = described_class.new
        result = formatter.send(:determine_status_type, complex_status)

        expect(result).to eq(:changes)
      end

      it 'handles whitespace-only status output' do
        whitespace_status = "   \n\t\n   "
        result = described_class.format_repository_status(repo_name, whitespace_status)

        expect(result).to include('Clean working directory')
      end

      it 'handles copied files status line' do
        copied_line = "\tcopied:     original.rb -> copy.rb"
        formatter = described_class.new(force_color: true)
        result = formatter.send(:colorize_status_line, copied_line)

        expect(result).to include('copied:')
        expect(result).to include("\033[32m") # Green for staged new
      end

      it "handles 'nothing to commit' message" do
        nothing_line = 'nothing to commit, working tree clean'
        formatter = described_class.new(force_color: true)
        result = formatter.send(:colorize_status_line, nothing_line)

        expect(result).to include("\033[2m") # Dim meta text
      end

      it "handles 'no changes added' message" do
        no_changes_line = 'no changes added to commit'
        formatter = described_class.new(force_color: true)
        result = formatter.send(:colorize_status_line, no_changes_line)

        expect(result).to include("\033[2m") # Dim meta text
      end

      it 'correctly identifies file lines without prefixes as untracked' do
        # Lines that are indented but don't have status prefixes should be untracked files
        untracked_line = '    untracked_file.txt'
        formatter = described_class.new(force_color: true)
        result = formatter.send(:colorize_status_line, untracked_line)

        expect(result).to include("\033[31m") # Red for untracked
        expect(result).to include('untracked_file.txt')
      end

      it 'handles status lines with unusual indentation' do
        status_lines = [
          ' modified:   file.rb',        # Single space
          '  modified:   file.rb',       # Double space
          "\t\tmodified:   file.rb",     # Double tab
          "   \tmodified:   file.rb"     # Mixed spaces and tabs
        ]

        formatter = described_class.new(force_color: true)
        status_lines.each do |line|
          result = formatter.send(:colorize_status_line, line)
          expect(result).to include('modified:')
        end
      end
    end
  end
end
