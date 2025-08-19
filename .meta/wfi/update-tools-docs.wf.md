# Update Tools Documentation Workflow (v3)

> **Scope:** Updates `dev-tools/docs/tools.md` for **gem executables only**.
> Ignore any `bin/*` binstubs – documentation should encourage using the commands
> directly from any directory via fish integration.
> 
> **Excluded Tools:** Skip `coding_agent_tools`, `llm-models`, `llm-usage-report` 
> from main documentation as they create noise for AI agents without adding value.

---

## 0  Goal
Maintain a concise, accurate, and skimmable tools reference that combines a
one‑screen cheat‑sheet with collapsible detailed entries, while preserving all
existing project‑context sections.

---

## 1  Prerequisites
- A new or modified file exists in `dev-tools/exe/`
- You have run `tool-name --help` and/or reviewed the source
- Write access to `dev-tools/docs/tools.md`

---

## 2  Project Context Loading

### Load dev-tools context preset
```bash
context --preset dev-tools
```

### Understand project purpose and architecture
- docs/what-do-we-build.md
- docs/architecture.md
- docs/blueprint.md
- docs/tools.md

### Review current tools documentation
- dev-tools/docs/tools.md

---

## 3  High‑Level Execution Plan

| Step | Action | Notes |
|------|--------|-------|
| **1 Plan** | Map the tool to function category, persona, and cheat‑sheet row | Table 1 below |
| **2 Edit** | Add / update the tool entry using the *Mini‑template* (§4) | Use `<details>` |
| **3 Update** | • Main cheat‑sheet<br>• Persona cheat‑sheet(s)<br>• Category lists | Keep rows alphabetical |
| **4 Validate** | Run scripts in §6 Validation | Ensure no `bin/*` refs |

---

## 4  Templates

### 4.1  Cheat‑sheet row

```markdown
| `tool-name` | 1‑liner purpose | `--top-flag`, `--flag2` |
```

### 4.2  Tool entry

```markdown
### `tool-name` – 1‑sentence pitch
<details><summary>Details</summary>

```bash
tool-name [ARGS] [OPTIONS]
```

| Flag | Purpose | Default |
|------|---------|---------|
| `--flag` | … | `false` |

**Examples**
```bash
tool-name foo bar
tool-name --flag value
```
</details>
```

#### Authoring guards
- Do **not** paste full `--help` output.
- Provide **2–3** realistic examples, simple → advanced.
- Never include the full `dev-tools/exe/` path – use the bare command name only.
- Skip marketing‑style “Key Features” lists; flags table + examples are faster to scan.

---

## 5  Process Steps

1. **Check Tool Eligibility**
   - Skip if tool is in exclusion list: `coding_agent_tools`, `llm-models`, `llm-usage-report`
   - These tools create noise for AI agents without adding workflow value

2. **Identify Tool Category & Purpose**
   - Test with `tool-name --help`, read source, determine function category.

3. **Locate Correct Documentation Section**
   - `Gem Executables` is the section to modify.
   - Delete any stray `bin/*` references.

4. **Create or Update Tool Entry**
   - Use the *Mini‑template* above.

5. **Add / Update Cheat‑sheets & Persona Sections**
   - Main cheat‑sheet at top of file.
   - Persona‑specific cheat‑sheets (*Human Dev*, *AI Agent*, *Release Manager*, *Git Power‑User*).

6. **Update Category & Workflow Sections**
   - Add tool name to function and persona lists.
   - Amend workflow snippets where the tool is relevant.

7. **Run Validation & Quality Checks** (see §6)

---

## 6  Validation Checklist

### 6.1  Cheat‑sheet parity
- [ ] Tool listed in **main** cheat‑sheet
- [ ] Tool listed in at least one **persona** cheat‑sheet

### 6.2  Content Completeness
- [ ] Tool name & one‑sentence purpose
- [ ] Basic usage syntax
- [ ] 2–3 working examples
- [ ] Flags table
- [ ] Integration notes if needed

### 6.3  Documentation Quality
- [ ] Clear, concise prose
- [ ] Code blocks formatted
- [ ] Consistent style

### 6.4  Structural Integration
- [ ] Correct section & category
- [ ] No `bin/*` references
- [ ] No full paths
- [ ] Excluded tools (`coding_agent_tools`, `llm-models`, `llm-usage-report`) are not documented

### 6.5  Technical Accuracy
- [ ] Examples tested
- [ ] Flags match `--help`

### 6.6  User Experience
- [ ] Examples progress simple → complex
- [ ] Common use cases first

#### Validation scripts
```bash
# markdown style
markdownlint dev-tools/docs/tools.md

# undocumented executables (excluding intentionally skipped tools)
excluded_tools="coding_agent_tools llm-models llm-usage-report"
for t in dev-tools/exe/*; do 
  n=$(basename $t)
  if [[ ! " $excluded_tools " =~ " $n " ]]; then
    grep -q "### \`$n\`" dev-tools/docs/tools.md || echo "⚠️  Missing: $n"
  fi
done
```

---

## 7  Example Snippet (before ⟶ after)

```diff
-| ### LLM Integration Tools
-| #### `llm-query` - Unified LLM Query Interface
+| ## Main Cheat‑sheet
+| | Tool | Purpose | Flags |
+| |------|---------|-------|
+| | `llm-query` | Unified LLM query | `--model`, `--track-cost` |
+
+### `llm-query` – Unified LLM query
+<details><summary>Details</summary>
```

---

## 8  Design Principles (appendix)

1. **One‑screen clarity** – readers get 90 % of answers from the cheat‑sheet.
2. **Progressive disclosure** – details live inside collapsible blocks.
3. **Alphabetical rows** – predictable lookup.
4. **Fish-first** – document bare command names, never paths.
5. **Lean text** – remove redundant “Key Features” marketing.
