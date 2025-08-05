# frozen_string_literal: true

require 'spec_helper'
require 'open3'

RSpec.describe 'handbook claude list integration' do
  let(:handbook_exe) { File.expand_path('../../../exe/handbook', __FILE__) }

  it 'displays help for the list command' do
    stdout, stderr, status = Open3.capture3("#{handbook_exe} claude list --help")
    
    expect(status).to be_success
    expect(stdout).to include('List all Claude commands and their status')
    expect(stdout).to include('verbose')
    expect(stdout).to include('--type')
    expect(stdout).to include('--format')
  end

  it 'runs the list command successfully' do
    stdout, stderr, status = Open3.capture3("#{handbook_exe} claude list")
    
    expect(status).to be_success
    expect(stdout).to include('Claude Commands Overview')
    expect(stdout).to include('========================')
    # It should show at least one of these sections
    expect(stdout).to match(/Custom Commands|Generated Commands|Missing Commands|Summary:/)
  end

  it 'supports JSON output format' do
    stdout, stderr, status = Open3.capture3("#{handbook_exe} claude list --format json")
    
    expect(status).to be_success
    # Verify it's valid JSON
    expect { JSON.parse(stdout) }.not_to raise_error
  end

  it 'supports type filtering' do
    stdout, stderr, status = Open3.capture3("#{handbook_exe} claude list --type custom")
    
    expect(status).to be_success
    # When filtering by custom, it should not show other types
    expect(stdout).to include('Claude Commands Overview')
    # Note: The output may or may not include 'Custom Commands' depending on whether any exist
  end

  it 'handles verbose flag' do
    stdout, stderr, status = Open3.capture3("#{handbook_exe} claude list --verbose")
    
    expect(status).to be_success
    expect(stdout).to include('Claude Commands Overview')
  end
end