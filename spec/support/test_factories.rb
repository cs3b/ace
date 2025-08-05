# frozen_string_literal: true

# Test Factories for creating complex test data structures
# Provides realistic test data based on actual system outputs
module TestFactories
  # Factory for task management objects
  class TaskFactory
    def self.valid_task_metadata
      {
        id: 'v.0.3.0+task.42',
        status: 'pending',
        priority: 'high',
        estimate: '2h',
        dependencies: [],
        title: 'Example Task Title'
      }
    end

    def self.task_with_dependencies
      {
        id: 'v.0.3.0+task.43',
        status: 'blocked',
        priority: 'medium',
        estimate: '4h',
        dependencies: ['v.0.3.0+task.41', 'v.0.3.0+task.42'],
        title: 'Task With Dependencies'
      }
    end

    def self.completed_task
      {
        id: 'v.0.3.0+task.41',
        status: 'done',
        priority: 'high',
        estimate: '1h',
        dependencies: [],
        title: 'Completed Task'
      }
    end

    def self.invalid_task_metadata
      {
        id: 'invalid-id-format',
        status: 'unknown_status',
        priority: nil,
        estimate: 'invalid',
        dependencies: 'not_an_array'
      }
    end
  end

  # Factory for file tree structures
  class FileTreeFactory
    def self.typical_ruby_project
      {
        'lib' => {
          'project_name' => {
            'atoms' => {
              'file_reader.rb' => '# File reader implementation',
              'env_reader.rb' => '# Environment reader'
            },
            'molecules' => {
              'config_loader.rb' => '# Configuration loader'
            },
            'organisms' => {
              'task_manager.rb' => '# Task manager'
            }
          }
        },
        'spec' => {
          'unit' => {
            'atoms' => {},
            'molecules' => {},
            'organisms' => {}
          },
          'spec_helper.rb' => '# RSpec configuration'
        },
        'README.md' => '# Project README',
        'Gemfile' => "source 'https://rubygems.org'",
        'Rakefile' => "require 'bundler/gem_tasks'"
      }
    end

    def self.task_directory_structure
      {
        'dev-taskflow' => {
          'current' => {
            'v.0.3.0-workflows' => {
              'tasks' => {
                'v.0.3.0+task.42-example-task.md' => '# Example task content'
              },
              'docs' => {}
            }
          },
          'backlog' => {
            'v.0.4.0-features' => {
              'tasks' => {}
            }
          },
          'done' => {
            'v.0.2.0-foundation' => {
              'tasks' => {}
            }
          }
        }
      }
    end

    def self.empty_directory
      {}
    end

    def self.single_file_directory
      {
        'README.md' => '# Single file directory'
      }
    end
  end

  # Factory for git repository states
  class GitStateFactory
    def self.clean_repository
      {
        status: :clean,
        branch: 'main',
        staged_files: [],
        modified_files: [],
        untracked_files: [],
        commits: [
          {
            hash: 'abc123def456',
            author: 'Test User <test@example.com>',
            date: '2024-01-01 12:00:00 +0000',
            message: 'Initial commit'
          }
        ]
      }
    end

    def self.dirty_repository
      {
        status: :dirty,
        branch: 'feature/new-feature',
        staged_files: ['lib/new_feature.rb'],
        modified_files: ['lib/existing_file.rb', 'README.md'],
        untracked_files: ['temp_file.txt'],
        commits: [
          {
            hash: 'def456abc123',
            author: 'Test User <test@example.com>',
            date: '2024-01-02 12:00:00 +0000',
            message: 'Add new feature'
          },
          {
            hash: 'abc123def456',
            author: 'Test User <test@example.com>',
            date: '2024-01-01 12:00:00 +0000',
            message: 'Initial commit'
          }
        ]
      }
    end

    def self.not_a_repository
      {
        status: :not_git,
        error: 'fatal: not a git repository (or any of the parent directories): .git'
      }
    end

    def self.repository_with_conflicts
      {
        status: :conflict,
        branch: 'main',
        staged_files: [],
        modified_files: [],
        untracked_files: [],
        conflicted_files: ['lib/conflicted_file.rb', 'README.md']
      }
    end
  end

  # Factory for CLI command outputs
  class CLIOutputFactory
    def self.help_output(command_name)
      <<~OUTPUT
        Usage: #{command_name} [OPTIONS]

        #{command_name.capitalize} command description

        Options:
          -h, --help     Show this help message
          -v, --verbose  Enable verbose output
          --version      Show version

        Examples:
          #{command_name} --help
          #{command_name} --verbose
      OUTPUT
    end

    def self.version_output(version = '1.0.0')
      "#{version}\n"
    end

    def self.error_output(message)
      "Error: #{message}\n"
    end

    def self.success_output(message)
      "#{message}\n"
    end

    def self.json_output(data)
      JSON.pretty_generate(data) + "\n"
    end
  end

  # Factory for configuration objects
  class ConfigFactory
    def self.default_config
      {
        'default_provider' => 'google',
        'models' => {
          'google' => 'gemini-2.0-flash-lite',
          'anthropic' => 'claude-3-sonnet-20240229',
          'openai' => 'gpt-4'
        },
        'temperature' => 0.7,
        'max_tokens' => 1000,
        'cache_enabled' => true
      }
    end

    def self.minimal_config
      {
        'default_provider' => 'google'
      }
    end

    def self.invalid_config
      {
        'default_provider' => 'unknown_provider',
        'temperature' => 'not_a_number',
        'max_tokens' => -1
      }
    end

    def self.empty_config
      {}
    end
  end

  # Factory for HTTP responses
  class HTTPResponseFactory
    def self.success_response(body, status = 200)
      double('HTTPResponse',
        code: status.to_s,
        body: body.is_a?(String) ? body : JSON.generate(body),
        success?: status >= 200 && status < 300,
        headers: { 'content-type' => 'application/json' })
    end

    def self.error_response(message, status = 500)
      double('HTTPResponse',
        code: status.to_s,
        body: JSON.generate({ 'error' => { 'message' => message } }),
        success?: false,
        headers: { 'content-type' => 'application/json' })
    end

    def self.timeout_response
      raise Faraday::TimeoutError, 'Request timed out'
    end

    def self.connection_error
      raise Faraday::ConnectionFailed, 'Connection failed'
    end
  end

  # Factory for validation results
  class ValidationResultFactory
    def self.success_result
      {
        valid: true,
        errors: [],
        warnings: []
      }
    end

    def self.error_result(errors, warnings = [])
      {
        valid: false,
        errors: Array(errors),
        warnings: Array(warnings)
      }
    end

    def self.warning_result(warnings)
      {
        valid: true,
        errors: [],
        warnings: Array(warnings)
      }
    end
  end
end
