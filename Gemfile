source "https://rubygems.org"

# Local workspace gems - flat in root (ace-* prefix)
gem "ace-core", path: "ace-core"

# To add new gem:
# 1. Add to Gemfile: gem "ace-context", path: "ace-context"
# 2. Run: bundle install
# 3. Commit both Gemfile and Gemfile.lock

# Shared dev/test tools for all gems
group :development, :test do
  gem "minitest", "~> 5.20"
  gem "minitest-reporters", "~> 1.6"
  gem "rake", "~> 13.0"
  gem "bundler", "~> 2.4"
end