# frozen_string_literal: true

require 'spec_helper'
require 'coding_agent_tools/organisms/prompt_processor'
require 'tempfile'
require 'fileutils'

RSpec.describe CodingAgentTools::Organisms::PromptProcessor do
  let(:processor) { described_class.new }
  let(:custom_processor) { described_class.new(max_file_size: 1024) }

  describe '#initialize' do
    it 'uses default max file size' do
      expect(processor.instance_variable_get(:@max_file_size)).to eq(10 * 1024 * 1024)
    end

    it 'accepts custom max file size' do
      expect(custom_processor.instance_variable_get(:@max_file_size)).to eq(1024)
    end
  end

  describe '#process' do
    context 'with string input' do
      it 'returns valid prompt string' do
        result = processor.process('This is a test prompt')
        expect(result).to eq('This is a test prompt')
      end

      it 'strips whitespace from prompt' do
        result = processor.process('  Prompt with spaces  ')
        expect(result).to eq('Prompt with spaces')
      end

      it 'raises error for empty prompt' do
        expect do
          processor.process('')
        end.to raise_error(CodingAgentTools::Error, 'Prompt cannot be empty')
      end

      it 'raises error for whitespace-only prompt' do
        expect do
          processor.process('   ')
        end.to raise_error(CodingAgentTools::Error, 'Prompt cannot be empty')
      end

      it 'raises error for nil prompt' do
        expect do
          processor.process(nil)
        end.to raise_error(CodingAgentTools::Error, 'Prompt cannot be empty')
      end
    end

    context 'with file input' do
      let(:temp_file) { Tempfile.new(['prompt', '.txt']) }

      after do
        temp_file.close
        temp_file.unlink
      end

      it 'reads prompt from file' do
        temp_file.write('Prompt from file')
        temp_file.close

        result = processor.process(temp_file.path, from_file: true)
        expect(result).to eq('Prompt from file')
      end

      it 'strips whitespace from file content' do
        temp_file.write("  File content with spaces  \n")
        temp_file.close

        result = processor.process(temp_file.path, from_file: true)
        expect(result).to eq('File content with spaces')
      end

      it 'raises error for non-existent file' do
        expect do
          processor.process('/non/existent/file.txt', from_file: true)
        end.to raise_error(CodingAgentTools::Error, 'Prompt file not found: /non/existent/file.txt')
      end

      it 'raises error for file exceeding size limit' do
        large_content = 'x' * (custom_processor.instance_variable_get(:@max_file_size) + 1)
        temp_file.write(large_content)
        temp_file.close

        expect do
          custom_processor.process(temp_file.path, from_file: true)
        end.to raise_error(CodingAgentTools::Error, /File too large: \d+ bytes \(max: 1024\)/)
      end

      it 'handles UTF-8 encoded files' do
        temp_file.write('UTF-8 content: こんにちは 🚀')
        temp_file.close

        result = processor.process(temp_file.path, from_file: true)
        expect(result).to eq('UTF-8 content: こんにちは 🚀')
      end

      it 'raises error for permission denied' do
        temp_file.close
        FileUtils.chmod(0o000, temp_file.path)

        expect do
          processor.process(temp_file.path, from_file: true)
        end.to raise_error(CodingAgentTools::Error, /Permission denied reading file/)

        # Restore permissions for cleanup
        FileUtils.chmod(0o644, temp_file.path)
      end
    end
  end

  describe '#process_multiple' do
    context 'with string inputs' do
      it 'processes multiple prompts' do
        prompts = ['First prompt', 'Second prompt', 'Third prompt']
        results = processor.process_multiple(prompts)

        expect(results).to eq(['First prompt', 'Second prompt', 'Third prompt'])
      end

      it 'strips whitespace from all prompts' do
        prompts = ['  First  ', '  Second  ', '  Third  ']
        results = processor.process_multiple(prompts)

        expect(results).to eq(['First', 'Second', 'Third'])
      end
    end

    context 'with file inputs' do
      let(:temp_files) do
        3.times.map do |i|
          file = Tempfile.new(["prompt#{i}", '.txt'])
          file.write("Content from file #{i}")
          file.close
          file
        end
      end

      after do
        temp_files.each do |file|
          file.unlink
        end
      end

      it 'reads multiple files' do
        file_paths = temp_files.map(&:path)
        results = processor.process_multiple(file_paths, from_files: true)

        expect(results).to eq([
          'Content from file 0',
          'Content from file 1',
          'Content from file 2'
        ])
      end
    end
  end

  describe '#build_conversation' do
    let(:prompts) { ['Hello', 'Hi there!', 'How are you?', "I'm doing well"] }

    context 'without explicit roles' do
      it 'alternates between user and assistant roles' do
        conversation = processor.build_conversation(prompts)

        expect(conversation).to eq([
          { role: 'user', content: 'Hello' },
          { role: 'assistant', content: 'Hi there!' },
          { role: 'user', content: 'How are you?' },
          { role: 'assistant', content: "I'm doing well" }
        ])
      end
    end

    context 'with explicit roles' do
      it 'uses provided roles' do
        roles = ['user', 'user', 'assistant', 'assistant']
        conversation = processor.build_conversation(prompts, roles)

        expect(conversation).to eq([
          { role: 'user', content: 'Hello' },
          { role: 'user', content: 'Hi there!' },
          { role: 'assistant', content: 'How are you?' },
          { role: 'assistant', content: "I'm doing well" }
        ])
      end
    end

    context 'with single prompt' do
      it 'creates single-turn conversation' do
        conversation = processor.build_conversation(['Single prompt'])

        expect(conversation).to eq([
          { role: 'user', content: 'Single prompt' }
        ])
      end
    end
  end

  describe '#extract_from_json' do
    let(:json_file) { Tempfile.new(['data', '.json']) }

    after do
      json_file.close
      json_file.unlink
    end

    context 'with valid JSON' do
      it 'extracts prompt from default key' do
        json_file.write('{"prompt": "Test prompt from JSON"}')
        json_file.close

        result = processor.extract_from_json(json_file.path)
        expect(result).to eq('Test prompt from JSON')
      end

      it 'extracts prompt from custom key' do
        json_file.write('{"query": "Custom key prompt"}')
        json_file.close

        result = processor.extract_from_json(json_file.path, 'query')
        expect(result).to eq('Custom key prompt')
      end

      it 'extracts array of prompts' do
        json_file.write('[{"prompt": "First"}, {"prompt": "Second"}]')
        json_file.close

        result = processor.extract_from_json(json_file.path)
        expect(result).to eq(['First', 'Second'])
      end

      it 'handles nested structures' do
        json_file.write('{"data": {"prompt": "Nested prompt"}}')
        json_file.close

        result = processor.extract_from_json(json_file.path, 'data')
        expect(result).to eq({ 'prompt' => 'Nested prompt' })
      end
    end

    context 'with invalid JSON' do
      it 'raises error for invalid JSON syntax' do
        json_file.write('{"invalid": json}')
        json_file.close

        expect do
          processor.extract_from_json(json_file.path)
        end.to raise_error(CodingAgentTools::Error, "Invalid JSON in file: #{json_file.path}")
      end

      it 'raises error for missing key' do
        json_file.write('{"other": "value"}')
        json_file.close

        expect do
          processor.extract_from_json(json_file.path)
        end.to raise_error(CodingAgentTools::Error, "Key 'prompt' not found in JSON data")
      end
    end
  end

  describe '#format_template' do
    context 'with valid template and variables' do
      it 'substitutes single braces variables' do
        template = 'Hello {name}, welcome to {place}!'
        variables = { name: 'Alice', place: 'Wonderland' }

        result = processor.format_template(template, variables)
        expect(result).to eq('Hello Alice, welcome to Wonderland!')
      end

      it 'substitutes double braces variables' do
        template = 'Hello {{name}}, welcome to {{place}}!'
        variables = { name: 'Bob', place: 'Paradise' }

        result = processor.format_template(template, variables)
        expect(result).to eq('Hello Bob, welcome to Paradise!')
      end

      it 'handles mixed brace styles' do
        template = 'Hello {name}, welcome to {{place}}!'
        variables = { name: 'Charlie', place: 'Earth' }

        result = processor.format_template(template, variables)
        expect(result).to eq('Hello Charlie, welcome to Earth!')
      end

      it 'converts non-string values to strings' do
        template = 'Count: {count}, Active: {active}'
        variables = { count: 42, active: true }

        result = processor.format_template(template, variables)
        expect(result).to eq('Count: 42, Active: true')
      end
    end

    context 'with missing variables' do
      it 'raises error for unfilled variables' do
        template = 'Hello {name}, your age is {age}'
        variables = { name: 'John' }

        expect do
          processor.format_template(template, variables)
        end.to raise_error(CodingAgentTools::Error, 'Unfilled template variables: age')
      end

      it 'lists all unfilled variables' do
        template = 'Hello {name}, {age}, {location}'
        variables = {}

        expect do
          processor.format_template(template, variables)
        end.to raise_error(CodingAgentTools::Error, 'Unfilled template variables: name, age, location')
      end
    end

    context 'with no variables' do
      it 'returns template unchanged' do
        template = 'No variables here'
        result = processor.format_template(template)
        expect(result).to eq('No variables here')
      end
    end
  end

  describe '#validate' do
    it 'validates non-empty prompt' do
      result = processor.validate('Valid prompt')
      expect(result).to eq('Valid prompt')
    end

    it 'strips whitespace during validation' do
      result = processor.validate('  Valid prompt  ')
      expect(result).to eq('Valid prompt')
    end

    it 'raises error for empty prompt' do
      expect do
        processor.validate('')
      end.to raise_error(CodingAgentTools::Error, 'Prompt cannot be empty')
    end

    it 'raises error for nil prompt' do
      expect do
        processor.validate(nil)
      end.to raise_error(CodingAgentTools::Error, 'Prompt cannot be empty')
    end

    it 'raises error for whitespace-only prompt' do
      expect do
        processor.validate("   \n\t  ")
      end.to raise_error(CodingAgentTools::Error, 'Prompt cannot be empty')
    end

    context 'with length validation' do
      it 'accepts prompt within length limit' do
        result = processor.validate('Short prompt', max_length: 20)
        expect(result).to eq('Short prompt')
      end

      it 'raises error for prompt exceeding length' do
        expect do
          processor.validate('This is a very long prompt', max_length: 10)
        end.to raise_error(CodingAgentTools::Error, 'Prompt exceeds maximum length of 10 characters')
      end
    end
  end

  describe '#split_into_chunks' do
    context 'with short prompt' do
      it 'returns single chunk for prompt within chunk size' do
        prompt = 'Short prompt'
        chunks = processor.split_into_chunks(prompt, chunk_size: 100)

        expect(chunks).to eq(['Short prompt'])
      end
    end

    context 'with long prompt' do
      let(:long_prompt) do
        'This is the first sentence. This is the second sentence. ' \
        'This is the third sentence. This is the fourth sentence. ' \
        'This is the fifth sentence. This is the sixth sentence.'
      end

      it 'splits prompt into chunks' do
        chunks = processor.split_into_chunks(long_prompt, chunk_size: 60, overlap: 10)

        expect(chunks.length).to be > 1
        chunks.each do |chunk|
          expect(chunk.length).to be <= 60
        end
      end

      it 'splits at sentence boundaries when possible' do
        chunks = processor.split_into_chunks(long_prompt, chunk_size: 60, overlap: 0)

        chunks.each do |chunk|
          # Check that chunks end with sentence terminator or are the last chunk
          expect(chunk).to match(/[.!?]\s*\z/) unless chunk == chunks.last
        end
      end

      it 'applies overlap between chunks' do
        chunks = processor.split_into_chunks(long_prompt, chunk_size: 60, overlap: 20)

        # Check that there's some overlap between consecutive chunks
        chunks.each_cons(2) do |chunk1, chunk2|
          expect(chunk2).to include(chunk1[-10..]) if chunk1.length >= 10
        end
      end
    end

    context 'with very long text without sentence breaks' do
      let(:continuous_text) { 'word' * 500 }

      it 'splits at chunk size boundary' do
        chunks = processor.split_into_chunks(continuous_text, chunk_size: 100, overlap: 0)

        chunks[0...-1].each do |chunk|
          expect(chunk.length).to eq(100)
        end
      end
    end

    context 'with custom parameters' do
      it 'respects custom chunk size' do
        prompt = 'a' * 1000
        chunks = processor.split_into_chunks(prompt, chunk_size: 200)

        chunks[0...-1].each do |chunk|
          expect(chunk.length).to eq(200)
        end
      end

      it 'handles zero overlap' do
        prompt = 'Section 1. ' * 10 + 'Section 2. ' * 10
        chunks = processor.split_into_chunks(prompt, chunk_size: 50, overlap: 0)

        # Verify no overlap
        all_text = chunks.join('')
        expect(all_text.length).to be <= prompt.length
      end
    end
  end

  describe 'edge cases' do
    it 'handles very large valid file within limit' do
      temp_file = Tempfile.new(['large', '.txt'])
      content = 'x' * (processor.instance_variable_get(:@max_file_size) - 1)
      temp_file.write(content)
      temp_file.close

      result = processor.process(temp_file.path, from_file: true)
      expect(result).to eq(content)

      temp_file.unlink
    end

    it 'handles empty file' do
      temp_file = Tempfile.new(['empty', '.txt'])
      temp_file.close

      expect do
        processor.process(temp_file.path, from_file: true)
      end.to raise_error(CodingAgentTools::Error, 'Prompt cannot be empty')

      temp_file.unlink
    end

    it 'handles file with only whitespace' do
      temp_file = Tempfile.new(['whitespace', '.txt'])
      temp_file.write("   \n\t  ")
      temp_file.close

      expect do
        processor.process(temp_file.path, from_file: true)
      end.to raise_error(CodingAgentTools::Error, 'Prompt cannot be empty')

      temp_file.unlink
    end
  end
end
