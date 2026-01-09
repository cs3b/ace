---
id: v.0.9.0+task.014
status: done
priority: medium
estimate: 1 day
dependencies: [v.0.9.0+task.013]
---

# Enhanced test report generation with individual failure reports and cleanup

## Behavioral Specification

### User Experience
- **Input**: Test execution through ace-test-runner with enhanced reporting capabilities
- **Process**: Automatic generation of individual failure reports, organized directory structure, and cleanup options
- **Output**: Individual markdown files for each failure, failure index file, enhanced progress display with report paths, and configurable cleanup options

### Expected Behavior
This task extends the original task 013 implementation with additional unplanned work that provides comprehensive failure reporting and cleanup capabilities:

1. **Individual Failure Reports**: Each test failure generates its own markdown file in a failures/ subdirectory
2. **Failure Index Generation**: An index.md file is created that links to all individual failure reports
3. **Enhanced Progress Display**: ProgressFormatter shows paths to individual failure report files
4. **Report Cleanup Command**: --cleanup-reports option with configurable retention policies
5. **Organized Directory Structure**: Reports are organized with subdirectories for better navigation

### Interface Contract

```bash
# Enhanced reporting automatically active
ace-test unit                          # Generates individual failure reports
ace-test atoms --format progress       # Shows paths to failure reports

# Cleanup command
ace-test --cleanup-reports              # Clean old reports using default policy
ace-test --cleanup-reports --keep-days 7  # Custom retention period
```

**Report Structure:**
```
test-reports/
├── summary.md                         # Main summary report
├── failures/                          # Individual failure reports
│   ├── index.md                      # Index linking to all failures
│   ├── failure-001-test-name.md      # Individual failure report
│   └── failure-002-other-test.md     # Another failure report
└── archives/                          # Archived reports (if cleanup enabled)
```

### Success Criteria
- [x] **Individual Failure Reports**: Each failure generates detailed markdown with unique filename
- [x] **Failure Index**: Index file provides navigation to all failure reports
- [x] **Enhanced Progress Display**: Progress formatter shows paths to individual reports
- [x] **Report Cleanup**: Cleanup command removes old reports based on retention policy
- [x] **Directory Organization**: Clean subdirectory structure for report navigation

## Implementation Plan

### Technical Approach

#### Implementation Completed
This task documents unplanned work that extended the original task 013 implementation. All work has been completed and tested.

**Files Modified:**
1. **ace-test-runner/lib/ace/test_runner/molecules/report_storage.rb**
   - Added `generate_individual_failure_report(failure, index)` method
   - Added `generate_failure_index(failures)` method
   - Enhanced directory structure with failures/ subdirectory

2. **ace-test-runner/lib/ace/test_runner/organisms/test_orchestrator.rb**
   - Integrated individual failure report generation
   - Added failure index generation after test completion

3. **ace-test-runner/lib/ace/test_runner/formatters/progress_formatter.rb**
   - Enhanced to show paths to individual failure report files
   - Added failure report path display in progress output

4. **ace-test-runner/exe/ace-test**
   - Added --cleanup-reports command option
   - Implemented configurable retention policies
   - Added cleanup functionality for old reports

### Features Implemented

#### Individual Failure Reports
- Each test failure generates a unique markdown file
- Files named with failure index and test name for easy identification
- Complete failure details including stack trace, assertion details, and code context
- Organized in failures/ subdirectory

#### Failure Index Generation
- Automatic generation of index.md in failures/ directory
- Links to all individual failure reports
- Summary statistics and navigation aids
- Updated after each test run

#### Enhanced Progress Display
- ProgressFormatter shows paths to individual failure reports
- Real-time feedback on where failure details are stored
- Maintains existing performance characteristics

#### Report Cleanup System
- --cleanup-reports command for removing old reports
- Configurable retention policies (default and custom)
- Safe cleanup with archive option
- Prevents accumulation of old report files

### Testing Strategy

#### Validation Completed
- Individual failure report generation tested with real failures
- Failure index generation verified with multiple failures
- Progress display enhancements confirmed working
- Cleanup command tested with various retention policies
- Directory structure organization validated

## Objective

Extend the ace-test-runner with comprehensive failure reporting capabilities that provide individual failure analysis, organized report structure, and maintenance tools for managing report accumulation over time.

## Scope of Work

- **Reporting Scope**: Individual failure markdown generation, failure index creation
- **Display Scope**: Enhanced progress formatting with report path display
- **Maintenance Scope**: Report cleanup with configurable retention policies
- **Organization Scope**: Structured directory layout for report navigation

### Deliverables

#### Implementation Artifacts
- Individual failure report generation system
- Failure index creation and maintenance
- Enhanced progress formatter with report paths
- Report cleanup command with retention policies

#### Validation Artifacts
- Tested individual failure report generation
- Validated failure index creation and updates
- Confirmed enhanced progress display functionality
- Verified report cleanup and retention policies

## Out of Scope

- ❌ **Report Templates**: Custom failure report templates (future enhancement)
- ❌ **Report Filtering**: Advanced filtering of failure reports
- ❌ **Report Analytics**: Failure trend analysis over time
- ❌ **Integration with External Tools**: Linking to external debugging tools

## References

- Task 013: Base implementation of enhanced ace-test-runner
- ace-test-runner architecture and performance characteristics
- Report generation patterns and markdown formatting standards