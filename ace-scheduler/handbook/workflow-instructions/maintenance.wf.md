---
update:
  update_frequency: on-change
  frequency: on-change
  last-updated: '2026-02-04'
---

# Maintenance Tasks Workflow

## Goal

Provide a standard workflow for using ace-scheduler to run scheduled maintenance tasks and event-driven checks.

## Prerequisites

- `ace-scheduler` installed and available in PATH
- Project scheduler config available at `.ace/scheduler/config.yml`

## Process Steps

1. **Review Scheduled Tasks**
   ```bash
   ace-scheduler list
   ```

2. **Run Daily Tests Manually (Optional)**
   ```bash
   ace-scheduler run daily-tests
   ```

3. **Run Weekly E2E Manually (Optional)**
   ```bash
   ace-scheduler run weekly-e2e
   ```

4. **Emit Event Triggers**
   * Post-merge verification:
     ```bash
     ace-scheduler emit pr-merged
     ```
   * Pre-release gates:
     ```bash
     ace-scheduler emit release-started
     ```

5. **Check Status and History**
   ```bash
   ace-scheduler status
   ```

## Output / Success Criteria

- Scheduler tasks and events are visible via `ace-scheduler list`.
- Manual runs and event emissions complete successfully.
- `ace-scheduler status` shows upcoming runs and recent history.
