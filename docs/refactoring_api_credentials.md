# API Credentials Refactoring

## Overview

The `APICredentials` class has been refactored to be more generic and reusable. Previously, it had hardcoded knowledge about Gemini API, but now it's a generic credential manager that can be used for any API service.

## Changes Made

### 1. Removed Service-Specific Constants

**Before:**
```ruby
class APICredentials
  # Default environment variable name for Gemini API key
  DEFAULT_GEMINI_KEY_NAME = "GEMINI_API_KEY"
  
  def initialize(env_key_name: DEFAULT_GEMINI_KEY_NAME, env_file_path: nil)
    # ...
  end
end
```

**After:**
```ruby
class APICredentials
  def initialize(env_key_name: nil, env_file_path: nil)
    # ...
  end
end
```

### 2. Made `env_key_name` Optional with Runtime Validation

The `env_key_name` parameter is now optional during initialization, but required when accessing the API key:

```ruby
def api_key
  raise KeyError, "env_key_name not set. Please provide it during initialization." if @env_key_name.nil?
  # ... rest of the logic
end
```

### 3. Moved Service-Specific Configuration to Service Classes

The Gemini-specific configuration is now owned by `GeminiClient`:

```ruby
class GeminiClient
  # Default environment variable name for Gemini API key
  DEFAULT_API_KEY_ENV = "GEMINI_API_KEY"
  
  def initialize(api_key: nil, model: DEFAULT_MODEL, **options)
    @credentials = Molecules::APICredentials.new(
      env_key_name: options.fetch(:api_key_env, DEFAULT_API_KEY_ENV)
    )
    # ...
  end
end
```

## Benefits

1. **Reusability**: `APICredentials` can now be used for any API service, not just Gemini
2. **Separation of Concerns**: Service-specific details are kept in service-specific classes
3. **Flexibility**: Each service can specify its own environment variable naming convention
4. **Backward Compatibility**: The optional `env_key_name` parameter maintains compatibility with existing code

## Usage Examples

### Generic API Credentials

```ruby
# For different services
github_creds = APICredentials.new(env_key_name: "GITHUB_TOKEN")
stripe_creds = APICredentials.new(env_key_name: "STRIPE_API_KEY")
custom_creds = APICredentials.new(env_key_name: "MY_SERVICE_KEY")

# Check if keys are available
if github_creds.api_key_present?
  token = github_creds.api_key_with_prefix("token ")
end
```

### With GeminiClient

```ruby
# Uses default GEMINI_API_KEY environment variable
client = GeminiClient.new

# Or with custom environment variable
client = GeminiClient.new(api_key_env: "MY_GEMINI_KEY")
```

### Error Handling

```ruby
# Without env_key_name
creds = APICredentials.new
creds.api_key # => KeyError: env_key_name not set. Please provide it during initialization.

# With env_key_name but missing environment variable
creds = APICredentials.new(env_key_name: "MISSING_KEY")
creds.api_key # => KeyError: API key not found. Please set MISSING_KEY environment variable...
```

## Migration Guide

If you were using `APICredentials` directly without specifying `env_key_name`:

**Before:**
```ruby
credentials = APICredentials.new  # Used GEMINI_API_KEY by default
```

**After:**
```ruby
credentials = APICredentials.new(env_key_name: "GEMINI_API_KEY")
```

If you were using `GeminiClient`, no changes are needed as it handles the configuration internally.

## Design Principles

This refactoring follows the SOLID principles:

1. **Single Responsibility**: `APICredentials` now has one job - manage API credentials generically
2. **Open/Closed**: The class is open for extension (can be used with any API) but closed for modification
3. **Dependency Inversion**: High-level modules (organisms) don't depend on low-level details (specific env var names)

The refactoring also maintains the atomic/molecular/organism hierarchy where:
- **Atoms** (EnvReader): Basic environment variable reading
- **Molecules** (APICredentials): Generic credential management
- **Organisms** (GeminiClient): Service-specific implementation with its own configuration