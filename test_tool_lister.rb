#!/usr/bin/env ruby

require './lib/coding_agent_tools/organisms/tool_lister'

begin
  lister = CodingAgentTools::Organisms::ToolLister.new
  puts "Exe directory: #{lister.exe_directory}"
  
  # Debug step by step
  tool_files = lister.send(:scan_tools)
  puts "Tool files found: #{tool_files.length}"
  puts "First few tools: #{tool_files.first(5)}"
  
  if tool_files.length > 0
    tools_with_metadata = lister.send(:extract_metadata, tool_files, false)
    puts "Tools with metadata: #{tools_with_metadata.length}"
    puts "First tool metadata: #{tools_with_metadata.first.inspect}"
    
    filtered_tools = lister.send(:apply_blacklist_filter, tools_with_metadata)
    puts "Filtered tools: #{filtered_tools.length}"
    puts "First filtered tool: #{filtered_tools.first.inspect}"
  end
  
  result = lister.list_all_tools
  puts "Final result: #{result.inspect}"
rescue => e
  puts "Error: #{e.message}"
  puts e.backtrace.join("\n")
end