//  UserRepositoryProtocol.swift
//  Models
//
//  Copyright © 2026 EduGo. All rights reserved.
//  Licensed under the MIT License.

import Foundation

/// Protocolo que define las operaciones de repositorio para la entidad User.
///
/// Este protocolo abstrae la capa de persistencia de usuarios, permitiendo
/// implementaciones en memoria, base de datos local o red.
///
/// ## Conformance
///
/// Las implementaciones deben ser `Sendable` para garantizar thread-safety
/// en contextos de concurrencia.
///
/// ## Operaciones
///
/// - `get(id:)`: Obtener un usuario por su ID
/// - `save(_:)`: Guardar o actualizar un usuario
/// - `delete(id:)`: Eliminar un usuario por su ID
/// - `list()`: Obtener todos los usuarios
///
/// ## Ejemplo de Implementación
///
/// ```swift
/// actor InMemoryUserRepository: UserRepositoryProtocol {
///     private var storage: [UUID: User] = [:]
///
///     func get(id: UUID) async throws -> User? {
///         return storage[id]
///     }
///
///     func save(_ user: User) async throws {
///         storage[user.id] = user
///     }
///
///     func delete(id: UUID) async throws {
///         storage.removeValue(forKey: id)
///     }
///
///     func list() async throws -> [User] {
///         return Array(storage.values)
///     }
/// }
/// ```
///
/// ## Testing
///
/// ```swift
/// final class MockUserRepository: UserRepositoryProtocol, @unchecked Sendable {
///     var users: [UUID: User] = [:]
///     var getCallCount = 0
///     var saveCallCount = 0
///
///     func get(id: UUID) async throws -> User? {
///         getCallCount += 1
///         return users[id]
///     }
///     // ... otros métodos
/// }
/// ```
public protocol UserRepositoryProtocol: Sendable {
    /// Obtiene un usuario por su ID.
    ///
    /// - Parameter id: El UUID del usuario a buscar.
    /// - Returns: El usuario si existe, `nil` en caso contrario.
    /// - Throws: Error de repositorio si hay problemas de acceso a datos.
    func get(id: UUID) async throws -> User?

    /// Guarda o actualiza un usuario en el repositorio.
    ///
    /// Si el usuario ya existe (mismo ID), se actualiza.
    /// Si no existe, se crea nuevo.
    ///
    /// - Parameter user: El usuario a guardar.
    /// - Throws: Error de repositorio si hay problemas de persistencia.
    func save(_ user: User) async throws

    /// Elimina un usuario del repositorio por su ID.
    ///
    /// Si el usuario no existe, la operación no hace nada (idempotente).
    ///
    /// - Parameter id: El UUID del usuario a eliminar.
    /// - Throws: Error de repositorio si hay problemas de acceso a datos.
    func delete(id: UUID) async throws

    /// Obtiene todos los usuarios del repositorio.
    ///
    /// - Returns: Array con todos los usuarios. Vacío si no hay usuarios.
    /// - Throws: Error de repositorio si hay problemas de acceso a datos.
    func list() async throws -> [User]
}
