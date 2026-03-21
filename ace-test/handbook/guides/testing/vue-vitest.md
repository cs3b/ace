---
doc-type: guide
title: Vue + Vitest Testing Guide
purpose: Vue Vitest testing reference
ace-docs:
  last-updated: 2026-01-23
  last-checked: 2026-03-21
---

# Vue + Vitest Testing Guide

Quick reference for Vue component testing with Vitest, focusing on single-run execution for coding agents and CI environments.

## Single-Run Commands

```bash
# Basic single run (exits immediately)
vitest run

# Run with output to file for parsing
vitest run --reporter=json --outputFile=reports/vitest.json

# Fail-fast with minimal output
vitest run --bail=1 --silent

# Run only changed files
vitest run --changed

# Run specific test files
vitest run src/components/__tests__/LoginForm.test.js
```

## Component Testing Patterns

### Basic Component Test Structure

```javascript
import { mount } from '@vue/test-utils'
import { describe, it, expect, beforeEach } from 'vitest'
import LoginForm from '../LoginForm.vue'

describe('LoginForm', () => {
  let wrapper

  beforeEach(() => {
    wrapper = mount(LoginForm)
  })

  it('renders login form elements', () => {
    expect(wrapper.find('input[type="email"]').exists()).toBe(true)
    expect(wrapper.find('input[type="password"]').exists()).toBe(true)
    expect(wrapper.find('button[type="submit"]').exists()).toBe(true)
  })

  it('emits login event with form data', async () => {
    await wrapper.find('input[type="email"]').setValue('test@example.com')
    await wrapper.find('input[type="password"]').setValue('password123')
    await wrapper.find('form').trigger('submit.prevent')

    expect(wrapper.emitted('login')).toHaveLength(1)
    expect(wrapper.emitted('login')[0][0]).toEqual({
      email: 'test@example.com',
      password: 'password123'
    })
  })
})
```

### Testing with Composables

```javascript
import { mount } from '@vue/test-utils'
import { vi } from 'vitest'
import ProfileView from '../ProfileView.vue'

// Mock the composable
vi.mock('@/composables/useAuth', () => ({
  useAuth: () => ({
    user: { value: { email: 'test@example.com', name: 'Test User' } },
    loading: { value: false },
    logout: vi.fn()
  })
}))

describe('ProfileView', () => {
  it('displays user information', () => {
    const wrapper = mount(ProfileView)
    expect(wrapper.text()).toContain('test@example.com')
    expect(wrapper.text()).toContain('Test User')
  })
})
```

### Testing with Router

```javascript
import { mount } from '@vue/test-utils'
import { createRouter, createWebHistory } from 'vue-router'
import App from '../App.vue'

const router = createRouter({
  history: createWebHistory(),
  routes: [
    { path: '/', component: { template: '<div>Home</div>' } },
    { path: '/login', component: { template: '<div>Login</div>' } }
  ]
})

describe('App with Router', () => {
  it('navigates to login page', async () => {
    const wrapper = mount(App, {
      global: {
        plugins: [router]
      }
    })

    await router.push('/login')
    await wrapper.vm.$nextTick()

    expect(wrapper.text()).toContain('Login')
  })
})
```

## Configuration for Single-Run

### vitest.config.js

```javascript
import { defineConfig } from 'vitest/config'
import vue from '@vitejs/plugin-vue'

export default defineConfig({
  plugins: [vue()],
  test: {
    environment: 'happy-dom',
    // For CI/automated testing
    run: true, // Force single-run mode
    reporters: ['default', 'json'],
    outputFile: {
      json: './reports/vitest.json'
    },
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov']
    }
  }
})
```

### package.json Scripts

```json
{
  "scripts": {
    "test": "vitest run",
    "test:watch": "vitest",
    "test:ui": "vitest --ui",
    "test:coverage": "vitest run --coverage"
  }
}
```

## Coding Agent Integration

### Exit Code Handling

```bash
# Test success/failure based on exit code
vitest run && echo "✅ Tests passed" || echo "❌ Tests failed"

# Store exit code for processing
vitest run
TEST_EXIT_CODE=$?
if [ $TEST_EXIT_CODE -eq 0 ]; then
  echo "All tests passed"
else
  echo "Tests failed with code $TEST_EXIT_CODE"
fi
```

### JSON Output Parsing

```javascript
// Parse test results from JSON output
const results = JSON.parse(fs.readFileSync('reports/vitest.json', 'utf8'))

console.log(`Tests: ${results.testResults.length}`)
console.log(`Passed: ${results.numPassedTests}`)
console.log(`Failed: ${results.numFailedTests}`)

// Get failed test details
const failedTests = results.testResults
  .filter(test => test.status === 'failed')
  .map(test => ({ name: test.name, error: test.message }))
```

## Common Pitfalls & Solutions

| Issue | Solution |
|-------|----------|
| Tests hang in watch mode | Always use `vitest run` for automated testing |
| Mock not applying | Ensure `vi.mock()` is called before imports |
| Async test failures | Use proper `await` and `nextTick()` |
| Component not rendering | Check if all required props are provided |
| Router tests failing | Mock router or provide test router instance |

## Best Practices for Automation

1. **Always use `vitest run`** - Never leave tests in watch mode for CI/agents
2. **Set explicit timeouts** - Prevent hanging tests with `--testTimeout=10000`
3. **Use JSON reporter** - Parse structured output instead of console logs
4. **Fail fast** - Use `--bail=1` to stop on first failure
5. **Clean output** - Use `--silent` or `--reporter=dot` for minimal noise
6. **Exit code validation** - Check process exit code for pass/fail status

## Quick Commands Reference

```bash
# Single run with coverage
vitest run --coverage

# Run specific test pattern
vitest run --testNamePattern="LoginForm"

# Run tests for specific files
vitest run src/components/**/*.test.js

# Generate machine-readable report
vitest run --reporter=junit --outputFile=reports/junit.xml

# Minimal output for CI
vitest run --reporter=dot --silent
```

This guide ensures your Vue + Vitest tests run deterministically and provide clear success/failure signals for coding agents and CI environments.