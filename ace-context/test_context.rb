#!/usr/bin/env ruby

# Add the ace-context lib directory to load path
$LOAD_PATH.unshift(File.join(__dir__, 'ace-context/lib'))

require 'ace/context'

puts "Testing ace-context with project-base preset..."
begin
  context = Ace::Context.load_preset('project-base')
  puts "SUCCESS: Context loaded without errors"
  puts "Context metadata: #{context.metadata}"
rescue => e
  puts "ERROR: #{e.class}: #{e.message}"
  puts "BACKTRACE:"
  puts e.backtrace.first(10).join("\n")
end
