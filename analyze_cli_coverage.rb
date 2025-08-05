require 'json'

# Read the SimpleCov resultset
resultset_path = 'coverage/.resultset.json'
data = JSON.parse(File.read(resultset_path))
coverage_data = data.values.first['coverage']

# Find CLI.rb
cli_file = coverage_data.keys.find { |f| f.end_with?('/lib/coding_agent_tools/cli.rb') }
if cli_file
  lines = coverage_data[cli_file]
  lines = lines.is_a?(Hash) ? lines['lines'] : lines
  
  # Read the actual file
  file_content = File.read(cli_file).lines
  
  puts "Uncovered lines in cli.rb:"
  puts "=" * 80
  
  lines.each_with_index do |hits, idx|
    line_num = idx + 1
    # Skip non-executable lines (nil) and covered lines
    next if hits.nil? || (hits.is_a?(Integer) && hits > 0)
    
    # Print uncovered executable lines
    if hits == 0
      puts "Line #{line_num}: #{file_content[idx].strip}"
    end
  end
else
  puts "CLI.rb not found in coverage data"
end
