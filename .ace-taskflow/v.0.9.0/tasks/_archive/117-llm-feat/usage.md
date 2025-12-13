# ace-prompt - Complete Behavioral Specification

**Purpose:** This document completely describes what ace-prompt should do. If the entire `ace-prompt/` gem directory were deleted, this document (plus the task definition) should be sufficient to recreate it from scratch.

## What Problem Does This Solve?

**Problem:** Claude Code's in-editor prompt writing is limited. Developers want to:
1. Write complex prompts in their full-featured editor (not Claude's input box)
2. Keep automatic history of all prompts they've run
3. Optionally enhance prompts via LLM for clarity
4. Use prompts in project, task, or release contexts

**Solution:** A simple queue-based workflow tool that reads from a single default file, archives it automatically, and outputs the content.

## Core Concept: Queue Workflow (NOT Template Library)

**This is NOT:**
- ❌ A named prompt library with discovery
- ❌ A template system with variables
- ❌ A protocol-based prompt manager
- ❌ A complex prompt engineering tool

**This IS:**
- ✅ A simple queue: one active prompt file at a time
- ✅ Automatic archiving with timestamps
- ✅ Optional LLM enhancement for clarity
- ✅ Task-scoped prompts for context

Think of it like a **print queue** but for AI prompts: you write to a file, run the command, it archives and outputs.

## File Structure

### Default Location

```
.cache/ace-prompt/prompts/
├── the-prompt.md              # THE active prompt (only one!)
├── _previous.md               # Symlink → archive/TIMESTAMP.md (latest)
└── archive/
    ├── 20251119-120000.md     # Archived prompt from 12:00
    ├── 20251119-143000.md     # Archived prompt from 14:30
    └── 20251119-155500.md     # Archived prompt from 15:55
```

### Task-Specific Location

```
.ace-taskflow/v.0.9.0/tasks/117-llm-feat/
└── prompts/
    ├── the-prompt.md          # Task-specific active prompt
    ├── _previous.md           # Symlink to latest archive
    └── archive/
        └── 20251119-120000.md
```

### Enhancement Cache (Optional)

```
.cache/ace-prompt/enhanced/
└── a3f2bc1d5e...md5hash.md    # Cached enhanced prompts by content hash
```

## Complete Command Behavior

### Command 1: `ace-prompt` (Default - No Arguments)

**What it does:**
1. Find prompt file: `.cache/ace-prompt/prompts/the-prompt.md`
2. Archive it: Copy to `.cache/ace-prompt/prompts/archive/YYYYMMDD-HHMMSS.md`
3. Update symlink: `_previous.md` → `archive/YYYYMMDD-HHMMSS.md` (relative path)
4. Read content from `the-prompt.md`
5. If `config.enhancement.enabled = true`: Enhance via LLM, use cache
6. Output to stdout

**Exit codes:**
- `0`: Success
- `1`: Prompt file not found

**Example:**
```bash
# Setup
mkdir -p .cache/ace-prompt/prompts
echo "Review this code for security issues" > .cache/ace-prompt/prompts/the-prompt.md

# Run
ace-prompt

# Output:
Review this code for security issues

# Files after:
# - the-prompt.md (unchanged)
# - archive/20251119-143000.md (new copy)
# - _previous.md -> archive/20251119-143000.md (updated symlink)
```

### Command 2: `ace-prompt --task 117`

**What it does:**
1. Find task directory: `.ace-taskflow/{version}/tasks/117-*/` (glob pattern)
2. Use prompt file: `{task-dir}/prompts/the-prompt.md`
3. Archive to: `{task-dir}/prompts/archive/YYYYMMDD-HHMMSS.md`
4. Update symlink: `{task-dir}/prompts/_previous.md`
5. Read, optionally enhance, output

**Task Finding Logic:**
- Search pattern: `.ace-taskflow/*/tasks/117-*/**`
- If multiple versions: use most recent (highest version number)
- If multiple matches in same version: use first found

**Exit codes:**
- `0`: Success
- `1`: Task not found or prompt file not found

**Example:**
```bash
# Setup
mkdir -p .ace-taskflow/v.0.9.0/tasks/117-llm-feat/prompts
echo "Implement archive mechanism" > .ace-taskflow/v.0.9.0/tasks/117-llm-feat/prompts/the-prompt.md

# Run
ace-prompt --task 117

# Output:
Implement archive mechanism

# Uses: .ace-taskflow/v.0.9.0/tasks/117-llm-feat/prompts/the-prompt.md
# Archives to: .ace-taskflow/v.0.9.0/tasks/117-llm-feat/prompts/archive/20251119-143000.md
```

### Command 3: `ace-prompt --raw`

**What it does:**
- Same as default command BUT skips enhancement step
- Always outputs raw content even if `config.enhancement.enabled = true`
- Still archives the prompt

**Use case:** When you want to see/use the exact prompt without LLM modifications

**Example:**
```bash
ace-prompt --raw
# Skips enhancement, outputs raw content
```

### Command 4: `ace-prompt --task 117 --raw`

**What it does:**
- Combines task-specific location with raw output
- No enhancement

## Archive Mechanism (CRITICAL)

### Requirements

**Copy Behavior:**
- COPY the file (do NOT move)
- Original `the-prompt.md` stays intact
- User can immediately write next prompt

**Timestamp Format:**
- `YYYYMMDD-HHMMSS.md`
- Example: `20251119-143055.md`
- Sortable by name
- Use local time (not UTC)

**Symlink Behavior:**
- Always create/update `_previous.md` in same directory as `the-prompt.md`
- Use **relative path**: `_previous.md -> archive/TIMESTAMP.md`
- NOT absolute path
- If symlink exists, overwrite it

**Directory Creation:**
- If `archive/` doesn't exist, create it automatically
- If parent directories don't exist, create them

**Error Handling:**
- If archive fails: **warn but continue** (don't fail the command)
- If symlink fails: **warn but continue** (don't fail the command)
- Output should still work even if archiving fails

### Example Archive Flow

```bash
# Before
.cache/ace-prompt/prompts/
├── the-prompt.md (content: "Prompt A")
└── _previous.md -> archive/20251119-120000.md

# Run ace-prompt

# After
.cache/ace-prompt/prompts/
├── the-prompt.md (still: "Prompt A")  # UNCHANGED
├── _previous.md -> archive/20251119-143000.md  # UPDATED
└── archive/
    ├── 20251119-120000.md (content: "Previous prompt")
    └── 20251119-143000.md (content: "Prompt A")  # NEW COPY
```

## Enhancement Feature (Optional)

### When Enhancement Happens

**Default:** Enhancement is **DISABLED**
- User must explicitly enable in config
- `config.enhancement.enabled = false` by default

**If Enabled:**
1. Read prompt content
2. Check cache: MD5 hash of content
3. If cache hit: return cached enhanced version (<100ms)
4. If cache miss:
   - Load system prompt from `handbook/prompts/enhance-system.md`
   - Call LLM: `ace-llm query --model MODEL --temperature 0.3 --system SYSTEM_PROMPT PROMPT_CONTENT`
   - Cache result: `.cache/ace-prompt/enhanced/{md5hash}.md`
   - Return enhanced version

### Enhancement System Prompt

**Location:** `ace-prompt/handbook/prompts/enhance-system.md` (in gem)

**Purpose:** Instructs LLM how to improve prompts

**Content Example:**
```markdown
You are a prompt clarity assistant. Improve the given prompt by:

1. Making ambiguous instructions more specific
2. Adding structure where helpful (numbered lists, sections)
3. Clarifying expected outputs
4. Improving clarity without changing the user's intent

Return ONLY the improved prompt. Do not add explanations or meta-commentary.
```

### Enhancement Caching

**Cache Key:** MD5 hash of prompt content
**Cache Location:** `.cache/ace-prompt/enhanced/{md5}.md`
**Cache Hit:** If same content seen before, return cached (no LLM call)
**Cache Miss:** Call LLM, save result, return enhanced version

### Enhancement Failure Handling

**If LLM call fails:**
- Log warning: "Enhancement failed: {error}. Outputting raw prompt."
- Output raw prompt content
- Exit code: `0` (success, not failure)
- Continue workflow

**Never fail the command due to enhancement issues.**

## Configuration

### File Location

**Project Config:** `.ace/prompt/config.yml` (highest priority)
**User Config:** `~/.ace/prompt/config.yml` (fallback)

### Complete Schema

```yaml
prompt:
  # Prompt file locations
  default_dir: .cache/ace-prompt/prompts  # Where to find the-prompt.md
  default_file: the-prompt.md             # Name of active prompt file
  archive_subdir: archive                 # Subdirectory for archives

  # Enhancement settings (optional, disabled by default)
  enhancement:
    enabled: false                        # Must be explicitly enabled
    model: google:gemini-2.0-flash-lite  # LLM model to use
    temperature: 0.3                      # Low temperature for consistency
    cache_enabled: true                   # Cache enhanced prompts
    cache_path: .cache/ace-prompt/enhanced  # Where to cache
    system_prompt_path: handbook/prompts/enhance-system.md  # System prompt
```

### Config Defaults (Hardcoded if No Config)

```ruby
DEFAULT_CONFIG = {
  'default_dir' => '.cache/ace-prompt/prompts',
  'default_file' => 'the-prompt.md',
  'archive_subdir' => 'archive',
  'enhancement' => {
    'enabled' => false,
    'model' => 'google:gemini-2.0-flash-lite',
    'temperature' => 0.3,
    'cache_enabled' => true,
    'cache_path' => '.cache/ace-prompt/enhanced',
    'system_prompt_path' => 'handbook/prompts/enhance-system.md'
  }
}
```

## Integration with Claude Code

### Slash Command: `/prompt`

**Implementation:** `.claude/commands/prompt.md`

**Content:**
```markdown
1. read the instructions from .cache/ace-prompt/prompts/the-prompt.md
2. archive the the-prompt.md
3. run instructions from the the-prompt.md
```

**Behavior:**
- Executes: `ace-prompt` (default command)
- Output is automatically available in Claude Code conversation
- Claude executes the prompt instructions

## Error Messages

### Prompt File Not Found

```
Error: Prompt file not found: .cache/ace-prompt/prompts/the-prompt.md

Create it with:
  mkdir -p .cache/ace-prompt/prompts
  echo "Your prompt here" > .cache/ace-prompt/prompts/the-prompt.md
```

Exit code: `1`

### Task Not Found

```
Error: Task 117 not found in .ace-taskflow/

Available tasks:
  ace-taskflow tasks all
```

Exit code: `1`

### Enhancement Failed

```
Warning: Enhancement failed: Connection timeout. Outputting raw prompt.
[raw prompt content]
```

Exit code: `0` (warning, not error)

### Archive Failed

```
Warning: Failed to archive prompt: Permission denied
[prompt content]
```

Exit code: `0` (warning, not error)

### Symlink Failed

```
Warning: Failed to update _previous.md: Operation not permitted
[prompt content]
```

Exit code: `0` (warning, not error)

## Complete Workflow Examples

### Example 1: Daily Development Workflow

```bash
# Morning - Write prompt for today's work
cat > .cache/ace-prompt/prompts/the-prompt.md <<'EOF'
Review yesterday's code changes and:
1. Check for any bugs introduced
2. Verify test coverage is adequate
3. Look for optimization opportunities
EOF

# Run it in Claude Code
/prompt
# Claude reads, archives, executes

# Afternoon - Write new prompt
cat > .cache/ace-prompt/prompts/the-prompt.md <<'EOF'
Help me refactor the PromptArchiver class:
1. Simplify the copy logic
2. Add better error handling
3. Update tests
EOF

# Run it
/prompt
# Previous prompt automatically archived with timestamp

# End of day - Review what you asked
cat _previous.md  # Shows afternoon prompt
ls -lt archive/   # Shows all day's prompts
```

### Example 2: Task-Specific Work

```bash
# Working on task 117
cd $(ace-taskflow task 117 | grep Path | awk '{print $2}')

# Create task prompt
mkdir -p prompts
cat > prompts/the-prompt.md <<'EOF'
Implement the archive mechanism for ace-prompt:

Requirements:
- Copy the-prompt.md to archive/TIMESTAMP.md
- Update _previous.md symlink
- Keep original file intact
- Handle errors gracefully

Include comprehensive tests.
EOF

# Run task-specific prompt
ace-prompt --task 117

# Later - different prompt for same task
cat > prompts/the-prompt.md <<'EOF'
Review the archive implementation for edge cases
EOF

ace-prompt --task 117
# Previous task prompt archived automatically
```

### Example 3: Enhancement Workflow

```bash
# Enable enhancement
cat > .ace/prompt/config.yml <<'EOF'
prompt:
  enhancement:
    enabled: true
EOF

# Write unclear prompt
echo "make it better" > .cache/ace-prompt/prompts/the-prompt.md

# Run with enhancement
ace-prompt
# Output (enhanced):
# Review the code and improve it by:
# 1. Enhancing code quality and readability
# 2. Optimizing performance where applicable
# 3. Ensuring proper error handling
# 4. Adding necessary documentation
# Please provide specific suggestions for each improvement.

# Run same prompt again
ace-prompt
# Fast (<100ms) - returned from cache

# Run without enhancement
ace-prompt --raw
# Output (raw):
# make it better
```

## Implementation Requirements

### ATOM Architecture

**Atoms (Pure Functions):**
- `ContentHasher` - Generate MD5 hash
- `TimestampGenerator` - Generate YYYYMMDD-HHMMSS
- `TaskFinder` - Find task directory by ID

**Molecules (Operations):**
- `PromptLoader` - Read file from path
- `PromptArchiver` - Copy file, create symlink (CRITICAL)
- `CacheManager` - Read/write cache by hash

**Organisms (Business Logic):**
- `PromptEnhancer` - LLM enhancement with caching
- `PromptProcessor` - Orchestrate: find, archive, enhance, output

### CLI Structure

**Default Command (no subcommands):**
```ruby
class CLI < Thor
  default_task :run

  desc "run", "Read and archive prompt (default)"
  option :task, type: :numeric, desc: "Task ID for task-specific prompt"
  option :raw, type: :boolean, desc: "Skip enhancement"
  def run
    # Main logic here
  end
end
```

**Execution:**
- `ace-prompt` → runs default task
- `ace-prompt --task 117` → runs with task option
- `ace-prompt --raw` → runs with raw option

### Dependencies

**Required:**
- `ace-support-core` (~> 0.10) - Config cascade, FileReader/Writer
- `ace-llm` (~> 0.5) - LLM queries (optional, only if enhancement enabled)
- `thor` (~> 1.2) - CLI framework

**Optional (only if using enhancement):**
- LLM provider (Google Gemini, etc.)

### Tests

**Critical Tests:**
1. Archive mechanism (copy + symlink)
2. Task directory finding
3. Default command (no args)
4. Enhancement caching
5. Error handling (file not found, archive failed)
6. Integration test: full workflow

## Success Criteria Checklist

To verify implementation is complete:

- [ ] `ace-prompt` (no args) works - reads default location
- [ ] Archives to `archive/TIMESTAMP.md` successfully
- [ ] Creates/updates `_previous.md` symlink correctly
- [ ] `--task N` finds and uses task-specific prompt
- [ ] `--raw` skips enhancement
- [ ] Enhancement works when enabled (via LLM)
- [ ] Enhancement caching works (fast second run)
- [ ] Error messages are clear and helpful
- [ ] Archive failures don't stop execution (warnings only)
- [ ] Config cascade works (project overrides user config)
- [ ] `/prompt` slash command integration works
- [ ] All files use relative paths (no hardcoded absolute paths)
- [ ] Can delete and recreate gem from this specification

## Non-Requirements (What NOT to Build)

**Do NOT implement:**
- ❌ Named prompts with discovery
- ❌ `list` command to show available prompts
- ❌ `info` command to show prompt metadata
- ❌ `config` command to display config
- ❌ YAML frontmatter parsing in prompts
- ❌ Protocol registration (`prompt://`)
- ❌ Multiple search paths
- ❌ Context preset merging
- ❌ ace-context integration
- ❌ Multiple commands beyond default

**Keep it simple:** One command, one file, automatic archiving, optional enhancement.
