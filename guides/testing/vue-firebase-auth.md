# Vue.js 3 + Firebase Authentication Testing Guide

## Overview

This guide provides comprehensive testing strategies for Vue.js 3 applications using Firebase Authentication with Vitest, covering both mock-based unit tests and integration tests with Firebase Emulator Suite.

## Testing Philosophy

Firebase Authentication testing follows a two-layer approach:

1. **Unit/Component Tests (Mocked)** - Fast, offline tests focusing on application logic
2. **Integration Tests (Emulator)** - Slower but comprehensive tests using Firebase Emulator Suite

## Mock-Based Testing Setup

### Firebase Auth Mock Module

Create a dedicated mock module for Firebase Authentication:

```typescript
// tests/__mocks__/firebase-auth.ts
import { vi } from 'vitest'

export const fakeUser = {
  uid: 'test-user-123',
  email: 'test@example.com',
  displayName: 'Test User',
  emailVerified: true
}

export const getAuth = vi.fn(() => ({
  currentUser: fakeUser,
}))

export const signInWithEmailAndPassword = vi.fn(async () => ({
  user: fakeUser,
}))

export const signOut = vi.fn(async () => {})

export const onAuthStateChanged = vi.fn((auth, callback) => {
  callback(fakeUser)
  return vi.fn() // Unsubscribe function
})

export const signInWithPopup = vi.fn(async () => ({
  user: fakeUser,
}))

export const GoogleAuthProvider = vi.fn()
```

### Vitest Configuration

Configure Vitest to use the mock:

```javascript
// vitest.config.js
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'jsdom',
    setupFiles: ['./tests/setup.ts']
  }
})
```

```typescript
// tests/setup.ts
import { vi } from 'vitest'

// Mock Firebase Auth before any imports
vi.mock('firebase/auth', () => import('./__mocks__/firebase-auth'))

// Reset mocks between tests
afterEach(() => {
  vi.resetAllMocks()
})
```

### Testing Vue Components with Authentication

```typescript
// tests/components/LoginForm.test.ts
import { mount } from '@vue/test-utils'
import { createTestingPinia } from '@pinia/testing'
import LoginForm from '@/components/auth/LoginForm.vue'
import { signInWithEmailAndPassword } from 'firebase/auth'

describe('LoginForm', () => {
  it('handles login successfully', async () => {
    const wrapper = mount(LoginForm, {
      global: {
        plugins: [createTestingPinia()]
      }
    })

    await wrapper.find('[data-testid="email"]').setValue('test@example.com')
    await wrapper.find('[data-testid="password"]').setValue('password')
    await wrapper.find('[data-testid="login-form"]').trigger('submit')

    expect(signInWithEmailAndPassword).toHaveBeenCalledWith(
      expect.anything(),
      'test@example.com',
      'password'
    )
  })

  it('displays error message on failed login', async () => {
    signInWithEmailAndPassword.mockRejectedValueOnce({
      code: 'auth/invalid-password',
      message: 'Invalid password'
    })

    const wrapper = mount(LoginForm, {
      global: {
        plugins: [createTestingPinia()]
      }
    })

    await wrapper.find('[data-testid="login-form"]').trigger('submit')
    await wrapper.vm.$nextTick()

    expect(wrapper.find('[data-testid="error-message"]').text())
      .toContain('Invalid password')
  })
})
```

### Testing Pinia Stores

```typescript
// tests/stores/userStore.test.ts
import { setActivePinia, createPinia } from 'pinia'
import { useUserStore } from '@/stores/userStore'
import { signInWithEmailAndPassword, signOut } from 'firebase/auth'

describe('userStore', () => {
  beforeEach(() => {
    setActivePinia(createPinia())
  })

  it('logs in user successfully', async () => {
    const store = useUserStore()
    
    await store.login('test@example.com', 'password')
    
    expect(signInWithEmailAndPassword).toHaveBeenCalledWith(
      expect.anything(),
      'test@example.com',
      'password'
    )
    expect(store.user).toEqual(expect.objectContaining({
      email: 'test@example.com'
    }))
    expect(store.isAuthenticated).toBe(true)
  })

  it('handles logout correctly', async () => {
    const store = useUserStore()
    store.user = { uid: '123', email: 'test@example.com' }
    
    await store.logout()
    
    expect(signOut).toHaveBeenCalled()
    expect(store.user).toBeNull()
    expect(store.isAuthenticated).toBe(false)
  })
})
```

### Testing Vue Router Guards

```typescript
// tests/router/authGuards.test.ts
import { createRouter, createWebHistory } from 'vue-router'
import { useUserStore } from '@/stores/userStore'
import { createTestingPinia } from '@pinia/testing'

describe('Auth Guards', () => {
  it('redirects unauthenticated users to login', async () => {
    const pinia = createTestingPinia()
    const userStore = useUserStore(pinia)
    userStore.isAuthenticated = false

    const router = createRouter({
      history: createWebHistory(),
      routes: [
        { path: '/login', component: { template: '<div>Login</div>' } },
        { 
          path: '/dashboard', 
          component: { template: '<div>Dashboard</div>' },
          beforeEnter: requireAuth
        }
      ]
    })

    await router.push('/dashboard')
    
    expect(router.currentRoute.value.path).toBe('/login')
  })
})
```

## Firebase Emulator Integration Testing

### Emulator Setup

```json
{
  "scripts": {
    "test:integration": "firebase emulators:exec --only auth,firestore \"vitest run --config vitest.integration.config.js\"",
    "test:emulator": "firebase emulators:start --only auth,firestore"
  }
}
```

### Integration Test Configuration

```javascript
// vitest.integration.config.js
import { defineConfig } from 'vitest/config'

export default defineConfig({
  test: {
    environment: 'jsdom',
    setupFiles: ['./tests/integration/setup.ts'],
    testTimeout: 10000
  }
})
```

```typescript
// tests/integration/setup.ts
import { initializeApp } from 'firebase/app'
import { getAuth, connectAuthEmulator } from 'firebase/auth'
import { getFirestore, connectFirestoreEmulator } from 'firebase/firestore'

// Initialize Firebase for testing
const app = initializeApp({
  projectId: 'demo-test-project',
  apiKey: 'fake-api-key'
})

const auth = getAuth(app)
const db = getFirestore(app)

// Connect to emulators
connectAuthEmulator(auth, 'http://localhost:9099', { disableWarnings: true })
connectFirestoreEmulator(db, 'localhost', 8080)

export { auth, db }
```

### Integration Test Examples

```typescript
// tests/integration/auth.test.ts
import { createUserWithEmailAndPassword, signInWithEmailAndPassword } from 'firebase/auth'
import { auth } from './setup'

describe('Firebase Auth Integration', () => {
  beforeEach(async () => {
    // Clear auth state before each test
    await fetch('http://localhost:9099/emulator/v1/projects/demo-test-project/accounts', {
      method: 'DELETE'
    })
  })

  it('creates and authenticates user', async () => {
    // Create user
    const userCredential = await createUserWithEmailAndPassword(
      auth,
      'test@example.com',
      'password123'
    )
    
    expect(userCredential.user.email).toBe('test@example.com')
    expect(userCredential.user.emailVerified).toBe(false)

    // Sign out
    await auth.signOut()
    
    // Sign in again
    const signInCredential = await signInWithEmailAndPassword(
      auth,
      'test@example.com',
      'password123'
    )
    
    expect(signInCredential.user.uid).toBe(userCredential.user.uid)
  })

  it('handles invalid credentials correctly', async () => {
    await expect(
      signInWithEmailAndPassword(auth, 'nonexistent@example.com', 'wrongpassword')
    ).rejects.toThrow()
  })
})
```

### Security Rules Testing

```typescript
// tests/integration/securityRules.test.ts
import { doc, getDoc, setDoc } from 'firebase/firestore'
import { db, auth } from './setup'
import { signInWithEmailAndPassword } from 'firebase/auth'

describe('Firestore Security Rules', () => {
  it('allows users to read their own profile', async () => {
    // Create and sign in user
    const user = await createTestUser('user@example.com', 'password')
    
    // Try to read user's own profile
    const profileRef = doc(db, 'users', user.uid)
    const profileSnap = await getDoc(profileRef)
    
    expect(profileSnap.exists()).toBe(true)
  })

  it('denies access to other users profiles', async () => {
    const user1 = await createTestUser('user1@example.com', 'password')
    const user2 = await createTestUser('user2@example.com', 'password')
    
    // Sign in as user1
    await signInWithEmailAndPassword(auth, 'user1@example.com', 'password')
    
    // Try to read user2's profile
    const otherProfileRef = doc(db, 'users', user2.uid)
    
    await expect(getDoc(otherProfileRef)).rejects.toThrow()
  })
})
```

## Test Helpers and Utilities

### Authentication Test Helpers

```typescript
// tests/helpers/authHelpers.ts
import { createUserWithEmailAndPassword, signInWithEmailAndPassword } from 'firebase/auth'
import { auth } from '../integration/setup'

export async function createTestUser(email: string, password: string) {
  const userCredential = await createUserWithEmailAndPassword(auth, email, password)
  return userCredential.user
}

export async function signInTestUser(email: string, password: string) {
  const userCredential = await signInWithEmailAndPassword(auth, email, password)
  return userCredential.user
}

export async function clearAuthEmulator() {
  await fetch('http://localhost:9099/emulator/v1/projects/demo-test-project/accounts', {
    method: 'DELETE'
  })
}
```

### Vue Component Test Helpers

```typescript
// tests/helpers/vueHelpers.ts
import { mount } from '@vue/test-utils'
import { createTestingPinia } from '@pinia/testing'
import { createRouter, createWebHistory } from 'vue-router'

export function createTestWrapper(component: any, options: any = {}) {
  const router = createRouter({
    history: createWebHistory(),
    routes: [
      { path: '/', component: { template: '<div>Home</div>' } },
      { path: '/login', component: { template: '<div>Login</div>' } }
    ]
  })

  return mount(component, {
    global: {
      plugins: [
        createTestingPinia({
          stubActions: false,
          ...options.pinia
        }),
        router
      ],
      ...options.global
    },
    ...options
  })
}
```

## CI/CD Integration

### GitHub Actions Workflow

```yaml
# .github/workflows/test.yml
name: Test
on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - uses: actions/setup-node@v4
        with:
          node-version: '20'
          cache: 'npm'
      
      - uses: actions/setup-java@v4
        with:
          distribution: 'temurin'
          java-version: '17'
      
      - run: npm ci
      
      - name: Run unit tests
        run: npm run test:unit
      
      - name: Run integration tests
        run: npm run test:integration
      
      - name: Upload coverage
        uses: codecov/codecov-action@v3
```

### NPM Scripts

```json
{
  "scripts": {
    "test": "vitest",
    "test:unit": "vitest run",
    "test:integration": "firebase emulators:exec --only auth,firestore \"vitest run --config vitest.integration.config.js\"",
    "test:coverage": "vitest run --coverage",
    "test:watch": "vitest watch"
  }
}
```

## Best Practices

### Test Organization

1. **Separate Unit and Integration Tests**
   - Unit tests in `tests/unit/`
   - Integration tests in `tests/integration/`
   - Shared helpers in `tests/helpers/`

2. **Mock Strategy**
   - Mock Firebase SDK for unit tests
   - Use real Firebase Emulator for integration tests
   - Mock external APIs and services

3. **Test Data Management**
   - Use factories for test data creation
   - Clear emulator state between tests
   - Use meaningful test data that reflects real usage

### Error Handling Testing

```typescript
describe('Error Handling', () => {
  it('handles network errors gracefully', async () => {
    signInWithEmailAndPassword.mockRejectedValueOnce(
      new Error('Network error')
    )

    const store = useUserStore()
    await store.login('test@example.com', 'password')

    expect(store.error).toContain('Network error')
    expect(store.isLoading).toBe(false)
  })

  it('handles Firebase auth errors', async () => {
    signInWithEmailAndPassword.mockRejectedValueOnce({
      code: 'auth/user-not-found',
      message: 'User not found'
    })

    const store = useUserStore()
    await store.login('nonexistent@example.com', 'password')

    expect(store.error).toContain('User not found')
  })
})
```

### Performance Testing

```typescript
describe('Authentication Performance', () => {
  it('completes login within acceptable time', async () => {
    const startTime = Date.now()
    
    await store.login('test@example.com', 'password')
    
    const duration = Date.now() - startTime
    expect(duration).toBeLessThan(1000) // 1 second max
  })
})
```

## Common Pitfalls and Solutions

### Mock Issues

- **ESM Side Effects**: Always mock before importing your application code
- **TypeScript Errors**: Create proper type declarations for mocked modules
- **Async Callbacks**: Use `vi.fn()` with proper callback simulation

### Emulator Issues

- **Connection Timing**: Ensure emulator is ready before running tests
- **State Pollution**: Clear emulator state between test suites
- **Port Conflicts**: Use dedicated ports for CI environments

### Vue-Specific Issues

- **Pinia State**: Reset store state between tests
- **Router Navigation**: Mock or stub router in unit tests
- **Component Lifecycle**: Use proper Vue Test Utils methods for async operations

## Resources

- [Vitest Documentation](https://vitest.dev/)
- [Firebase Emulator Suite](https://firebase.google.com/docs/emulator-suite)
- [Vue Test Utils](https://test-utils.vuejs.org/)
- [Pinia Testing](https://pinia.vuejs.org/cookbook/testing.html)