# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'coding_agent_tools/atoms/taskflow_management/yaml_frontmatter_parser'

RSpec.describe CodingAgentTools::Atoms::TaskflowManagement::YamlFrontmatterParser do
  describe 'ParseResult' do
    let(:frontmatter) { { 'title' => 'Test', 'status' => 'draft' } }
    let(:content) { 'This is the content' }
    let(:raw_frontmatter) { "title: Test\nstatus: draft" }
    let(:parse_result) { described_class::ParseResult.new(frontmatter, content, raw_frontmatter, true) }

    describe '#valid?' do
      it 'returns true when frontmatter is not nil' do
        expect(parse_result.valid?).to be true
      end

      it 'returns false when frontmatter is nil' do
        result = described_class::ParseResult.new(nil, content, raw_frontmatter, false)
        expect(result.valid?).to be false
      end
    end

    describe '#empty_frontmatter?' do
      it 'returns false when frontmatter has content' do
        expect(parse_result.empty_frontmatter?).to be false
      end

      it 'returns true when frontmatter is nil' do
        result = described_class::ParseResult.new(nil, content, raw_frontmatter, false)
        expect(result.empty_frontmatter?).to be true
      end

      it 'returns true when frontmatter is empty hash' do
        result = described_class::ParseResult.new({}, content, raw_frontmatter, true)
        expect(result.empty_frontmatter?).to be true
      end
    end
  end

  describe 'ParseError' do
    let(:error) { described_class::ParseError.new('Test error', line_number: 5, column: 10, yaml_error: StandardError.new('YAML issue')) }

    it 'stores line number, column, and yaml_error' do
      expect(error.line_number).to eq(5)
      expect(error.column).to eq(10)
      expect(error.yaml_error).to be_a(StandardError)
    end

    it 'inherits from StandardError' do
      expect(error).to be_a(StandardError)
    end
  end

  describe 'SecurityError' do
    let(:error) { described_class::SecurityError.new('Security issue') }

    it 'inherits from StandardError' do
      expect(error).to be_a(StandardError)
    end
  end

  describe '.parse' do
    context 'with valid frontmatter' do
      let(:content_with_frontmatter) do
        <<~CONTENT
          ---
          title: Test Document
          status: draft
          tags:
            - test
            - example
          ---
          
          This is the main content of the document.
          It can span multiple lines.
        CONTENT
      end

      it 'parses frontmatter and content correctly' do
        result = described_class.parse(content_with_frontmatter)

        expect(result.valid?).to be true
        expect(result.has_frontmatter?).to be true
        expect(result.frontmatter['title']).to eq('Test Document')
        expect(result.frontmatter['status']).to eq('draft')
        expect(result.frontmatter['tags']).to eq(['test', 'example'])
        expect(result.content.strip).to start_with('This is the main content')
        expect(result.raw_frontmatter).to include('title: Test Document')
      end

      it 'handles frontmatter with different delimiters' do
        content = "+++\ntitle: Test\n+++\nContent here"
        result = described_class.parse(content, delimiter: '+++')

        expect(result.valid?).to be true
        expect(result.frontmatter['title']).to eq('Test')
        expect(result.content.strip).to eq('Content here')
      end

      it 'handles empty frontmatter' do
        content = "---\n---\nContent only"
        result = described_class.parse(content)

        expect(result.valid?).to be true
        expect(result.empty_frontmatter?).to be true
        expect(result.content.strip).to eq('Content only')
      end
    end

    context 'without frontmatter' do
      it 'returns content without frontmatter extraction' do
        content = 'This is just regular content without frontmatter'
        result = described_class.parse(content)

        expect(result.has_frontmatter?).to be false
        expect(result.frontmatter).to eq({})
        expect(result.content).to eq(content)
        expect(result.raw_frontmatter).to eq('')
      end

      it 'handles content that starts with delimiter but has no closing delimiter' do
        content = "---\nThis looks like frontmatter but never closes\nMore content"
        result = described_class.parse(content)

        expect(result.has_frontmatter?).to be false
        expect(result.content).to eq(content)
      end
    end

    context 'with empty or nil content' do
      it 'handles empty content' do
        result = described_class.parse('')

        expect(result.has_frontmatter?).to be false
        expect(result.frontmatter).to eq({})
        expect(result.content).to eq('')
      end

      it 'handles whitespace-only content' do
        result = described_class.parse("   \n\t  ")

        expect(result.has_frontmatter?).to be false
        expect(result.frontmatter).to eq({})
      end

      it 'raises ArgumentError for nil content' do
        expect { described_class.parse(nil) }.to raise_error(ArgumentError, /content cannot be nil/)
      end
    end

    context 'with invalid parameters' do
      it 'raises ArgumentError for nil delimiter' do
        expect { described_class.parse('content', delimiter: nil) }.to raise_error(ArgumentError, /delimiter cannot be nil/)
      end

      it 'raises ArgumentError for empty delimiter' do
        expect { described_class.parse('content', delimiter: '') }.to raise_error(ArgumentError, /delimiter cannot be nil/)
      end
    end

    context 'with malformed YAML' do
      it 'raises ParseError for invalid YAML syntax' do
        content = "---\ntitle: Test\nstatus: [invalid yaml\n---\nContent"

        expect { described_class.parse(content) }.to raise_error(described_class::ParseError) do |error|
          expect(error.message).to include('Invalid YAML syntax')
          expect(error.yaml_error).to be_a(Psych::SyntaxError)
        end
      end

      it 'raises ParseError when frontmatter is not a hash' do
        content = "---\n- item1\n- item2\n---\nContent"

        expect { described_class.parse(content) }.to raise_error(described_class::ParseError, /must be a hash/)
      end
    end

    context 'with safe mode enabled' do
      it 'raises SecurityError for dangerous YAML patterns' do
        dangerous_content = "---\n!ruby/object:User name: evil\n---\nContent"

        expect { described_class.parse(dangerous_content, safe_mode: true) }.to raise_error(described_class::SecurityError, /dangerous pattern/)
      end

      it 'raises SecurityError for excessive nesting' do
        nested_yaml = 'a: ' + '{ b: ' * 60 + 'value' + ' }' * 60
        content = "---\n#{nested_yaml}\n---\nContent"

        expect { described_class.parse(content, safe_mode: true) }.to raise_error(described_class::SecurityError, /maximum nesting level/)
      end

      it 'raises SecurityError for excessive length' do
        long_yaml = 'key: ' + 'a' * 100_001
        content = "---\n#{long_yaml}\n---\nContent"

        expect { described_class.parse(content, safe_mode: true) }.to raise_error(described_class::SecurityError, /maximum length/)
      end
    end

    context 'with safe mode disabled' do
      it 'allows more permissive YAML parsing' do
        content = "---\ntitle: Test\n---\nContent"
        result = described_class.parse(content, safe_mode: false)

        expect(result.valid?).to be true
        expect(result.frontmatter['title']).to eq('Test')
      end
    end
  end

  describe '.parse_file' do
    let(:test_dir) { Dir.mktmpdir('yaml_parser_test') }
    let(:test_file) { File.join(test_dir, 'test.md') }

    after do
      FileUtils.rm_rf(test_dir)
    end

    context 'with valid file' do
      before do
        File.write(test_file, <<~CONTENT)
          ---
          title: File Test
          author: Test Author
          ---
          
          File content here.
        CONTENT
      end

      it 'parses file content correctly' do
        result = described_class.parse_file(test_file)

        expect(result.valid?).to be true
        expect(result.frontmatter['title']).to eq('File Test')
        expect(result.frontmatter['author']).to eq('Test Author')
        expect(result.content.strip).to eq('File content here.')
      end

      it 'respects delimiter parameter' do
        File.write(test_file, "+++\ntitle: Test\n+++\nContent")
        result = described_class.parse_file(test_file, delimiter: '+++')

        expect(result.frontmatter['title']).to eq('Test')
      end

      it 'respects safe_mode parameter' do
        File.write(test_file, "---\ntitle: Test\n---\nContent")
        result = described_class.parse_file(test_file, safe_mode: false)

        expect(result.valid?).to be true
      end
    end

    context 'with invalid file parameters' do
      it 'raises ArgumentError for nil file_path' do
        expect { described_class.parse_file(nil) }.to raise_error(ArgumentError, /file_path cannot be nil/)
      end

      it 'raises ArgumentError for empty file_path' do
        expect { described_class.parse_file('') }.to raise_error(ArgumentError, /file_path cannot be nil/)
      end

      it 'raises ArgumentError for non-existent file' do
        expect { described_class.parse_file('/nonexistent/file.md') }.to raise_error(ArgumentError, /File does not exist/)
      end

      it 'raises SecurityError for file path with null bytes' do
        expect { described_class.parse_file("file\0path") }.to raise_error(described_class::SecurityError, /invalid characters/)
      end

      it 'raises SecurityError for file path with control characters' do
        expect { described_class.parse_file("file\x01path") }.to raise_error(described_class::SecurityError, /invalid characters/)
      end
    end

    context 'with file access issues' do
      let(:unreadable_file) { File.join(test_dir, 'unreadable.md') }

      before do
        File.write(unreadable_file, 'content')
        FileUtils.chmod(0o000, unreadable_file)
      end

      after do
        FileUtils.chmod(0o644, unreadable_file)
      end

      it 'raises ArgumentError for unreadable file' do
        expect { described_class.parse_file(unreadable_file) }.to raise_error(ArgumentError, /not readable/)
      end
    end

    context 'with encoding issues' do
      let(:binary_file) { File.join(test_dir, 'binary.md') }

      before do
        File.binwrite(binary_file, "\xFF\xFE\x00\x01")
      end

      it 'handles invalid UTF-8 content gracefully' do
        expect { described_class.parse_file(binary_file) }.to raise_error(ArgumentError, /invalid byte sequence|invalid UTF-8 content/)
      end
    end
  end

  describe '.has_frontmatter?' do
    it 'returns true for content with valid frontmatter' do
      content = "---\ntitle: Test\n---\nContent"
      expect(described_class.has_frontmatter?(content)).to be true
    end

    it 'returns false for content without frontmatter' do
      content = 'Just regular content'
      expect(described_class.has_frontmatter?(content)).to be false
    end

    it 'returns false for content with opening delimiter but no closing' do
      content = "---\ntitle: Test\nNo closing delimiter"
      expect(described_class.has_frontmatter?(content)).to be false
    end

    it 'returns false for nil content' do
      expect(described_class.has_frontmatter?(nil)).to be false
    end

    it 'returns false for empty content' do
      expect(described_class.has_frontmatter?('')).to be false
    end

    it 'supports custom delimiters' do
      content = "+++\ntitle: Test\n+++\nContent"
      expect(described_class.has_frontmatter?(content, delimiter: '+++')).to be true
    end
  end

  describe '.extract_frontmatter' do
    it 'extracts only the frontmatter hash' do
      content = "---\ntitle: Test\nstatus: draft\n---\nContent here"
      frontmatter = described_class.extract_frontmatter(content)

      expect(frontmatter).to eq({ 'title' => 'Test', 'status' => 'draft' })
    end

    it 'returns empty hash when no frontmatter exists' do
      content = 'Just content'
      frontmatter = described_class.extract_frontmatter(content)

      expect(frontmatter).to eq({})
    end

    it 'supports custom delimiters' do
      content = "+++\ntitle: Test\n+++\nContent"
      frontmatter = described_class.extract_frontmatter(content, delimiter: '+++')

      expect(frontmatter['title']).to eq('Test')
    end

    it 'respects safe_mode parameter' do
      content = "---\ntitle: Test\n---\nContent"
      frontmatter = described_class.extract_frontmatter(content, safe_mode: false)

      expect(frontmatter['title']).to eq('Test')
    end
  end

  describe '.extract_content' do
    it 'extracts only the content without frontmatter' do
      content = "---\ntitle: Test\n---\nThis is the content"
      extracted = described_class.extract_content(content)

      expect(extracted.strip).to eq('This is the content')
    end

    it 'returns full content when no frontmatter exists' do
      content = 'This is just content'
      extracted = described_class.extract_content(content)

      expect(extracted).to eq(content)
    end

    it 'supports custom delimiters' do
      content = "+++\ntitle: Test\n+++\nContent here"
      extracted = described_class.extract_content(content, delimiter: '+++')

      expect(extracted.strip).to eq('Content here')
    end
  end

  describe '.validate_frontmatter' do
    let(:valid_frontmatter) { { 'title' => 'Test', 'status' => 'draft', 'tags' => ['test'] } }

    context 'with valid frontmatter' do
      it 'returns valid result for complete frontmatter' do
        result = described_class.validate_frontmatter(valid_frontmatter)

        expect(result[:valid?]).to be true
        expect(result[:errors]).to be_empty
        expect(result[:warnings]).to be_empty
      end

      it 'validates required keys' do
        result = described_class.validate_frontmatter(valid_frontmatter, required_keys: ['title', 'status'])

        expect(result[:valid?]).to be true
        expect(result[:errors]).to be_empty
      end

      it 'validates allowed keys' do
        result = described_class.validate_frontmatter(valid_frontmatter, allowed_keys: ['title', 'status', 'tags', 'author'])

        expect(result[:valid?]).to be true
        expect(result[:warnings]).to be_empty
      end
    end

    context 'with missing required keys' do
      it 'reports missing required keys' do
        result = described_class.validate_frontmatter(valid_frontmatter, required_keys: ['title', 'author'])

        expect(result[:valid?]).to be false
        expect(result[:errors]).to include('Missing required key: author')
      end

      it 'handles symbol keys in frontmatter' do
        frontmatter_with_symbols = { title: 'Test', status: 'draft' }
        result = described_class.validate_frontmatter(frontmatter_with_symbols, required_keys: ['title', 'status'])

        expect(result[:valid?]).to be true
      end
    end

    context 'with unknown keys' do
      it 'warns about unknown keys when allowed_keys is specified' do
        result = described_class.validate_frontmatter(valid_frontmatter, allowed_keys: ['title', 'status'])

        expect(result[:valid?]).to be true
        expect(result[:warnings]).to include('Unknown key: tags')
      end

      it 'allows all keys when allowed_keys is nil' do
        result = described_class.validate_frontmatter(valid_frontmatter, allowed_keys: nil)

        expect(result[:valid?]).to be true
        expect(result[:warnings]).to be_empty
      end
    end

    context 'with nil or empty frontmatter' do
      it 'returns valid result for nil frontmatter' do
        result = described_class.validate_frontmatter(nil)

        expect(result[:valid?]).to be true
        expect(result[:errors]).to be_empty
      end

      it 'returns valid result for empty frontmatter' do
        result = described_class.validate_frontmatter({})

        expect(result[:valid?]).to be true
        expect(result[:errors]).to be_empty
      end
    end
  end

  describe 'security features' do
    describe 'dangerous pattern detection' do
      let(:dangerous_patterns) do
        [
          '!ruby/object:User',
          '!ruby/class:String',
          '!!ruby/object',
          '!!python/object',
          '<%=',
          '{{variable}}',
          '${variable}',
          'eval(',
          'system(',
          '`command`',
          "require 'file'",
          "load 'file'",
          'send :method',
          'define_method',
          'class_eval',
          'module_eval',
          'instance_eval'
        ]
      end

      it 'detects various dangerous patterns' do
        # Test specific dangerous patterns from the implementation
        dangerous_content_examples = [
          "---\nkey: !ruby/object:User\n---\nContent",
          "---\nkey: !ruby/class:String\n---\nContent",
          "---\nkey: !!ruby/object\n---\nContent",
          "---\nkey: !!python/object\n---\nContent",
          "---\nkey: <% code %>\n---\nContent",
          "---\nkey: {{ variable }}\n---\nContent",
          "---\nkey: ${variable}\n---\nContent",
          "---\nkey: `command`\n---\nContent",
          "---\nkey: eval(code)\n---\nContent",
          "---\nkey: system('command')\n---\nContent"
        ]

        dangerous_content_examples.each do |content|
          expect { described_class.parse(content, safe_mode: true) }.to raise_error(described_class::SecurityError, /dangerous pattern/)
        end
      end
    end

    describe 'nesting limits' do
      it 'prevents YAML bombs through excessive nesting' do
        # Create deeply nested structure
        nested = 'a: ' + ('{ b: ' * 60) + 'value' + (' }' * 60)
        content = "---\n#{nested}\n---\nContent"

        expect { described_class.parse(content, safe_mode: true) }.to raise_error(described_class::SecurityError, /nesting level/)
      end
    end

    describe 'length limits' do
      it 'prevents processing of excessively long YAML' do
        long_value = 'a' * 100_001
        content = "---\nkey: #{long_value}\n---\nContent"

        expect { described_class.parse(content, safe_mode: true) }.to raise_error(described_class::SecurityError, /maximum length/)
      end
    end
  end

  describe 'private methods' do
    describe '.find_closing_delimiter' do
      it 'finds closing delimiter correctly' do
        lines = ['---', 'title: Test', 'status: draft', '---', 'Content line']
        index = described_class.send(:find_closing_delimiter, lines, '---')

        expect(index).to eq(3)
      end

      it 'returns nil when closing delimiter not found' do
        lines = ['---', 'title: Test', 'status: draft', 'Content line']
        index = described_class.send(:find_closing_delimiter, lines, '---')

        expect(index).to be_nil
      end
    end

    describe '.parse_yaml_safely' do
      it 'parses valid YAML in safe mode' do
        yaml_content = "title: Test\nstatus: draft"
        result = described_class.send(:parse_yaml_safely, yaml_content, true)

        expect(result).to eq({ 'title' => 'Test', 'status' => 'draft' })
      end

      it 'returns empty hash for empty YAML' do
        result = described_class.send(:parse_yaml_safely, '', true)

        expect(result).to eq({})
      end

      it 'raises ParseError for malformed YAML' do
        yaml_content = "title: Test\nstatus: [invalid"

        expect { described_class.send(:parse_yaml_safely, yaml_content, true) }.to raise_error(described_class::ParseError)
      end
    end

    describe '.perform_security_checks' do
      it 'allows safe YAML content' do
        safe_yaml = "title: Test\nstatus: draft\ntags:\n  - test\n  - example"

        expect { described_class.send(:perform_security_checks, safe_yaml) }.not_to raise_error
      end

      it 'rejects dangerous patterns' do
        dangerous_yaml = 'content: !ruby/object:User'

        expect { described_class.send(:perform_security_checks, dangerous_yaml) }.to raise_error(described_class::SecurityError)
      end
    end
  end

  describe 'comprehensive coverage for all uncovered lines' do
    describe 'ParseResult methods coverage' do
      it 'covers all ParseResult initialization and accessor methods' do
        frontmatter = { 'title' => 'Test', 'status' => 'draft' }
        content = 'Test content'
        raw_frontmatter = "title: Test\nstatus: draft"

        # Test ParseResult struct creation and accessors
        result = described_class::ParseResult.new(frontmatter, content, raw_frontmatter, true)

        expect(result.frontmatter).to eq(frontmatter)
        expect(result.content).to eq(content)
        expect(result.raw_frontmatter).to eq(raw_frontmatter)
        expect(result.has_frontmatter?).to be true
      end

      it 'covers valid? method logic paths' do
        # Test valid? with non-nil frontmatter
        result_valid = described_class::ParseResult.new({ 'key' => 'value' }, 'content', 'raw', true)
        expect(result_valid.valid?).to be true

        # Test valid? with nil frontmatter
        result_invalid = described_class::ParseResult.new(nil, 'content', 'raw', false)
        expect(result_invalid.valid?).to be false
      end

      it 'covers empty_frontmatter? method logic paths' do
        # Test with nil frontmatter
        result_nil = described_class::ParseResult.new(nil, 'content', 'raw', false)
        expect(result_nil.empty_frontmatter?).to be true

        # Test with empty hash
        result_empty = described_class::ParseResult.new({}, 'content', 'raw', true)
        expect(result_empty.empty_frontmatter?).to be true

        # Test with populated frontmatter
        result_populated = described_class::ParseResult.new({ 'key' => 'value' }, 'content', 'raw', true)
        expect(result_populated.empty_frontmatter?).to be false
      end
    end

    describe 'parse method comprehensive coverage' do
      it 'covers successful parse with frontmatter detection' do
        content = "---\ntitle: Test Document\nstatus: published\n---\n\nThis is content"

        result = described_class.parse(content)

        # Covers lines 44-82 (main parse flow)
        expect(result.frontmatter['title']).to eq('Test Document')
        expect(result.frontmatter['status']).to eq('published')
        expect(result.content.strip).to eq('This is content')
        expect(result.has_frontmatter?).to be true
        expect(result.valid?).to be true
        expect(result.raw_frontmatter).to include('title: Test Document')
      end

      it 'covers content without frontmatter path' do
        content = 'This is just regular content without any frontmatter'

        result = described_class.parse(content)

        # Covers lines 57-60 (no frontmatter detection)
        expect(result.has_frontmatter?).to be false
        expect(result.frontmatter).to eq({})
        expect(result.content).to eq(content)
        expect(result.raw_frontmatter).to eq('')
      end

      it 'covers no closing delimiter detection' do
        content = "---\ntitle: Test\nThis never closes properly"

        result = described_class.parse(content)

        # Covers lines 65-68 (no closing delimiter found)
        expect(result.has_frontmatter?).to be false
        expect(result.content).to eq(content)
        expect(result.raw_frontmatter).to eq('')
      end

      it 'covers empty content handling' do
        result = described_class.parse('')

        # Covers lines 49-51 (empty content path)
        expect(result.has_frontmatter?).to be false
        expect(result.frontmatter).to eq({})
        expect(result.content).to eq('')
        expect(result.raw_frontmatter).to eq('')
      end

      it 'covers whitespace-only content handling' do
        result = described_class.parse("   \n\t  \n   ")

        # Covers lines 49-51 (whitespace content treated as empty)
        expect(result.has_frontmatter?).to be false
        expect(result.frontmatter).to eq({})
        expect(result.content).to eq('')
        expect(result.raw_frontmatter).to eq('')
      end

      it 'covers argument validation paths' do
        # Covers line 45 (nil content check)
        expect { described_class.parse(nil) }.to raise_error(ArgumentError, 'content cannot be nil')

        # Covers line 46 (nil delimiter check)
        expect { described_class.parse('content', delimiter: nil) }.to raise_error(ArgumentError, 'delimiter cannot be nil or empty')

        # Covers line 46 (empty delimiter check)
        expect { described_class.parse('content', delimiter: '') }.to raise_error(ArgumentError, 'delimiter cannot be nil or empty')
      end

      it 'covers custom delimiter usage' do
        content = "+++\ntitle: Custom Delimiter Test\n+++\nContent with custom delimiter"

        result = described_class.parse(content, delimiter: '+++')

        # Covers delimiter parameter usage throughout parse flow
        expect(result.frontmatter['title']).to eq('Custom Delimiter Test')
        expect(result.content.strip).to eq('Content with custom delimiter')
        expect(result.has_frontmatter?).to be true
      end
    end

    describe 'parse_file method comprehensive coverage' do
      let(:test_dir) { Dir.mktmpdir('yaml_parser_coverage_test') }
      let(:test_file) { File.join(test_dir, 'coverage_test.md') }

      after { FileUtils.rm_rf(test_dir) }

      it 'covers successful file parsing flow' do
        File.write(test_file, "---\ntitle: File Coverage Test\n---\nFile content")

        result = described_class.parse_file(test_file)

        # Covers lines 92-117 (successful file parsing)
        expect(result.frontmatter['title']).to eq('File Coverage Test')
        expect(result.content.strip).to eq('File content')
      end

      it 'covers file path validation' do
        # Covers line 93 (nil file_path check)
        expect { described_class.parse_file(nil) }.to raise_error(ArgumentError, 'file_path cannot be nil or empty')

        # Covers line 93 (empty file_path check)
        expect { described_class.parse_file('') }.to raise_error(ArgumentError, 'file_path cannot be nil or empty')
      end

      it 'covers security validation for file paths' do
        # Covers lines 96-98 (null byte security check)
        expect { described_class.parse_file("file\0path") }.to raise_error(described_class::SecurityError, 'File path contains invalid characters')

        # Covers lines 96-98 (control character security check)
        expect { described_class.parse_file("file\x01path") }.to raise_error(described_class::SecurityError, 'File path contains invalid characters')
      end

      it 'covers file existence validation' do
        # Covers line 100 (file existence check)
        expect { described_class.parse_file('/nonexistent/file.md') }.to raise_error(ArgumentError, 'File does not exist: /nonexistent/file.md')
      end

      it 'covers file readability validation' do
        File.write(test_file, 'content')
        FileUtils.chmod(0o000, test_file)

        # Covers line 101 (file readability check)
        expect { described_class.parse_file(test_file) }.to raise_error(ArgumentError, "File is not readable: #{test_file}")

        # Cleanup
        FileUtils.chmod(0o644, test_file)
      end

      it 'covers UTF-8 encoding handling' do
        File.write(test_file, "---\ntitle: UTF-8 Test\n---\nContent")

        result = described_class.parse_file(test_file)

        # Covers lines 104 (UTF-8 file reading)
        expect(result.frontmatter['title']).to eq('UTF-8 Test')
      end

      it 'covers encoding error handling' do
        # Create file with invalid UTF-8 bytes
        File.binwrite(test_file, "\xFF\xFE\x00\x01")

        # Covers lines 105-114 (encoding error handling)
        expect { described_class.parse_file(test_file) }.to raise_error(ArgumentError, /invalid byte sequence|invalid UTF-8 content/)
      end

      it 'covers generic file reading error handling' do
        File.write(test_file, 'content')

        # Mock File.read to trigger generic error
        allow(File).to receive(:read).and_raise(IOError, 'Generic read error')

        # Covers lines 112-114 (generic error handling)
        expect { described_class.parse_file(test_file) }.to raise_error(ArgumentError, 'Error reading file: Generic read error')
      end
    end

    describe 'has_frontmatter? method coverage' do
      it 'covers successful frontmatter detection' do
        content = "---\ntitle: Test\n---\nContent"

        # Covers lines 123-135 (successful detection)
        expect(described_class.has_frontmatter?(content)).to be true
      end

      it 'covers nil and empty content handling' do
        # Covers line 124 (nil content)
        expect(described_class.has_frontmatter?(nil)).to be false

        # Covers line 124 (empty content)
        expect(described_class.has_frontmatter?('')).to be false

        # Covers line 124 (whitespace content)
        expect(described_class.has_frontmatter?('   ')).to be false
      end

      it 'covers empty lines handling' do
        # Covers line 127 (empty lines array)
        expect(described_class.has_frontmatter?("\n\n")).to be false
      end

      it 'covers first line delimiter check' do
        content = "Not a delimiter\ntitle: Test\n---\nContent"

        # Covers lines 130 (first line not delimiter)
        expect(described_class.has_frontmatter?(content)).to be false
      end

      it 'covers closing delimiter search' do
        content = "---\ntitle: Test\nNo closing delimiter"

        # Covers lines 133-134 (no closing delimiter found)
        expect(described_class.has_frontmatter?(content)).to be false
      end
    end

    describe 'extract_frontmatter method coverage' do
      it 'covers successful frontmatter extraction' do
        content = "---\ntitle: Extract Test\nstatus: active\n---\nContent"

        result = described_class.extract_frontmatter(content)

        # Covers lines 142-145 (extract frontmatter flow)
        expect(result).to eq({ 'title' => 'Extract Test', 'status' => 'active' })
      end

      it 'covers nil frontmatter handling' do
        content = 'Just content without frontmatter'

        result = described_class.extract_frontmatter(content)

        # Covers line 144 (nil frontmatter fallback to empty hash)
        expect(result).to eq({})
      end
    end

    describe 'extract_content method coverage' do
      it 'covers successful content extraction' do
        content = "---\ntitle: Content Test\n---\nThis is the extracted content"

        result = described_class.extract_content(content)

        # Covers lines 151-154 (extract content flow)
        expect(result.strip).to eq('This is the extracted content')
      end

      it 'covers nil content handling' do
        content = 'Just content'

        result = described_class.extract_content(content)

        # Covers line 153 (nil content fallback)
        expect(result).to eq(content)
      end
    end

    describe 'validate_frontmatter method coverage' do
      it 'covers nil and empty frontmatter early return' do
        # Covers line 168 (nil frontmatter early return)
        result = described_class.validate_frontmatter(nil)
        expect(result[:valid?]).to be true
        expect(result[:errors]).to be_empty
        expect(result[:warnings]).to be_empty

        # Covers line 168 (empty frontmatter early return)
        result = described_class.validate_frontmatter({})
        expect(result[:valid?]).to be true
      end

      it 'covers required keys validation logic' do
        frontmatter = { 'title' => 'Test' }

        # Covers lines 171-176 (required keys checking)
        result = described_class.validate_frontmatter(frontmatter, required_keys: ['title', 'missing'])

        expect(result[:valid?]).to be false
        expect(result[:errors]).to include('Missing required key: missing')
      end

      it 'covers symbol key handling in required keys' do
        frontmatter = { title: 'Test', status: 'draft' }

        # Covers line 172 (symbol key alternative check)
        result = described_class.validate_frontmatter(frontmatter, required_keys: ['title', 'status'])

        expect(result[:valid?]).to be true
        expect(result[:errors]).to be_empty
      end

      it 'covers allowed keys validation logic' do
        frontmatter = { 'title' => 'Test', 'unknown' => 'value' }

        # Covers lines 179-186 (allowed keys checking)
        result = described_class.validate_frontmatter(frontmatter, allowed_keys: ['title'])

        expect(result[:valid?]).to be true
        expect(result[:warnings]).to include('Unknown key: unknown')
      end

      it 'covers symbol to string key conversion' do
        frontmatter = { title: 'Test', status: 'draft' }

        # Covers line 181 (key.to_s conversion)
        result = described_class.validate_frontmatter(frontmatter, allowed_keys: ['title', 'status'])

        expect(result[:warnings]).to be_empty
      end
    end

    describe 'private method coverage' do
      describe 'find_closing_delimiter' do
        it 'covers successful delimiter finding' do
          lines = ['---', 'title: Test', 'status: draft', '---', 'Content']

          # Covers lines 200-204 (successful delimiter search)
          index = described_class.send(:find_closing_delimiter, lines, '---')
          expect(index).to eq(3)
        end

        it 'covers delimiter not found path' do
          lines = ['---', 'title: Test', 'Content without closing']

          # Covers line 203 (delimiter not found)
          index = described_class.send(:find_closing_delimiter, lines, '---')
          expect(index).to be_nil
        end
      end

      describe 'parse_yaml_safely' do
        it 'covers empty YAML handling' do
          # Covers lines 214 (empty YAML early return)
          result = described_class.send(:parse_yaml_safely, '', true)
          expect(result).to eq({})

          # Covers whitespace-only YAML
          result = described_class.send(:parse_yaml_safely, "   \n\t  ", true)
          expect(result).to eq({})
        end

        it 'covers security checks invocation' do
          yaml_content = 'title: Safe Content'

          # Covers lines 217-219 (security checks in safe mode)
          expect(described_class).to receive(:perform_security_checks).with(yaml_content)
          described_class.send(:parse_yaml_safely, yaml_content, true)
        end

        it 'covers safe_load vs load branching' do
          yaml_content = 'title: Test'

          # Covers lines 222-229 (safe_load branch)
          result = described_class.send(:parse_yaml_safely, yaml_content, true)
          expect(result['title']).to eq('Test')

          # Covers lines 227-228 (regular load branch)
          result = described_class.send(:parse_yaml_safely, yaml_content, false)
          expect(result['title']).to eq('Test')
        end

        it 'covers parsed result type checking' do
          # Covers lines 232-239 (hash result)
          result = described_class.send(:parse_yaml_safely, 'title: Test', true)
          expect(result).to be_a(Hash)

          # Covers lines 235-236 (nil result)
          result = described_class.send(:parse_yaml_safely, '# Just a comment', true)
          expect(result).to eq({})
        end

        it 'covers non-hash result error' do
          yaml_content = "- item1\n- item2"  # Array, not hash

          # Covers lines 237-239 (non-hash error)
          expect { described_class.send(:parse_yaml_safely, yaml_content, true) }.to raise_error(described_class::ParseError, /must be a hash/)
        end

        it 'covers Psych::SyntaxError handling' do
          yaml_content = "title: test\nstatus: [invalid"

          # Covers lines 240-246 (Psych::SyntaxError)
          expect { described_class.send(:parse_yaml_safely, yaml_content, true) }.to raise_error(described_class::ParseError) do |error|
            expect(error.message).to include('Invalid YAML syntax')
            expect(error.yaml_error).to be_a(Psych::SyntaxError)
          end
        end

        it 'covers ArgumentError date parsing handling' do
          yaml_content = 'date: 2024-13-45'  # Invalid date

          # Mock to trigger ArgumentError with date message
          allow(YAML).to receive(:safe_load).and_raise(ArgumentError, 'invalid date format')

          # Covers lines 249-251 (date parsing error)
          expect { described_class.send(:parse_yaml_safely, yaml_content, true) }.to raise_error(described_class::ParseError, /Invalid date format in YAML/)
        end

        it 'covers generic ArgumentError handling' do
          yaml_content = 'title: Test'

          # Mock to trigger generic ArgumentError
          allow(YAML).to receive(:safe_load).and_raise(ArgumentError, 'generic error')

          # Covers lines 252-253 (generic ArgumentError)
          expect { described_class.send(:parse_yaml_safely, yaml_content, true) }.to raise_error(described_class::ParseError, /YAML parsing error/)
        end
      end

      describe 'perform_security_checks' do
        it 'covers each dangerous pattern detection' do
          patterns_to_test = [
            '!ruby/object:User', '!ruby/class:String', '!ruby/module:Kernel', '!ruby/regexp:/test/',
            '!ruby/string:test', '!!ruby/object:Test', '!!python/object:User', '!!binary',
            '<%=code%>', '{{variable}}', '${substitution}', 'eval(code)', "system('cmd')",
            '`command`', 'exec code', "popen('cmd')", 'fork do', "require 'file'",
            'include Module', "load 'file'", 'eval code', 'send :method', 'define_method :test',
            "class_eval 'code'", "module_eval 'code'", "instance_eval 'code'"
          ]

          patterns_to_test.each do |pattern|
            # Covers lines 292-296 (pattern matching and error raising)
            expect { described_class.send(:perform_security_checks, pattern) }.to raise_error(described_class::SecurityError, /dangerous pattern/)
          end
        end

        it 'covers nesting level tracking' do
          # Covers lines 299-311 (nesting level logic)
          nested_content = '{ a: { b: { c: value } } }'
          expect { described_class.send(:perform_security_checks, nested_content) }.not_to raise_error

          # Test excessive nesting
          excessive_nesting = '{ a: ' + '{ b: ' * 60 + 'value' + ' }' * 60
          expect { described_class.send(:perform_security_checks, excessive_nesting) }.to raise_error(described_class::SecurityError, /nesting level/)
        end

        it 'covers nesting decrements' do
          content_with_decrements = '{ a: value } [ item ] - list'

          # Covers lines 308-310 (nesting decrements)
          expect { described_class.send(:perform_security_checks, content_with_decrements) }.not_to raise_error
        end

        it 'covers length validation' do
          # Covers lines 314-316 (length check)
          short_content = 'a' * 1000
          expect { described_class.send(:perform_security_checks, short_content) }.not_to raise_error

          long_content = 'a' * 100_001
          expect { described_class.send(:perform_security_checks, long_content) }.to raise_error(described_class::SecurityError, /maximum length/)
        end
      end
    end

    describe 'error class coverage' do
      it 'covers ParseError initialization with all parameters' do
        yaml_error = Psych::SyntaxError.new('test', 1, 2, 'offset', 'problem', 'context')

        # Covers lines 26-31 (ParseError initialization)
        error = described_class::ParseError.new('Test message', line_number: 5, column: 10, yaml_error: yaml_error)

        expect(error.message).to eq('Test message')
        expect(error.line_number).to eq(5)
        expect(error.column).to eq(10)
        expect(error.yaml_error).to eq(yaml_error)
      end

      it 'covers SecurityError inheritance' do
        # Covers line 35 (SecurityError class definition)
        error = described_class::SecurityError.new('Security violation')

        expect(error).to be_a(StandardError)
        expect(error.message).to eq('Security violation')
      end
    end
  end
end
