source 'https://rubygems.org'

# Local workspace gems - flat in root (ace-* prefix)
gem 'ace-context', path: 'ace-context'
gem 'ace-core', path: 'ace-core'
gem 'ace-docs', path: 'ace-docs'
gem 'ace-git-commit', path: 'ace-git-commit'
gem 'ace-llm', path: 'ace-llm'
gem 'ace-llm-providers-cli', path: 'ace-llm-providers-cli'
gem 'ace-nav', path: 'ace-nav'
gem 'ace-review', path: 'ace-review'
gem 'ace-search', path: 'ace-search'
gem 'ace-support-mac-clipboard', path: 'ace-support-mac-clipboard'
gem 'ace-taskflow', path: 'ace-taskflow'
gem 'ace-test-runner', path: 'ace-test-runner'

# Shared dev/test tools for all gems
group :development, :test do
  gem 'ace-test-support', path: 'ace-test-support'
  gem 'bundler', '~> 2.4'
  gem 'minitest', '~> 5.20'
  gem 'minitest-reporters', '~> 1.6'
  gem 'rake', '~> 13.0'
  gem 'simplecov', '~> 0.22'

  # Temporary: dev-tools dependencies for migration period
  # TODO: Remove once dev-tools are properly isolated or ace-context handles bundler contexts
  # These are needed for task-manager, release-manager, and other dev-tools executables
  gem 'addressable', '~> 2.8'
  gem 'bigdecimal', '~> 3.1'
  gem 'csv', '~> 3.0'
  gem 'dotenv', '~> 2.0'
  gem 'dry-cli'
  gem 'dry-configurable', '~> 1.0'
  gem 'dry-monitor', '~> 1.0'
  gem 'faraday', '~> 2.0'
  gem 'kramdown', '~> 2.0'
  gem 'kramdown-parser-gfm', '~> 1.0'
  gem 'ostruct', '~> 0.6.1'
  gem 'zeitwerk', '~> 2.6'
end
