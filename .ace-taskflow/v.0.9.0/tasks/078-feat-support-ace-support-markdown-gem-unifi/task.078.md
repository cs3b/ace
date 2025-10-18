---
id: v.0.9.0+task.078
status: pending
priority: high
estimate: 3-4 weeks
dependencies: []
---

# Create ace-support-markdown gem for unified markdown editing

## Behavioral Specification

### User Experience
- **Input**: Developers (human or AI) need to safely edit markdown files with frontmatter and structured sections
- **Process**: Use a unified API to atomically update frontmatter fields or specific sections without corrupting the document
- **Output**: Markdown files are modified safely with validation, backup, and rollback capabilities

### Expected Behavior

Developers can perform surgical edits on markdown documents without risk of corruption or data loss. The system treats markdown as structured data rather than plain text, enabling targeted modifications to:

- **Frontmatter fields**: Update YAML metadata atomically (e.g., change `status: draft` to `status: done`)
- **Document sections**: Replace, append, or delete content under specific headings
- **Complete documents**: Build new documents programmatically with validation

All operations include:
- **Validation**: Parse before write, verify after write
- **Safety**: Automatic backup before modification
- **Atomicity**: Changes succeed completely or fail completely (no partial edits)
- **Rollback**: Restore from backup on any error

**Current Problem**: ACE gems have scattered implementations (ace-docs FrontmatterManager, ace-taskflow DoctorFixer) that use direct `File.write` calls, leading to corruption when regex replacements go wrong (as demonstrated by task 076 corruption).

**Solution**: Centralized markdown editing gem using Kramdown AST for reliable parsing and surgical section editing.

### Interface Contract

```ruby
# Frontmatter Operations
editor = Ace::Support::Markdown::DocumentEditor.new("task.md")
editor.update_frontmatter({"status" => "done"})
result = editor.save!(backup: true, validate: true)
# Returns: { success: Boolean, backup_path: String, errors: Array }

# Section Operations
editor.replace_section("## References", new_content)
editor.append_to_section("## Acceptance Criteria", "- [ ] New criterion")
editor.delete_section("## Implementation Notes")
editor.save!

# Validation
validation = editor.validate
if validation[:errors].any?
  editor.rollback  # Restore from backup
end

# Safe File Writing
Ace::Support::Markdown::SafeFileWriter.write_with_safety(
  "task.md",
  content,
  backup: true,
  validate: true,
  validator: ->(content) { validate_task_frontmatter(content) }
)

# Document Building
builder = Ace::Support::Markdown::DocumentBuilder.new
builder.frontmatter({"id" => "task.078", "status" => "draft"})
builder.add_section(heading: "# Title", content: "Description")
builder.to_markdown
```

**Error Handling:**
- Invalid frontmatter: Clear YAML syntax error messages
- Missing sections: Returns nil or raises specific SectionNotFoundError
- File write failures: Automatic rollback to backup
- Validation failures: Prevents write, returns detailed error info

**Edge Cases:**
- Concurrent edits: Atomic write using temp file + move
- Large files: Efficient AST-based parsing
- Malformed markdown: Graceful degradation with error reporting
- Backup cleanup: Configurable retention policy

### Success Criteria

- [ ] **Zero Corruption**: No markdown file corruption after migration from current implementations
- [ ] **API Coverage**: Supports frontmatter update, section edit, document build, safe write
- [ ] **Validation**: Pre-write parsing, post-write verification, rollback on error
- [ ] **Performance**: <10ms for typical frontmatter updates, <50ms for section edits
- [ ] **Migration Complete**: ace-taskflow and ace-docs migrated to use new API
- [ ] **Test Coverage**: 100% coverage for atoms, 95%+ for molecules/organisms
- [ ] **Kramdown Integration**: Uses Kramdown AST for all parsing operations

### Validation Questions

- [ ] **Kramdown vs. Alternatives**: Should we use Kramdown (pure Ruby, GFM support) or evaluate CommonMarker (faster, C-based)?
- [ ] **Section Matching**: Support exact string (`"## References"`), regex (`/^##\s+Ref/`), or level+index (`{level: 2, index: 3}`)?
- [ ] **Validation Schemas**: Should we support JSON Schema validation for frontmatter (optional per-document-type schemas)?
- [ ] **Backward Compatibility**: Keep existing FrontmatterManager/DoctorFixer APIs as deprecated wrappers during transition?

## Objective

Create a centralized, safe markdown editing gem that eliminates code duplication, prevents file corruption, and provides a unified API for all markdown operations across ACE gems. This addresses the immediate corruption risk (task 076) and establishes a foundation for reliable document management.

## Scope of Work

- **User Experience Scope**:
  - Safe frontmatter field updates without corruption risk
  - Section-based content editing by heading
  - Programmatic document generation from scratch
  - Validation and rollback capabilities

- **System Behavior Scope**:
  - Parse markdown with frontmatter using Kramdown AST
  - Extract and modify YAML frontmatter atomically
  - Navigate and edit document sections by heading
  - Backup before write, rollback on failure
  - Validate before and after all modifications

- **Interface Scope**:
  - DocumentEditor fluent API for chained operations
  - SafeFileWriter for atomic file operations
  - DocumentBuilder for programmatic generation
  - FrontmatterEditor for YAML operations
  - SectionEditor for heading-based edits

### Deliverables

#### Behavioral Specifications
- Frontmatter update workflows (get, set, delete fields)
- Section editing workflows (replace, append, delete by heading)
- Document building workflows (from scratch or template)
- Safe file writing workflows (backup, validate, rollback)

#### Validation Artifacts
- Frontmatter validation (YAML syntax, required fields)
- Section extraction validation (heading detection, content boundaries)
- File safety validation (backup exists, restore works)
- Performance benchmarks (<10ms frontmatter, <50ms section edit)

## Out of Scope

- ❌ **Markdown Rendering**: HTML/PDF generation (use kramdown directly)
- ❌ **Version Control**: Git integration beyond file writing
- ❌ **Concurrent Editing**: Multi-user simultaneous edit resolution
- ❌ **UI/Web Interface**: CLI and API only, no web editor
- ❌ **Legacy dev-handbook**: Skip migrating legacy dev-handbook code

## References

- **Root Cause**: Task 076 corruption - `tasks/done/076-feat-context-preset-composition-support-ace/task.076.md` reduced from 337 lines to 3 lines during frontmatter edit
- **Current Implementations**:
  - `ace-docs/lib/ace/docs/molecules/frontmatter_manager.rb` - Frontmatter updates
  - `ace-docs/lib/ace/docs/atoms/frontmatter_parser.rb` - YAML parsing
  - `ace-taskflow/lib/ace/taskflow/molecules/doctor_fixer.rb` - `rebuild_content_with_frontmatter`
  - `ace-lint/lib/ace/lint/atoms/kramdown_parser.rb` - Kramdown AST parsing
- **Existing Dependencies**: kramdown ~> 2.4, kramdown-parser-gfm ~> 1.1 (used in ace-lint, ace-llm)
- **Integration Points**: ace-taskflow (task/idea files), ace-docs (all docs), ace-context (presets), .ace-taskflow (all task management)
## Technical Approach

### Architecture Pattern
- **ATOM Architecture**: Follow established ACE pattern with Atoms (pure functions), Molecules (composed operations), Organisms (orchestration), Models (data structures)
- **Integration Strategy**: New gem at repository root alongside other ace-* gems
- **Zero-Dependency Core**: Use only Ruby stdlib and Kramdown (mirrors ace-core philosophy)
- **Immutable Operations**: DocumentEditor operations return new state, don't mutate in place

**Rationale**: ATOM architecture proven across 15+ ACE gems, provides testability and maintainability. Kramdown provides reliable GFM-compatible AST parsing.

### Technology Stack
- **Parser**: Kramdown ~> 2.4 with kramdown-parser-gfm ~> 1.1 (already used in ace-lint, ace-llm)
- **YAML**: Ruby Psych (stdlib) for frontmatter parsing
- **File I/O**: Ruby File/FileUtils (stdlib) with atomic write pattern
- **Testing**: ace-test-support for test infrastructure, minitest for assertions

**Version Requirements**:
- Ruby >= 2.7 (ACE standard)
- kramdown ~> 2.4 (stable, GFM support)
- kramdown-parser-gfm ~> 1.1 (GitHub Flavored Markdown)

**Performance Considerations**:
- Kramdown AST parsing: ~5-10ms for typical task files
- YAML parsing: <1ms for typical frontmatter
- File I/O: Atomic write adds ~2-3ms overhead
- Target: <10ms total for frontmatter updates

### Implementation Strategy
1. **Phase 1: Core Foundation** - Atoms and basic parsing
2. **Phase 2: Editing Operations** - Molecules for frontmatter/section editing
3. **Phase 3: Safe File Operations** - Organisms with backup/rollback
4. **Phase 4: Migration** - Replace existing implementations in ace-taskflow and ace-docs

## File Modifications

### Create

**Gem Structure:**
- `ace-support-markdown/` (root directory)
  - Purpose: New gem for unified markdown editing
  - Key components: ATOM-structured library, tests, examples

**Library Files (Atoms):**
- `ace-support-markdown/lib/ace/support/markdown/atoms/frontmatter_extractor.rb`
  - Purpose: Extract YAML frontmatter from markdown content
  - Key components: Delimiter detection, YAML parsing, body extraction
- `ace-support-markdown/lib/ace/support/markdown/atoms/section_extractor.rb`
  - Purpose: Extract sections from Kramdown AST by heading
  - Key components: AST traversal, heading detection, content extraction
- `ace-support-markdown/lib/ace/support/markdown/atoms/frontmatter_serializer.rb`
  - Purpose: Serialize frontmatter hash to YAML format
  - Key components: YAML formatting, delimiter wrapping
- `ace-support-markdown/lib/ace/support/markdown/atoms/document_validator.rb`
  - Purpose: Validate markdown structure and frontmatter
  - Key components: YAML validation, structure checks, schema validation (optional)

**Library Files (Molecules):**
- `ace-support-markdown/lib/ace/support/markdown/molecules/frontmatter_editor.rb`
  - Purpose: Update frontmatter fields atomically
  - Key components: Field updates, nested key handling, value processing
- `ace-support-markdown/lib/ace/support/markdown/molecules/section_editor.rb`
  - Purpose: Edit document sections by heading
  - Key components: Section replacement, append, delete operations
- `ace-support-markdown/lib/ace/support/markdown/molecules/kramdown_processor.rb`
  - Purpose: Parse/serialize markdown via Kramdown
  - Key components: AST parsing, GFM configuration, markdown generation
- `ace-support-markdown/lib/ace/support/markdown/molecules/document_builder.rb`
  - Purpose: Build markdown documents programmatically
  - Key components: Frontmatter assembly, section composition, validation

**Library Files (Organisms):**
- `ace-support-markdown/lib/ace/support/markdown/organisms/document_editor.rb`
  - Purpose: Main API for document editing with fluent interface
  - Key components: Operation chaining, state management, save/rollback
- `ace-support-markdown/lib/ace/support/markdown/organisms/safe_file_writer.rb`
  - Purpose: Safe file writing with backup and validation
  - Key components: Backup creation, atomic write, rollback, cleanup

**Library Files (Models):**
- `ace-support-markdown/lib/ace/support/markdown/models/markdown_document.rb`
  - Purpose: Immutable document representation
  - Key components: Frontmatter storage, sections storage, transformation methods
- `ace-support-markdown/lib/ace/support/markdown/models/section.rb`
  - Purpose: Immutable section representation
  - Key components: Heading, level, content, metadata

**Test Files:**
- `ace-support-markdown/test/atoms/*_test.rb` - Unit tests for pure functions
- `ace-support-markdown/test/molecules/*_test.rb` - Integration tests for operations
- `ace-support-markdown/test/organisms/*_test.rb` - End-to-end tests
- `ace-support-markdown/test/integration/*_test.rb` - Full workflow tests

**Configuration Files:**
- `ace-support-markdown/.ace.example/markdown/config.yml` - Example configuration
- `ace-support-markdown/ace-support-markdown.gemspec` - Gem specification
- `ace-support-markdown/Gemfile` - Development dependencies
- `ace-support-markdown/Rakefile` - Test tasks
- `ace-support-markdown/README.md` - Usage documentation
- `ace-support-markdown/CHANGELOG.md` - Version history

### Modify

**ace-taskflow:**
- `ace-taskflow/lib/ace/taskflow/molecules/doctor_fixer.rb`
  - Changes: Replace `rebuild_content_with_frontmatter` with ace-support-markdown API
  - Impact: Safer task file updates, eliminates corruption risk
  - Integration points: Use DocumentEditor for status updates

- `ace-taskflow/lib/ace/taskflow/organisms/task_manager.rb`
  - Changes: Replace direct `File.write` with SafeFileWriter
  - Impact: Validated task file creation
  - Integration points: Use DocumentBuilder for new tasks

- `ace-taskflow/lib/ace/taskflow/organisms/idea_writer.rb`
  - Changes: Replace direct `File.write` with SafeFileWriter
  - Impact: Validated idea file creation
  - Integration points: Use DocumentBuilder for new ideas

- `ace-taskflow/ace-taskflow.gemspec`
  - Changes: Add dependency `ace-support-markdown ~> 0.1`
  - Impact: Gem dependency management

**ace-docs:**
- `ace-docs/lib/ace/docs/molecules/frontmatter_manager.rb`
  - Changes: Replace implementation with ace-support-markdown FrontmatterEditor
  - Impact: Consolidate duplicate code, safer updates
  - Integration points: Delegate to DocumentEditor

- `ace-docs/lib/ace/docs/atoms/frontmatter_parser.rb`
  - Changes: Deprecate in favor of ace-support-markdown FrontmatterExtractor
  - Impact: Eliminate duplication
  - Migration strategy: Keep wrapper for backward compatibility initially

- `ace-docs/ace-docs.gemspec`
  - Changes: Add dependency `ace-support-markdown ~> 0.1`
  - Impact: Gem dependency management

### Delete

*None - will deprecate rather than delete for backward compatibility*

## Implementation Plan

### Planning Steps

* [ ] Research Kramdown AST traversal patterns for section extraction
  - Understand `Kramdown::Element` structure for headings
  - Identify how to extract content between headings
  - Determine efficient AST navigation strategies

* [ ] Analyze existing frontmatter implementations for consolidation opportunities
  - Compare ace-docs FrontmatterParser vs ace-taskflow patterns
  - Identify common operations and edge cases
  - Document backward compatibility requirements

* [ ] Design section matching API (exact string vs regex vs level+index)
  - Prototype different matching strategies
  - Evaluate usability and flexibility trade-offs
  - Decide on initial implementation (can add others later)

### Execution Steps

- [ ] Step 1: Create gem skeleton with ATOM structure
  ```bash
  mkdir -p ace-support-markdown/{lib/ace/support/markdown/{atoms,molecules,organisms,models},test/{atoms,molecules,organisms,integration}}
  ```
  > TEST: Directory Structure Verification
  > Type: Setup Validation
  > Assert: All ATOM directories exist with correct structure
  > Command: ls -la ace-support-markdown/lib/ace/support/markdown/

- [ ] Step 2: Implement Atoms (pure functions)
  - Create FrontmatterExtractor with YAML parsing
  - Create SectionExtractor with Kramdown AST traversal
  - Create FrontmatterSerializer with delimiter formatting
  - Create DocumentValidator with schema support
  > TEST: Atom Unit Tests
  > Type: Unit Test Suite
  > Assert: All atom tests pass with 100% coverage
  > Command: cd ace-support-markdown && bundle exec rake test TEST=test/atoms/

- [ ] Step 3: Implement Molecules (composed operations)
  - Create FrontmatterEditor with atomic field updates
  - Create SectionEditor with replace/append/delete
  - Create KramdownProcessor with GFM configuration
  - Create DocumentBuilder with programmatic generation
  > TEST: Molecule Integration Tests
  > Type: Integration Test Suite
  > Assert: All molecule tests pass, operations compose correctly
  > Command: cd ace-support-markdown && bundle exec rake test TEST=test/molecules/

- [ ] Step 4: Implement Organisms (orchestration)
  - Create DocumentEditor with fluent API and state management
  - Create SafeFileWriter with backup/rollback/atomic write
  - Add validation hooks and error handling
  > TEST: Organism End-to-End Tests
  > Type: End-to-End Test Suite
  > Assert: Full workflows work, backup/rollback functional
  > Command: cd ace-support-markdown && bundle exec rake test TEST=test/organisms/

- [ ] Step 5: Implement Models (data structures)
  - Create MarkdownDocument with immutable operations
  - Create Section with metadata support
  - Add serialization methods
  > TEST: Model Behavior Tests
  > Type: Unit Test Suite
  > Assert: Models immutable, transformations work correctly
  > Command: cd ace-support-markdown && bundle exec rake test TEST=test/models/

- [ ] Step 6: Create comprehensive integration tests
  - Test real task file editing scenarios
  - Test backup and rollback workflows
  - Test error handling and validation
  - Test performance benchmarks (<10ms frontmatter, <50ms sections)
  > TEST: Full Integration Test Suite
  > Type: Integration Test Suite
  > Assert: All real-world scenarios pass, performance targets met
  > Command: cd ace-support-markdown && bundle exec rake test TEST=test/integration/

- [ ] Step 7: Document API and create examples
  - Write README with usage examples
  - Create .ace.example/ configuration samples
  - Document migration guide from existing implementations
  > TEST: Documentation Examples Validation
  > Type: Manual Validation
  > Assert: All README examples execute successfully
  > Command: # Manually run examples from README

- [ ] Step 8: Migrate ace-taskflow to use new API
  - Update DoctorFixer to use DocumentEditor
  - Update TaskManager to use SafeFileWriter
  - Update IdeaWriter to use DocumentBuilder
  - Add ace-support-markdown dependency
  > TEST: ace-taskflow Test Suite
  > Type: Regression Test Suite
  > Assert: All ace-taskflow tests still pass after migration
  > Command: cd ace-taskflow && bundle exec rake test

- [ ] Step 9: Migrate ace-docs to use new API
  - Update FrontmatterManager to delegate to new gem
  - Deprecate FrontmatterParser with compatibility wrapper
  - Add ace-support-markdown dependency
  > TEST: ace-docs Test Suite
  > Type: Regression Test Suite
  > Assert: All ace-docs tests still pass after migration
  > Command: cd ace-docs && bundle exec rake test

- [ ] Step 10: Update root Gemfile and publish gem
  - Add ace-support-markdown to workspace Gemfile
  - Verify all gems can access new dependency
  - Publish v0.1.0 with initial functionality
  > TEST: Workspace Integration
  > Type: Integration Test
  > Assert: All gems resolve dependencies correctly
  > Command: bundle install && bundle exec rake test:all

## Risk Assessment

### Technical Risks

- **Risk:** Kramdown AST complexity leads to incorrect section extraction
  - **Probability:** Medium
  - **Impact:** High (incorrect edits = data loss)
  - **Mitigation:** Comprehensive test suite with edge cases, validate round-trip parsing
  - **Rollback:** Use backup files, extensive testing before migration

- **Risk:** Performance degradation with large markdown files
  - **Probability:** Low
  - **Impact:** Medium (slower operations)
  - **Mitigation:** Profile with real ACE task files, optimize hot paths
  - **Monitoring:** Add benchmarks in CI, set performance thresholds (<50ms for sections)

- **Risk:** Backward compatibility breaks existing workflows
  - **Probability:** Medium
  - **Impact:** High (breaks ace-taskflow, ace-docs)
  - **Mitigation:** Keep deprecated wrappers, extensive regression testing
  - **Rollback:** Maintain existing implementations until migration proven stable

### Integration Risks

- **Risk:** Dependency version conflicts with existing Kramdown usage
  - **Probability:** Low
  - **Impact:** Medium (build failures)
  - **Mitigation:** Use version ranges compatible with ace-lint/ace-llm (~> 2.4)
  - **Monitoring:** CI build checks across all gems

- **Risk:** Migration incomplete, some gems still use unsafe File.write
  - **Probability:** Medium
  - **Impact:** Medium (partial improvement only)
  - **Mitigation:** Grep for all File.write calls, track migration progress
  - **Monitoring:** Create migration checklist, verify completion

## Test Planning

### Unit Tests (Atoms)
- **Frontmatter extraction**: Valid YAML, missing delimiters, malformed YAML
- **Section extraction**: Single heading, nested headings, no headings, duplicate headings
- **Serialization**: Round-trip parsing, special characters, nested structures
- **Validation**: Required fields, invalid YAML, schema violations

### Integration Tests (Molecules)
- **Frontmatter editing**: Update existing, add new fields, delete fields, nested keys
- **Section editing**: Replace by exact match, append content, delete sections, missing sections
- **Document building**: From scratch, with sections, with frontmatter, validation

### End-to-End Tests (Organisms)
- **DocumentEditor**: Chained operations, save with backup, rollback on error, validation
- **SafeFileWriter**: Atomic write, backup creation, rollback mechanics, concurrent access

### Migration Tests
- **ace-taskflow**: Task status updates, task creation, idea file generation
- **ace-docs**: Document frontmatter updates, section modifications

### Performance Tests
- **Frontmatter updates**: <10ms for typical task files
- **Section edits**: <50ms for typical documents
- **Large files**: <200ms for 10,000 line markdown files

## Acceptance Criteria

- [ ] All ATOM layers implemented (atoms, molecules, organisms, models)
- [ ] Kramdown AST-based section extraction working
- [ ] Frontmatter updates atomic and safe
- [ ] Backup/rollback mechanism functional
- [ ] 100% test coverage for atoms
- [ ] 95%+ test coverage for molecules and organisms
- [ ] Performance benchmarks met (<10ms frontmatter, <50ms sections)
- [ ] ace-taskflow migrated and tests passing
- [ ] ace-docs migrated and tests passing
- [ ] No markdown corruption in any test scenario
- [ ] README with complete API documentation
- [ ] CHANGELOG.md with v0.1.0 release notes

