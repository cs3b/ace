# Hermes transport test responsibility map

| Behavior | Risk | Owner and verification |
|---|---|---|
| Exact channel, Captain, Reply/command authority | High | `telegram_transport_test.rb`, explicit channels, controlled transport identities |
| Submission clock, refusal, uncertain send, immutable binding | High | transport integration with fake Bot API acknowledgement and real folder/journal |
| Receipt time, sequence, cutoff, queued ingress, polling gap | High | transport/poller integration with deterministic local clock and update batches |
| Single polling owner | High | actor lease plus runtime rejection of enabled gateway configuration |
| OTP pre-write rejection and secret IPC | High | low-level box gate and `transport_cli_test.rb` real local authenticated lifecycle service |
| Durable lifecycle exactly-once effects and expired OTP | High | existing `ace-hitl` owner suite, plus consumer duplicate/late cases |
| Installed plugin pre-preview guard, sanitized failures | High | installed package assets imported in controlled Python subprocess |
| Live registered Telegram channel, Lab removal/adoption | High | external `lab-config:gad.2` acceptance; no authorized real destination available in this run |

Production classes, filesystem, fsync journal, local IPC service and folder codecs remain real. Only Telegram I/O and binding liveness authority are controlled fixtures. The installed local socket test uses actual kernel peer credentials under the current test UID; it does not claim a deployed multi-user Lab acceptance.
