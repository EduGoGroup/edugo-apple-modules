import Foundation

// MARK: - Material Response DTO

/// Representa la respuesta de un material del backend.
///
/// Mapea directamente la respuesta JSON de:
/// - `GET /v1/materials`
/// - `GET /v1/materials/{id}`
public struct MaterialDTO: Decodable, Sendable, Equatable {
    /// Identificador único del material.
    public let id: String

    /// Título del material.
    public let title: String

    /// Descripción del material.
    public let description: String

    /// Materia a la que pertenece el material.
    public let subject: String

    /// Grado académico del material.
    public let grade: String

    /// ID de la unidad académica asociada.
    public let academicUnitId: String

    /// ID de la escuela asociada.
    public let schoolId: String

    /// ID del profesor que subió el material.
    public let uploadedByTeacherId: String

    /// Tipo MIME del archivo (ej: application/pdf).
    public let fileType: String

    /// Tamaño del archivo en bytes.
    public let fileSizeBytes: Int

    /// URL del archivo.
    public let fileUrl: String

    /// Estado de procesamiento del material.
    public let status: MaterialStatus

    /// Indica si el material es público.
    public let isPublic: Bool

    /// Fecha de creación.
    public let createdAt: Date

    /// Fecha de última actualización.
    public let updatedAt: Date

    /// Fecha de eliminación (soft delete).
    public let deletedAt: Date?

    /// Fecha de inicio del procesamiento.
    public let processingStartedAt: Date?

    /// Fecha de finalización del procesamiento.
    public let processingCompletedAt: Date?
}

// MARK: - Material Status

/// Estados posibles de un material durante su ciclo de vida.
public enum MaterialStatus: String, Decodable, Sendable, Equatable {
    /// Material subido, pendiente de procesamiento.
    case uploaded

    /// Material en procesamiento.
    case processing

    /// Material listo para uso.
    case ready

    /// Procesamiento fallido.
    case failed
}

// MARK: - Assessment Request DTO

/// Request para enviar un intento de assessment.
///
/// Usado en `POST /v1/materials/{id}/assessment/attempts`.
public struct CreateAttemptRequest: Encodable, Sendable, Equatable {
    /// Respuestas del usuario a cada pregunta.
    public let answers: [AnswerRequest]

    /// Tiempo total empleado en segundos (1-7200).
    public let timeSpentSeconds: Int

    /// Inicializa una request de intento de assessment.
    /// - Parameters:
    ///   - answers: Lista de respuestas (mínimo 1).
    ///   - timeSpentSeconds: Tiempo empleado en segundos (1-7200).
    public init(answers: [AnswerRequest], timeSpentSeconds: Int) {
        self.answers = answers
        self.timeSpentSeconds = timeSpentSeconds
    }
}

/// Respuesta individual a una pregunta del assessment.
public struct AnswerRequest: Encodable, Sendable, Equatable {
    /// ID de la pregunta.
    public let questionId: String

    /// ID de la respuesta seleccionada.
    public let selectedAnswerId: String

    /// Tiempo empleado en esta pregunta en segundos.
    public let timeSpentSeconds: Int

    /// Inicializa una respuesta a una pregunta.
    /// - Parameters:
    ///   - questionId: ID de la pregunta.
    ///   - selectedAnswerId: ID de la opción seleccionada.
    ///   - timeSpentSeconds: Tiempo empleado en segundos.
    public init(questionId: String, selectedAnswerId: String, timeSpentSeconds: Int) {
        self.questionId = questionId
        self.selectedAnswerId = selectedAnswerId
        self.timeSpentSeconds = timeSpentSeconds
    }
}

// MARK: - Assessment Response DTO

/// Resultado de un intento de assessment.
///
/// Respuesta de `POST /v1/materials/{id}/assessment/attempts`.
public struct AttemptResultDTO: Decodable, Sendable, Equatable {
    /// ID del intento.
    public let attemptId: String

    /// ID del assessment.
    public let assessmentId: String

    /// ID del material asociado.
    public let materialId: String

    /// Puntaje obtenido.
    public let score: Int

    /// Puntaje máximo posible.
    public let maxScore: Int

    /// Número de respuestas correctas.
    public let correctAnswers: Int

    /// Número total de preguntas.
    public let totalQuestions: Int

    /// Indica si el usuario aprobó.
    public let passed: Bool

    /// Umbral de aprobación.
    public let passThreshold: Int

    /// Mejor puntaje anterior del usuario.
    public let previousBestScore: Int?

    /// Indica si puede reintentar.
    public let canRetake: Bool

    /// Tiempo total empleado en segundos.
    public let timeSpentSeconds: Int

    /// Fecha de inicio del intento.
    public let startedAt: Date

    /// Fecha de finalización del intento.
    public let completedAt: Date

    /// Feedback detallado por pregunta.
    public let feedback: [QuestionFeedback]
}

/// Feedback de una pregunta individual.
public struct QuestionFeedback: Decodable, Sendable, Equatable {
    /// ID de la pregunta.
    public let questionId: String

    /// Texto de la pregunta.
    public let questionText: String

    /// Opción seleccionada por el usuario.
    public let selectedOption: String

    /// Respuesta correcta.
    public let correctAnswer: String

    /// Indica si la respuesta fue correcta.
    public let isCorrect: Bool

    /// Mensaje de feedback.
    public let message: String
}
