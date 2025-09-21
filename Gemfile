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

  # Temporary: dev-tools dependencies for migration period
  # TODO: Remove once dev-tools are properly isolated or ace-context handles bundler contexts
  # These are needed for task-manager, release-manager, and other dev-tools executables
  gem "dry-cli"
  gem "dotenv", "~> 2.0"
  gem "faraday", "~> 2.0"
  gem "zeitwerk", "~> 2.6"
  gem "dry-monitor", "~> 1.0"
  gem "dry-configurable", "~> 1.0"
  gem "addressable", "~> 2.8"
  gem "csv", "~> 3.0"
  gem "kramdown", "~> 2.0"
  gem "kramdown-parser-gfm", "~> 1.0"
  gem "ostruct", "~> 0.6.1"
end