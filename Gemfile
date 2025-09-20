source "https://rubygems.org"

# Local workspace gems - flat in root (ace-* prefix)
gem "ace-core", path: "ace-core"
gem "ace-context", path: "ace-context"
gem "ace-test-runner", path: "ace-test-runner"

# Shared dev/test tools for all gems
group :development, :test do
  gem "ace-test-support", path: "ace-test-support"
  gem "minitest", "~> 5.20"
  gem "minitest-reporters", "~> 1.6"
  gem "rake", "~> 13.0"
  gem "bundler", "~> 2.4"
end