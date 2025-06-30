---
id: v.0.1.0+task.1 # Example ID, replace with actual generated ID
status: pending
priority: high
estimate: 8 h
dependencies: []
---

# Refactor Developer Guides by Language (Ruby, Rust, TypeScript)

## 0. Directory Audit ✅

_Command run 2025‑04‑24:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
```

_Result excerpt (irrelevant folders omitted):_

```
guides
├── coding-standards.md
├── documentation.md
├── error-handling.md
├── performance.md
├── quality-assurance.md
├── security.md
├── publish-release.md
├── testing.md
├── version-control.md
└── ...
```

🔍 **General guides requiring language splits:**  
`coding-standards.md`, `documentation.md`, `error-handling.md`, `performance.md`,  
`quality-assurance.md`, `security.md`, `publish-release.md`, `testing.md`,  
`version-control.md`

---

## Objective

Split language‑specific snippets out of _every_ general guide so developers can jump straight to the rules for their stack.

## Scope of Work

1. **Audit** each general guide above.  
2. **Extract** Ruby, Rust, and TypeScript blocks into per‑language sub‑guides.  
   - _Testing_ uses `ruby-rspec.md` & `typescript-bun.md`.  
3. **Clean** general guides so only polyglot advice remains.  
4. **Index** – add links for all new files to `dev-handbook/guides/README.md` (or create `index.md`).  
5. **Review** – run `md-link-check`; ensure docs build passes.

### Deliverables

| General guide | Sub‑directory → files to **create / update**                |
|---------------|-------------------------------------------------------------|
| coding-standards.md | coding-standards/ruby.md · rust.md · typescript.md |
| documentation.md    | documentation/ruby.md · rust.md · typescript.md |
| error-handling.md   | error-handling/ruby.md · rust.md · typescript.md |
| performance.md      | performance/ruby.md · rust.md · typescript.md |
| quality-assurance.md| quality-assurance/ruby.md · rust.md · typescript.md |
| security.md         | security/ruby.md · rust.md · typescript.md |
| publish-release.md  | publish-release/ruby.md · rust.md · typescript.md |
| testing.md          | testing/ruby-rspec.md · rust.md · typescript-bun.md |
| version-control.md  | version-control/ruby.md · rust.md · typescript.md |

**Delete / Flag**

- Remove `testing/frameworks.md` (superseded).  
- Tag any unmapped obsolete examples with `<!--TODO:Delete-->`.

---

## Phases

1. **Audit** – add `<!--LANG:Ruby-->` etc. comments.  
2. **Extract & Create** – move content into sub‑guides.  
3. **Refactor General Guides** – ensure only language‑agnostic material.  
4. **Index & Cleanup** – update README; run `md-link-check`.  
5. **PR Review** – assign to @docs-maintainers.

## Implementation Plan

- [ ] **Audit:** Add `<!--LANG:Ruby-->`, `<!--LANG:Rust-->`, `<!--LANG:TypeScript-->` comments to relevant blocks
  in all 9 general guides.
- [ ] **Create Sub-directories:** Create the language-specific sub-directories (`coding-standards/`, `documentation/`, etc.) if they don't exist.
  > TEST: Coding Standards Sub-directory Created
  > Type: Post-condition Check
  > Assert: The `dev-handbook/guides/coding-standards` directory exists.
  > Command: bin/test --check-file-exists dev-handbook/guides/coding-standards --type d
- [ ] **Extract & Create (Ruby):** Move Ruby blocks from general guides to `guides/<category>/ruby.md` (or
  `ruby-rspec.md` for testing).
  > TEST: Ruby Coding Standard File Created
  > Type: Post-condition Check
  > Assert: The `dev-handbook/guides/coding-standards/ruby.md` file exists and is not empty.
  > Command: bin/test --check-file-exists-not-empty dev-handbook/guides/coding-standards/ruby.md
- [ ] **Extract & Create (Rust):** Move Rust blocks from general guides to `guides/<category>/rust.md`.
- [ ] **Extract & Create (TypeScript):** Move TypeScript blocks from general guides to
  `guides/<category}/typescript.md` (or `typescript-bun.md` for testing).
- [ ] **Refactor General Guides:** Review each of the 9 general guides, removing the extracted language-specific
  blocks and ensuring only language-agnostic content remains. Remove `testing/frameworks.md`.
- [ ] **Tag Obsolete:** Tag any remaining unmapped examples with `<!--TODO:Delete-->`.
- [ ] **Index:** Update `dev-handbook/guides/README.md` (or create `index.md`) to include links to all newly created
  language-specific guides.
- [ ] **Review & Check:** Run `md-link-check`.
  > TEST: Markdown Links Check
  > Type: Guardrail
  > Assert: All markdown links are valid in the `dev-handbook/guides` directory.
  > Command: md-link-check dev-handbook/guides
>
> # Or a more specific path / project-wide lint command

- [ ] Ensure local site build passes (if applicable, this might be a manual step or a separate command).

## Acceptance Criteria

- [ ] Sub‑guides exist for all nine categories above.  
- [ ] General guides contain no Ruby/Rust/TS blocks.  
- [ ] Deprecated files removed or tagged.  
- [ ] README (or index) lists every guide with working links.  
- [ ] All automated tests defined in the Implementation Plan pass (e.g., directory/file creation, link checks).
- [ ] Local site build OK (if applicable and checked manually or via separate command).

## Out of Scope

- No additional stacks (Python, Go, …).  
- Do not rewrite existing examples—only relocate.

## References

- ADR‑010 “Documentation Structure”
- `.remarkrc` for lint rules

## Risks & Mitigations

- **Broken links after moves** → run `md-link-check` (as included in Implementation Plan) & add redirects if needed.
