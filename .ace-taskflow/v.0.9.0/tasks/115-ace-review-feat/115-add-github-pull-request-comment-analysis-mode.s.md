---
id: v.0.9.0+task.115
status: pending
priority: medium
estimate: 12h
dependencies:
- v.0.9.0+task.116
---

# Add GitHub Pull Request comment analysis mode to ace-review

## Behavioral Specification

### User Experience
- **Input**: PR identifier (number, URL, or `owner/repo#number` format), optional filter flags (`--filter questions`, `--filter unresolved`)
- **Process**: ace-review fetches all PR comment threads via `gh` CLI, analyzes discussion with specialized "comment analysis" LLM prompt, extracts unanswered questions, action items, and resolution status, generates structured synthesis
- **Output**: Cached analysis in `.cache/ace-review/sessions/comment-analysis-{timestamp}/`, terminal summary of findings (questions, action items, resolved discussions), optional GitHub PR comment with synthesis

### Expected Behavior

When a developer or AI agent uses `ace-review --pr-comments <PR_IDENTIFIER>`, they experience:

1. **Comment Thread Extraction**: Fetches all PR comments (review comments, issue comments, inline code comments) via `gh pr view --comments`
2. **Specialized Analysis**: Uses distinct LLM system prompt optimized for conversation analysis, not code review
3. **Structured Synthesis**: Identifies and categorizes:
   - Unanswered questions with author, timestamp, and context
   - Action items mentioned in discussions (refactoring, testing, documentation)
   - Resolved discussions and their outcomes
   - Conflicting opinions requiring resolution
4. **Actionable Output**: Generates markdown-formatted synthesis suitable for posting as PR comment
5. **Optional Posting**: `--post-comment` publishes synthesis to PR for team visibility

### Interface Contract

```bash
# Analyze PR comment threads
ace-review --pr-comments 123
ace-review --pr-comments https://github.com/owner/repo/pull/123
ace-review --pr-comments owner/repo#123

# Filter specific comment types
ace-review --pr-comments 123 --filter questions
ace-review --pr-comments 123 --filter unresolved
ace-review --pr-comments 123 --filter action-items

# Analyze and post synthesis to PR
ace-review --pr-comments 123 --post-comment

# Dry run (show what would be posted)
ace-review --pr-comments 123 --post-comment --dry-run

# Expected outputs:
# Success: "✓ Comment analysis completed. Found 3 unanswered questions, 2 action items, 5 resolved discussions."
# Success with details:
"""
## PR Comment Analysis Summary

**Unanswered Questions (3):**
- @alice [#issuecomment-123](link): "Should we add integration tests for this?" - No response yet
- @bob [#discussion_r456](link): "What's the performance impact on large datasets?" - Needs clarification
- @charlie [#issuecomment-789](link): "Is this backward compatible?" - Awaiting maintainer response

**Action Items (2):**
- Extract `formatUserData` utility function (suggested by @dave in discussion thread)
- Add error handling for null inputs (identified by @eve)

**Resolved Discussions (5):**
- ✓ Naming convention: Settled on `getUserProfile` (consensus reached)
- ✓ Testing approach: Agreed to unit tests + integration test (approved by maintainer)
- ✓ Performance concern: Addressed with caching strategy (@bob satisfied)
- ✓ Code style: Applied prettier formatting (@alice approved)
- ✓ Merge timing: Waiting for CI to pass (blocker identified)

**Conflicting Opinions (1):**
- Database migration strategy: @alice prefers immediate migration, @bob suggests gradual rollout
  Recommendation: Needs maintainer decision

**Recommendations:**
1. Address @alice's integration testing question before merge
2. Implement @dave's utility extraction suggestion for better code organization
3. Resolve database migration strategy conflict (maintainer input needed)
4. All resolved discussions cleared - ready to proceed once open items addressed
"""

# Success with post: "✓ Comment synthesis posted to PR #123: https://github.com/owner/repo/pull/123#issuecomment-999"
# No comments: "ℹ No comments found in PR #123. Nothing to analyze."
# Error: "✗ Failed to fetch PR comments: GitHub authentication required. Run 'gh auth login'"
```

**Error Handling:**
- [No `gh` CLI installed]: Error with installation instructions
- [Not authenticated with GitHub]: Error directing to `gh auth login`
- [PR not found]: Clear message indicating invalid PR number/URL
- [No comments found]: Informative message (not an error), empty analysis
- [Insufficient permissions]: Error explaining required GitHub permissions
- [Network/API failures]: Retry with exponential backoff, clear failure message
- [Rate limiting]: Pause with informative message about rate limit status

**Edge Cases:**
- [Draft PRs]: Comments analyzable with informational note
- [Closed/merged PRs]: Read-only analysis, `--post-comment` allowed (for retrospectives)
- [Large comment threads]: Pagination handling, chunked analysis if exceeding context limits, summary of summary
- [Review comments vs issue comments]: Both types analyzed and distinguished in output
- [Comment reactions]: Consider emoji reactions as signals (👍 = agreement, 👀 = acknowledged, ❤️ = appreciation)
- [Outdated comments]: Flag comments on changed code lines as potentially resolved
- [Bot comments]: Filter or flag automated comments (CI status, bot notifications)
- [Empty comments]: Skip comments with only reactions, no text content

### Success Criteria

- [ ] **Comment Extraction**: Successfully fetches all PR comment types (review comments, issue comments, inline) via `gh pr view --comments`
- [ ] **Thread Analysis**: Identifies unanswered questions with author context and timestamps
- [ ] **Action Item Detection**: Extracts mentioned action items (refactoring, testing, documentation tasks)
- [ ] **Resolution Tracking**: Distinguishes resolved vs unresolved discussion threads
- [ ] **Specialized Prompting**: Uses distinct system prompt optimized for conversation analysis (not code review)
- [ ] **Synthesis Format**: Generates structured markdown output suitable for GitHub PR comments
- [ ] **Comment Posting**: `--post-comment` successfully posts synthesis to PR
- [ ] **Filter Support**: `--filter` flag works for questions, unresolved, action-items
- [ ] **Cache Consistency**: Comment analysis cached in `.cache/ace-review/sessions/comment-analysis-{timestamp}/`

### Validation Questions

- [ ] **System Prompt Design**: Should comment analysis focus on summarization, action extraction, conflict identification, or all three?
- [ ] **Thread Grouping**: How should we group related comments - by file, by user, by topic, or chronologically?
- [ ] **Output Location**: Should comment synthesis post as new PR comment, update existing "analysis" comment, or both (versioned)?
- [ ] **Filter Granularity**: What filters are most useful - questions, action-items, conflicts, resolved, unresolved, by-author?
- [ ] **Comment Metadata**: Should we track comment age, author roles (maintainer/contributor/first-timer), resolution timestamps?
- [ ] **Update Behavior**: When re-analyzing same PR, should we update previous synthesis comment or create new one?
- [ ] **Thread Resolution Detection**: How do we detect when a question is answered - by reactions, follow-up comments, or explicit markers?
- [ ] **Integration with Diff Review**: Should `--pr 123 --include-comments` run both analyses in one session, or keep them separate?

## Objective

Enable ace-review to analyze GitHub Pull Request comment threads and discussion to surface unanswered questions, track action items, identify resolved discussions, and synthesize conversation insights - allowing AI agents and developers to quickly understand PR discussion state without manual comment scanning.

## Scope of Work

- **User Experience Scope**: Developers and AI agents analyzing PR discussions, identifying blockers, tracking action items, understanding conversation context
- **System Behavior Scope**: Comment thread fetching via `gh` CLI, LLM-powered conversation analysis with specialized prompt, structured synthesis generation, optional GitHub comment posting
- **Interface Scope**: New `--pr-comments` flag with PR identifier parsing, `--filter` flag for comment type selection, specialized analysis output format distinct from code review

### Deliverables

#### Behavioral Specifications
- PR comment fetching via `gh pr view --comments` with pagination
- Comment type classification (review comments, issue comments, inline code comments)
- Question detection and unanswered state tracking
- Action item extraction from discussion threads
- Resolution status determination (resolved vs active discussions)
- Specialized LLM system prompt for conversation analysis
- Synthesis output format (markdown-structured, GitHub-friendly)

#### Validation Artifacts
- Test scenarios for various comment thread patterns (questions, action items, conflicts)
- Comment type detection accuracy validation
- Resolution status determination logic verification
- Edge case handling (empty threads, bot comments, outdated comments)
- Filter functionality validation (questions-only, unresolved-only)

## Out of Scope

- ❌ **Implementation Details**: Specific Ruby modules, comment parsing architecture, LLM prompt engineering specifics
- ❌ **Technology Decisions**: Whether to use `gh` CLI JSON output or formatted text parsing
- ❌ **Inline Comment Positioning**: Mapping comments to specific code lines or diffs (focus on thread content)
- ❌ **Sentiment Analysis**: Detecting tone, frustration, or emotional content in comments
- ❌ **Auto-Resolution**: Automatically marking discussions as resolved based on analysis
- ❌ **Performance Optimization**: Comment caching across runs, incremental analysis
- ❌ **Future Enhancements**: Email notifications for unanswered questions, Slack integration, comment trend analysis

## References

- Original idea: `.ace-taskflow/v.0.9.0/ideas/done/20251113-112856-ace-review-feat/integrate-github-pull-request-gh-cli.s.md`
- Prerequisite task: Task 116 - Add GitHub Pull Request diff review mode (provides `gh` CLI integration foundation)
- GitHub CLI documentation: `gh pr view --comments`, `gh pr comment`, `gh api` for comment metadata
- Current ace-review architecture: Uses ace-llm for analysis, preset-based review logic
- Differentiation: This uses specialized conversation analysis prompt, not code review prompt

## Technical Approach

### Architecture Pattern

**Integration Strategy**: Extend ace-review with new comment analysis molecule layer, leveraging existing gh CLI integration from Task 116

The implementation follows ace-review's ATOM pattern with specialized focus on conversation analysis:
- **Atoms**: Reuse `gh_cli_executor.rb` from Task 116 for gh CLI execution
- **Molecules**: New comment-specific operations (`gh_comment_fetcher.rb`, `comment_thread_analyzer.rb`, `comment_synthesis_generator.rb`)
- **Organisms**: New orchestration via `comment_analysis_manager.rb` (separate from code review flow)
- **CLI**: New `--pr-comments` flag in `cli.rb`

**Key Design Decisions**:
1. **Separate Analysis Pipeline**: Comment analysis uses distinct workflow from code review (different LLM prompt, different output format)
2. **Reuse gh CLI Foundation**: Leverage PR identifier parser and gh CLI executor from Task 116
3. **Specialized LLM Prompt**: Create dedicated "conversation analysis" system prompt focused on question detection, action extraction, resolution tracking
4. **Thread Grouping**: Organize comments chronologically with author context and reply chains
5. **Filter Architecture**: Post-analysis filtering (fetch all, analyze, then filter) for flexibility
6. **Session Naming**: Use `comment-analysis-{timestamp}` pattern to distinguish from code reviews

**Integration with Existing Architecture**:
- Reuses `pr_identifier_parser.rb` and `gh_cli_executor.rb` from Task 116
- Independent from code review pipeline (no modifications to existing review flow)
- Uses `llm_executor.rb` for LLM execution with specialized prompt
- Comment synthesis cached in standard session structure for auditability

### Technology Stack

**Primary Dependencies**:
- **GitHub CLI (`gh`)**: Provided by Task 116 integration
  - Commands: `gh pr view --json comments,reviews`, `gh pr comment` (for posting)
  - JSON fields: `comments` (issue/PR comments), `reviews` (review threads)
  - API access: `gh api repos/{owner}/{repo}/pulls/{number}/comments` for detailed thread data

**Ruby Libraries** (already in ace-review):
- `Open3`: Safe subprocess execution (from Task 116)
- `JSON`: Parse gh CLI JSON output
- `Time`: Timestamp parsing for comment age analysis
- `FileUtils`: Session directory management

**Integration Points**:
- **Task 116 Dependencies**: `gh_cli_executor.rb`, `pr_identifier_parser.rb`
- **ace-llm-query**: Existing integration for LLM execution with new conversation prompt
- **ace-nav**: For resolving conversation analysis prompt template

**LLM Prompt Strategy**:
- **System Prompt Focus**: Question detection, action item extraction, resolution analysis, conflict identification
- **Input Format**: Chronologically organized comment threads with metadata (author, timestamp, reply chains)
- **Output Format**: Structured markdown with sections for questions, actions, resolved items, conflicts
- **Prompt Template**: Store in `.ace/prompts/comment-analysis.md` for customization

**Performance Implications**:
- Comment fetching: ~1-3 seconds via `gh pr view --json`
- Large threads: May require pagination or chunking for LLM context limits (>1000 comments)
- Analysis execution: Standard LLM latency (5-30 seconds depending on model/thread size)
- Filtering: Post-analysis, negligible performance impact

### Tool Selection

**Comment Fetching Approach**:

| Criteria | gh pr view --json | gh api (REST) | GraphQL | Selected |
|----------|-------------------|---------------|---------|----------|
| **Simplicity** | High (single command) | Medium (pagination) | Low (complex queries) | gh pr view |
| **Comment Types** | Both issue+review | Separate endpoints | Unified query | gh pr view |
| **Reply Chains** | Included | Requires parsing | Native support | gh pr view |
| **Rate Limits** | Same as API | 5000/hour | 5000/hour | gh pr view |
| **Maintenance** | GitHub-maintained | Manual pagination | Schema changes | gh pr view |

**Selection Rationale**:
- `gh pr view --json comments,reviews` provides all comment data in single call
- Includes both issue comments and review threads with reply chains
- Leverages Task 116's gh CLI foundation
- Fallback to `gh api` for pagination if needed (>100 comments)

**Dependency Analysis**:
- **No new external dependencies**: Uses gh CLI from Task 116
- **No new gem dependencies**: Uses existing Ruby stdlib
- **Task 116 prerequisite**: Must be implemented first for gh CLI integration

### Comment Analysis LLM Prompt Design

**System Prompt Structure**:
```
You are analyzing GitHub Pull Request discussion threads to identify:
1. Unanswered questions requiring responses
2. Action items mentioned in discussions
3. Resolved discussions and their outcomes
4. Conflicting opinions needing resolution

Input: Chronologically ordered PR comments with author, timestamp, reply chains
Output: Structured synthesis in markdown format
```

**Key Prompt Directives**:
- Distinguish questions from statements
- Track which questions have replies (resolved) vs no replies (unanswered)
- Extract action items (refactoring, testing, documentation tasks)
- Identify agreement/consensus patterns (emoji reactions, explicit confirmations)
- Flag conflicts (disagreements between reviewers)
- Consider comment context (code location, quoted text)

**Output Template**:
```markdown
## PR Comment Analysis Summary

**Unanswered Questions ({count}):**
- @author [#comment-link](url): "Question text" - Context/status

**Action Items ({count}):**
- Description (suggested by @author in thread)

**Resolved Discussions ({count}):**
- Topic: Outcome (consensus/decision)

**Conflicting Opinions ({count}):**
- Issue: Perspectives - Recommendation

**Recommendations:**
1. Priority actions before merge
2. Follow-up items for future work
```

## File Modifications

### Create

- **lib/ace/review/molecules/gh_comment_fetcher.rb**
  - Purpose: Fetch PR comments and review threads via gh CLI
  - Key components:
    - `fetch_comments(pr_identifier)`: Get all issue and review comments via `gh pr view --json`
    - `fetch_comment_threads(pr_identifier)`: Get detailed thread structure with replies
    - `parse_comment_metadata(comment_json)`: Extract author, timestamp, body, reactions, position
    - `organize_by_thread(comments)`: Group replies under parent comments
    - `filter_bot_comments(comments)`: Remove automated bot comments (CI, dependabot)
  - Dependencies: gh_cli_executor (from Task 116), pr_identifier_parser (from Task 116)
  - Testing: Integration tests with VCR cassettes for gh responses

- **lib/ace/review/molecules/comment_thread_analyzer.rb**
  - Purpose: Analyze comment threads for questions, actions, resolutions
  - Key components:
    - `analyze_threads(threads, options)`: Execute LLM analysis on comment threads
    - `prepare_llm_context(threads)`: Format comments for LLM input (chronological, with metadata)
    - `detect_question_replies(thread)`: Match replies to questions for resolution status
    - `extract_reactions(comment)`: Parse emoji reactions as signals
    - `identify_outdated_comments(thread, pr_diff)`: Flag comments on changed code lines
  - Dependencies: llm_executor, nav_prompt_resolver (for conversation prompt)
  - Testing: Unit tests with sample comment structures, LLM execution mocking

- **lib/ace/review/molecules/comment_synthesis_generator.rb**
  - Purpose: Generate structured synthesis from LLM analysis
  - Key components:
    - `generate_synthesis(analysis_result, filter_options)`: Create formatted output
    - `apply_filters(synthesis, filters)`: Filter to questions-only, unresolved-only, etc.
    - `format_for_terminal(synthesis)`: Terminal-friendly output with colors
    - `format_for_github(synthesis)`: GitHub markdown comment format
    - `count_items(synthesis)`: Extract counts for summary message
  - Dependencies: Analysis result structure
  - Testing: Unit tests for formatting, filtering logic

- **lib/ace/review/organisms/comment_analysis_manager.rb**
  - Purpose: Orchestrate comment analysis workflow
  - Key components:
    - `analyze_pr_comments(pr_identifier, options)`: Main entry point
    - `create_analysis_session(pr_identifier)`: Session directory (`comment-analysis-{timestamp}`)
    - `execute_analysis(comments, options)`: Run LLM analysis with conversation prompt
    - `save_analysis_results(session, synthesis)`: Cache synthesis and raw data
    - `post_synthesis_comment(pr_identifier, synthesis, options)`: Optional GitHub posting
  - Dependencies: gh_comment_fetcher, comment_thread_analyzer, synthesis_generator, gh_comment_poster (from Task 116)
  - Testing: Integration tests for full workflow

- **lib/ace/review/models/comment_analysis_options.rb**
  - Purpose: Data model for comment analysis options
  - Key components:
    - `pr_identifier`: Parsed PR reference
    - `filter`: Filter type (questions, unresolved, action-items, all)
    - `post_comment`: Boolean flag for posting synthesis
    - `dry_run`: Boolean flag for dry run mode
    - `include_bot_comments`: Boolean flag (default: false)
  - Dependencies: Inherits/composes with base options model
  - Testing: Unit tests for option validation

- **.ace/prompts/comment-analysis.md**
  - Purpose: LLM system prompt template for conversation analysis
  - Content: Specialized prompt for question detection, action extraction, resolution tracking
  - Format: ace-nav compatible prompt template
  - Testing: Manual prompt engineering testing with sample PR threads

- **test/molecules/test_gh_comment_fetcher.rb**
  - Purpose: Integration tests for comment fetching
  - Test scenarios: Comment retrieval, thread organization, bot filtering, pagination

- **test/molecules/test_comment_thread_analyzer.rb**
  - Purpose: Unit tests for thread analysis logic
  - Test scenarios: Question detection, reply matching, reaction parsing, outdated comments

- **test/molecules/test_comment_synthesis_generator.rb**
  - Purpose: Unit tests for synthesis generation
  - Test scenarios: Formatting, filtering, GitHub markdown output

- **test/organisms/test_comment_analysis_manager.rb**
  - Purpose: Integration tests for comment analysis workflow
  - Test scenarios: Full analysis flow, session management, comment posting

- **test/integration/test_pr_comment_workflow.rb**
  - Purpose: End-to-end PR comment analysis tests
  - Test scenarios: Complete workflows with different filters and options

### Modify

- **lib/ace/review/cli.rb**
  - Changes: Add `--pr-comments` option to OptionParser
  - Impact: CLI accepts PR comment analysis mode
  - Integration points: Route to comment_analysis_manager instead of review_manager
  - Lines affected: ~40 lines (new option definition, mode routing, help text)
  - Implementation:
    ```ruby
    opts.on('--pr-comments PR_IDENTIFIER', 'Analyze PR comment threads') do |pr|
      options[:mode] = :comment_analysis
      options[:pr_identifier] = pr
    end

    opts.on('--filter FILTER', 'Filter comment types (questions, unresolved, action-items)') do |f|
      options[:comment_filter] = f
    end
    ```

- **lib/ace/review/errors.rb**
  - Changes: Add comment analysis error classes
  - Impact: Clear error messages for comment analysis failures
  - New errors:
    - `NoCommentsFoundError` (informational, not failure)
    - `CommentFetchError` (network/API issues)
    - `CommentAnalysisError` (LLM execution failures)
  - Lines affected: ~15 lines

- **lib/ace/review.rb**
  - Changes: Require new comment analysis files
  - Impact: Load new molecules and organisms on gem initialization
  - Lines affected: ~6 lines (new require statements)

- **README.md**
  - Changes: Add PR comment analysis documentation section
  - Impact: Users discover comment analysis capability
  - Content: Usage examples, filter options, synthesis format
  - Lines affected: ~100 lines (new section after PR review mode)

### Delete

No files require deletion for this feature.

## Test Case Planning

### Comment Fetching Tests

**Happy Path Scenarios**:
1. Fetch comments from PR with issue and review comments: Returns both types
2. Fetch from PR with reply threads: Returns organized thread structure
3. Fetch from PR with emoji reactions: Includes reaction data
4. Fetch from PR with 0 comments: Returns empty array gracefully

**Edge Cases**:
1. Large PR (>100 comments): Handle pagination
2. PR with only bot comments: Filter correctly
3. PR with outdated comments (on changed lines): Flag appropriately
4. PR with deleted comments: Handle gracefully
5. Cross-repository PR (fork): Fetch comments correctly

**Error Conditions**:
1. PR not found: Clear error message
2. Network timeout: Retry logic
3. Rate limit exceeded: Clear wait time message
4. Insufficient permissions: Permission requirements explained

### Thread Analysis Tests

**Question Detection**:
1. Comment ending with "?": Detected as question
2. Comment with "should we", "what about": Detected as question
3. Statement without question marker: Not detected as question
4. Rhetorical question with answer in same comment: Context-aware detection

**Reply Matching**:
1. Direct reply to question comment: Marked as answered
2. Question with no replies: Marked as unanswered
3. Question with partial reply: Marked as needs clarification
4. Multiple replies to same question: Track conversation chain

**Action Item Extraction**:
1. Comment with "TODO": Extracted as action item
2. Comment with "we should refactor": Extracted with author attribution
3. Comment agreeing to change: Extracted as committed action
4. Suggestion vs command: Distinguish priority

**Resolution Detection**:
1. Thread with final "LGTM" or approval: Marked as resolved
2. Thread with thumbs up reactions: Consider consensus
3. Thread with conflicting opinions: Marked as unresolved conflict
4. Abandoned thread (no activity for days): Flag as stale

### Synthesis Generation Tests

**Formatting Tests**:
1. Generate synthesis with all sections: Proper markdown structure
2. Synthesis with empty sections: Omit empty sections gracefully
3. Synthesis with many items: Organize readably (limits per section)
4. GitHub comment format: Proper header, links, formatting

**Filter Tests**:
1. Filter to questions only: Shows only unanswered questions section
2. Filter to unresolved: Shows questions + conflicts
3. Filter to action-items: Shows only action items
4. Filter with no matches: Clear "no items found" message

### Comment Analysis Workflow Tests

**Happy Path Scenarios**:
1. Analyze PR with diverse comments: Creates session, saves synthesis
2. Analyze and post synthesis: Posts to GitHub successfully
3. Dry run mode: Shows preview without posting
4. Filter to questions: Returns filtered synthesis

**Session Management**:
1. Analysis creates `comment-analysis-{timestamp}` directory
2. Session includes raw comment JSON and synthesis markdown
3. Multiple analyses create separate sessions
4. Session compatible with ace-llm workflow inspection

**LLM Integration**:
1. Conversation prompt loaded from ace-nav
2. Comment threads formatted correctly for LLM context
3. LLM response parsed to extract structured data
4. Analysis failures logged clearly

### End-to-End Workflow Tests

**Complete Scenarios**:
1. **Basic Comment Analysis**:
   ```bash
   ace-review --pr-comments 123
   ```
   - Validates: Fetch comments, analyze, display synthesis

2. **Filtered Question Analysis**:
   ```bash
   ace-review --pr-comments 123 --filter questions
   ```
   - Validates: Fetch, analyze, filter to questions only

3. **Analysis with GitHub Posting**:
   ```bash
   ace-review --pr-comments 456 --post-comment
   ```
   - Validates: Fetch, analyze, post synthesis to PR

4. **Dry Run Preview**:
   ```bash
   ace-review --pr-comments 789 --post-comment --dry-run
   ```
   - Validates: Complete analysis, show preview, no posting

### Test Prioritization

**High Priority** (Core functionality):
- Comment fetching via gh CLI (all types)
- Thread organization and reply matching
- Basic LLM analysis execution
- Question detection and unanswered tracking
- Synthesis generation and formatting

**Medium Priority** (Enhanced features):
- Filter implementation (questions, unresolved, actions)
- Action item extraction
- Resolution detection logic
- Comment posting to GitHub
- Bot comment filtering

**Low Priority** (Edge cases):
- Pagination for large comment threads
- Outdated comment detection
- Emoji reaction parsing
- Stale thread identification
- Very large synthesis handling

## Implementation Plan

### Planning Steps

* [x] Analyze ace-review architecture and Task 116 dependencies
  > TEST: Architecture Understanding Check
  > Type: Pre-condition Check
  > Assert: Task 116 gh CLI foundation identified and reusable
  > Command: ls /Users/mc/Ps/ace-meta/ace-review/lib/ace/review/molecules/ | grep -E "(gh_|pr_)"

* [x] Research gh CLI comment fetching capabilities
  > TEST: gh CLI Comment API Verification
  > Type: External Dependency Check
  > Assert: `gh pr view --json comments,reviews` available, format understood
  > Command: gh pr view --help | grep -E "(comments|reviews)"

* [x] Design conversation analysis LLM prompt strategy
  > TEST: Prompt Design Validation
  > Type: Design Review
  > Assert: Prompt template covers question detection, action extraction, resolution tracking
  > Command: # Validate .ace/prompts/comment-analysis.md structure

* [x] Plan comment thread organization approach
  > TEST: Thread Organization Logic
  > Type: Design Review
  > Assert: Reply chains grouped, chronological ordering, metadata preserved
  > Command: # Review thread analyzer design

* [x] Design filter architecture (post-analysis vs pre-analysis)
  > TEST: Filter Strategy Validation
  > Type: Design Review
  > Assert: Post-analysis filtering chosen for flexibility
  > Command: # Verify synthesis generator supports all filter types

### Execution Steps

- [ ] Create `.ace/prompts/comment-analysis.md` with conversation analysis prompt
  > TEST: Prompt Template Validation
  > Type: Manual Test
  > Assert: Prompt clearly defines question, action, resolution, conflict identification
  > Command: cat .ace/prompts/comment-analysis.md

- [ ] Create `lib/ace/review/molecules/gh_comment_fetcher.rb` with comment fetching
  > TEST: Comment Fetching
  > Type: Integration Test (VCR cassette)
  > Assert: Fetches comments via `gh pr view --json comments,reviews`
  > Command: bundle exec rake test test/molecules/test_gh_comment_fetcher.rb::test_fetch_comments

- [ ] Implement thread organization in `gh_comment_fetcher.rb`
  > TEST: Thread Organization
  > Type: Unit Test
  > Assert: Reply chains grouped under parent comments chronologically
  > Command: bundle exec rake test test/molecules/test_gh_comment_fetcher.rb::test_organize_threads

- [ ] Implement bot comment filtering in `gh_comment_fetcher.rb`
  > TEST: Bot Filtering
  > Type: Unit Test
  > Assert: Filters common bots (dependabot, github-actions, etc.)
  > Command: bundle exec rake test test/molecules/test_gh_comment_fetcher.rb::test_filter_bots

- [ ] Create `lib/ace/review/molecules/comment_thread_analyzer.rb` with LLM integration
  > TEST: Thread Analysis Execution
  > Type: Integration Test
  > Assert: Executes LLM with conversation prompt and comment context
  > Command: bundle exec rake test test/molecules/test_comment_thread_analyzer.rb::test_analyze_threads

- [ ] Implement question-reply matching in `comment_thread_analyzer.rb`
  > TEST: Reply Matching Logic
  > Type: Unit Test
  > Assert: Identifies which questions have replies (resolved) vs not (unanswered)
  > Command: bundle exec rake test test/molecules/test_comment_thread_analyzer.rb::test_reply_matching

- [ ] Implement reaction parsing in `comment_thread_analyzer.rb`
  > TEST: Reaction Parsing
  > Type: Unit Test
  > Assert: Extracts emoji reactions and interprets as signals (👍 = agreement)
  > Command: bundle exec rake test test/molecules/test_comment_thread_analyzer.rb::test_parse_reactions

- [ ] Create `lib/ace/review/molecules/comment_synthesis_generator.rb` with formatting
  > TEST: Synthesis Generation
  > Type: Unit Test
  > Assert: Generates structured markdown with sections (questions, actions, resolved, conflicts)
  > Command: bundle exec rake test test/molecules/test_comment_synthesis_generator.rb::test_generate_synthesis

- [ ] Implement filter logic in `comment_synthesis_generator.rb`
  > TEST: Filter Application
  > Type: Unit Test
  > Assert: Filters work for questions, unresolved, action-items
  > Command: bundle exec rake test test/molecules/test_comment_synthesis_generator.rb::test_apply_filters

- [ ] Implement GitHub comment formatting in `comment_synthesis_generator.rb`
  > TEST: GitHub Format
  > Type: Unit Test
  > Assert: Format suitable for posting (proper markdown, links, header)
  > Command: bundle exec rake test test/molecules/test_comment_synthesis_generator.rb::test_github_format

- [ ] Create `lib/ace/review/organisms/comment_analysis_manager.rb` with workflow
  > TEST: Analysis Workflow
  > Type: Integration Test
  > Assert: Orchestrates fetch → analyze → synthesize → save
  > Command: bundle exec rake test test/organisms/test_comment_analysis_manager.rb::test_analyze_workflow

- [ ] Implement session directory creation in `comment_analysis_manager.rb`
  > TEST: Session Directory
  > Type: Integration Test
  > Assert: Creates `.cache/ace-review/sessions/comment-analysis-{timestamp}/`
  > Command: bundle exec rake test test/organisms/test_comment_analysis_manager.rb::test_session_creation

- [ ] Implement comment posting integration in `comment_analysis_manager.rb`
  > TEST: Comment Posting
  > Type: Integration Test
  > Assert: Uses gh_comment_poster from Task 116 to post synthesis
  > Command: bundle exec rake test test/organisms/test_comment_analysis_manager.rb::test_post_synthesis

- [ ] Create `lib/ace/review/models/comment_analysis_options.rb` with options model
  > TEST: Options Model
  > Type: Unit Test
  > Assert: Validates filter values, pr_identifier, post_comment flag
  > Command: bundle exec rake test test/models/test_comment_analysis_options.rb

- [ ] Modify `lib/ace/review/cli.rb` to add `--pr-comments` option
  > TEST: CLI Option Parsing
  > Type: Integration Test
  > Assert: CLI accepts `--pr-comments 123` and routes to comment analysis
  > Command: bundle exec exe/ace-review --help | grep -- "--pr-comments"

- [ ] Add `--filter` option to `cli.rb`
  > TEST: Filter Option
  > Type: Integration Test
  > Assert: CLI accepts `--filter questions` and passes to analysis
  > Command: bundle exec exe/ace-review --help | grep -- "--filter"

- [ ] Implement comment analysis mode routing in `cli.rb`
  > TEST: Mode Routing
  > Type: Integration Test
  > Assert: `--pr-comments` routes to comment_analysis_manager not review_manager
  > Command: bundle exec rake test test/cli/test_cli_routing.rb::test_comment_mode

- [ ] Add comment analysis error classes to `lib/ace/review/errors.rb`
  > TEST: Error Classes
  > Type: Unit Test
  > Assert: NoCommentsFoundError, CommentFetchError, CommentAnalysisError defined
  > Command: bundle exec ruby -r ./lib/ace/review -e "puts Ace::Review::NoCommentsFoundError.new.message"

- [ ] Update `lib/ace/review.rb` with new file requires
  > TEST: Module Loading
  > Type: Integration Test
  > Assert: All comment analysis modules load without errors
  > Command: bundle exec ruby -r ./lib/ace/review -e "puts Ace::Review::VERSION"

- [ ] Create unit tests for `gh_comment_fetcher.rb`
  > TEST: Comment Fetcher Coverage
  > Type: Test Validation
  > Assert: Tests cover fetching, threading, filtering, pagination
  > Command: bundle exec rake test test/molecules/test_gh_comment_fetcher.rb

- [ ] Create unit tests for `comment_thread_analyzer.rb`
  > TEST: Analyzer Coverage
  > Type: Test Validation
  > Assert: Tests cover question detection, reply matching, reactions
  > Command: bundle exec rake test test/molecules/test_comment_thread_analyzer.rb

- [ ] Create unit tests for `comment_synthesis_generator.rb`
  > TEST: Generator Coverage
  > Type: Test Validation
  > Assert: Tests cover formatting, filtering, GitHub output
  > Command: bundle exec rake test test/molecules/test_comment_synthesis_generator.rb

- [ ] Create integration tests for `comment_analysis_manager.rb`
  > TEST: Manager Coverage
  > Type: Test Validation
  > Assert: Tests cover workflow, session management, posting
  > Command: bundle exec rake test test/organisms/test_comment_analysis_manager.rb

- [ ] Create end-to-end PR comment analysis tests
  > TEST: E2E Workflow
  > Type: Integration Test
  > Assert: Complete workflows (basic, filtered, posting, dry-run) pass
  > Command: bundle exec rake test test/integration/test_pr_comment_workflow.rb

- [ ] Update README.md with PR comment analysis documentation
  > TEST: Documentation Completeness
  > Type: Manual Review
  > Assert: README includes comment analysis usage, filters, examples
  > Command: grep -A 10 "PR Comment Analysis" README.md

- [ ] Run full test suite to verify no regressions
  > TEST: Full Test Suite
  > Type: Regression Test
  > Assert: All existing tests pass, no functionality broken
  > Command: bundle exec rake test

- [ ] Test manual workflow with real GitHub PR comments
  > TEST: Real-World Validation
  > Type: Manual Test
  > Assert: Can analyze actual PR comments, post synthesis
  > Command: bundle exec exe/ace-review --pr-comments <test-pr> --dry-run

## Risk Assessment

### Technical Risks

- **Risk**: Comment thread structure complexity (nested replies, deleted comments, edited comments)
  - **Probability**: Medium
  - **Impact**: Medium (analysis quality degradation)
  - **Mitigation**: Robust JSON parsing with error handling, graceful degradation for malformed threads
  - **Rollback**: Feature is additive; users can still use code review mode

- **Risk**: LLM accuracy in question/action detection
  - **Probability**: Medium
  - **Impact**: Medium (false positives/negatives in synthesis)
  - **Mitigation**: Iterative prompt engineering, user testing with diverse comment patterns, manual review via dry-run
  - **Monitoring**: Track user feedback on synthesis quality

- **Risk**: Large comment threads exceeding LLM context limits
  - **Probability**: Low-Medium (PRs with >500 comments rare but exist)
  - **Impact**: High (analysis failure or truncation)
  - **Mitigation**: Detect thread size, warn user, implement chunking strategy or summary-of-summaries approach
  - **Rollback**: Error with clear guidance on manual comment review

- **Risk**: GitHub API rate limiting for comment-heavy workflows
  - **Probability**: Low
  - **Impact**: Medium (temporary service disruption)
  - **Mitigation**: Reuse rate limit detection from Task 116, cache comment data in session
  - **Rollback**: N/A (GitHub API limitation)

### Integration Risks

- **Risk**: Task 116 gh CLI foundation not yet implemented
  - **Probability**: N/A (dependency enforced)
  - **Impact**: High (feature cannot be built)
  - **Mitigation**: Task dependency explicitly defined, Task 116 must complete first
  - **Monitoring**: Verify Task 116 completion before starting Task 115

- **Risk**: Conversation prompt design inadequacy
  - **Probability**: Medium (prompt engineering is iterative)
  - **Impact**: Medium (poor analysis quality)
  - **Mitigation**: Store prompt in `.ace/prompts/` for easy customization, provide examples in documentation
  - **Monitoring**: User feedback on analysis quality, A/B test prompt variations

- **Risk**: Confusion between code review and comment analysis modes
  - **Probability**: Low
  - **Impact**: Low (user experience issue)
  - **Mitigation**: Clear CLI flag naming (`--pr` vs `--pr-comments`), distinct help text, different session naming
  - **Monitoring**: Documentation clarity review

### Performance Risks

- **Risk**: Comment fetching latency for large PRs
  - **Mitigation**: Single `gh pr view --json` call for efficiency, caching in session
  - **Monitoring**: Log fetch time in verbose mode
  - **Thresholds**: Warn if fetch >10s, timeout at 30s

- **Risk**: LLM analysis latency for long threads
  - **Mitigation**: User expectation management (analysis takes time), progress indicators
  - **Monitoring**: Track analysis time by comment count
  - **Thresholds**: Typical analysis 5-30s, warn if >60s

### Security Risks

- **Risk**: Sensitive information in comment synthesis posted publicly
  - **Probability**: Low (LLM-dependent)
  - **Impact**: Medium (information disclosure)
  - **Mitigation**: Dry-run mode mandatory for first use (documentation), user review before posting
  - **Rollback**: Delete posted comment via GitHub UI

- **Risk**: Command injection via malicious PR identifiers (inherited from Task 116)
  - **Mitigation**: Task 116 implements input validation and array-form subprocess args
  - **Monitoring**: Input validation tests from Task 116

## Validation Questions Decisions

### System Prompt Design
**Decision**: Focus on all three - summarization, action extraction, AND conflict identification
- Comprehensive analysis provides most value
- Users can filter post-analysis to specific needs
- Prompt complexity manageable with clear structure

### Thread Grouping
**Decision**: Chronological ordering with author context and reply chains preserved
- Chronological reflects discussion flow
- Reply chains essential for resolution detection
- Author context critical for attribution

### Output Location
**Decision**: Create new PR comment on each analysis
- Simplest implementation
- Avoids complexity of comment update detection
- Users can delete old analyses manually if desired
- Clear audit trail of analysis iterations

### Filter Granularity
**Decision**: Support questions, action-items, unresolved, all (by-author deferred)
- Covers primary use cases (finding blockers, tracking TODOs)
- Post-analysis filtering flexible and efficient
- By-author filtering lower priority, can add later

### Comment Metadata
**Decision**: Track author, timestamp, reaction counts; author roles and resolution timestamps deferred
- Core metadata sufficient for quality synthesis
- Role detection adds API complexity (maintainer/contributor)
- Can enhance incrementally based on user feedback

### Update Behavior
**Decision**: Always create new synthesis comment
- Simpler than update detection logic
- Preserves analysis history
- Users control deletion manually

### Thread Resolution Detection
**Decision**: Multi-signal approach - reactions (👍), follow-up comments, time decay
- No single reliable marker exists
- Reaction count + reply presence = strong signal
- Prompt engineering to detect resolution language ("sounds good", "LGTM")

### Integration with Diff Review
**Decision**: Keep separate - no combined `--pr 123 --include-comments` for MVP
- Different analysis goals (code quality vs discussion tracking)
- Allows specialized prompts for each mode
- Can add combined mode later if user demand exists
