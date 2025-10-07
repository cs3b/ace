# Changelog

All notable changes to ace-test-runner will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [0.1.1] - 2025-10-08

### Fixed
- **InProcessRunner Minitest::Reporters initialization**: Fixed `undefined method 'fetch' for StringIO` error
  - Changed `Minitest::Reporters::DefaultReporter.new($stdout)` to use `io:` parameter
  - Fixes error when running tests with direct/in-process execution mode
  - Location: `lib/ace/test_runner/molecules/in_process_runner.rb:208`

- **Double test execution**: Fixed tests running twice (once by ace-test, once by Minitest autorun)
  - Preserved `ENV['MT_NO_AUTORUN']` value instead of deleting it in InProcessRunner cleanup
  - Changed main executable to use `exit!` instead of `exit` to skip at_exit handlers
  - Prevents Minitest autorun from executing after ace-test completes
  - Locations:
    - `lib/ace/test_runner/molecules/in_process_runner.rb:30,121-125`
    - `exe/ace-test:299-301`

## [0.1.0] - 2025-10-05

Initial release with test execution and reporting capabilities.
