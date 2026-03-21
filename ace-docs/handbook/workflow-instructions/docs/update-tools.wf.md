---
doc-type: workflow
title: Update Tools Documentation Workflow (v5)
purpose: Documentation for ace-docs/handbook/workflow-instructions/docs/update-tools.wf.md
ace-docs:
  last-updated: 2026-02-22
  last-checked: 2026-03-21
---

# Update Tools Documentation Workflow (v5)

> **Scope:** Updates `docs/tools.md` for ACE ecosystem tools. Focus on active tools used in current workflows.
>
> **CRITICAL COMPRESSION TARGET:** Keep total documentation under 500 lines. Each tool entry should be 10-15 lines
> maximum including the collapsible details section.

* * *

## 0 Goal

Maintain an ultra-compact tools reference focused on essential information only. Each tool gets: name, one-line purpose,
2-3 key flags, and ONE primary example. Extended documentation belongs in workflows/agents, not here.

* * *

## 1 Prerequisites

* A new or modified ACE tool executable exists
* You have run `tool-name --help` and/or reviewed the source
* Write access to `docs/tools.md`

* * *

## 2 Project Context Loading

### Load dev-tools context preset

    context --preset dev-tools
{: .language-bash}

### Understand project purpose and architecture

* docs/vision.md
* docs/architecture.md
* docs/blueprint.md
* docs/tools.md

### Review current tools documentation

* docs/tools.md

* * *

## 3 High-Level Execution Plan

| Step | Action | Notes |
|----------
| **1 Plan** | Map the tool to function category, persona, and cheat-sheet row | Table 1 below |
| **2 Edit** | Add / update the tool entry using the *Mini-template* (§4) | Use `<details>` |
| **3 Update** | • Main cheat-sheet<br />• Persona cheat-sheet(s)<br />• Category lists | Keep rows alphabetical |
| **4 Validate** | Run scripts in §6 Validation | Ensure documentation is current and accurate |

* * *

## 4 Templates

### 4.1 Cheat-sheet row

    | `tool-name` | 1-liner purpose | `--top-flag`, `--flag2` |
{: .language-markdown}

### 4.2 Tool entry (ULTRA-COMPACT)

    ### `tool-name` – 1-sentence pitch
    <details><summary>Details</summary>
    
    ```bash
    tool-name [ARGS] [OPTIONS]
{: .language-markdown}

**Key flags:** `--flag1` (purpose), `--flag2` (purpose)

**Example:**

    tool-name foo --flag value  # one clear example
{: .language-bash}

</details>

    
    #### COMPRESSION RULES
    - **MAXIMUM 3 flags** - only the most essential
    - **ONE example** - the most common use case
    - **NO** full `--help` output
    - **NO** feature lists or marketing copy
    - **NO** performance notes or detailed explanations
    - **NO** multiple examples unless absolutely critical
    - Keep details section to 5-8 lines max
    
    ---
    
    ## 5  Process Steps
    
    1. **Check Tool Eligibility**
       - Focus on active ACE ecosystem tools used in current workflows
       - Ensure tool provides value to AI agents and developers

    2. **Identify Tool Category & Purpose**
       - Test with `tool-name --help`, read source, determine function category

    3. **Locate Correct Documentation Section**
       - Find appropriate section in `docs/tools.md`
       - Ensure consistent categorization with other ACE tools
    
    4. **Create or Update Tool Entry**
       - Use the *Mini-template* above.
       - COMPRESS: Only essential flags, ONE example
    
    5. **Add / Update Cheat-sheets & Persona Sections**
       - Main cheat-sheet at top of file.
       - Persona-specific cheat-sheets (*Human Dev*, *AI Agent*, *Release Manager*, *Git Power-User*).
       - Keep cheat-sheets minimal - tool name, 5-word purpose, 1-2 flags max.
    
    6. **Update Category & Workflow Sections**
       - Add tool name to function and persona lists.
       - Amend workflow snippets where the tool is relevant.
    
    7. **Run Validation & Quality Checks** (see §6)
    
    ---
    
    ## 6  Validation Checklist
    
    ### 6.1  Cheat-sheet parity
    - [ ] Tool listed in **main** cheat-sheet
    - [ ] Tool listed in at least one **persona** cheat-sheet
    
    ### 6.2  Content Completeness
    - [ ] Tool name & one-sentence purpose
    - [ ] Basic usage syntax  
    - [ ] ONE primary example
    - [ ] 2-3 essential flags only
    - [ ] Total entry under 15 lines
    
    ### 6.3  Documentation Quality
    - [ ] Clear, concise prose
    - [ ] Code blocks formatted
    - [ ] Consistent style
    
    ### 6.4  Structural Integration
    - [ ] Correct section & category
    - [ ] No full paths
    - [ ] Focus on active ACE ecosystem tools
    
    ### 6.5  Technical Accuracy
    - [ ] Example tested
    - [ ] Essential flags match `--help`
    
    ### 6.6  User Experience  
    - [ ] Single most common use case shown
    - [ ] Entry fits on one screen when collapsed
    
    #### Validation scripts
    ```bash
    # markdown style
    markdownlint docs/tools.md

    # Check line count
    lines=$(wc -l < docs/tools.md)
    if [ $lines -gt 500 ]; then
      echo "⚠️  File too large: $lines lines (target: <500)"
    fi

* * *

## 7 Example Snippet (before → after)

### BEFORE (verbose):

    ### `search` – Unified intelligent search across project
    <details><summary>Details</summary>
    
    ```bash
    search [OPTIONS] PATTERN
{: .language-markdown}

| Flag | Purpose | Default |
|----------
| `-t, --type TYPE` | Search type (file, content, hybrid, auto) | `auto` |
| `-f, --files` | Search for files only | `false` |
| `-c, --content` | Search in file content only | `false` |
| `-i, --case-insensitive` | Case insensitive search | `false` |
| `-w, --whole-word` | Match whole words only | `false` |
| `-U, --multiline` | Enable multiline matching | `false` |
| `-A, --after NUM` | Show NUM lines after match | `0` |
| `-B, --before NUM` | Show NUM lines before match | `0` |
| `-C, --context NUM` | Show NUM lines of context | `0` |
| `-g, --glob PATTERN` | File glob pattern to include | None |
| `-e, --exclude PATTERN` | Pattern to exclude | None |
| `--since TIME` | Files modified since TIME | None |
| `--before TIME` | Files modified before TIME | None |
| `--staged` | Search staged files only | `false` |
| `--tracked` | Search tracked files only | `false` |
| `--changed` | Search changed files only | `false` |
| `--json` | Output in JSON format | `false` |
| `--yaml` | Output in YAML format | `false` |
| `-l, --files-with-matches` | Only print filenames | `false` |
| `--max-results NUM` | Limit number of results | None |
| `--fzf` | Use fzf for interactive selection | `false` |
| `-p, --preset NAME` | Use search preset | None |
| `--list-presets` | List available presets | N/A |

**Examples**

    # Basic content search
    search "TODO"
    
    # Find all Ruby files
    search "*.rb" --files
    
    # Search with regex in content
    search "def\s+initialize" --content
    
    # Interactive selection with fzf
    search "pattern" --fzf
    
    # Use built-in preset
    search --preset todo
    
    # Search with path filtering
    search "bug" --include "**/*.rb"
    
    # Find recently modified files
    search "*.md" --since "1 week ago"
    
    # Case-insensitive whole word search
    search "error" -i -w
    
    # Search staged files only
    search "console.log" --staged
    
    # Output results as JSON
    search "API" --json --max-results 10
{: .language-bash}

**Built-in Presets**

* `todo` - Find TODO, FIXME, HACK, XXX, NOTE comments
* `ruby` - Find all Ruby files (\*.rb)
* `tests` - Find all test files (\*\_spec.rb)
* `recent` - Find files modified in the last week
* `git-changes` - Find changed files in git

**Purpose:** The search tool provides unified, intelligent searching across your entire project. It uses DWIM (Do What I
Mean) heuristics to automatically determine whether you're searching for files or content, leverages ripgrep and fd for
blazing-fast performance, and supports interactive result selection with fzf. Perfect for single-project workflows with
streamlined, path-based results.

**Features:**

* Automatic mode detection (file vs content search)
* Streamlined, path-based output for single-project workflows
* Git-aware scopes (staged, tracked, changed files)
* Time-based file filtering
* Interactive result selection with fzf
* Configurable search presets
* Multiple output formats (text, JSON, YAML)
* Intelligent pattern analysis for optimal tool selection
* Simplified architecture focused on speed and usability

**Performance:**

* Uses ripgrep for content search (extremely fast)
* Uses fd for file search (faster than find)
* Streams results for immediate feedback
* Optimized for large codebases

</details>

    
    ### AFTER (ultra-compact):
    ```markdown
    ### `search` – Fast unified search for files and content
    <details><summary>Details</summary>
    
    ```bash
    search [PATTERN] [OPTIONS]

**Key flags:** `--files` (file search), `--preset NAME` (use preset), `--fzf` (interactive)

**Example:**

    search "TODO" --preset todo  # Find all TODO comments
{: .language-bash}

</details> \`\`\`

* * *

## 8 Design Principles (appendix)

1.  **Ultra-compact** – total file under 500 lines, each tool 10-15 lines max
2.  **Essential only** – workflows/agents have detailed usage, not here
3.  **One example rule** – show the primary use case only
4.  **Minimal flags** – 2-3 most important flags, not exhaustive lists
5.  **No fluff** – zero marketing copy, feature lists, or performance notes

