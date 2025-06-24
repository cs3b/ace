---
id: v.0.2.0+task.60
status: done
priority: low
estimate: 2h
dependencies: ["v.0.2.0+task.57"]
---

# Standardize Client Filename Conventions to Eliminate Hardcoded Mappings

## Objective / Problem

The current client files use inconsistent naming conventions that require hardcoded class name mappings in the dynamic loading logic. Files like `lm_studio_client.rb` → `LMStudioClient` and `openai_client.rb` → `OpenAIClient` break the simple capitalization pattern, forcing us to maintain a hardcoded mapping in `ProviderModelParser#filename_to_class_name`.

This creates maintenance overhead and violates the DRY principle. We should standardize the filename conventions to follow predictable patterns that can be transformed algorithmically.

## Directory Audit

Current client files with problematic naming:
- `lm_studio_client.rb` → `LMStudioClient` (should be `lmstudio_client.rb` → `LmstudioClient`)
- `openai_client.rb` → `OpenAIClient` (should be `openai_client.rb` → `OpenaiClient`)
- `together_ai_client.rb` → `TogetherAIClient` (should be `togetherai_client.rb` → `TogetheraiClient`)

## Scope of Work

- Rename client files to follow consistent snake_case conventions
- Update corresponding class names to match algorithmic transformation
- Update all imports and references throughout the codebase
- Remove hardcoded mapping logic from `ProviderModelParser`
- Update tests to use new class names

## Deliverables / Manifest

| File | Action | Purpose |
|------|--------|---------|
| `lib/coding_agent_tools/organisms/lm_studio_client.rb` | Rename → `lmstudio_client.rb` | Consistent naming |
| `lib/coding_agent_tools/organisms/openai_client.rb` | Rename → `openai_client.rb` | Already correct |
| `lib/coding_agent_tools/organisms/together_ai_client.rb` | Rename → `togetherai_client.rb` | Consistent naming |
| Class names in renamed files | Modify | Update to match new conventions |
| `lib/coding_agent_tools/molecules/provider_model_parser.rb` | Modify | Remove hardcoded mapping |
| All spec files | Modify | Update class references |
| All require statements | Modify | Update file paths |

## Phases

1. **Analysis** - Identify all files and references that need updating
2. **Rename** - Rename files and update class names
3. **Update References** - Update all imports, requires, and test references
4. **Simplify Logic** - Remove hardcoded mapping from parser

## Implementation Plan

### Planning Steps
* [x] Create comprehensive list of all files that reference the affected classes
* [x] Plan the new naming conventions and class names
* [x] Identify all test files that need updating
* [x] Plan the order of operations to avoid breaking changes

### Execution Steps
- [x] Rename files and update class names:
  - `lm_studio_client.rb` → `lmstudio_client.rb` (LMStudioClient → LmstudioClient)
  - `together_ai_client.rb` → `togetherai_client.rb` (TogetherAIClient → TogetheraiClient)
  - Keep `openai_client.rb` as is, but update class to `OpenaiClient`
- [x] Update all require statements and file references
- [x] Update all test files to use new class names
- [x] Update provider_name methods in client classes if needed
- [x] Remove hardcoded mapping from ProviderModelParser:
  ```ruby
  def filename_to_class_name(filename)
    # Simple algorithmic transformation - no special cases needed
    filename.split('_').map(&:capitalize).join
  end
  ```
- [x] Run all tests to ensure no regressions
- [x] Update any documentation that references the old class names

## Acceptance Criteria

- [x] All client files follow consistent snake_case naming without acronyms
- [x] Class names can be derived algorithmically from filenames
- [x] No hardcoded mapping exists in ProviderModelParser
- [x] All tests pass with new naming conventions
- [x] All require statements and references updated
- [x] Provider functionality remains unchanged

## Out of Scope

- Changing the provider names returned by provider_name methods
- Modifying the external API or CLI interface
- Changing the BaseClient hierarchy
- Updating provider configuration or constants

## References & Risks

- Task 57: [Refactor ClientFactory to Use Dynamic Client Loading](v.0.2.0+task.57-refactor-client-factory-dynamic-loading.md)
- Risk: Breaking changes to existing code that references these classes directly
- Risk: Test failures if we miss updating references
- Mitigation: Comprehensive search and systematic updates

## Notes

This task eliminates the temporary hardcoded solution implemented in Task 57 and provides a long-term maintainable approach to dynamic client loading. After completion, adding new providers will require no changes to the loading logic.