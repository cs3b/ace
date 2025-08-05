# frozen_string_literal: true

require 'spec_helper'
require 'tmpdir'
require 'fileutils'
require 'coding_agent_tools/organisms/tool_lister'

# Create a temporary executable file for testing
def create_test_executable(dir, name, content = "#!/bin/bash\necho 'test'")
  path = File.join(dir, name)
  File.write(path, content)
  File.chmod(0o755, path)
  path
end

RSpec.describe CodingAgentTools::Organisms::ToolLister do
  let(:temp_exe_dir) { Dir.mktmpdir('test_exe') }
  let(:tool_lister) { described_class.new(temp_exe_dir, config_path: '/non/existent/config.yml') }

  before do
    # Create test executables
    create_test_executable(temp_exe_dir, 'git-status')
    create_test_executable(temp_exe_dir, 'llm-query')
    create_test_executable(temp_exe_dir, 'nav-ls')
    create_test_executable(temp_exe_dir, 'coding_agent_tools')
    create_test_executable(temp_exe_dir, 'test-debug')
    create_test_executable(temp_exe_dir, '.hidden')

    # Create non-executable file
    non_exec_path = File.join(temp_exe_dir, 'not-executable')
    File.write(non_exec_path, 'test')
    File.chmod(0o644, non_exec_path)
  end

  after do
    FileUtils.rm_rf(temp_exe_dir)
  end

  describe '#initialize' do
    it 'sets the exe directory and blacklist' do
      expect(tool_lister.exe_directory).to eq(File.expand_path(temp_exe_dir))
      expect(tool_lister.blacklist).to eq(described_class::DEFAULT_BLACKLIST)
    end

    it 'accepts custom blacklist' do
      custom_blacklist = ['custom-*']
      lister = described_class.new(temp_exe_dir, blacklist: custom_blacklist)
      expect(lister.blacklist).to eq(custom_blacklist)
    end
  end

  describe '#list_all_tools' do
    it 'returns categorized tools by default' do
      result = tool_lister.list_all_tools

      expect(result).to have_key(:categories)
      expect(result).to have_key(:total)
      expect(result[:total]).to be > 0
    end

    it 'filters out blacklisted tools' do
      result = tool_lister.list_all_tools

      # Should not include coding_agent_tools (blacklisted)
      all_tools = result[:categories].values.flat_map { |cat| cat[:tools] }
      tool_names = all_tools.map { |tool| tool[:name] }

      expect(tool_names).not_to include('coding_agent_tools')
      expect(tool_names).not_to include('test-debug')
    end

    it 'includes descriptions when requested' do
      result = tool_lister.list_all_tools(descriptions: true)

      # Find a tool and check it has a description
      git_category = result[:categories]['Git Operations']
      expect(git_category).not_to be_nil

      git_tool = git_category[:tools].first
      expect(git_tool).to have_key(:description)
      expect(git_tool[:description]).not_to be_empty
    end

    it 'excludes descriptions when not requested' do
      result = tool_lister.list_all_tools(descriptions: false)

      # Find a tool and check it doesn't have a description
      git_category = result[:categories]['Git Operations']
      expect(git_category).not_to be_nil

      git_tool = git_category[:tools].first
      expect(git_tool).not_to have_key(:description)
    end

    it 'returns uncategorized list when requested' do
      result = tool_lister.list_all_tools(categorized: false)

      expect(result).to have_key(:tools)
      expect(result).to have_key(:total)
      expect(result).not_to have_key(:categories)
      expect(result[:tools]).to be_an(Array)
    end
  end

  describe '#list_tool_names' do
    it 'returns array of tool names' do
      names = tool_lister.list_tool_names

      expect(names).to be_an(Array)
      expect(names).to include('git-status')
      expect(names).to include('llm-query')
      expect(names).to include('nav-ls')
      expect(names).not_to include('coding_agent_tools') # blacklisted
    end

    it 'returns sorted tool names' do
      names = tool_lister.list_tool_names
      expect(names).to eq(names.sort)
    end
  end

  describe 'error handling' do
    it 'raises error for non-existent directory' do
      lister = described_class.new('/non/existent/path')

      expect do
        lister.list_all_tools
      end.to raise_error(CodingAgentTools::Error, /Executable directory not found/)
    end
  end
end
