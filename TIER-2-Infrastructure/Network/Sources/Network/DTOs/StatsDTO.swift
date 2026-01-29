import Foundation

// MARK: - Global Stats Response DTO

/// Estadísticas globales del sistema.
///
/// Respuesta de `GET /v1/stats/global`.
/// Nota: El backend retorna un objeto genérico (additionalProperties: true),
/// por lo que usamos un enum tipado para los campos dinámicos.
public struct GlobalStatsDTO: Decodable, Sendable, Equatable {
    /// Campos de estadísticas conocidos.
    public let totalUsers: Int?
    public let totalMaterials: Int?
    public let totalSchools: Int?
    public let totalTeachers: Int?
    public let totalStudents: Int?
    public let totalAssessments: Int?
    public let averageProgress: Double?

    /// Campos adicionales dinámicos del backend.
    public let additionalFields: [String: JSONValue]

    /// Inicializa las estadísticas globales.
    public init(
        totalUsers: Int? = nil,
        totalMaterials: Int? = nil,
        totalSchools: Int? = nil,
        totalTeachers: Int? = nil,
        totalStudents: Int? = nil,
        totalAssessments: Int? = nil,
        averageProgress: Double? = nil,
        additionalFields: [String: JSONValue] = [:]
    ) {
        self.totalUsers = totalUsers
        self.totalMaterials = totalMaterials
        self.totalSchools = totalSchools
        self.totalTeachers = totalTeachers
        self.totalStudents = totalStudents
        self.totalAssessments = totalAssessments
        self.averageProgress = averageProgress
        self.additionalFields = additionalFields
    }

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKey.self)

        // Decodificar campos conocidos
        totalUsers = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKey(stringValue: "totalUsers")!)
        totalMaterials = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKey(stringValue: "totalMaterials")!)
        totalSchools = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKey(stringValue: "totalSchools")!)
        totalTeachers = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKey(stringValue: "totalTeachers")!)
        totalStudents = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKey(stringValue: "totalStudents")!)
        totalAssessments = try container.decodeIfPresent(Int.self, forKey: DynamicCodingKey(stringValue: "totalAssessments")!)
        averageProgress = try container.decodeIfPresent(Double.self, forKey: DynamicCodingKey(stringValue: "averageProgress")!)

        // Decodificar campos adicionales dinámicos
        let knownKeys: Set<String> = [
            "totalUsers", "totalMaterials", "totalSchools",
            "totalTeachers", "totalStudents", "totalAssessments", "averageProgress"
        ]

        var additional: [String: JSONValue] = [:]
        for key in container.allKeys where !knownKeys.contains(key.stringValue) {
            if let value = try? container.decode(JSONValue.self, forKey: key) {
                additional[key.stringValue] = value
            }
        }
        additionalFields = additional
    }
}

// MARK: - Dynamic Coding Key

/// Clave de codificación dinámica para decodificar campos desconocidos.
struct DynamicCodingKey: CodingKey {
    var stringValue: String
    var intValue: Int?

    init?(stringValue: String) {
        self.stringValue = stringValue
        self.intValue = nil
    }

    init?(intValue: Int) {
        self.stringValue = String(intValue)
        self.intValue = intValue
    }
}

// MARK: - JSONValue

/// Representación type-safe de valores JSON arbitrarios.
///
/// Compatible con Swift 6.2 Sendable requirements.
public enum JSONValue: Decodable, Sendable, Equatable {
    case null
    case bool(Bool)
    case int(Int)
    case double(Double)
    case string(String)
    case array([JSONValue])
    case object([String: JSONValue])

    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()

        if container.decodeNil() {
            self = .null
        } else if let bool = try? container.decode(Bool.self) {
            self = .bool(bool)
        } else if let int = try? container.decode(Int.self) {
            self = .int(int)
        } else if let double = try? container.decode(Double.self) {
            self = .double(double)
        } else if let string = try? container.decode(String.self) {
            self = .string(string)
        } else if let array = try? container.decode([JSONValue].self) {
            self = .array(array)
        } else if let object = try? container.decode([String: JSONValue].self) {
            self = .object(object)
        } else {
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "JSONValue cannot decode value"
            )
        }
    }

    /// Obtiene el valor como Bool si es posible.
    public var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    /// Obtiene el valor como Int si es posible.
    public var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }

    /// Obtiene el valor como Double si es posible.
    public var doubleValue: Double? {
        switch self {
        case .double(let value): return value
        case .int(let value): return Double(value)
        default: return nil
        }
    }

    /// Obtiene el valor como String si es posible.
    public var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    /// Obtiene el valor como Array si es posible.
    public var arrayValue: [JSONValue]? {
        if case .array(let value) = self { return value }
        return nil
    }

    /// Obtiene el valor como Dictionary si es posible.
    public var objectValue: [String: JSONValue]? {
        if case .object(let value) = self { return value }
        return nil
    }

    /// Indica si el valor es null.
    public var isNull: Bool {
        if case .null = self { return true }
        return false
    }
}
