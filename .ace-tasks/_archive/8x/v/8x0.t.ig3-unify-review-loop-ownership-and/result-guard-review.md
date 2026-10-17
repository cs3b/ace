# Current-result guard source checkpoint

Implemented the approved with_verified_result! block API with one existing read transaction, required lock availability, exact live acceptance and expected binding, recursively frozen projection and exception-safe release. No history writes or nested public transaction calls. Protected child provenance and receipt/CAS integration remain outstanding; this does not complete R2.

Executed targeted CampaignManager: 27 tests / 230 assertions PASS (4c0fec26-0d33-486e-b84c-d32ce3d29e47). Full ace-review fast: 963 tests / 3022 assertions PASS (28ce185d-a3df-4594-af1b-33bfe8fae719), 11.44 seconds. Tests include real flock exclusion during callback, release after exception, frozen nested projection, mismatched tuple/result and missing lock refusal.

Independent /root/wave_n0n review: APPROVE source/store/tests; no concrete finding. Guard uses one private projection path under required existing read lock and does not mutate. Approval does not extend to future protected CAS/child linkage or use of an escaped projection as permission.
