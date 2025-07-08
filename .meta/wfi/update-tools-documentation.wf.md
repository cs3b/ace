# Update Tools Documentation Workflow (v2)

> **Scope:** Updates `dev-tools/docs/tools.md` for **gem executables only**.
> Ignore any `bin/*` binstubs – documentation should encourage using the commands
> directly from any directory via fish integration.

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

### Understand project purpose and architecture
- docs/what-do-we-build.md
- docs/architecture.md
- docs/blueprint.md

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

1. **Identify Tool Category & Purpose**
   - Test with `tool-name --help`, read source, determine function category.

2. **Locate Correct Documentation Section**
   - `Gem Executables` is the section to modify.
   - Delete any stray `bin/*` references.

3. **Create or Update Tool Entry**
   - Use the *Mini‑template* above.

4. **Add / Update Cheat‑sheets & Persona Sections**
   - Main cheat‑sheet at top of file.
   - Persona‑specific cheat‑sheets (*Human Dev*, *AI Agent*, *Release Manager*, *Git Power‑User*).

5. **Update Category & Workflow Sections**
   - Add tool name to function and persona lists.
   - Amend workflow snippets where the tool is relevant.

6. **Run Validation & Quality Checks** (see §6)

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

# undocumented executables
for t in dev-tools/exe/*; do n=$(basename $t); grep -q "### \`$n\`" dev-tools/docs/tools.md || echo "⚠️  Missing: $n"; done
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
