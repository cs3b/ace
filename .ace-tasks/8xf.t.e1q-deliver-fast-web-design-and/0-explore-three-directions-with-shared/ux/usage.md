# Explore three directions with shared mock data: usage contract

## Happy path

/as-design-site BRIEF; /as-design-app BRIEF; ace-design preview SESSION [--port PORT]; ace-design doctor; ace-design validate.

Expected: User supplies a brief or existing interface, receives three lightweight directions, gives feedback and selects a direction without production engineering overhead.

## Invalid input

A missing target/session or unavailable browser produces a specific error, preserves prior artifacts, and never claims completion.

## Resume

Reuse the recorded context and decisions; only requested variants or affected checks run again.
