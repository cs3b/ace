# Canonical result API — draft usage

These are executable Ruby examples against the existing public
Ace::Assign::Authority::Client.call surface after this draft is implemented.
Run under the already configured mapped OS principal. Installed deployment
selects mapping/project/socket/scratch; callers supply no authority paths.
No new CLI is proposed. Existing attempt finish/evidence command routing remains
xz9.0-owned; these direct APIs do not pretend that terminal finish is ready.

## Live owning worker: submit receipt and ordered artifact bytes

Save this example in a local consumer script and pass mapping ID, assignment ID,
attempt ID, a caller-persisted mutation ID and local receipt JSON path as ARGV.
It reads local files only to transmit bytes; the authority receives no paths.

```ruby
require "ace/assign"
require "json"
require "digest"

mapping, assignment, attempt, mutation, receipt_path = ARGV
client = Ace::Assign::Authority::Client.new(mapping_id: mapping)
status = client.call("attempt_status", {
  "assignment_id" => assignment, "attempt_id" => attempt,
  "result_candidate_generation" => nil
}, mutation_id: nil).data
receipt_bytes = File.binread(receipt_path)
receipt = JSON.parse(receipt_bytes)
artifact_bytes = receipt.fetch("artifacts").map { |item| File.binread(item.fetch("path")) }
reply = client.call("submit_result", {
  "assignment_id" => assignment, "attempt_id" => attempt,
  "expected_generation" => status.fetch("authority_generation"),
  "candidate_generation" => status.fetch("result_candidate_generation"),
  "head" => receipt.fetch("head"),
  "receipt_sha256" => Digest::SHA256.hexdigest(receipt_bytes)
}, mutation_id: mutation, upload_parts: [receipt_bytes, *artifact_bytes],
   purpose: :receipt_artifacts, timeout: 30)
puts JSON.generate(reply.data)
```

Expected: result_id, head/candidate generation, verdict, distinct uploaded/raw,
original and normalized receipt digests, ordered canonical artifact references,
generation and journal_commit; Reply.replayed says whether this was exact retry.
Client injects mapping_id/project_id and transfer descriptor. Private producer,
receipt and native binding are absent. Failed zero-artifact receipt uses [] and
sends only the receipt part. The receipt must already meet the normal binding,
checks/digests and canonical mapped producer requirements.

Persist the exact params (including original expected_generation), mutation ID
and ordered byte inputs before calling when a retry may be needed. Retry those
exact inputs rather than refreshing generation for the original mutation.
An identical retry with persisted mutation and identical original bytes while
worker lineage remains live/active returns the same projection without importing
twice. Once worker exits/attempt terminalizes submit retry fails closed. A new
mutation cannot replace content in this candidate generation; correction requires
new canonical candidate generation even at unchanged HEAD, and fresh review
before any successful finish.

## Supervisor/owning launcher: discover after lost reply and worker exit

This script runs under a mapped supervisor or exact owning launcher incarnation.
ARGV are mapping ID, assignment ID, attempt ID and optional retained generation.
No retained generation means latest canonical candidate, not latest cached reply.

```ruby
require "ace/assign"
require "json"
require "digest"

mapping, assignment, attempt, retained_generation = ARGV
client = Ace::Assign::Authority::Client.new(mapping_id: mapping)
status = client.call("attempt_status", {
  "assignment_id" => assignment, "attempt_id" => attempt,
  "result_candidate_generation" => retained_generation && Integer(retained_generation)
}, mutation_id: nil).data
puts JSON.generate(status.slice("result_candidate_generation", "submitted_result",
                               "authority_generation", "journal_commit"))
result = status.fetch("submitted_result")
abort "No result submitted for the selected canonical candidate" unless result
artifact = result.fetch("artifacts").first
if artifact
  artifact_id = artifact.fetch("path").delete_prefix("evidence/imports/")
  fetched = client.call("evidence_fetch", {
    "assignment_id" => assignment, "attempt_id" => attempt,
    "kind" => "result", "purpose_id" => result.fetch("result_id"),
    "artifact_id" => artifact_id
  }, mutation_id: nil, download: true, purpose: :artifacts, timeout: 30)
  bytes = fetched.parts.fetch(0)
  descriptor = fetched.data.fetch("descriptor")
  raise "Canonical bytes differ" unless bytes.bytesize == descriptor.fetch("bytes") &&
    Digest::SHA256.hexdigest(bytes) == descriptor.fetch("sha256")
  puts JSON.generate(fetched.data)
else
  puts "Verified failed result has no artifacts"
end
```

Expected: canonical sanitized result identity/references even after worker exit,
owner-reader restart and deleted cache; status generation is current canonical
CAS generation, not original result admission. Null result means proved absence
for a known candidate; nonexistent explicit generation is missing. Corruption
is evidence_unavailable, never null. Later finish references this result_id only
after xz9.0/9c2 proof is delivered; discovery itself frees nothing.

Fetch data is exactly descriptor, generation, journal_commit and transfer. Existing
Server-generated transfer contains version/aggregate bytes/SHA256 and one ordered
part bytes/SHA256, equal to descriptor; Client consumes data.transfer with the
existing artifacts codec and exposes one part only after verification. The code
uses a local byte string; it does not ask authority to read/write a caller path.

## Refusals and consumer ownership

Worker can discover/fetch only its own result while exact lineage is live;
reviewer only its current assigned exact candidate; executor cannot discover
result metadata. Wrong purpose, retired reviewer assignment, wrong launcher
incarnation or current visibility revocation refuses. Worker raw review or
observation fetch is unauthorized. Missing/mismatched/extra-part transfer metadata
or corrupted canonical provenance refuses without exposing bytes/private fields.
The existing Client raises EvidenceUnavailable with sanitized refusal code.

xz9.3 updates existing Client/Server download checks, Endcap result/fetch and the
single services attempt_status owner projection. Its public Client examples and
real socket/Git integration tests are its executable consumers. Existing
commands/attempt/finish.rb and commands/attempt/evidence.rb retain their normal
CLI input meanings; xz9.0 owns their protected coordinator/driver integration,
with no caller-local protected fallback. Full-service construction stays guarded
until all required operations exist; source handler tests use existing seams.
