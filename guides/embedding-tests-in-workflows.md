# Embedding Tests in AI Agent Workflows

This guide details the standard for incorporating tests directly within AI agent workflow instruction files.
Integrating tests makes workflows more robust, provides faster feedback, and improves the reliability of
automated tasks.

## Purpose

Embedding tests directly into workflow instructions allows an AI agent to:

- Verify pre-conditions before starting complex operations.
- Validate the outcome of individual actions or tool uses.
- Confirm that a series of steps achieved the desired overall result.
- Request user verification for subjective or critical outputs.
- Ensure adherence to safety guardrails and compliance requirements.

This immediate feedback loop helps catch errors early, reduces the need for extensive manual checking, and
automated processes.

## Test Categories

The following categories of tests can be embedded in workflows:

1. **Pre-condition Checks:**
   - **Description:** Verify that the environment and inputs are ready before an action or task begins.
   - **Examples:** Ensure input files exist, required tools are available, API keys are set.

2. **Action Validation (Tool-Specific Tests):**
   - **Description:** Validate the immediate output or effect of a specific tool usage or agent action.
   - **Examples:** Check if a file was correctly modified, a command ran successfully, an API call returned expected data.

3. **Post-condition Checks (Task-Level Outcome Validation):**
   - **Description:** Verify that a sequence of actions has achieved its broader goal.
   - **Examples:** Confirm a generated report contains all necessary sections, a refactoring task didn\'t break existing tests.

4. **Output Validation (Against External Systems or Ground Truth):**
   - **Description:** Compare the agent\'s final output with an external reference or known correct state.
   - **Examples:** Check if a deployed service responds correctly, if data written to a database matches expectations.

5. **Guardrail Tests (Safety and Compliance):**
   - **Description:** Ensure the agent\'s operations stay within safe boundaries and meet compliance rules.
   - **Examples:** Prevent accidental deletion of critical files, check for hardcoded secrets, ensure generated code meets linting standards.

6. **User Feedback/Verification Prompts:**
   - **Description:** Solicit explicit confirmation from a human user for steps that are subjective, critical, or difficult
      to automate verification for.
   - **Examples:** Ask user to review a generated summary, confirm a proposed destructive action.

## Syntax for Embedding Tests

Tests are embedded in workflow markdown files using a specific blockquote structure. There are two main keywords: `TEST` for automated checks and `VERIFY` for user feedback prompts.

```

> TEST: <Test Name (brief, human-readable)>
>   Type: <Pre-condition | Action Validation | Post-condition | Output Validation | Guardrail>
>   Assert: <Human-readable description of what\\\'s being checked>
>   [Command: <executable command or script call, e.g., `bin/test --check-file ...`>]
>   [File: <path_to_file_to_check_or_use_in_command>]
>   [Pattern: <regex_or_string_pattern for_grep_like_checks>]
>   [Expected: <expected_value_or_outcome_description>]

> VERIFY: <Verification Point Name>
>   Type: User Feedback
>   Prompt: <Text to display to the user for verification>
>   [Options: <e.g., (yes/no), (proceed/abort/edit)>]
```

**Fields:**

- `TEST:` / `VERIFY:`: Keyword to initiate the test or verification block. Followed by a human-readable name.
- `Type:`: One of the defined test categories.
- `Assert:` (for `TEST`): A clear, human-readable statement of the condition being checked.
- `Command:` (optional, for `TEST`): The shell command the agent should execute to perform the test. A non-zero
  exit code indicates failure. This is the **preferred method for automated checks**.
- `File:` (optional, for `TEST`): Path to a file relevant to the test. Can be used by the `Command` or by the agent
  for simple checks if no `Command` is provided.
- `Pattern:` (optional, for `TEST`): A regex or string pattern to search for, typically within the `File`.
- `Expected:` (optional, for `TEST`): A description of the expected outcome or value, useful if the `Command` doesn\'t
  directly assert this.
- `Prompt:` (for `VERIFY`): The question or instruction presented to the user.
- `Options:` (optional, for `VERIFY`): Suggested responses for the user.

## Agent Interpretation and Execution

The AI agent should:

1. **Parse Blocks:** Identify `> TEST:` and `> VERIFY:` blocks in the workflow markdown.
2. **Execute `TEST` Blocks:**
   - If a `Command:` is provided, execute it (e.g., using a `terminal` tool). The `bin/test` utility is designed to be the common target for these commands. A non-zero exit status from the command signifies a test failure.
   - If no `Command:` is provided, the agent may attempt simple, direct checks based on `File:`, `Pattern:`, and `Assert:`, such as file existence or basic content checks. However, complex logic should always be encapsulated in a `Command:`.
3. **Handle `VERIFY` Blocks:**
   - Display the `Prompt:` text to the user.
   - Wait for user input. The workflow may pause or proceed based on the response.
4. **Handle Test Outcomes:**
   - **Success:** Proceed with the workflow.
   - **Failure (Automated Test or Negative User Feedback):** Report the failure (including test name, assertion, and command output if any). Halt the current task or follow specific error-handling instructions in the workflow, then await user guidance.
5. **Log:** Record all test executions and their outcomes.

## Examples

### Simple, Fast Feedback Tests

**Example 1: Check if a file was created**

## Step 2: Generate Configuration File

The agent will generate `config.json` based on the inputs.

> TEST: Config File Created
> Type: Post-condition Check
> Assert: The `config.json` file exists in the output directory.
> File: output/config.json
> Command: bin/test --check-file-exists output/config.json

**Example 2: Check if a file contains specific text**

## Step 3: Update README

The agent will add a "## Usage" section to `README.md`.

```

> TEST: README Usage Section Added
>   Type: Action Validation
>   Assert: The `README.md` file now contains the "## Usage" heading.
>   File: README.md
>   Pattern: "## Usage"
>   Command: bin/test --check-file-contains-pattern "## Usage" README.md

### Higher-Level Verification Tests


**Example 3: Confirm a command achieves an outcome (e.g., code formatting)**

## Step 4: Format Source Code

The agent will run the project's code formatter on all `.py` files.

> TEST: Code Formatting Applied
>   Type: Post-condition Check
>   Assert: The code formatter reports no changes are needed, indicating formatting was successful.
>   Command: black --check .  # (Assumes 'black' exits non-zero if changes are needed)
```

*Note: For commands like linters or formatters that exit 0 if successful (or no changes needed) and non-zero
if issues are found/changes would be made, the agent might need to interpret the exit code accordingly.
A wrapper script via `bin/test` could invert this if needed (e.g. `bin/test --expect-exit-code 0 \\\"black --check .\\\"`).*

**Example 4: User verification of generated content**

## Step 5: Generate Project Summary

The agent will write a summary of the project to `docs/summary.md`.

> VERIFY: Summary Accuracy
> Type: User Feedback
> Prompt: Please review `docs/summary.md`. Does it accurately reflect the project's current state and goals?
> Options: (Yes, Accurate / No, Needs Revision)

```


**Example 5: Pre-condition check for API key**

## Step 1: Initialize API Client

The agent will prepare to make calls to an external service.

> TEST: API Key Available
>   Type: Pre-condition Check
>   Assert: The `EXTERNAL_SERVICE_API_KEY` environment variable is set.
>   Command: bin/test --check-env-var-set EXTERNAL_SERVICE_API_KEY
```

## The `bin/test` Utility

A helper script, `bin/test`, is envisioned to simplify common test operations invoked via the `Command:` field.
This script would provide a consistent interface for checks like:

- File existence (`--check-file-exists <path>`)
- File non-existence (`--check-file-not-exists <path>`)
- File is not empty (`--check-file-not-empty <path>`)
- File contains a string/pattern (`--check-file-contains-pattern "<pattern>" <path>`)
- Environment variable is set (`--check-env-var-set <VAR_NAME>`)
- Arbitrary command execution and exit code checking (`--exec "your command here" --expect-exit-code <N>`)

Using `bin/test` promotes consistency and simplifies the `Command:` field in workflow files.

By adopting this standard, AI agent workflows can become significantly more reliable and easier to debug, leading to more efficient and trustworthy automation.
