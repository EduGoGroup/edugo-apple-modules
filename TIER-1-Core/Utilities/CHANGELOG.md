# Changelog

Todos los cambios notables de este modulo seran documentados en este archivo.

El formato esta basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-01-29

### Added

#### CodableSerializer
- `CodableSerializer` - Actor thread-safe para serialización JSON
- `CodableSerializer.shared` - Instancia compartida con configuración por defecto (snake_case keys)
- `CodableSerializer.dtoSerializer` - Instancia para DTOs con CodingKeys explícitos (sin conversión de keys)
- Métodos `encode<T>(_:prettyPrinted:)` y `encodeToString<T>(_:prettyPrinted:)` para codificación
- Métodos `decode<T>(_:from: Data)` y `decode<T>(_:from: String)` para decodificación

#### Configuration
- `SerializerConfiguration` - Configuración flexible para encoder/decoder
- Configuración `.default` - ISO8601 dates + snake_case keys
- Configuración `.dtoCompatible` - ISO8601 dates sin conversión de keys
- Configuración `.prettyPrinted` - Output formateado para debug

#### Error Handling
- `SerializationError` - Errores tipados con mensajes descriptivos
- `.encodingFailed(type:reason:)` - Error de codificación
- `.decodingFailed(type:reason:)` - Error de decodificación
- Mensajes de error detallados con path de la propiedad fallida

#### Documentation
- `README-CodableSerializer.md` - Documentación completa con ejemplos
- Diagramas de arquitectura (Mermaid/ASCII)
- Guía de extensión para estrategias custom
- Ejemplos de integración con NetworkClient y LocalPersistence

### Technical Details

- Swift 6.2 con strict concurrency
- iOS 26+ / macOS 26+
- Todas las operaciones son async/await
- Thread safety garantizado via actors
- Todos los tipos conforman Sendable
- Estrategias pre-configuradas:
  - Date: ISO8601 (encoding/decoding)
  - Keys: snake_case <-> camelCase (configurable)

### Integration Notes

- **NetworkClient**: Usa `CodableSerializer.shared` para tipos sin CodingKeys explícitos
- **LocalPersistence**: Usa `CodableSerializer.dtoSerializer` para DTOs con CodingKeys
- Los DTOs existentes (UserDTO, SchoolDTO, etc.) tienen CodingKeys explícitos, usar `.dtoSerializer`

## [Unreleased]

### Planned
- Cache de instancias de serializer por configuración
- Soporte para formatos adicionales (XML, Plist)
- Métricas de serialización (tiempo, tamaño)
- Validación de schema JSON

---

[1.0.0]: https://github.com/edugo/eduui-modules-apple/releases/tag/utilities-v1.0.0
[Unreleased]: https://github.com/edugo/eduui-modules-apple/compare/utilities-v1.0.0...HEAD
