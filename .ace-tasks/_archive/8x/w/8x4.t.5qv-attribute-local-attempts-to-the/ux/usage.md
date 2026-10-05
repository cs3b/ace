# Local attempt account attribution

## Developer API

### Ordinary local process

Call the existing `ExecutionIdentityResolver.new(adapter: "local").resolve` from an ordinary process with equal real/effective UIDs. Its actor is the OS account for that UID, even if terminal login or `USER`/`LOGNAME` names another account. Existing local role, runtime, and genuine native binding behavior remain unchanged.

### Missing terminal login

Use the same API with no terminal login and no `USER`/`LOGNAME`. A valid OS account still resolves successfully; these environment values are not required.

### Unsupported or unresolved account

Use the same API with unequal real/effective UIDs, an unresolved account, or changing credentials. Resolution raises the existing `UnauthorizedIdentity` classification before attempt publication. Supplying login/environment names cannot override the refusal. No historical attempt ownership is changed.

The maintained package reference is `ace-assign/docs/usage.md`, under attempt identity and native ownership.
