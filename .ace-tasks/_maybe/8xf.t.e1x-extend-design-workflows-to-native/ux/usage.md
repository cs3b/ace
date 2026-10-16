# Extend design workflows to native platforms: usage contract

## Happy path

Future family: /as-design-native-ios, /as-design-native-android, /as-design-native-mac, /as-design-native-linux. Not implemented by web release.

Expected: Future users explore and implement native UI using the same brief/variants/feedback process with platform-specific conventions and verification.

## Invalid input

A missing target/session or unavailable browser produces a specific error, preserves prior artifacts, and never claims completion.

## Resume

Reuse the recorded context and decisions; only requested variants or affected checks run again.
