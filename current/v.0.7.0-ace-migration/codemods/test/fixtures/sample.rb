# Test fixture for Ruby files
# This file contains various references to dev-* paths that should be updated

require_relative '../.ace/tools/lib/coding_agent_tools'
require '.ace/handbook/lib/handbook'

module TestModule
  # Constants with path references
  TOOLS_PATH = '.ace/tools/bin'
  HANDBOOK_DIR = ".ace/handbook/docs"
  TASKFLOW_ROOT = File.join('.ace/taskflow', 'current')
  LOCAL_CONFIG = File.expand_path('.ace/local/config')

  class PathProcessor
    def initialize
      @base = '.ace/tools/'
      @handbook = ".ace/handbook/"
      @taskflow = '.ace/taskflow/'
      @local = ".ace/local/"
    end

    def process
      # Comments should also be updated
      # Load from .ace/tools/lib
      # Save to .ace/handbook/output
      # Check .ace/taskflow/backlog
      # Use .ace/local/cache

      paths = [
        '.ace/tools/spec',
        '.ace/handbook/templates',
        '.ace/taskflow/done',
        '.ace/local/tmp'
      ]

      paths.map do |path|
        File.join(path, 'data.yml')
      end
    end

    def documentation
      <<~DOC
        This tool uses the following directories:
        - .ace/tools/ for executables
        - .ace/handbook/ for documentation
        - .ace/taskflow/ for task management
        - .ace/local/ for local configuration
      DOC
    end
  end
end

# Configuration hash
CONFIG = {
  'tools_dir' => '.ace/tools/',
  'handbook_dir' => '.ace/handbook/',
  'taskflow_dir' => '.ace/taskflow/',
  'local_dir' => '.ace/local/',
  'paths' => {
    'executable' => '.ace/tools/bin/tool',
    'docs' => '.ace/handbook/docs/index.md',
    'tasks' => '.ace/taskflow/current/task.md',
    'config' => '.ace/local/settings.yml'
  }
}

# Method calls with path arguments
FileUtils.cp('.ace/tools/template.rb', '.ace/local/output.rb')
Dir.glob('.ace/handbook/**/*.md')
File.read('.ace/taskflow/README.md')
load '.ace/local/init.rb'