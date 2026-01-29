# CodableSerializer

Thread-safe JSON serialization actor for Swift 6.2 with pre-configured strategies for ISO8601 dates and snake_case key conversion.

## Overview

`CodableSerializer` provides a centralized, thread-safe API for JSON encoding and decoding. It encapsulates `JSONEncoder` and `JSONDecoder` within a Swift actor, ensuring safe concurrent access without locks or dispatch queues.

### Key Features

- **Thread-Safe**: Actor isolation guarantees safe concurrent access
- **Pre-configured Strategies**: ISO8601 dates and snake_case/camelCase key conversion
- **Sendable Conformance**: All types conform to `Sendable` for Swift 6.2 strict concurrency
- **Detailed Error Messages**: Human-readable error descriptions for debugging
- **Flexible Configuration**: Support for custom encoder/decoder strategies

## Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                        Application Layer                         │
├─────────────────────────────────────────────────────────────────┤
│  NetworkClient          LocalPersistence        Other Modules    │
│       │                       │                       │          │
│       ▼                       ▼                       ▼          │
│  ┌─────────────────────────────────────────────────────────┐    │
│  │                   CodableSerializer                      │    │
│  │  ┌─────────────┐              ┌─────────────┐           │    │
│  │  │ JSONEncoder │              │ JSONDecoder │           │    │
│  │  │ - iso8601   │              │ - iso8601   │           │    │
│  │  │ - snakeCase │              │ - snakeCase │           │    │
│  │  └─────────────┘              └─────────────┘           │    │
│  └─────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────┘
```

### Data Flow: NetworkClient -> CodableSerializer -> DTO

```
┌──────────┐     ┌───────────────┐     ┌──────────────────┐     ┌─────────┐
│  Server  │────▶│ NetworkClient │────▶│ CodableSerializer │────▶│   DTO   │
│ (JSON)   │     │   (async)     │     │   .decode()      │     │ (Swift) │
└──────────┘     └───────────────┘     └──────────────────┘     └─────────┘

┌─────────┐     ┌──────────────────┐     ┌───────────────┐     ┌──────────┐
│   DTO   │────▶│ CodableSerializer │────▶│ NetworkClient │────▶│  Server  │
│ (Swift) │     │   .encode()      │     │   (async)     │     │  (JSON)  │
└─────────┘     └──────────────────┘     └───────────────┘     └──────────┘
```

## Quick Start

### Basic Usage

```swift
import Utilities

// Using the shared instance (snake_case key conversion)
let serializer = CodableSerializer.shared

// Encode a struct to JSON
struct User: Codable, Sendable {
    let userId: UUID
    let userName: String
    let createdAt: Date
}

let user = User(userId: UUID(), userName: "John", createdAt: Date())
let jsonData = try await serializer.encode(user)
// Result: {"user_id":"...","user_name":"John","created_at":"2024-01-15T10:30:00Z"}

// Decode JSON to struct
let decodedUser: User = try await serializer.decode(User.self, from: jsonData)
```

### Using with DTOs (Explicit CodingKeys)

If your DTOs already have explicit `CodingKeys` for snake_case mapping, use `dtoSerializer` to avoid double conversion:

```swift
// DTOs with explicit CodingKeys
struct UserDTO: Codable, Sendable {
    let firstName: String
    let lastName: String
    
    enum CodingKeys: String, CodingKey {
        case firstName = "first_name"
        case lastName = "last_name"
    }
}

// Use dtoSerializer - no key conversion applied
let dto = try await CodableSerializer.dtoSerializer.decode(UserDTO.self, from: jsonData)
```

### Pretty-Printed Output

```swift
let prettyJSON = try await serializer.encode(user, prettyPrinted: true)
// Result:
// {
//   "created_at": "2024-01-15T10:30:00Z",
//   "user_id": "550e8400-e29b-41d4-a716-446655440000",
//   "user_name": "John"
// }
```

### String Encoding/Decoding

```swift
// Encode to string
let jsonString = try await serializer.encodeToString(user)

// Decode from string
let userFromString: User = try await serializer.decode(User.self, from: jsonString)
```

## Configuration Options

### Pre-defined Configurations

| Configuration | Date Strategy | Key Strategy | Use Case |
|--------------|---------------|--------------|----------|
| `.default` | ISO8601 | snake_case | Types without CodingKeys |
| `.dtoCompatible` | ISO8601 | None | DTOs with explicit CodingKeys |
| `.prettyPrinted` | ISO8601 | snake_case | Debug output |

### Custom Configuration

```swift
let customConfig = SerializerConfiguration(
    dateEncodingStrategy: .secondsSince1970,
    keyEncodingStrategy: .useDefaultKeys,
    dateDecodingStrategy: .secondsSince1970,
    keyDecodingStrategy: .useDefaultKeys,
    outputFormatting: [.prettyPrinted, .sortedKeys]
)

let customSerializer = CodableSerializer(configuration: customConfig)
```

## Strategy Guide

### When to Use `.shared` (Default)

Use `CodableSerializer.shared` when:
- Your types do NOT have explicit `CodingKeys`
- You want automatic camelCase <-> snake_case conversion
- API returns snake_case JSON and you want Swift camelCase properties

```swift
// No CodingKeys defined - automatic conversion
struct Product: Codable, Sendable {
    let productId: UUID      // Encodes to "product_id"
    let productName: String  // Encodes to "product_name"
    let createdAt: Date      // Encodes to "created_at"
}
```

### When to Use `.dtoSerializer`

Use `CodableSerializer.dtoSerializer` when:
- Your DTOs have explicit `CodingKeys` for snake_case
- You're working with existing DTOs from the codebase
- You want to avoid double key conversion

```swift
// Has explicit CodingKeys - use dtoSerializer
struct SchoolDTO: Codable, Sendable {
    let schoolId: UUID
    let isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case schoolId = "school_id"
        case isActive = "is_active"
    }
}

let school = try await CodableSerializer.dtoSerializer.decode(SchoolDTO.self, from: data)
```

## Extending with Custom Strategies

### Adding UNIX Timestamp Support

```swift
extension SerializerConfiguration {
    /// Configuration using UNIX timestamps instead of ISO8601.
    static let unixTimestamp = SerializerConfiguration(
        dateEncodingStrategy: .secondsSince1970,
        keyEncodingStrategy: .convertToSnakeCase,
        dateDecodingStrategy: .secondsSince1970,
        keyDecodingStrategy: .convertFromSnakeCase,
        outputFormatting: nil
    )
}

// Create a serializer with UNIX timestamps
let unixSerializer = CodableSerializer(configuration: .unixTimestamp)

// Dates encoded as seconds since 1970
let data = try await unixSerializer.encode(user)
// {"created_at":1705312200,"user_id":"...","user_name":"John"}
```

### Adding Millisecond Timestamp Support

```swift
extension SerializerConfiguration {
    /// Configuration using milliseconds since 1970.
    static let millisecondTimestamp = SerializerConfiguration(
        dateEncodingStrategy: .custom { date, encoder in
            var container = encoder.singleValueContainer()
            try container.encode(Int64(date.timeIntervalSince1970 * 1000))
        },
        keyEncodingStrategy: .convertToSnakeCase,
        dateDecodingStrategy: .custom { decoder in
            let container = try decoder.singleValueContainer()
            let milliseconds = try container.decode(Int64.self)
            return Date(timeIntervalSince1970: Double(milliseconds) / 1000)
        },
        keyDecodingStrategy: .convertFromSnakeCase,
        outputFormatting: nil
    )
}
```

### Adding Custom Date Format

```swift
extension SerializerConfiguration {
    /// Configuration with custom date format (yyyy-MM-dd).
    static func customDateFormat(_ format: String) -> SerializerConfiguration {
        let formatter = DateFormatter()
        formatter.dateFormat = format
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(identifier: "UTC")
        
        return SerializerConfiguration(
            dateEncodingStrategy: .formatted(formatter),
            keyEncodingStrategy: .convertToSnakeCase,
            dateDecodingStrategy: .formatted(formatter),
            keyDecodingStrategy: .convertFromSnakeCase,
            outputFormatting: nil
        )
    }
}

// Usage
let dateOnlySerializer = CodableSerializer(configuration: .customDateFormat("yyyy-MM-dd"))
```

## Error Handling

`CodableSerializer` provides detailed error messages through `SerializationError`:

```swift
do {
    let user: User = try await serializer.decode(User.self, from: invalidData)
} catch let error as SerializationError {
    switch error {
    case .encodingFailed(let type, let reason):
        print("Failed to encode \(type): \(reason)")
    case .decodingFailed(let type, let reason):
        print("Failed to decode \(type): \(reason)")
        // Example: "Failed to decode User: Key 'user_id' not found at user_id"
    }
}
```

### Error Message Examples

| Error Type | Example Message |
|------------|-----------------|
| Key not found | `Key 'user_id' not found at user_id` |
| Type mismatch | `Type mismatch for Int at age` |
| Value not found | `Value not found for String at name` |
| Data corrupted | `Data corrupted at root: Invalid JSON` |

## Integration Examples

### NetworkClient Integration

```swift
public actor NetworkClient {
    private let serializer: CodableSerializer
    
    public init(serializer: CodableSerializer = .shared) {
        self.serializer = serializer
    }
    
    public func request<T: Decodable & Sendable>(
        _ request: HTTPRequest
    ) async throws -> T {
        let (data, _) = try await session.data(for: request.urlRequest)
        return try await serializer.decode(T.self, from: data)
    }
    
    public func post<T: Encodable & Sendable, R: Decodable & Sendable>(
        _ body: T,
        to request: HTTPRequest
    ) async throws -> R {
        var urlRequest = request.urlRequest
        urlRequest.httpBody = try await serializer.encode(body)
        let (data, _) = try await session.data(for: urlRequest)
        return try await serializer.decode(R.self, from: data)
    }
}
```

### LocalPersistence Integration

```swift
enum IntegrationTestFixtures {
    /// Use dtoSerializer for DTOs with explicit CodingKeys.
    static var serializer: CodableSerializer { .dtoSerializer }
    
    static func decode<T: Decodable & Sendable>(
        _ type: T.Type,
        from data: Data
    ) async throws -> T {
        try await serializer.decode(type, from: data)
    }
    
    static func encode<T: Encodable & Sendable>(
        _ value: T
    ) async throws -> Data {
        try await serializer.encode(value)
    }
}
```

## Performance Considerations

### Actor Overhead

The actor isolation adds minimal overhead compared to direct encoder/decoder access. For most applications, this overhead is negligible compared to network latency or disk I/O.

### Recommendations

1. **Use Shared Instance**: Reuse `CodableSerializer.shared` or `.dtoSerializer` instead of creating new instances
2. **Batch Operations**: When encoding/decoding multiple items, consider using `TaskGroup` for concurrent processing
3. **Avoid Blocking**: All operations are async - never use `.wait()` or blocking patterns

```swift
// Good: Concurrent batch encoding
let results = try await withThrowingTaskGroup(of: Data.self) { group in
    for item in items {
        group.addTask {
            try await serializer.encode(item)
        }
    }
    return try await group.reduce(into: []) { $0.append($1) }
}

// Bad: Sequential encoding
var results: [Data] = []
for item in items {
    results.append(try await serializer.encode(item))
}
```

## Thread Safety

As a Swift actor, `CodableSerializer` automatically ensures thread safety:

- All method calls are serialized within the actor
- No data races possible when accessing from multiple tasks
- `Sendable` conformance verified by the compiler

```swift
// Safe: Multiple concurrent calls
await withTaskGroup(of: Void.self) { group in
    for _ in 0..<100 {
        group.addTask {
            let data = try? await serializer.encode(someValue)
            let decoded: SomeType? = try? await serializer.decode(SomeType.self, from: data!)
        }
    }
}
```

## API Reference

### CodableSerializer

| Method | Description |
|--------|-------------|
| `encode<T>(_:prettyPrinted:)` | Encodes value to JSON Data |
| `encodeToString<T>(_:prettyPrinted:)` | Encodes value to JSON String |
| `decode<T>(_:from: Data)` | Decodes JSON Data to type |
| `decode<T>(_:from: String)` | Decodes JSON String to type |

### Static Instances

| Instance | Configuration | Use Case |
|----------|---------------|----------|
| `.shared` | Default (snake_case) | Types without CodingKeys |
| `.dtoSerializer` | DTO-compatible | DTOs with explicit CodingKeys |

### SerializerConfiguration

| Property | Type | Default |
|----------|------|---------|
| `dateEncodingStrategy` | `JSONEncoder.DateEncodingStrategy` | `.iso8601` |
| `keyEncodingStrategy` | `JSONEncoder.KeyEncodingStrategy` | `.convertToSnakeCase` |
| `dateDecodingStrategy` | `JSONDecoder.DateDecodingStrategy` | `.iso8601` |
| `keyDecodingStrategy` | `JSONDecoder.KeyDecodingStrategy` | `.convertFromSnakeCase` |
| `outputFormatting` | `JSONEncoder.OutputFormatting?` | `nil` |

## Requirements

- Swift 6.2+
- iOS 26+ / macOS 26+
- Strict Concurrency enabled
