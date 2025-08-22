#!/usr/bin/env ruby

require 'json'
require 'fileutils'
require 'time'

# Load configuration from JSON file
CONFIG_FILE = File.join(File.dirname(__FILE__), 'wrapper-tools-config.json')

def load_config
  if File.exist?(CONFIG_FILE)
    JSON.parse(File.read(CONFIG_FILE))
  else
    # Fallback configuration if file doesn't exist
    {
      'debug' => {
        'enabled' => true,
        'log_file' => '/tmp/wrapper-tools-hook.log'
      },
      'enforcements' => []
    }
  end
rescue JSON::ParserError => e
  $stderr.puts "Error parsing config file: #{e.message}"
  exit 1
end

def save_debug_info(config, input)
  return unless config.dig('debug', 'enabled')
  
  # Save individual JSON files with timestamp
  if config.dig('debug', 'save_individual_files')
    timestamp = Time.now.strftime('%Y%m%d-%H%M%S-%6N')
    pattern = config.dig('debug', 'file_pattern') || '/tmp/hook-debug-{timestamp}.json'
    debug_file = pattern.gsub('{timestamp}', timestamp)
    
    File.write(debug_file, JSON.pretty_generate(input))
  end
  
  # Append to log file
  if log_file = config.dig('debug', 'log_file')
    File.open(log_file, 'a') do |f|
      f.puts "=" * 60
      f.puts "#{Time.now.iso8601}"
      f.puts "Session: #{input['session_id']}"
      f.puts "Tool: #{input['tool_name']}"
      f.puts "Command: #{input.dig('tool_input', 'command')}"
      f.puts "CWD: #{input['cwd']}"
      # Note which agent would be useful but we don't have that info
      f.puts "Agent: [Not available in hook context]"
    end
  end
end

def check_wrapper_enforcement(config, command)
  config['enforcements'].each do |enforcement|
    next unless enforcement['enabled']
    
    # Check if command starts with any wrapper tool for this enforcement
    wrapper_tools = enforcement['wrapper_tools'] || {}
    wrapper_command = wrapper_tools.keys.find { |tool| command.start_with?(tool) }
    
    if wrapper_command
      # This is already a wrapper tool, allow it
      return { allow: true }
    end
    
    # Check if this is a native command that should use a wrapper
    if pattern = enforcement['pattern']
      if command =~ /#{pattern}/
        subcommand = $1
        native_command = "#{enforcement['name']} #{subcommand}"
        
        # Check if there's a wrapper mapping
        command_mappings = enforcement['command_mappings'] || {}
        wrapper_tool = command_mappings[native_command]
        
        # Check if this command has no wrapper available
        no_wrapper = enforcement['no_wrapper_available'] || []
        if no_wrapper.include?(native_command)
          # Allow commands that don't have wrapper replacements
          return { allow: true }
        end
        
        return {
          allow: false,
          enforcement_name: enforcement['name'],
          native_command: native_command,
          wrapper_tool: wrapper_tool,
          subcommand: subcommand
        }
      end
    end
  end
  
  # No enforcement rules matched, allow the command
  { allow: true }
end

def generate_error_message(result, config)
  enforcement = config['enforcements'].find { |e| e['name'] == result[:enforcement_name] }
  return nil unless enforcement
  
  error_messages = []
  error_messages << "ERROR: Use #{result[:enforcement_name]} wrapper tools instead of native commands."
  error_messages << ""
  error_messages << "You attempted to use: '#{result[:native_command]}'"
  
  if result[:wrapper_tool] && !result[:wrapper_tool].include?('no wrapper')
    error_messages << "Please use: '#{result[:wrapper_tool]}' instead"
    error_messages << ""
    error_messages << "Example:"
    
    # Provide specific examples based on the command
    case result[:subcommand]
    when 'status'
      error_messages << "  git-status                    # Check status across all repos"
      error_messages << "  git-status --short            # Compact output"
    when 'commit'
      error_messages << "  git-commit --intention \"fix bug\"              # Commit all changes"
      error_messages << "  git-commit file.rb --intention \"update code\" # Commit specific files"
    when 'add'
      error_messages << "  git-add file1.md file2.rb    # Stage specific files"
      error_messages << "  git-add --all                # Stage all changes"
    when 'diff'
      error_messages << "  git diff --stat              # Show summary of changes"
      error_messages << "  git diff --staged            # Show staged changes"
    when 'log'
      error_messages << "  git-log --oneline -n 10      # Show recent commits"
    end
  else
    error_messages << "No wrapper tool available for '#{result[:native_command]}'"
    error_messages << "This command is not allowed in this context."
  end
  
  error_messages << ""
  error_messages << "Wrapper tools provide:"
  error_messages << "• Multi-repository awareness"
  error_messages << "• Intelligent processing"
  error_messages << "• Enhanced functionality"
  
  error_messages.join("\n")
end

begin
  # Load configuration
  config = load_config
  
  # Read JSON input from stdin
  input_json = $stdin.read
  input = JSON.parse(input_json)
  
  # Save debug information
  save_debug_info(config, input)
  
  # Only process Bash tool calls
  exit 0 unless input['tool_name'] == 'Bash'
  
  # Get the command being executed
  command = input.dig('tool_input', 'command') || ''
  
  # Check wrapper enforcement rules
  result = check_wrapper_enforcement(config, command)
  
  if result[:allow]
    # Command is allowed
    exit 0
  else
    # Command should use wrapper tool
    error_message = generate_error_message(result, config)
    $stderr.puts error_message if error_message
    exit 2
  end
  
rescue JSON::ParserError => e
  $stderr.puts "Error parsing JSON input: #{e.message}"
  exit 1
rescue => e
  $stderr.puts "Unexpected error in wrapper enforcement hook: #{e.message}"
  $stderr.puts e.backtrace.first(5).join("\n") if ENV['DEBUG']
  exit 1
end