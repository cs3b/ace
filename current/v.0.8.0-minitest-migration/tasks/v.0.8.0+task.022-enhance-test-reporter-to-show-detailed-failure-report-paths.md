---
id: v.0.8.0+task.022
status: done
priority: medium
estimate: small
dependencies: []
---

# Enhance test reporter to show detailed failure report paths

## Behavioral Context

**Issue**: The ace-test formatter did not display where users could find detailed test failure information. When tests failed, users had to manually navigate to the test-report directory to find the timestamped folders containing failure details.

**Key Behavioral Requirements**:
- Display the report directory location prominently when tests fail
- Show individual report paths for each test failure
- Keep output compact and readable

## Objective

Enhanced the ace-test reporter to display paths to detailed failure reports directly in the console output.

## Scope of Work

- Modified test reporter to prepare report directory before printing console output
- Added individual failure report paths to each failure in the list
- Improved visibility of the overall report directory location

### Deliverables

#### Modify
- `lib/ace_tools/test_reporter/agent_reporter.rb`: Enhanced to show report paths
  - Fixed timing issue where report path was printed before being created
  - Added individual report paths for each failure (📄 timestamp/failures/001-test.md)
  - Improved formatting with colors and emojis for better visibility

## Implementation Summary

### What Was Done

- **Problem Identification**: User reported that ace-test output didn't indicate where to find detailed failure reports
- **Investigation**: Found that `@report_generator.current_report_path` was nil when printing because directory creation happened after console output
- **Solution**:
  1. Moved report directory preparation before console output
  2. Added individual failure report paths to each failure entry
  3. Enhanced formatting with emoji indicators and color coding
- **Validation**: Tested with multiple failing tests to verify output format

### Technical Details

The key fix was reordering operations in the `report` method:
```ruby
def report
  super
  return if config[:mode] == 'quiet'

  # Prepare report directory first if there are failures
  if has_failures_or_errors?
    @report_generator.prepare_report_directory
  end

  print_console_output
  generate_detailed_reports if has_failures_or_errors?
end
```

Enhanced failure output to include report paths:
```ruby
# Add path to detailed report if we're generating reports
if @report_generator.current_report_path && @markdown_formatter
  filename = @markdown_formatter.generate_failure_filename(result, idx + 1)
  timestamp = File.basename(@report_generator.current_report_path)
  report_path = "#{timestamp}/failures/#{filename}"
  io.puts "     📄 #{colorize(report_path, '36')}"
end
```

### Testing/Validation

```bash
# Created test files with deliberate failures
ruby -Ilib:test /tmp/test_reporter_demo.rb

# Ran full test suite
ace-test
```

**Results**:
- Failure reports now show individual paths: `📄 20250918-152754/failures/001-test_failure_with_message.md`
- Overall report location displayed prominently: `📁 Full report: /path/to/test-report/20250918-152754/`
- Output remains clean and readable even with multiple failures

## References

- Changes made directly in response to user feedback during session
- No commits yet (work to be committed)
- Related to test infrastructure improvements in v.0.8.0-minitest-migration release