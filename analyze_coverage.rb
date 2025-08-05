require 'json'

# Read the SimpleCov resultset
resultset_path = 'coverage/.resultset.json'
unless File.exist?(resultset_path)
  puts "Coverage resultset not found at #{resultset_path}"
  exit 1
end

data = JSON.parse(File.read(resultset_path))
coverage_data = data.values.first['coverage']

# Calculate coverage for each file
file_coverage = {}
coverage_data.each do |file, coverage_info|
  next unless file.include?('/lib/') && file.end_with?('.rb')
  
  # Handle both array and hash formats
  lines = coverage_info.is_a?(Hash) ? coverage_info['lines'] : coverage_info
  next unless lines.is_a?(Array)
  
  # Count covered and total lines (nil means non-executable)
  total_lines = lines.compact.size
  covered_lines = lines.compact.count { |hits| hits.is_a?(Integer) && hits > 0 }
  
  if total_lines > 0
    percentage = (covered_lines.to_f / total_lines * 100).round(2)
    file_coverage[file] = {
      covered: covered_lines,
      total: total_lines,
      percentage: percentage
    }
  end
end

# Sort by percentage (lowest first) and display
puts "Low coverage files (< 70%):"
puts "=" * 80
file_coverage
  .select { |_, stats| stats[:percentage] < 70 }
  .sort_by { |_, stats| stats[:percentage] }
  .each do |file, stats|
    short_path = file.split('/lib/').last
    puts "#{stats[:percentage].to_s.rjust(6)}% | #{stats[:covered].to_s.rjust(4)}/#{stats[:total].to_s.ljust(4)} | #{short_path}"
  end

# Summary
total_covered = file_coverage.values.sum { |s| s[:covered] }
total_lines = file_coverage.values.sum { |s| s[:total] }
overall = total_covered.to_f / total_lines * 100
puts "=" * 80
puts "Overall: #{overall.round(2)}% (#{total_covered}/#{total_lines})"

# Top priority files (largest impact)
puts "\nTop priority files (by potential coverage gain):"
puts "=" * 80
file_coverage
  .select { |_, stats| stats[:percentage] < 70 }
  .sort_by { |_, stats| -stats[:total] * (70 - stats[:percentage]) / 100 }
  .first(10)
  .each do |file, stats|
    short_path = file.split('/lib/').last
    potential_gain = ((70 - stats[:percentage]) * stats[:total] / 100).round
    puts "#{stats[:percentage].to_s.rjust(6)}% | +#{potential_gain.to_s.ljust(3)} lines | #{short_path}"
  end
