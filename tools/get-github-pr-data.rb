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

# Parse CLI options
options = {}

OptionParser.new do |opts|
  opts.banner = "Usage: ruby get_github_pr_data.rb [options]"

  opts.on("-o", "--owner OWNER", "GitHub repo owner") { |v| options[:owner] = v }
  opts.on("-r", "--repo REPO", "GitHub repo name") { |v| options[:repo] = v }
  opts.on("-p", "--pr PR_NUMBER", Integer, "Pull request number") { |v| options[:pr] = v }
  opts.on("-d", "--dir OUTPUT_DIR", "Output directory") { |v| options[:output] = v }
end.parse!

%w[owner repo pr output].each do |k|
  abort("❌ Missing required option: --#{k}") unless options[k.to_sym]
end

# Resolve output directory path
output_dir = options[:output]
output_dir = File.join(PROJECT_ROOT, output_dir) unless output_dir.start_with?('/')

# Create timestamped directory
timestamp = Time.now.strftime("%Y%m%d-%H%M%S")
pr_dir = File.join(output_dir, "docs", "pr-#{options[:pr]}-#{timestamp}")
FileUtils.mkdir_p(pr_dir)



# Define output paths
comments_file = File.join(pr_dir, "comments.json")
reviews_file = File.join(pr_dir, "reviews.json")
pr_file = File.join(pr_dir, "pr.json")

# GitHub API helpers
def github_get(url)
  uri = URI(url)
  req = Net::HTTP::Get.new(uri)
  req['Authorization'] = "Bearer #{GITHUB_TOKEN}"
  req['Accept'] = "application/vnd.github+json"

  Net::HTTP.start(uri.hostname, uri.port, use_ssl: true) do |http|
    response = http.request(req)
    unless response.is_a?(Net::HTTPSuccess)
      abort("❌ GitHub API error (#{response.code}): #{response.body}")
    end
    response.body
  end
end

# Fetch and save data
puts "📥 Fetching PR details..."
pr_data = JSON.parse(github_get("https://api.github.com/repos/#{options[:owner]}/#{options[:repo]}/pulls/#{options[:pr]}"))
File.write(pr_file, JSON.pretty_generate(pr_data))

puts "📥 Fetching PR reviews..."
reviews = JSON.parse(github_get("https://api.github.com/repos/#{options[:owner]}/#{options[:repo]}/pulls/#{options[:pr]}/reviews"))
reviews_with_comments = reviews.map do |review|
  if review["id"]
    comments = JSON.parse(github_get("https://api.github.com/repos/#{options[:owner]}/#{options[:repo]}/pulls/#{options[:pr]}/reviews/#{review["id"]}/comments"))
    review.merge("comments" => comments)
  else
    review
  end
end
File.write(reviews_file, JSON.pretty_generate(reviews_with_comments))

puts "📥 Fetching PR comments..."
comments_data = JSON.parse(github_get("https://api.github.com/repos/#{options[:owner]}/#{options[:repo]}/pulls/#{options[:pr]}/comments?per_page=100"))
File.write(comments_file, JSON.pretty_generate(comments_data))

# Create subdirectories for individual comments and reviews
comments_dir = File.join(pr_dir, "comments")
reviews_dir = File.join(pr_dir, "reviews")
FileUtils.mkdir_p(comments_dir)
FileUtils.mkdir_p(reviews_dir)

# Process and save individual comments
puts "📝 Processing comments..."
JSON.parse(File.read(comments_file)).each do |comment|
  if !comment["id"] || !comment["created_at"]
    puts "  - Skipping comment without ID or timestamp"
    next
  end
  
  timestamp = Time.parse(comment["created_at"]).strftime("%Y-%m-%d-%H%M")
  comment_filename = File.join(comments_dir, "comment-#{timestamp}-#{comment["id"]}.json")
  File.write(comment_filename, JSON.pretty_generate(comment))
  puts "  - Saved #{File.basename(comment_filename)}"
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
puts "Raw data files:"
puts "- #{File.basename(pr_file)}"
puts "- #{File.basename(reviews_file)}"
puts "- #{File.basename(comments_file)}"
puts "\nProcessed individual files:"
puts "- #{Dir[File.join(pr_info_dir, "*.json")].count} PR info in #{pr_info_dir.gsub(pr_dir + '/', '')}"
puts "- #{Dir[File.join(comments_dir, "*.json")].count} comments in #{comments_dir.gsub(pr_dir + '/', '')}"
puts "- #{Dir[File.join(reviews_dir, "*.json")].count} reviews in #{reviews_dir.gsub(pr_dir + '/', '')}"
puts "\nAbsolute path: #{File.expand_path(pr_dir)}"
puts "Relative to project root: #{pr_dir.gsub(PROJECT_ROOT + '/', '')}"
