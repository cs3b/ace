# frozen_string_literal: true

# Mock Helpers for comprehensive unit testing
# Provides consistent mocking patterns for external dependencies
module MockHelpers
  # Mock git command outputs with realistic responses
  class GitMockData
    def self.status_clean
      {
        success: true,
        output: "On branch main\nnothing to commit, working tree clean\n",
        exit_code: 0
      }
    end

    def self.status_dirty
      {
        success: true,
        output: <<~OUTPUT,
          On branch main
          Changes not staged for commit:
            modified:   lib/example.rb
          
          Untracked files:
            new_file.rb
        OUTPUT
        exit_code: 0
      }
    end

    def self.log_recent
      {
        success: true,
        output: <<~OUTPUT,
          commit abc123def456789
          Author: Test User <test@example.com>
          Date:   Mon Jan 1 12:00:00 2024 +0000
          
              Add new feature
          
          commit def456abc123789
          Author: Test User <test@example.com>
          Date:   Sun Dec 31 12:00:00 2023 +0000
          
              Fix bug in parser
        OUTPUT
        exit_code: 0
      }
    end

    def self.command_error
      {
        success: false,
        output: "fatal: not a git repository\n",
        exit_code: 128
      }
    end
  end

  # Mock file system operations
  module FileSystemMocks
    def mock_file_exists(path, exists = true)
      allow(File).to receive(:exist?).with(path).and_return(exists)
      allow(File).to receive(:file?).with(path).and_return(exists)
    end

    def mock_directory_exists(path, exists = true)
      allow(File).to receive(:exist?).with(path).and_return(exists)
      allow(File).to receive(:directory?).with(path).and_return(exists)
    end

    def mock_file_read(path, content)
      allow(File).to receive(:read).with(path).and_return(content)
    end

    def mock_file_write(path, content = anything)
      allow(File).to receive(:write).with(path, content)
    end

    def mock_directory_listing(path, entries)
      allow(Dir).to receive(:entries).with(path).and_return(entries)
      allow(Dir).to receive(:[]).with(File.join(path, "*")).and_return(entries.map { |e| File.join(path, e) })
    end
  end

  # Mock LLM API responses
  class LLMResponseMocks
    def self.google_success_response
      {
        "candidates" => [
          {
            "content" => {
              "parts" => [{"text" => "This is a test response from Google Gemini."}]
            },
            "finishReason" => "STOP",
            "index" => 0
          }
        ],
        "usageMetadata" => {
          "candidatesTokenCount" => 10,
          "promptTokenCount" => 5,
          "totalTokenCount" => 15
        }
      }
    end

    def self.anthropic_success_response
      {
        "id" => "msg_test123",
        "type" => "message",
        "role" => "assistant",
        "content" => [{"type" => "text", "text" => "This is a test response from Claude."}],
        "model" => "claude-3-sonnet-20240229",
        "stop_reason" => "end_turn",
        "usage" => {
          "input_tokens" => 5,
          "output_tokens" => 10
        }
      }
    end

    def self.openai_success_response
      {
        "id" => "chatcmpl-test123",
        "object" => "chat.completion",
        "created" => Time.now.to_i,
        "model" => "gpt-4",
        "choices" => [
          {
            "index" => 0,
            "message" => {
              "role" => "assistant",
              "content" => "This is a test response from OpenAI."
            },
            "finish_reason" => "stop"
          }
        ],
        "usage" => {
          "prompt_tokens" => 5,
          "completion_tokens" => 10,
          "total_tokens" => 15
        }
      }
    end

    def self.api_error_response(status = 401)
      {
        status: status,
        error: {
          "error" => {
            "message" => "Invalid API key",
            "type" => "invalid_request_error",
            "code" => "invalid_api_key"
          }
        }
      }
    end
  end

  # Mock system command execution
  module SystemCommandMocks
    def mock_system_command(command, success: true, output: "", exit_code: nil)
      exit_code ||= success ? 0 : 1

      allow(Open3).to receive(:capture3).with(anything).and_return([output, "", exit_code])
      allow(system).to receive(:call).with(command).and_return(success)
    end

    def mock_git_command(subcommand, response_data)
      command_pattern = /git #{Regexp.escape(subcommand)}/
      allow(Open3).to receive(:capture3).with(command_pattern, anything).and_return([
        response_data[:output],
        "",
        response_data[:exit_code]
      ])
    end
  end

  # Mock environment variables safely
  module EnvironmentMocks
    def with_mocked_env(env_vars)
      original_env = {}
      env_vars.each do |key, value|
        original_env[key] = ENV[key]
        ENV[key] = value
      end

      yield
    ensure
      original_env.each do |key, value|
        if value.nil?
          ENV.delete(key)
        else
          ENV[key] = value
        end
      end
    end

    def mock_env_var(key, value)
      allow(ENV).to receive(:[]).with(key).and_return(value)
      allow(ENV).to receive(:fetch).with(key, anything).and_return(value)
    end
  end

  # Mock project root detection to avoid file system dependencies
  module ProjectRootMocks
    def mock_project_root(root_path)
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(root_path)
    end

    def with_temp_project_root(&block)
      temp_dir = Dir.mktmpdir

      # Create .git directory to make it a valid project root
      FileUtils.mkdir_p(File.join(temp_dir, ".git"))

      # Mock the project root detector to return our temp directory
      CodingAgentTools::Atoms::ProjectRootDetector.method(:find_project_root)
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_return(temp_dir)

      yield temp_dir
    ensure
      # Restore original method
      allow(CodingAgentTools::Atoms::ProjectRootDetector).to receive(:find_project_root).and_call_original
      safe_directory_cleanup(temp_dir) if temp_dir
    end

    def with_working_directory(directory)
      original_dir = Dir.pwd
      Dir.chdir(directory)
      yield
    ensure
      Dir.chdir(original_dir)
    end
  end

  # Include all mock modules
  include FileSystemMocks
  include SystemCommandMocks
  include EnvironmentMocks
  include ProjectRootMocks
end
