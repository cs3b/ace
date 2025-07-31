---
id: {id}
status: draft
priority: {priority}
estimate: TBD
dependencies: {dependencies}
---

# {title}

## Behavioral Specification

### User Experience
- **Input**: [What users provide]
- **Process**: [What users experience during interaction]
- **Output**: [What users receive]

### Expected Behavior
[Describe WHAT the system should do, not HOW]

### Interface Contract
```bash
# CLI Interface (if applicable)
command-name [options] <arguments>

# API Interface (if applicable)
GET/POST/PUT/DELETE /endpoint
```

### Success Criteria

- [ ] [Measurable outcome 1]
- [ ] [Measurable outcome 2]

### Validation Questions

- [ ] Question about unclear requirements?
- [ ] Question about edge cases?
- [ ] Question about user expectations?

## 0. Directory Audit ✅

_Command run:_

```bash
tree -L 2 dev-handbook/guides | sed 's/^/    /'
```

_Result excerpt:_

```
<insert tree here>
```

## Objective

Why are we doing this? Focus on user value and behavioral outcomes.

## Scope of Work

- Behavioral requirement 1 (user experience focused)
- Behavioral requirement 2 (interface contract focused)

### Deliverables

#### Interface Contracts
- CLI command specifications
- API endpoint definitions
- UI component behaviors

#### Behavioral Documentation
- User experience flows
- Success criteria definitions
- Validation question resolutions

## Out of Scope

- ❌ Implementation details (file structures, code organization)
- ❌ Technical architecture decisions
- ❌ Tool or library selections
- ❌ Performance optimization strategies

## References

- Related ideas-manager output (if applicable)
- User experience requirements
- Interface specification examples