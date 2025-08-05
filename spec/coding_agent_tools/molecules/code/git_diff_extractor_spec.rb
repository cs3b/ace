# frozen_string_literal: true

require 'spec_helper'

RSpec.describe CodingAgentTools::Molecules::Code::GitDiffExtractor do
  let(:extractor) { described_class.new }
  let(:git_executor_mock) { instance_double(CodingAgentTools::Atoms::Git::GitCommandExecutor) }
  let(:file_reader_mock) { instance_double(CodingAgentTools::Atoms::Code::FileContentReader) }

  before do
    # Mock the atoms dependencies
    allow(CodingAgentTools::Atoms::Git::GitCommandExecutor).to receive(:new).and_return(git_executor_mock)
    allow(CodingAgentTools::Atoms::Code::FileContentReader).to receive(:new).and_return(file_reader_mock)

    # Set up the instance variable mocks
    extractor.instance_variable_set(:@git_executor, git_executor_mock)
    extractor.instance_variable_set(:@file_reader, file_reader_mock)
  end

  describe '#extract_diff' do
    context 'when extracting staged changes' do
      let(:target_spec) { 'staged' }
      let(:diff_output) do
        <<~DIFF
          diff --git a/lib/example.rb b/lib/example.rb
          index 1234567..abcdefg 100644
          --- a/lib/example.rb
          +++ b/lib/example.rb
          @@ -1,3 +1,4 @@
           # Example file
          +puts "Hello World"
           def example_method
             true
        DIFF
      end

      before do
        allow(git_executor_mock).to receive(:execute).with('diff --no-color --staged').and_return(
          success: true,
          stdout: diff_output,
          stderr: ''
        )
      end

      it 'returns successful result with diff content' do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be true
        expect(result[:content]).to eq(diff_output)
        expect(result[:metadata][:target]).to eq('staged')
        expect(result[:metadata][:empty]).to be false
        expect(result[:error]).to be_nil
      end

      it 'extracts metadata about changes' do
        result = extractor.extract_diff(target_spec)

        metadata = result[:metadata]
        expect(metadata[:files_changed]).to eq(1)
        expect(metadata[:additions]).to be_positive
        expect(metadata[:target]).to eq(target_spec)
      end
    end

    context 'when extracting commit range' do
      let(:target_spec) { 'HEAD~2..HEAD' }
      let(:diff_output) do
        <<~DIFF
          diff --git a/README.md b/README.md
          index 1111111..2222222 100644
          --- a/README.md
          +++ b/README.md
          @@ -1,2 +1,3 @@
           # Project Title
           Description
          +New line added
        DIFF
      end

      before do
        allow(git_executor_mock).to receive(:execute).with('diff --no-color HEAD~2..HEAD').and_return(
          success: true,
          stdout: diff_output,
          stderr: ''
        )
      end

      it 'returns diff for specified commit range' do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be true
        expect(result[:content]).to eq(diff_output)
        expect(result[:metadata][:type]).to eq('git_diff')
        expect(result[:metadata][:target]).to eq(target_spec)
      end
    end

    context 'when no changes exist' do
      let(:target_spec) { 'staged' }

      before do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: '',
          stderr: ''
        )
      end

      it 'returns successful result with empty content' do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be true
        expect(result[:content]).to eq('')
        expect(result[:metadata][:empty]).to be true
        expect(result[:metadata][:files_changed]).to eq(0)
      end
    end

    context 'when git command fails' do
      let(:target_spec) { 'invalid-range' }

      before do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: false,
          stdout: '',
          stderr: "fatal: ambiguous argument 'invalid-range'"
        )
      end

      it 'returns failure result with error message' do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be false
        expect(result[:content]).to be_nil
        expect(result[:metadata]).to eq({})
        expect(result[:error]).to include('ambiguous argument')
      end
    end

    context 'when git executor raises exception' do
      let(:target_spec) { 'staged' }

      before do
        allow(git_executor_mock).to receive(:execute).and_raise(StandardError.new('Git not found'))
      end

      it 'handles exceptions gracefully' do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be false
        expect(result[:content]).to be_nil
        expect(result[:error]).to include('Git command failed: Git not found')
      end
    end

    context 'when extracting unstaged changes', :new_edge_cases do
      let(:target_spec) { 'unstaged' }
      let(:diff_output) do
        <<~DIFF
          diff --git a/modified.rb b/modified.rb
          index 5678abc..defg123 100644
          --- a/modified.rb
          +++ b/modified.rb
          @@ -1,2 +1,3 @@
           def method
          +  # new comment
             puts "unstaged change"
        DIFF
      end

      before do
        allow(git_executor_mock).to receive(:execute).with('diff --no-color').and_return(
          success: true,
          stdout: diff_output,
          stderr: ''
        )
      end

      it 'extracts unstaged changes correctly' do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be true
        expect(result[:content]).to eq(diff_output)
        expect(result[:metadata][:target]).to eq('unstaged')
        expect(result[:metadata][:files_changed]).to eq(1)
        expect(result[:metadata][:additions]).to eq(1)
      end
    end

    context 'when target is malformed SHA', :new_edge_cases do
      let(:target_spec) { 'invalid123' }

      before do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: false,
          stdout: '',
          stderr: "fatal: bad revision 'invalid123'"
        )
      end

      it 'handles malformed SHA gracefully' do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be false
        expect(result[:content]).to be_nil
        expect(result[:error]).to include('bad revision')
      end
    end

    context 'when target is very short SHA', :new_edge_cases do
      let(:target_spec) { 'abc' }

      before do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: false,
          stdout: '',
          stderr: "fatal: ambiguous argument 'abc': unknown revision"
        )
      end

      it 'handles ambiguous short SHA' do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be false
        expect(result[:error]).to include('ambiguous argument')
      end
    end

    context 'when target contains special characters', :new_edge_cases do
      let(:target_spec) { 'HEAD~1..HEAD@{upstream}' }
      let(:diff_output) { "diff --git a/special.rb b/special.rb\n+special content" }

      before do
        allow(git_executor_mock).to receive(:execute).with('diff --no-color HEAD~1..HEAD@{upstream}').and_return(
          success: true,
          stdout: diff_output,
          stderr: ''
        )
      end

      it 'handles special git revision syntax' do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be true
        expect(result[:content]).to eq(diff_output)
        expect(result[:metadata][:target]).to eq('HEAD~1..HEAD@{upstream}')
      end
    end

    context 'when diff contains multiple files', :complex_parsing do
      let(:target_spec) { 'staged' }
      let(:multi_file_diff) do
        <<~DIFF
          diff --git a/file1.rb b/file1.rb
          index 1111111..2222222 100644
          --- a/file1.rb
          +++ b/file1.rb
          @@ -1,3 +1,4 @@
           class File1
          +  attr_reader :name
             def initialize
               @name = "file1"
          diff --git a/file2.rb b/file2.rb
          index 3333333..4444444 100644
          --- a/file2.rb
          +++ b/file2.rb
          @@ -1,2 +1,3 @@
           class File2
          +  # new comment
             def process; end
          diff --git a/file3.py b/file3.py
          new file mode 100644
          index 0000000..5555555
          --- /dev/null
          +++ b/file3.py
          @@ -0,0 +1,2 @@
          +def hello():
          +    print("Hello from Python")
        DIFF
      end

      before do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: multi_file_diff,
          stderr: ''
        )
      end

      it 'correctly counts multiple files and changes' do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be true
        expect(result[:metadata][:files_changed]).to eq(3)
        expect(result[:metadata][:additions]).to eq(4) # +attr_reader, +comment, +def hello, +print
        expect(result[:metadata][:deletions]).to eq(0)
        expect(result[:metadata][:line_count]).to be > 20
      end
    end

    context 'when diff contains binary files', :complex_parsing do
      let(:target_spec) { 'HEAD' }
      let(:binary_diff) do
        <<~DIFF
          diff --git a/image.png b/image.png
          index abc123..def456 100644
          Binary files a/image.png and b/image.png differ
          diff --git a/text.rb b/text.rb
          index 111111..222222 100644
          --- a/text.rb
          +++ b/text.rb
          @@ -1,2 +1,3 @@
           class TextFile
          +  # Added for binary test
             def read; end
        DIFF
      end

      before do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: binary_diff,
          stderr: ''
        )
      end

      it 'handles binary files in diff' do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be true
        expect(result[:metadata][:files_changed]).to eq(2)
        expect(result[:metadata][:additions]).to eq(1) # Only text file addition counted
        expect(result[:content]).to include('Binary files')
        expect(result[:content]).to include('# Added for binary test')
      end
    end

    context 'when diff is very large', :complex_parsing do
      let(:target_spec) { 'working' }
      let(:large_diff) do
        # Generate a large diff with many lines
        header = "diff --git a/large_file.rb b/large_file.rb\nindex 1234567..abcdefg 100644\n--- a/large_file.rb\n+++ b/large_file.rb\n"
        content_lines = (1..100).map { |i| "+  line_#{i} = 'generated content for large diff test'" }.join("\n")
        "#{header}@@ -1,1 +1,100 @@\n class LargeFile\n#{content_lines}\n end"
      end

      before do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: large_diff,
          stderr: ''
        )
      end

      it 'handles large diffs efficiently' do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be true
        expect(result[:metadata][:line_count]).to be > 100
        expect(result[:metadata][:additions]).to eq(100)
        expect(result[:metadata][:files_changed]).to eq(1)
        expect(result[:metadata][:word_count]).to be > 500
      end
    end

    context 'when diff contains deletions only', :complex_parsing do
      let(:target_spec) { 'staged' }
      let(:deletion_diff) do
        <<~DIFF
          diff --git a/removed_file.rb b/removed_file.rb
          deleted file mode 100644
          index 1111111..0000000
          --- a/removed_file.rb
          +++ /dev/null
          @@ -1,5 +0,0 @@
          -class RemovedFile
          -  def initialize
          -    @deleted = true
          -  end
          -end
        DIFF
      end

      before do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: deletion_diff,
          stderr: ''
        )
      end

      it 'correctly counts deletions' do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be true
        expect(result[:metadata][:files_changed]).to eq(1)
        expect(result[:metadata][:additions]).to eq(0)
        expect(result[:metadata][:deletions]).to eq(5)
        expect(result[:content]).to include('deleted file mode')
      end
    end

    context 'when diff contains mixed additions and deletions', :complex_parsing do
      let(:target_spec) { 'HEAD~1..HEAD' }
      let(:mixed_diff) do
        <<~DIFF
          diff --git a/modified.rb b/modified.rb
          index aaaaaaa..bbbbbbb 100644
          --- a/modified.rb
          +++ b/modified.rb
          @@ -1,8 +1,10 @@
           class Modified
          -  # old comment
          +  # new comment
          +  # additional comment
             def old_method
          -    puts "old implementation"
          +    puts "new implementation"
          +    puts "with extra functionality"
             end
           
          +  def new_method
          +    puts "brand new method"
          +  end
           end
        DIFF
      end

      before do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: mixed_diff,
          stderr: ''
        )
      end

      it 'correctly counts mixed changes' do
        result = extractor.extract_diff(target_spec)

        expect(result[:success]).to be true
        expect(result[:metadata][:files_changed]).to eq(1)
        expect(result[:metadata][:additions]).to eq(7) # +new comment, +additional comment, +new implementation, +with extra, +def new_method, +puts brand new, +end
        expect(result[:metadata][:deletions]).to eq(2) # -old comment, -old implementation
      end
    end
  end

  describe '#extract_and_save' do
    let(:target_spec) { 'staged' }
    let(:session_dir) { '/tmp/session' }
    let(:diff_content) { "diff --git a/test.rb b/test.rb\n+new line" }

    before do
      allow(git_executor_mock).to receive(:execute).and_return(
        success: true,
        stdout: diff_content,
        stderr: ''
      )
      allow(File).to receive(:write)
    end

    it 'saves diff and metadata files' do
      diff_file = File.join(session_dir, 'input.diff')
      meta_file = File.join(session_dir, 'input.meta')

      result = extractor.extract_and_save(target_spec, session_dir)

      expect(result[:success]).to be true
      expect(result[:diff_file]).to eq(diff_file)
      expect(result[:meta_file]).to eq(meta_file)

      expect(File).to have_received(:write).with(diff_file, diff_content)
      expect(File).to have_received(:write).with(meta_file, anything)
    end

    it 'handles file write errors' do
      allow(File).to receive(:write).and_raise(StandardError.new('Permission denied'))

      result = extractor.extract_and_save(target_spec, session_dir)

      expect(result[:success]).to be false
      expect(result[:error]).to include('Failed to save diff: Permission denied')
    end

    context 'file operation error scenarios', :file_operations do
      it 'handles permission denied errors' do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: 'test diff content',
          stderr: ''
        )
        allow(File).to receive(:write).and_raise(Errno::EACCES.new('Permission denied - /restricted/input.diff'))

        result = extractor.extract_and_save(target_spec, session_dir)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Failed to save diff: Permission denied')
        expect(result[:diff_file]).to be_nil
        expect(result[:meta_file]).to be_nil
      end

      it 'handles no space left on device errors' do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: 'test diff content',
          stderr: ''
        )
        allow(File).to receive(:write).and_raise(Errno::ENOSPC.new('No space left on device'))

        result = extractor.extract_and_save(target_spec, session_dir)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Failed to save diff: No space left on device')
      end

      it 'handles directory not found errors' do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: 'test diff content',
          stderr: ''
        )
        allow(File).to receive(:write).and_raise(Errno::ENOENT.new('No such file or directory - /nonexistent/input.diff'))

        result = extractor.extract_and_save(target_spec, session_dir)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Failed to save diff: No such file or directory')
      end

      it 'handles read-only filesystem errors' do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: 'test diff content',
          stderr: ''
        )
        allow(File).to receive(:write).and_raise(Errno::EROFS.new('Read-only file system'))

        result = extractor.extract_and_save(target_spec, session_dir)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Failed to save diff: Read-only file system')
      end

      it 'handles IO errors during write' do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: 'test diff content',
          stderr: ''
        )
        allow(File).to receive(:write).and_raise(IOError.new('closed stream'))

        result = extractor.extract_and_save(target_spec, session_dir)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Failed to save diff: closed stream')
      end

      it 'handles partial file write failures (meta file fails)' do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: 'test diff content',
          stderr: ''
        )

        # Let diff file write succeed, but meta file write fail
        diff_file_path = File.join(session_dir, 'input.diff')
        meta_file_path = File.join(session_dir, 'input.meta')

        allow(File).to receive(:write).with(diff_file_path, anything)
        allow(File).to receive(:write).with(meta_file_path, anything).and_raise(StandardError.new('Meta write failed'))

        result = extractor.extract_and_save(target_spec, session_dir)

        expect(result[:success]).to be false
        expect(result[:error]).to include('Failed to save diff: Meta write failed')
      end

      it 'handles extract_diff failure before file operations' do
        allow(git_executor_mock).to receive(:execute).and_return(
          success: false,
          stdout: '',
          stderr: 'fatal: not a git repository'
        )

        result = extractor.extract_and_save(target_spec, session_dir)

        expect(result[:success]).to be false
        expect(result[:error]).to include('not a git repository')
        # File operations should not be attempted
        expect(File).not_to have_received(:write) if File.respond_to?(:write)
      end

      it 'handles very large diff content that might cause memory issues' do
        large_content = '+' + ("large content line\n" * 10_000)
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: large_content,
          stderr: ''
        )
        allow(File).to receive(:write)

        result = extractor.extract_and_save(target_spec, session_dir)

        expect(result[:success]).to be true
        expect(File).to have_received(:write).with(File.join(session_dir, 'input.diff'), large_content)
      end

      it 'handles special characters in session directory path' do
        special_session_dir = '/tmp/session with spaces & special-chars'
        allow(git_executor_mock).to receive(:execute).and_return(
          success: true,
          stdout: 'test content',
          stderr: ''
        )
        allow(File).to receive(:write)

        result = extractor.extract_and_save(target_spec, special_session_dir)

        expected_diff_file = File.join(special_session_dir, 'input.diff')
        expected_meta_file = File.join(special_session_dir, 'input.meta')

        expect(result[:success]).to be true
        expect(result[:diff_file]).to eq(expected_diff_file)
        expect(result[:meta_file]).to eq(expected_meta_file)
      end
    end
  end

  describe 'private methods' do
    describe '#build_diff_command' do
      it 'builds command for staged changes' do
        command = extractor.send(:build_diff_command, 'staged')
        expect(command).to eq('diff --no-color --staged')
      end

      it 'builds command for working directory changes' do
        command = extractor.send(:build_diff_command, 'working')
        expect(command).to eq('diff --no-color HEAD')
      end

      it 'builds command for commit ranges' do
        command = extractor.send(:build_diff_command, 'HEAD~1..HEAD')
        expect(command).to eq('diff --no-color HEAD~1..HEAD')
      end

      it 'builds command for specific commits' do
        command = extractor.send(:build_diff_command, 'abc123')
        expect(command).to eq('diff --no-color abc123')
      end
    end

    describe '#build_diff_metadata' do
      let(:diff_with_changes) do
        <<~DIFF
          diff --git a/file1.rb b/file1.rb
          index 1234567..abcdefg 100644
          --- a/file1.rb
          +++ b/file1.rb
          @@ -1,2 +1,3 @@
           existing line
          +new line
           another line
          diff --git a/file2.rb b/file2.rb
          index 7890abc..defghij 100644
          --- a/file2.rb
          +++ b/file2.rb
          @@ -1 +1,2 @@
           original
          +added line
        DIFF
      end

      it 'extracts metadata from diff output' do
        metadata = extractor.send(:build_diff_metadata, 'staged', diff_with_changes)

        expect(metadata[:target]).to eq('staged')
        expect(metadata[:type]).to eq('git_diff')
        expect(metadata[:empty]).to be false
        expect(metadata[:files_changed]).to eq(2)
        expect(metadata[:additions]).to eq(2)
        expect(metadata[:deletions]).to eq(0)
      end

      it 'handles empty diff output' do
        metadata = extractor.send(:build_diff_metadata, 'working', '')

        expect(metadata[:empty]).to be true
        expect(metadata[:files_changed]).to eq(0)
        expect(metadata[:additions]).to eq(0)
        expect(metadata[:deletions]).to eq(0)
      end

      context 'edge cases', :metadata_edge_cases do
        it 'handles diff with only whitespace' do
          whitespace_diff = "   \n\t\n   \n"
          metadata = extractor.send(:build_diff_metadata, 'test', whitespace_diff)

          expect(metadata[:empty]).to be true
          expect(metadata[:files_changed]).to eq(0)
          expect(metadata[:line_count]).to eq(3)
          expect(metadata[:word_count]).to eq(0)
        end

        it 'handles diff with context lines only (no +/- changes)' do
          context_only_diff = <<~DIFF
            diff --git a/context.rb b/context.rb
            index 1111111..2222222 100644
            --- a/context.rb
            +++ b/context.rb
            @@ -1,3 +1,3 @@
             class Context
               def unchanged; end
             end
          DIFF

          metadata = extractor.send(:build_diff_metadata, 'context', context_only_diff)

          expect(metadata[:files_changed]).to eq(1)
          expect(metadata[:additions]).to eq(0)
          expect(metadata[:deletions]).to eq(0)
          expect(metadata[:empty]).to be false
        end

        it 'handles diff with +++ and --- headers correctly' do
          diff_with_headers = <<~DIFF
            diff --git a/test.rb b/test.rb
            index abc123..def456 100644
            --- a/test.rb
            +++ b/test.rb
            @@ -1,2 +1,3 @@
            +added line
            -removed line
             context line
          DIFF

          metadata = extractor.send(:build_diff_metadata, 'headers', diff_with_headers)

          expect(metadata[:additions]).to eq(1) # Should not count +++ header
          expect(metadata[:deletions]).to eq(1) # Should not count --- header
        end

        it 'handles diff with very long lines' do
          long_line = '+' + ('word ' * 200).strip + "\n"
          long_diff = "diff --git a/long.rb b/long.rb\n#{long_line}"

          metadata = extractor.send(:build_diff_metadata, 'long', long_diff)

          expect(metadata[:additions]).to eq(1)
          expect(metadata[:word_count]).to be > 200
          expect(metadata[:line_count]).to eq(2)
        end

        it 'handles diff with unicode characters' do
          unicode_diff = <<~DIFF
            diff --git a/unicode.rb b/unicode.rb
            index 1111111..2222222 100644
            --- a/unicode.rb
            +++ b/unicode.rb
            @@ -1,2 +1,3 @@
             # Comment with émojis 🎉
            +puts "Hellö Wörld! 世界"
             puts "ASCII text"
          DIFF

          metadata = extractor.send(:build_diff_metadata, 'unicode', unicode_diff)

          expect(metadata[:additions]).to eq(1)
          expect(metadata[:files_changed]).to eq(1)
          expect(metadata[:empty]).to be false
        end

        it 'handles diff with special git diff markers' do
          special_diff = <<~DIFF
            diff --git a/special.rb b/special.rb
            index 1111111..2222222 100644
            --- a/special.rb
            +++ b/special.rb
            @@ -1,3 +1,4 @@
             class Special
            +  # This line starts with + in content: +1
            -  # This line starts with - in content: -1  
             end
          DIFF

          metadata = extractor.send(:build_diff_metadata, 'special', special_diff)

          expect(metadata[:additions]).to eq(1)
          expect(metadata[:deletions]).to eq(1)
          expect(metadata[:files_changed]).to eq(1)
        end

        it 'handles malformed diff (missing headers)' do
          malformed_diff = <<~DIFF
            +some addition
            -some deletion
             context line
          DIFF

          metadata = extractor.send(:build_diff_metadata, 'malformed', malformed_diff)

          expect(metadata[:files_changed]).to eq(0) # No "diff --git" headers
          expect(metadata[:additions]).to eq(1)
          expect(metadata[:deletions]).to eq(1)
        end
      end
    end

    describe '#git_diff_target?' do
      it 'identifies staged changes' do
        result = extractor.git_diff_target?('staged')
        expect(result).to be true
      end

      it 'identifies working directory changes' do
        result = extractor.git_diff_target?('working')
        expect(result).to be true
      end

      it 'identifies unstaged changes', :new_edge_cases do
        result = extractor.git_diff_target?('unstaged')
        expect(result).to be true
      end

      it 'identifies commit ranges' do
        result = extractor.git_diff_target?('HEAD~2..HEAD')
        expect(result).to be true
      end

      it 'identifies single commits' do
        result = extractor.git_diff_target?('abc123def')
        expect(result).to be true
      end

      it 'identifies short SHA (7 characters)', :new_edge_cases do
        result = extractor.git_diff_target?('a1b2c3d')
        expect(result).to be true
      end

      it 'identifies full SHA (40 characters)', :new_edge_cases do
        result = extractor.git_diff_target?('a1b2c3d4e5f6789012345678901234567890abcd')
        expect(result).to be true
      end

      it 'rejects too short SHA (less than 7 characters)', :new_edge_cases do
        result = extractor.git_diff_target?('abc123')
        expect(result).to be false
      end

      it 'rejects non-git targets' do
        result = extractor.git_diff_target?('invalid-target')
        expect(result).to be false
      end

      it 'rejects empty string', :new_edge_cases do
        result = extractor.git_diff_target?('')
        expect(result).to be false
      end

      it 'rejects nil input', :new_edge_cases do
        result = extractor.git_diff_target?(nil)
        expect(result).to be false
      end
    end
  end
end
