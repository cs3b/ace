# Antigravity CLI Provider — Draft Usage

## API Surface

- [x] CLI/provider configuration
- [ ] Developer API
- [ ] Agent API
- [ ] New configuration keys

## Usage Scenarios

### Run with Antigravity

Select provider `agy` and provide a prompt. ACE invokes the verified public CLI contract and returns output using sibling-provider conventions.

### Provider process fails

A fixture `agy` exits non-zero. ACE reports the established safe diagnostic and does not retry guessed legacy flags.

### Deterministic demo

A fixture executable records distinct argv and returns a deterministic response; no authentication or real dangerous permission operation occurs.

## Notes for Implementer

Complete usage docs after verifying the current public `agy` contract and record unresolved uncertainty.
