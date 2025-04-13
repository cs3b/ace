#!/usr/bin/env ruby

require 'optparse'
require 'json'
require 'net/http'
require 'uri'
require 'dotenv'
require 'time'
require 'fileutils'

# Determine the project root directory
PROJECT_ROOT = File.expand_path('../../..', __FILE__)

# Load .env from the same directory as the script
env_file = File.join(File.dirname(__FILE__), '.env')
Dotenv.load(env_file)

GITHUB_TOKEN = ENV['GITHUB_TOKEN']
abort("❌ Missing GITHUB_TOKEN in #{env_file}") unless GITHUB_TOKEN
# Start tracking execution time
script_start_time = Time.now

# Parse CLI options
options = {verbose: false}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby get_github_pr_data.rb [options]"

  opts.on("-o", "--owner OWNER", "GitHub repo owner") { |v| options[:owner] = v }
  opts.on("-r", "--repo REPO", "GitHub repo name") { |v| options[:repo] = v }
  opts.on("-p", "--pr PR_NUMBER", Integer, "Pull request number") { |v| options[:pr] = v }
  opts.on("-d", "--dir OUTPUT_DIR", "Output directory") { |v| options[:output] = v }
  opts.on("-v", "--verbose", "Enable verbose output") { |v| options[:verbose] = true }
  opts.on("-h", "--help", "Show this help message") do
    puts opts
    exit
  end
end.parse!
# Get all pages of a GitHub API result
def github_get_paginated(url)
  all_results = []
  next_url = url
  
  while next_url
    uri = URI(next_url)
    req = Net::HTTP::Get.new(uri)
    req['Authorization'] = "Bearer #{GITHUB_TOKEN}"
    req['Accept'] = "application/vnd.github+json"
    
    response = nil
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      response = http.request(req)
    end
    
    unless response.is_a?(Net::HTTPSuccess)
      return github_get(next_url) # Fallback to regular method which has retry logic
    end
    
    page_results = JSON.parse(response.body)
    all_results.concat(page_results)
    
    # Extract next page URL from Link header
    link_header = response['Link']
    next_url = nil
    
    if link_header
      matches = link_header.match(/<([^>]*)>;\s*rel="next"/)
      next_url = matches[1] if matches
    end
  end
  
  JSON.generate(all_results)
end


def log(message, verbose_only = false)
  puts message unless verbose_only && !options[:verbose]
end

%w[owner repo pr output].each do |k|
  abort("❌ Missing required option: --#{k}") unless options[k.to_sym]
end

# Resolve output directory path
output_dir = options[:output]
output_dir = File.join(PROJECT_ROOT, output_dir) unless output_dir.start_with?('/')

# Create timestamped directory
timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
pr_dir = File.join(output_dir, "docs", "pr-#{options[:pr]}-#{timestamp}")

begin
  FileUtils.mkdir_p(pr_dir)
rescue => e
  abort("❌ Failed to create output directory: #{e.message}")
end

# Create raw data directory
raw_dir = File.join(pr_dir, "raw")
begin
  FileUtils.mkdir_p(raw_dir)
rescue => e
  abort("❌ Failed to create raw data directory: #{e.message}")
end

# Define output paths
comments_file = File.join(raw_dir, "comments.json")
reviews_file = File.join(raw_dir, "reviews.json")
pr_file = File.join(raw_dir, "pr.json")

# GitHub API helpers
def github_get(url, retries = 3)
  uri = URI(url)
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{GITHUB_TOKEN}"
  req['Accept'] = "application/vnd.github+json"

  begin
    Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
      response = http.request(req)

      case response
      when Net::HTTPSuccess
        return response.body
      when Net::HTTPTooManyRequests
        if retries > 0
          # Get retry after time or default to 5 seconds
          retry_after = response['Retry-After']&.to_i || 5
          puts "Rate limited. Retrying after #{retry_after} seconds..."
          sleep retry_after
          return github_get(url, retries - 1)
        else
          abort("❌ GitHub API rate limit exceeded: #{response.body}")
        end
      else
        abort("❌ GitHub API error (#{response.code}): #{response.body}")
      end
    end
  rescue StandardError => e
    if retries > 0
      puts "Network error: #{e.message}. Retrying..."
      sleep 2
      return github_get(url, retries - 1)
    else
      abort("❌ Network error after multiple retries: #{e.message}")
    end
  end
end

# Fetch and save data
puts "📥 Fetching PR details..."
pr_data = JSON.parse(github_get("https://api.github.com/repos/#{options[:owner]}/#{options[:repo]}/pulls/#{options[:pr]}"))
File.write(pr_file, JSON.pretty_generate(pr_data))

puts "📥 Fetching PR reviews..."
reviews = JSON.parse(github_get_paginated("https://api.github.com/repos/#{options[:owner]}/#{options[:repo]}/pulls/#{options[:pr]}/reviews"))
reviews_with_comments = reviews.map do |review|
  if review["id"]
    comments = JSON.parse(github_get_paginated("https://api.github.com/repos/#{options[:owner]}/#{options[:repo]}/pulls/#{options[:pr]}/reviews/#{review["id"]}/comments"))
    review.merge("comments" => comments)
  else
    review
  end
end
File.write(reviews_file, JSON.pretty_generate(reviews_with_comments))

puts "📥 Fetching PR comments..."
comments_data = JSON.parse(github_get_paginated("https://api.github.com/repos/#{options[:owner]}/#{options[:repo]}/pulls/#{options[:pr]}/comments"))
File.write(comments_file, JSON.pretty_generate(comments_data))

# Create subdirectories for individual comments and reviews
comments_dir = File.join(pr_dir, "comments")
reviews_dir = File.join(pr_dir, "reviews")
FileUtils.mkdir_p(comments_dir)
FileUtils.mkdir_p(reviews_dir)

# Sanitize a filename to ensure it's safe across platforms
def sanitize_filename(filename)
  # Remove characters that cause issues in filenames
  filename.gsub(/[\/\\:*?"<>|]/, '_').gsub(/\s+/, '_')
end

def save_file_with_feedback(path, data, type)
  File.write(path, JSON.pretty_generate(data))
  puts "  - Saved #{File.basename(path)} #{type}"
end

# Process and save individual comments
puts "📝 Processing comments..."
comments = JSON.parse(File.read(comments_file))
total_comments = comments.size
progress_step = [1, (total_comments / 10).ceil].max # Show progress at most 10 times

comments.each_with_index do |comment, index|
  if !comment["id"] || !comment["created_at"]
    puts "  - Skipping comment without ID or timestamp"
    next
  end

  timestamp = Time.parse(comment["created_at"]).strftime("%Y-%m-%d-%H%M")
  comment_filename = File.join(comments_dir, "comment-#{timestamp}-#{comment["id"]}.json")
  File.write(comment_filename, JSON.pretty_generate(comment))

  if index % progress_step == 0 || index == total_comments - 1
    puts "  - Processed #{index + 1}/#{total_comments} comments (#{((index + 1.0) / total_comments * 100).round}%)"
  elsif options[:verbose]
    puts "  - Saved #{File.basename(comment_filename)}"
  end
end

# Process and save individual reviews
puts "📝 Processing reviews..."
JSON.parse(File.read(reviews_file)).each do |review|
  if !review["id"] || !review["submitted_at"]
    puts "  - Skipping review without ID or timestamp"
    next
  end

  timestamp = Time.parse(review["submitted_at"]).strftime("%Y-%m-%d-%H%M")
  review_filename = File.join(reviews_dir, "review-#{timestamp}-#{review["id"]}.json")

  # Remove embedded comments to avoid duplication
  review_copy = review.dup
  review_copy.delete("comments")

  File.write(review_filename, JSON.pretty_generate(review_copy))
  puts "  - Saved #{File.basename(review_filename)}"

  # Save review comments as individual files
  if review["comments"] && !review["comments"].empty?
    review["comments"].each do |comment|
      if !comment["id"] || !comment["created_at"]
        puts "    - Skipping review comment without ID or timestamp"
        next
      end

      comment_timestamp = Time.parse(comment["created_at"]).strftime("%Y-%m-%d-%H%M")
      comment_filename = File.join(comments_dir, "comment-#{comment_timestamp}-#{comment["id"]}.json")

      # Check if this comment was already saved (to avoid duplication)
      if File.exist?(comment_filename)
        puts "    - Skipping duplicate comment: #{File.basename(comment_filename)}"
      else
        File.write(comment_filename, JSON.pretty_generate(comment))
        puts "    - Saved #{File.basename(comment_filename)} (from review)"
      end
    end
  end
end

# Save PR data as a separate file
puts "📝 Processing PR data..."
pr_info_dir = File.join(pr_dir, "pr")
FileUtils.mkdir_p(pr_info_dir)

if pr_data["id"] && pr_data["created_at"]
  timestamp = Time.parse(pr_data["created_at"]).strftime("%Y-%m-%d-%H%M")
  pr_info_filename = File.join(pr_info_dir, "pr-#{timestamp}-#{pr_data["id"]}.json")
  File.write(pr_info_filename, JSON.pretty_generate(pr_data))
  puts "  - Saved #{File.basename(pr_info_filename)}"
end
puts "✅ Done! Files stored in: #{pr_dir}"
puts "Raw data files (in #{raw_dir.gsub(pr_dir + '/', '')}):"
puts "- #{File.basename(pr_file)}"
puts "- #{File.basename(reviews_file)}"
puts "- #{File.basename(comments_file)}"
puts "\nProcessed individual files:"
puts "- #{Dir[File.join(pr_info_dir, "*.json")].count} PR info in #{pr_info_dir.gsub(pr_dir + '/', '')}"
puts "- #{Dir[File.join(comments_dir, "*.json")].count} comments in #{comments_dir.gsub(pr_dir + '/', '')}"
puts "- #{Dir[File.join(reviews_dir, "*.json")].count} reviews in #{reviews_dir.gsub(pr_dir + '/', '')}"
puts "\nAbsolute path: #{File.expand_path(pr_dir)}"
puts "Relative to project root: #{pr_dir.gsub(PROJECT_ROOT + '/', '')}"

# Calculate and display execution time
execution_time = Time.now - script_start_time
puts "\nExecution completed in #{execution_time.round(2)} seconds"
