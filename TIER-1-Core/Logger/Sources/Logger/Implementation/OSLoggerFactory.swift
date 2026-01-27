//
// OSLoggerFactory.swift
// Logger
//
// Created by EduGo Team on 27/01/2026.
// Copyright © 2026 EduGo. All rights reserved.
//

import Foundation

/// Factory para crear instancias de OSLoggerAdapter con configuraciones predefinidas.
///
/// Proporciona convenience methods para crear loggers configurados según diferentes
/// escenarios de uso (development, production, testing, etc.), eliminando la
/// necesidad de configurar manualmente cada instancia.
///
/// ## Ejemplo de uso:
/// ```swift
/// // Logger para desarrollo
/// let devLogger = OSLoggerFactory.development()
///
/// // Logger para producción con override específico
/// let prodLogger = OSLoggerFactory.production(
///     categoryOverrides: ["com.edugo.auth": .debug]
/// )
///
/// // Logger custom
/// let customLogger = OSLoggerFactory.custom(
///     globalLevel: .info,
///     subsystem: "com.myapp.custom"
/// )
/// ```
public enum OSLoggerFactory {

    // MARK: - Preset Factories

    /// Crea un logger configurado para desarrollo.
    ///
    /// - Nivel global: `.debug`
    /// - Metadata: Habilitado
    /// - Environment: `.development`
    ///
    /// - Parameters:
    ///   - categoryOverrides: Overrides opcionales por categoría
    /// - Returns: Logger configurado para desarrollo
    public static func development(
        categoryOverrides: [String: LogLevel] = [:]
    ) -> OSLoggerAdapter {
        let config = LogConfiguration(
            globalLevel: .debug,
            environment: .development,
            categoryOverrides: categoryOverrides,
            includeMetadata: true
        )
        return OSLoggerAdapter(configuration: config)
    }

    /// Crea un logger configurado para staging.
    ///
    /// - Nivel global: `.info`
    /// - Metadata: Habilitado
    /// - Environment: `.staging`
    ///
    /// - Parameters:
    ///   - categoryOverrides: Overrides opcionales por categoría
    /// - Returns: Logger configurado para staging
    public static func staging(
        categoryOverrides: [String: LogLevel] = [:]
    ) -> OSLoggerAdapter {
        let config = LogConfiguration(
            globalLevel: .info,
            environment: .staging,
            categoryOverrides: categoryOverrides,
            includeMetadata: true
        )
        return OSLoggerAdapter(configuration: config)
    }

    /// Crea un logger configurado para producción.
    ///
    /// - Nivel global: `.warning`
    /// - Metadata: Deshabilitado (performance)
    /// - Environment: `.production`
    ///
    /// - Parameters:
    ///   - categoryOverrides: Overrides opcionales por categoría
    /// - Returns: Logger configurado para producción
    public static func production(
        categoryOverrides: [String: LogLevel] = [:]
    ) -> OSLoggerAdapter {
        let config = LogConfiguration(
            globalLevel: .warning,
            environment: .production,
            categoryOverrides: categoryOverrides,
            includeMetadata: false
        )
        return OSLoggerAdapter(configuration: config)
    }

    /// Crea un logger configurado para testing.
    ///
    /// - Nivel global: `.error`
    /// - Logging: Deshabilitado
    /// - Metadata: Deshabilitado
    ///
    /// Útil para tests unitarios donde se quiere silenciar logging.
    ///
    /// - Returns: Logger configurado para testing (silenciado)
    public static func testing() -> OSLoggerAdapter {
        let config = LogConfiguration(
            globalLevel: .error,
            isEnabled: false,
            environment: .development,
            includeMetadata: false
        )
        return OSLoggerAdapter(configuration: config)
    }

    // MARK: - Custom Factories

    /// Crea un logger con configuración personalizada.
    ///
    /// - Parameters:
    ///   - globalLevel: Nivel mínimo global
    ///   - isEnabled: Si el logging está habilitado
    ///   - environment: Entorno de ejecución
    ///   - subsystem: Identificador del subsistema
    ///   - categoryOverrides: Overrides por categoría
    ///   - includeMetadata: Si incluir metadata de origen
    /// - Returns: Logger configurado según parámetros
    public static func custom(
        globalLevel: LogLevel,
        isEnabled: Bool = true,
        environment: LogConfiguration.Environment = .development,
        subsystem: String = "com.edugo.apple",
        categoryOverrides: [String: LogLevel] = [:],
        includeMetadata: Bool = true
    ) -> OSLoggerAdapter {
        let config = LogConfiguration(
            globalLevel: globalLevel,
            isEnabled: isEnabled,
            environment: environment,
            subsystem: subsystem,
            categoryOverrides: categoryOverrides,
            includeMetadata: includeMetadata
        )
        return OSLoggerAdapter(configuration: config)
    }

    /// Crea un logger basado en la configuración detectada automáticamente.
    ///
    /// Usa `#if DEBUG` para determinar si crear logger de desarrollo o producción.
    ///
    /// - Returns: Logger configurado automáticamente
    public static func automatic() -> OSLoggerAdapter {
        #if DEBUG
        return development()
        #else
        return production()
        #endif
    }

    // MARK: - Builder Pattern

    /// Builder para crear loggers con configuración fluida.
    ///
    /// Permite construir configuraciones complejas de forma legible.
    ///
    /// ## Ejemplo de uso:
    /// ```swift
    /// let logger = OSLoggerFactory.builder()
    ///     .globalLevel(.info)
    ///     .environment(.production)
    ///     .override(level: .debug, for: "com.edugo.auth")
    ///     .override(level: .error, for: "com.edugo.network")
    ///     .includeMetadata(false)
    ///     .build()
    /// ```
    public static func builder() -> LoggerBuilder {
        LoggerBuilder()
    }
}

// MARK: - Logger Builder

/// Builder pattern para crear loggers con configuración fluida.
public final class LoggerBuilder: @unchecked Sendable {

    private var globalLevel: LogLevel = .info
    private var isEnabled: Bool = true
    private var environment: LogConfiguration.Environment = .development
    private var subsystem: String = "com.edugo.apple"
    private var categoryOverrides: [String: LogLevel] = [:]
    private var includeMetadata: Bool = true

    /// Establece el nivel global mínimo.
    public func globalLevel(_ level: LogLevel) -> LoggerBuilder {
        self.globalLevel = level
        return self
    }

    /// Habilita o deshabilita el logging.
    public func enabled(_ isEnabled: Bool) -> LoggerBuilder {
        self.isEnabled = isEnabled
        return self
    }

    /// Establece el entorno de ejecución.
    public func environment(_ env: LogConfiguration.Environment) -> LoggerBuilder {
        self.environment = env
        return self
    }

    /// Establece el subsistema.
    public func subsystem(_ subsystem: String) -> LoggerBuilder {
        self.subsystem = subsystem
        return self
    }

    /// Añade un override de nivel para una categoría específica.
    ///
    /// - Parameters:
    ///   - level: El nivel a establecer
    ///   - categoryId: El identifier de la categoría
    public func override(level: LogLevel, for categoryId: String) -> LoggerBuilder {
        self.categoryOverrides[categoryId] = level
        return self
    }

    /// Añade un override de nivel para una categoría específica.
    ///
    /// - Parameters:
    ///   - level: El nivel a establecer
    ///   - category: La categoría
    public func override(level: LogLevel, for category: LogCategory) -> LoggerBuilder {
        self.categoryOverrides[category.identifier] = level
        return self
    }

    /// Habilita o deshabilita la inclusión de metadata.
    public func includeMetadata(_ include: Bool) -> LoggerBuilder {
        self.includeMetadata = include
        return self
    }

    /// Construye el logger con la configuración establecida.
    public func build() -> OSLoggerAdapter {
        let config = LogConfiguration(
            globalLevel: globalLevel,
            isEnabled: isEnabled,
            environment: environment,
            subsystem: subsystem,
            categoryOverrides: categoryOverrides,
            includeMetadata: includeMetadata
        )
        return OSLoggerAdapter(configuration: config)
    }
}
