# Test FAILURE: test_real_client_refuses_missing_mismatched_extra_part_and_open_descriptor_before_bytes

**Status:** FAILURE
**Location:** /Users/mc/Ps/ace/.ace-wt/review-9c2-runtime/ace-runtime/lib/ace/runtime/molecules/protected_socket.rb:63

## Error Message

[Ace::Assign::AttemptErrors::EvidenceUnavailable] exception expected, not
Class: <Ace::Runtime::RuntimeUnavailableError>
Message: <"protected socket deadline expired">
---Backtrace---

## Related stderr

```
/Users/mc/Ps/ace/.ace-wt/review-9c2-runtime/ace-support-test-helpers/lib/ace/test_support/performance_helpers.rb:3: warning: benchmark was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 4.0.0.
You can add benchmark to your Gemfile or gemspec to silence this warning.

```

## Code Context

```ruby
 58:    
 59:          def read(socket, deadline:, limit: LIMIT, with_size: false)  
 60:            buffer = +""  
 61:            loop do  
 62:              remaining = deadline - Process.clock_gettime(Process::CLOCK_MONOTONIC)  
 63:              raise RuntimeUnavailableError, "protected socket deadline expired" unless remaining.positive? &&  ← ERROR HERE
 64:                IO.select([socket], nil, nil, remaining)  
 65:              chunk = socket.read_nonblock(1, exception: false)  
 66:              next if chunk == :wait_readable  
 67:              raise RuntimeUnavailableError, "protected socket closed before response" unless chunk  
 68:              buffer << chunk  
```
