# Test FAILURE: test_parent_only_proof_guarded_abort_and_durable_release_are_all_required_for_reuse

**Status:** FAILURE
**Location:** /Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-assign/test/feat/authority/launch_scope_admission_test.rb:206

## Error Message

Expected false to be truthy.

## Related stderr

```
/Users/mc/Ps/ace/.ace-wt/scope-local-implementation/ace-support-test-helpers/lib/ace/test_support/performance_helpers.rb:3: warning: benchmark was loaded from the standard library, but will no longer be part of the default gems starting from Ruby 4.0.0.
You can add benchmark to your Gemfile or gemspec to silence this warning.

```

## Code Context

```ruby
201:            assert_raises(AttemptErrors::Conflict) { @owner.send(:ensure_slot_available!, @map, @journal) }  
202:            params = @params.slice("mapping_id", "assignment_id", "attempt_id").merge("mutation_id" => "release", "expected_generation" => 5)  
203:            released = @owner.release_scope_reservation!(params: params, peer: @peer, role: :launcher)  
204:            assert_equal "released", released.dig(:data, "reservation")  
205:            assert_equal 6, released.dig(:data, "generation")  
206:            assert @owner.send(:ensure_slot_available!, @map, @journal).nil?  ← ERROR HERE
207:            replay = @owner.release_scope_reservation!(params: params, peer: @peer, role: :launcher)  
208:            assert replay.fetch(:replayed)  
209:            assert_equal released.fetch(:data), replay.fetch(:data)  
210:          end  
211:        end  
```
