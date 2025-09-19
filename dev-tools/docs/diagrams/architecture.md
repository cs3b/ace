# Architecture Diagrams

This document contains all architectural diagrams for the Coding Agent Tools gem, illustrating both the overall ATOM architecture and the detailed security and caching component interactions.

## Overall ATOM Architecture

This diagram shows the high-level structure of the gem following the ATOM-based hierarchy (Atoms, Molecules, Organisms, Ecosystems) and external system interactions.

```mermaid
flowchart TD
    subgraph Ruby Gem (CAT)
        direction TB
        CLI[CLI Commands<br/>dev-tools/exe/* & cli/]
        Organisms[🧬 Organisms<br/>Business Logic]
        Molecules[🔬 Molecules<br/>Composed Operations]
        Atoms[⚛️ Atoms<br/>Basic Utilities]
        Models[(Models<br/>Data Structures)]
    end
    CLI --> Organisms
    Organisms --> Molecules
    Molecules --> Atoms
    Organisms --> Models

    Atoms -->|HTTP| GeminiAPI((Google Gemini))
    Atoms -->|HTTP| LMStudio((LM Studio))<br/>(localhost:1234)
    Atoms -->|System Calls| FileSystem[(File System)]
    Atoms -->|ENV| Environment[Environment Variables]
```

## Security and Caching Components Interaction

## High-Level Component Interaction Diagram

```mermaid
flowchart TD
    subgraph CLI["🖥️ CLI Layer"]
        LLMQuery["llm-query<br/>--force flag"]
        UsageReport["llm-usage-report"]
    end

    subgraph Organisms["🧬 Organisms (Business Logic)"]
        GeminiClient["GeminiClient"]
        LMStudioClient["LMStudioClient"] 
        OtherClients["Other Provider Clients"]
    end

    subgraph SecurityMolecules["🔒 Security Molecules"]
        SecurePathValidator["SecurePathValidator<br/>• Path traversal prevention<br/>• Allowlist/denylist validation<br/>• Normalization checks"]
        FileOperationConfirmer["FileOperationConfirmer<br/>• Interactive confirmations<br/>• Force flag handling<br/>• CI-safe defaults"]
        FileIOHandler["FileIOHandler<br/>• Secure file operations<br/>• Integrated path validation<br/>• Overwrite protection"]
    end

    subgraph CachingMolecules["💾 Caching Molecules"]
        CacheManager["CacheManager<br/>• XDG-compliant storage<br/>• Legacy migration<br/>• Cache type management"]
        RetryMiddleware["RetryMiddleware<br/>• Exponential backoff<br/>• Resilient HTTP requests<br/>• Failure recovery"]
    end

    subgraph SecurityAtoms["⚛️ Security Atoms"]
        SecurityLogger["SecurityLogger<br/>• Credential redaction<br/>• PII protection<br/>• Safe logging"]
        XDGResolver["XDGDirectoryResolver<br/>• Cross-platform paths<br/>• Standard compliance<br/>• Environment-aware"]
    end

    subgraph CoreAtoms["⚛️ Core Atoms"]
        HTTPClient["HTTPClient<br/>• Enhanced with retry logic"]
        EnvReader["EnvReader"]
        JSONFormatter["JSONFormatter"]
    end

    subgraph ExternalSystems["🌐 External Systems"]
        FileSystem["File System<br/>~/.cache/coding-agent-tools<br/>~/.config/coding-agent-tools"]
        APIs["LLM APIs<br/>Google Gemini<br/>OpenAI<br/>Anthropic<br/>etc."]
    end

    %% CLI to Organisms
    LLMQuery --> GeminiClient
    LLMQuery --> LMStudioClient
    LLMQuery --> OtherClients
    UsageReport --> GeminiClient

    %% Organisms to Security Molecules
    GeminiClient --> FileIOHandler
    LMStudioClient --> FileIOHandler
    OtherClients --> FileIOHandler

    %% Organisms to Caching Molecules  
    GeminiClient --> CacheManager
    LMStudioClient --> CacheManager
    OtherClients --> CacheManager
    GeminiClient --> RetryMiddleware
    LMStudioClient --> RetryMiddleware
    OtherClients --> RetryMiddleware

    %% Security Molecule Dependencies
    FileIOHandler --> SecurePathValidator
    FileIOHandler --> FileOperationConfirmer
    FileOperationConfirmer --> SecurityLogger

    %% Caching Molecule Dependencies
    CacheManager --> XDGResolver
    RetryMiddleware --> HTTPClient

    %% Security Atom Dependencies
    SecurePathValidator --> XDGResolver
    SecurityLogger --> EnvReader

    %% External System Interactions
    CacheManager --> FileSystem
    FileIOHandler --> FileSystem
    RetryMiddleware --> APIs
    HTTPClient --> APIs

    %% Styling
    classDef security fill:#ffebee,stroke:#c62828,stroke-width:2px
    classDef caching fill:#e8f5e8,stroke:#2e7d32,stroke-width:2px
    classDef core fill:#e3f2fd,stroke:#1565c0,stroke-width:2px
    classDef external fill:#fff3e0,stroke:#ef6c00,stroke-width:2px

    class SecurePathValidator,FileOperationConfirmer,FileIOHandler,SecurityLogger security
    class CacheManager,RetryMiddleware,XDGResolver caching
    class GeminiClient,LMStudioClient,OtherClients,HTTPClient,EnvReader,JSONFormatter core
    class FileSystem,APIs external
```

## Security Component Flow

### Path Validation and File Operations
1. **User Input**: CLI commands receive file paths and output destinations
2. **Path Validation**: `SecurePathValidator` checks all paths against:
   - Allowlist of safe directories (project root, XDG cache/config, system temp)
   - Denylist of dangerous patterns (path traversal, system directories)
   - Normalization to prevent bypass attempts
3. **User Confirmation**: `FileOperationConfirmer` prompts for overwrite confirmation
   - Respects `--force` flag for automation
   - Safe defaults in CI environments
4. **Secure Execution**: `FileIOHandler` performs validated file operations
5. **Audit Logging**: `SecurityLogger` records operations while redacting sensitive data

### Security Logger Protection
```mermaid
flowchart LR
    Input["Raw Log Data<br/>API keys, emails, IPs"] 
    --> SecurityLogger["SecurityLogger<br/>Pattern-based redaction"]
    --> Output["Safe Log Output<br/>[REDACTED] tokens"]
    
    SecurityLogger --> Patterns["Redaction Patterns:<br/>• API key formats<br/>• Email addresses<br/>• IP addresses<br/>• Common secrets"]
```

## Caching Component Flow

### XDG-Compliant Cache Management
1. **Initialization**: `CacheManager` uses `XDGDirectoryResolver` for standard paths
2. **Migration**: Automatically migrates from legacy `~/.coding-agent-tools-cache`
3. **Structured Storage**: Organizes cache by type (models, HTTP responses, temp files)
4. **Cross-Platform**: Works consistently across Linux, macOS, and Windows

### HTTP Resilience with Retry Logic
```mermaid
sequenceDiagram
    participant Client as LLM Client
    participant Retry as RetryMiddleware  
    participant HTTP as HTTPClient
    participant API as External API

    Client->>Retry: Make API Request
    Retry->>HTTP: Execute Request
    HTTP->>API: HTTP Call
    API-->>HTTP: Failure Response
    HTTP-->>Retry: Request Failed
    
    Note over Retry: Exponential Backoff<br/>Wait 1s → 2s → 4s → 8s
    
    Retry->>HTTP: Retry Request
    HTTP->>API: HTTP Call
    API-->>HTTP: Success Response
    HTTP-->>Retry: Request Succeeded
    Retry-->>Client: Final Response
```

## Component Benefits

### Security Improvements
- **Defense in Depth**: Multiple layers of protection for file operations
- **Path Traversal Prevention**: Comprehensive validation against directory escape attacks  
- **Safe Defaults**: Secure behavior in automated environments
- **Audit Trail**: Detailed logging without credential exposure
- **Interactive Safety**: User confirmation for destructive operations

### Caching & Performance Benefits
- **Standards Compliance**: XDG Base Directory specification adherence
- **Backward Compatibility**: Seamless migration from legacy cache locations
- **Failure Resilience**: Automatic retry with intelligent backoff strategies
- **Performance Optimization**: Reduced redundant API calls through intelligent caching
- **Cross-Platform Consistency**: Works reliably across different operating systems

## Integration Points

The security and caching components are tightly integrated:

1. **Shared Path Resolution**: Both systems use `XDGDirectoryResolver` for consistent path handling
2. **Unified Logging**: `SecurityLogger` protects sensitive data across all operations
3. **Cache Security**: Cache operations go through the same path validation as user files
4. **Resilient Caching**: Failed cache operations are logged securely and can be retried
5. **Configuration Management**: Both systems respect environment variables and user configuration

This architecture ensures that security is built-in rather than bolted-on, while providing robust caching that enhances performance without compromising safety.