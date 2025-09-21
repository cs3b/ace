#!/usr/bin/env ruby

# Debug script to test template discovery

Dir.chdir('/Users/mc/Ps/ace-meta/ace-context')
$LOAD_PATH.unshift('lib')

require 'ace/context/molecules/template_discoverer'

discoverer = Ace::Context::Molecules::TemplateDiscoverer.new

puts "Default template paths:"
p Ace::Context::Molecules::TemplateDiscoverer::DEFAULT_TEMPLATE_PATHS

puts "\nChecking for templates..."
Ace::Context::Molecules::TemplateDiscoverer::DEFAULT_TEMPLATE_PATHS.each do |pattern|
  puts "\nPattern: #{pattern}"
  files = Dir.glob(pattern)
  puts "  Found: #{files.count} files"
  files.each { |f| puts "    - #{f}" }
end

# Try from parent directory
puts "\nFrom parent directory:"
Dir.chdir('..')
Ace::Context::Molecules::TemplateDiscoverer::DEFAULT_TEMPLATE_PATHS.each do |pattern|
  puts "\nPattern: #{pattern}"
  files = Dir.glob(pattern)
  puts "  Found: #{files.count} files"
  files.each { |f| puts "    - #{f}" }
end

# Test discovery
puts "\nDiscovering templates:"
discoverer = Ace::Context::Molecules::TemplateDiscoverer.new
templates = discoverer.discover_templates
puts "Found #{templates.count} templates:"
templates.each do |t|
  puts "  - #{t[:name]} (#{t[:template]})"
end