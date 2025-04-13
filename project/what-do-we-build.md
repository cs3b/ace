# AI Ruby Agent SDK - Project Overview

## What We Build 🔍

An elegant Ruby SDK for building AI agents that interact with both LLMs and system tools. The SDK follows a minimalist philosophy focusing on three core components:

- Environment: File-based agent communication and queueing
- Tools: A unified registry for various capabilities (browser control, file operations, etc.)
- Prompt: ERB templates for natural Ruby-style prompt interpolation

The goal is to keep agents simple for easy iteration while still providing power through a clean, Ruby-like DSL.

## ✨ Key Features

- **Elegant Ruby DSL** - Define agents using a natural, declarative syntax
- **File-Based Communication** - Agents communicate via source/output directories acting as queues
- **Unified Tool Registry** - Consistent interface for browsers, file operations, APIs etc.
- **ERB Template Prompts** - Ruby-native variable interpolation in prompts
- **Step-Based Workflows** - Support for multi-step agent processes
- **Loop & Review** - Built-in validation and retry mechanisms