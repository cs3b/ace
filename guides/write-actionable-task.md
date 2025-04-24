# 📑 Writing Clear, Actionable Dev Tasks  
*A playbook for documentation‑oriented tickets, with a complete worked example*

## Introduction & Goal

This guide provides a structured approach and template for writing effective development tasks, particularly those focused on documentation changes within this toolkit. Following these steps ensures tasks are clear, scoped correctly, actionable, and easily understood by both human developers and AI agents contributing to the project. The goal is to minimize ambiguity and streamline the process of defining and executing documentation work.

---

## 0. Directory Audit Step ✅  
**Always start by discovering what actually exists in the repo.**  
1. Run a tree or ls command (exclude `node_modules`, `vendor`, etc.).  
2. Copy the relevant excerpt into the ticket.  
3. From that listing, build the deliverable manifest.  

> **Tip:**  
> • If you don’t have repo access, create a tiny *pre‑ticket* titled “Generate Guide‑Audit Manifest”.  
> • Commit the tree output as a comment or markdown file, then reference it in the main ticket.

Example audit snippet to embed:

```bash
tree -L 2 docs-dev/guides | sed 's/^/    /'

guides
├── coding-standards.md
├── error-handling.md
├── performance.md
├── testing.md
└── ...
```

---

## 1. Anatomy of a Great Task

| Section | Purpose | Key Questions |
|---------|---------|---------------|
| **Front‑matter** | Helps tooling & humans filter | id, status, priority, estimate, dependencies |
| **Objective / Problem** | *Why* are we doing this? | What pain are we fixing? |
| **Directory Audit (0)** | Source‑of‑truth for scope | Did we include the current tree? |
| **Scope of Work** | *What* to touch | Which guides/folders? |
| **Deliverables / Manifest** | Exact files to create / modify / delete | Could a newcomer do it with just this? |
| **Phases** | Bite‑sized plan | Audit → Extract → Refactor → Index |
| **Acceptance Criteria** | Definition of Done | Check‑list style `[ ]` |
| **Out of Scope** | Prevent scope creep | What must *not* be touched? |
| **References & Risks** | Links to style guides, ADRs; mitigations | Any scripts to run? |

---

## 2. Re‑usable Markdown Template

~~~markdown
---
id: <ticket-id>
status: pending
priority: <high/medium/low>
estimate: <n>h
dependencies: [<ticket-ids>]
---

# <Verb + Object>

## 0. Directory Audit ✅
_Command run:_
```bash
tree -L 2 docs-dev/guides | sed 's/^/    /'
```
_Result excerpt:_
```
<insert tree here>
```

## Objective
Why are we doing this?

## Scope of Work
- Bullet 1 …
- Bullet 2 …

### Deliverables
#### Create
- path/to/file.ext
#### Modify
- path/to/other.ext
#### Delete
- path/to/obsolete.ext

## Phases
1. Audit
2. Extract …
3. Refactor …

## Acceptance Criteria
- [ ] AC 1 …
- [ ] AC 2 …

## Out of Scope
- ❌ …

## References
- [writing-guides-guide.md](docs-dev/guides/writing-guides-guide.md)
~~~

Copy ➜ fill ➜ ship.

---

## 3. **Full Worked Example** – “Tailor Guides to Tech Stack”

~~~markdown
---
id: DOC-01
status: pending
priority: high
estimate: 8 h
dependencies: []
---

# Refactor Developer Guides by Language (Ruby, Rust, TypeScript)

## 0. Directory Audit ✅
_Command run 2025‑04‑24:_
```bash
tree -L 2 docs-dev/guides | sed 's/^/    /'
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
├── ship-release.md
├── testing.md
├── version-control.md
└── ...
```

🔍 **General guides requiring language splits:**  
`coding-standards.md`, `documentation.md`, `error-handling.md`, `performance.md`,  
`quality-assurance.md`, `security.md`, `ship-release.md`, `testing.md`,  
`version-control.md`

---

## Objective
Split language‑specific snippets out of *every* general guide so developers can jump straight to the rules for their stack.

## Scope of Work
1. **Audit** each general guide above.  
2. **Extract** Ruby, Rust, and TypeScript blocks into per‑language sub‑guides.  
   - *Testing* uses `ruby-rspec.md` & `typescript-bun.md`.  
3. **Clean** general guides so only polyglot advice remains.  
4. **Index** – add links for all new files to `docs-dev/guides/README.md` (or create `index.md`).  
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
| ship-release.md     | ship-release/ruby.md · rust.md · typescript.md |
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

## Acceptance Criteria
- [ ] Sub‑guides exist for all nine categories above.  
- [ ] General guides contain no Ruby/Rust/TS blocks.  
- [ ] Deprecated files removed or tagged.  
- [ ] README (or index) lists every guide with working links.  
- [ ] `md-link-check` passes; local site build OK.

## Out of Scope
- No additional stacks (Python, Go, …).  
- Do not rewrite existing examples—only relocate.

## References
- [`writing-guides-guide.md`](docs-dev/guides/writing-guides-guide.md)  
- ADR‑010 “Documentation Structure”  
- `.remarkrc` for lint rules

## Risks & Mitigations
- **Broken links after moves** → run `md-link-check` & add redirects if needed.
~~~

---

### 4. Quick “Ship‑It” Checklist 🚦
1. Is the **Directory Audit** present?  
2. Could a newcomer complete the work using only the manifest?  
3. Do the Acceptance Criteria read like QA steps?  
4. Is scope creep prevented by an **Out of Scope** section?  
5. Are references & scripts one click away?  

Tick them all ➜ merge the ticket.