import Foundation

/// Errores relacionados con la capa de persistencia y acceso a datos del sistema EduGo.
///
/// Estos errores representan fallos en operaciones de lectura, escritura, eliminación
/// y sincronización de datos con las fuentes de persistencia (API, base de datos local, etc.).
///
/// ## Conformidades
/// - `Error`: Para que pueda ser lanzado con `throw`
/// - `LocalizedError`: Para proporcionar mensajes descriptivos en español
/// - `Sendable`: Para cumplir con Swift 6.2 Strict Concurrency
///
/// ## Ejemplo de uso
/// ```swift
/// protocol StudentRepository {
///     func fetch(id: String) async throws -> Student
/// }
///
/// class APIStudentRepository: StudentRepository {
///     func fetch(id: String) async throws -> Student {
///         guard let url = URL(string: "\(baseURL)/students/\(id)") else {
///             throw RepositoryError.fetchFailed(reason: "URL inválida")
///         }
///         // ... implementación de red
///     }
/// }
/// ```
public enum RepositoryError: Error, LocalizedError, Sendable {
    /// Falló la operación de recuperación de datos.
    ///
    /// - Parameter reason: La razón específica por la cual falló la recuperación
    ///
    /// ## Ejemplo
    /// ```swift
    /// throw RepositoryError.fetchFailed(
    ///     reason: "El servidor respondió con código 404"
    /// )
    /// ```
    case fetchFailed(reason: String)

    /// Falló la operación de guardado de datos.
    ///
    /// - Parameter reason: La razón específica por la cual falló el guardado
    ///
    /// ## Ejemplo
    /// ```swift
    /// throw RepositoryError.saveFailed(
    ///     reason: "No se pudo sincronizar con el servidor remoto"
    /// )
    /// ```
    case saveFailed(reason: String)

    /// Falló la operación de eliminación de datos.
    ///
    /// - Parameter reason: La razón específica por la cual falló la eliminación
    ///
    /// ## Ejemplo
    /// ```swift
    /// throw RepositoryError.deleteFailed(
    ///     reason: "El registro está siendo referenciado por otras entidades"
    /// )
    /// ```
    case deleteFailed(reason: String)

    /// Error de conexión con la fuente de datos.
    ///
    /// - Parameter underlyingError: El error original de red o conexión (opcional)
    ///
    /// ## Ejemplo
    /// ```swift
    /// do {
    ///     let data = try await URLSession.shared.data(from: url)
    /// } catch {
    ///     throw RepositoryError.connectionError(underlyingError: error)
    /// }
    /// ```
    case connectionError(underlyingError: Error?)

    /// Error de serialización o deserialización de datos.
    ///
    /// - Parameter type: El tipo de dato que se intentaba serializar/deserializar
    ///
    /// ## Ejemplo
    /// ```swift
    /// do {
    ///     let student = try JSONDecoder().decode(Student.self, from: data)
    /// } catch {
    ///     throw RepositoryError.serializationError(type: "Student")
    /// }
    /// ```
    case serializationError(type: String)

    /// Inconsistencia detectada en los datos almacenados.
    ///
    /// - Parameter description: Descripción de la inconsistencia encontrada
    ///
    /// ## Ejemplo
    /// ```swift
    /// throw RepositoryError.dataInconsistency(
    ///     description: "Encontrados múltiples estudiantes con el mismo ID único"
    /// )
    /// ```
    case dataInconsistency(description: String)

    // MARK: - LocalizedError

    /// Descripción legible del error en español.
    public var errorDescription: String? {
        switch self {
        case .fetchFailed(let reason):
            return "Error al recuperar datos: \(reason)"
        case .saveFailed(let reason):
            return "Error al guardar datos: \(reason)"
        case .deleteFailed(let reason):
            return "Error al eliminar datos: \(reason)"
        case .connectionError(let underlyingError):
            if let underlying = underlyingError {
                return "Error de conexión: \(underlying.localizedDescription)"
            }
            return "Error de conexión con la fuente de datos"
        case .serializationError(let type):
            return "Error de serialización para el tipo '\(type)'"
        case .dataInconsistency(let description):
            return "Inconsistencia en los datos: \(description)"
        }
    }

    /// Razón técnica del fallo.
    public var failureReason: String? {
        switch self {
        case .fetchFailed:
            return "No se pudo completar la operación de lectura desde la fuente de datos."
        case .saveFailed:
            return "No se pudo completar la operación de escritura en la fuente de datos."
        case .deleteFailed:
            return "No se pudo completar la operación de eliminación en la fuente de datos."
        case .connectionError:
            return "No se pudo establecer o mantener la conexión con la fuente de datos."
        case .serializationError(let type):
            return "Los datos recibidos no pudieron ser convertidos al tipo '\(type)' esperado."
        case .dataInconsistency:
            return "Los datos almacenados no cumplen con las restricciones de integridad esperadas."
        }
    }

    /// Sugerencia de recuperación para el usuario.
    public var recoverySuggestion: String? {
        switch self {
        case .fetchFailed:
            return "Verifique su conexión a internet y vuelva a intentar. Si el problema persiste, contacte al soporte técnico."
        case .saveFailed:
            return "Asegúrese de tener conexión a internet y permisos suficientes. Intente guardar nuevamente."
        case .deleteFailed:
            return "Verifique que el recurso no esté siendo utilizado por otras entidades y vuelva a intentar."
        case .connectionError:
            return "Revise su conexión a internet y asegúrese de que el servicio esté disponible."
        case .serializationError:
            return "Los datos recibidos pueden estar en un formato incorrecto. Actualice la aplicación o contacte al soporte."
        case .dataInconsistency:
            return "Intente sincronizar los datos nuevamente o contacte al soporte técnico para resolver la inconsistencia."
        }
    }
}

// MARK: - Equatable

extension RepositoryError: Equatable {
    public static func == (lhs: RepositoryError, rhs: RepositoryError) -> Bool {
        switch (lhs, rhs) {
        case (.fetchFailed(let lReason), .fetchFailed(let rReason)):
            return lReason == rReason
        case (.saveFailed(let lReason), .saveFailed(let rReason)):
            return lReason == rReason
        case (.deleteFailed(let lReason), .deleteFailed(let rReason)):
            return lReason == rReason
        case (.connectionError(let lError), .connectionError(let rError)):
            // Comparar errors por su localizedDescription ya que Error no es Equatable
            return lError?.localizedDescription == rError?.localizedDescription
        case (.serializationError(let lType), .serializationError(let rType)):
            return lType == rType
        case (.dataInconsistency(let lDesc), .dataInconsistency(let rDesc)):
            return lDesc == rDesc
        default:
            return false
        }
    }
}
