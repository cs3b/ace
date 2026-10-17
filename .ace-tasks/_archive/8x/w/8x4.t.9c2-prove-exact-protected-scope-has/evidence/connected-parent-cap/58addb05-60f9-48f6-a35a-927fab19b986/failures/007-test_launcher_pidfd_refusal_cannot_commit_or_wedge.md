# Test FAILURE: test_launcher_pidfd_refusal_cannot_commit_or_wedge_reservation

**Status:** FAILURE
**Location:** /Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-assign/lib/ace/assign/authority/execution_scope_observation.rb:157

## Error Message

[Ace::Runtime::RuntimeUnavailableError] exception expected, not
Class: <KeyError>
Message: <"key not found: \"slice_unit\"">
---Backtrace---

## Related stderr

```
/Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-support-test-helpers/lib/ace/test_support/performance_helpers.rb:3: warning: benchmark was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 4.0.0.
You can add benchmark to your Gemfile or gemspec to silence this warning.

```

## Code Context

```ruby
152:          def initialize(mapping_id:, deployment:, kernel:, manager: nil, cgroups: Ace::Runtime::Molecules::CgroupObservation.new, files: Files.new)  
153:            @mapping_id, @deployment, @kernel, @cgroups, @files = mapping_id, deployment, kernel, cgroups, files  
154:            @map = deployment.mapping(mapping_id)  
155:            @scope = @map.fetch("execution_scope")  
156:            @manager = manager || Ace::Runtime::Molecules::SystemdScopeManager.new(  
157:              slice_unit: @scope.fetch("slice_unit"), service_unit: @scope.fetch("service_unit"))  ← ERROR HERE
158:          end  
159:    
160:          def observe(lineage)  
161:            @deployment.verify!(@mapping_id, kernel: @kernel, manager: @manager)  
162:            binding = lineage.binding  
```

## Fix Suggestion

Resource doesn't exist. Check paths and names
