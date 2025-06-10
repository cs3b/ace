## Inline comments  <!-- feel free to jump to “Summary” if you just want the big picture -->

### lib/coding_agent_tools/cli/commands/llm/query.rb
*L115-118*
```ruby
def error_output(message, debug_enabled)
  warn message
end
```
`debug_enabled` isn’t used. Either drop the argument or honour it (e.g. suppress non-debug output).

---

### lib/coding_agent_tools/molecules/http_request_builder.rb
*build_headers*
Sending `"Content-Type": "application/json"` on `GET` requests is unusual and may break very strict servers.
Consider adding it only when a body is present **or** when `method == :post`.

*build_url_with_query*
```ruby
all_params = existing_query.merge(query.transform_keys(&:to_s))
```
If `query` contains an Array value (e.g. `ids=[1,2]`) the semantics will be lost. `URI.encode_www_form` supports array tuples – treat array values explicitly or document limitation.

---

### lib/coding_agent_tools/organisms/gemini_client.rb
*extract_generated_text*
If Google ever returns an empty `candidates` array this will raise `NoMethodError`. Guard with
```ruby
return handle_error(parsed_response) unless candidate
```

*handle_error*
`message` drops the original HTTP status for non-JSON bodies. Including it improves debugging:
```ruby
"Gemini API Error (#{error[:status]}): …"
```

---

### lib/coding_agent_tools/atoms/json_formatter.rb
*sanitize*
`data.is_a?(String)` but **invalid JSON** returns the raw string → the whole string is considered non-sensitive although it might actually be JSON-with-a-typo exposing tokens. Consider a regexp replace for common key names as a last resort.

---

### spec/support/env_helper.rb
`#load_env_file` silently overrides env vars if they are _unset_, but **never overwrites**.
Great for safety; still, a warning when both sources differ would help newcomers.

---

### exe/llm-gemini-query
Redirecting `$stdout/$stderr` to `StringIO` and then re-printing means **ANSI colour codes** injected by Dry-CLI won’t propagate (they’re already escaped). Minor, but worth noting.

Also, the regex used to rewrite help text is fragile. If Dry-CLI changes its formatting the replace may break. Consider using `sub` on the first line only or accept original wording.

---

### lib/coding_agent_tools/molecules/api_credentials.rb
`#api_key_present?` first checks the config store, then ENV, **but** it ignores blank strings in the config path (whereas ENV path uses `present?`). Either treat `""` as absent everywhere or nowhere.

---

### docs/testing-with-vcr.md
The doc still mentions `spec/.env` but helper now also picks up repo-root `.env`. Update for clarity.

---

## Summary (check-list)

| Area | Verdict | Notes |
|------|---------|-------|
| Correctness / regressions | ✅ | All unit & integration tests green; happy path works. |
| Design / architecture | ✅ | ATOM layering respected; good abstractions. |
| Ruby idioms | ✅ | Clean, modern Ruby 3.4 code. |
| Use of gems | ✅ | Faraday, WebMock, VCR leveraged correctly. Could consider `dry-monads` for result types later. |
| Readability | ✅ | Well-named modules, extensive docs, ADRs 👍 |
| Performance | ⚠️ | Minor: unconditional JSON headers on GET; large StringIO copies in wrapper. |
| Security / errors | ⚠️ | Missing candidate guard; blank API keys; sanitize edge-case. |
| Testing | ✅ | >95 % coverage; CI-aware VCR neat. |
| Documentation | ✅ | Very complete. Only small outdated path in VCR docs. |

### Blocking issues
None – all comments are minor. Feel free to merge after triage.

### High-priority TODO before next release
1. Remove unused `debug_enabled` param or utilise it.
2. Don’t send `Content-Type: application/json` on GET unless required.
3. Guard `extract_generated_text` against empty `candidates`.

### Nice-to-have / future
* Switch from manual stdout capture in `exe/` wrapper to `Dry::CLI::Parser` customization – simpler & faster.
* Consider extracting a tiny DSL over `HTTPRequestBuilder` to reduce boilerplate in future API clients.
* Look at `addressable` for robust query building with arrays/duplicates.

Overall: Excellent, well-tested feature. 🚀
