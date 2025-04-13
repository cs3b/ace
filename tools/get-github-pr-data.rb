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

puts "✅ Done! Files stored in: #{pr_dir}"
puts "- #{File.basename(pr_file)}"
puts "- #{File.basename(reviews_file)}"
puts "- #{File.basename(comments_file)}"
puts "\nAbsolute path: #{File.expand_path(pr_dir)}"
puts "Relative to project root: #{pr_dir.gsub(PROJECT_ROOT + '/', '')}"
