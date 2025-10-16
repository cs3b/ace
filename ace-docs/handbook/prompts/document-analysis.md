# Document Analysis

Analyze the following code changes to determine what needs to be updated in project documentation.

## Document Information

**Path**: {document_path}
**Type**: {document_type}
**Purpose**: {document_purpose}
**Context Keywords**: {context_keywords}
**Context Preset**: {context_preset}

## Target Documents

The following documents should be checked for impacts from these changes:

{target_documents_list}

## Document Anchors

Below is the section structure for each target document. Use these **exact anchors** when proposing updates.

{anchors_map}

## Diff Statistics

- **Total hunks**: {hunks_total}
- **Files changed**: {files_changed}
- **Insertions**: +{insertions}
- **Deletions**: -{deletions}

## Changes to Analyze

The following git diff shows changes {time_period}.

{subject_filters_note}

```diff
{diff_content}
```

## Analysis Acceptance Criteria

**Required for valid analysis:**
- Do NOT claim "all changes mapped successfully" unless: `hunks_mapped + hunks_ambiguous == hunks_total`
- Every Recommended Update MUST include Evidence column with file:line or file::hunk_header
- Every section reference MUST use exact anchors from the Anchors Map above
- Report MUST check ALL target documents listed above, not just the primary document
- Identify cross-document impacts (usage guides, workflows, CI examples)
- Flag schema/namespace inconsistencies if configuration examples appear in diff
- Recommend test/development documentation updates if test files or dependencies change
