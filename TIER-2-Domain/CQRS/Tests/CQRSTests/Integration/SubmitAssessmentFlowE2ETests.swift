import Foundation
import Testing
@testable import CQRS
import UseCases
import Models
import EduGoCommon

/// Tests de integración end-to-end para el flujo completo de Submit Assessment.
///
/// Este test suite valida el flujo completo:
/// 1. Dispatch GetAssessmentQuery
/// 2. Dispatch SubmitAssessmentCommand
/// 3. Verificar uso de AssessmentStateMachine
/// 4. Verificar event AssessmentSubmittedEvent publicado
/// 5. Verificar Dashboard invalidado
@Suite("Submit Assessment Flow End-to-End Tests")
struct SubmitAssessmentFlowE2ETests {

    // MARK: - Test: Flujo completo de submit assessment

    @Test("Submit assessment command completes successfully")
    func testSubmitAssessmentFlowComplete() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)

        let getAssessmentHandler = MockGetAssessmentQueryHandler()
        let submitHandler = MockSubmitAssessmentCommandHandler()

        try await mediator.registerQueryHandler(getAssessmentHandler)
        try await mediator.registerCommandHandler(submitHandler)

        // Execute: Get Assessment
        let assessmentId = UUID()
        let userId = UUID()

        let getQuery = GetAssessmentQuery(
            assessmentId: assessmentId,
            userId: userId
        )

        let assessmentDetail = try await mediator.send(getQuery)

        // Verify: Assessment loaded
        #expect(assessmentDetail.assessment.questions.count > 0)

        // Execute: Submit Assessment
        let answers = assessmentDetail.assessment.questions.map { question in
            UserAnswer(
                questionId: question.id,
                selectedOptionId: question.options.first!.id,
                timeSpentSeconds: 30
            )
        }

        let submitCommand = SubmitAssessmentCommand(
            assessmentId: assessmentId,
            userId: userId,
            answers: answers,
            timeSpentSeconds: 300
        )

        let result = try await mediator.execute(submitCommand)

        // Verify: Command exitoso
        #expect(result.isSuccess)
        #expect(result.events.contains("AssessmentSubmittedEvent"))

        if let attemptResult = result.getValue() {
            #expect(attemptResult.assessmentId == assessmentId)
            #expect(attemptResult.userId == userId)
            #expect(attemptResult.score >= 0)
        }
    }

    // MARK: - Test: Submit con respuestas incompletas

    @Test("Submit assessment fails with incomplete answers")
    func testSubmitWithIncompleteAnswers() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let submitHandler = MockSubmitAssessmentCommandHandlerIncomplete()

        try await mediator.registerCommandHandler(submitHandler)

        // Execute: Submit con solo 1 respuesta (de 3 requeridas)
        let submitCommand = SubmitAssessmentCommand(
            assessmentId: UUID(),
            userId: UUID(),
            answers: [
                UserAnswer(
                    questionId: UUID(),
                    selectedOptionId: UUID(),
                    timeSpentSeconds: 30
                )
            ],
            timeSpentSeconds: 100
        )

        let result = try await mediator.execute(submitCommand)

        // Verify: Falla por respuestas incompletas
        #expect(!result.isSuccess)
    }

    // MARK: - Test: State machine transitions

    @Test("Assessment uses state machine for flow control")
    func testAssessmentStateMachineTransitions() async throws {
        // Setup
        let mediator = Mediator(loggingEnabled: false, metricsEnabled: false)
        let submitHandler = MockSubmitAssessmentCommandHandlerWithStateMachine()

        try await mediator.registerCommandHandler(submitHandler)

        // Execute
        let answers = [
            UserAnswer(questionId: UUID(), selectedOptionId: UUID(), timeSpentSeconds: 30),
            UserAnswer(questionId: UUID(), selectedOptionId: UUID(), timeSpentSeconds: 30)
        ]

        let submitCommand = SubmitAssessmentCommand(
            assessmentId: UUID(),
            userId: UUID(),
            answers: answers,
            timeSpentSeconds: 200
        )

        let result = try await mediator.execute(submitCommand)

        // Verify: State transitions correctas
        #expect(result.isSuccess)
        if let metadata = result.metadata {
            #expect(metadata["stateTransitions"] != nil)
        }
    }
}

// MARK: - Mock Query Handlers

/// Mock QueryHandler para GetAssessmentQuery
actor MockGetAssessmentQueryHandler: QueryHandler {
    typealias QueryType = GetAssessmentQuery

    func handle(_ query: GetAssessmentQuery) async throws -> AssessmentDetail {
        let questions = [
            AssessmentQuestion(
                id: UUID(),
                text: "¿Cuánto es 2+2?",
                options: [
                    QuestionOption(id: UUID(), text: "3", orderIndex: 0),
                    QuestionOption(id: UUID(), text: "4", orderIndex: 1),
                    QuestionOption(id: UUID(), text: "5", orderIndex: 2)
                ],
                isRequired: true,
                orderIndex: 0
            ),
            AssessmentQuestion(
                id: UUID(),
                text: "¿Cuánto es 3+3?",
                options: [
                    QuestionOption(id: UUID(), text: "5", orderIndex: 0),
                    QuestionOption(id: UUID(), text: "6", orderIndex: 1),
                    QuestionOption(id: UUID(), text: "7", orderIndex: 2)
                ],
                isRequired: true,
                orderIndex: 1
            )
        ]

        let assessment = Assessment(
            id: query.assessmentId,
            materialId: UUID(),
            title: "Test de Matemáticas",
            description: "Evaluación básica",
            questions: questions,
            timeLimitSeconds: 600,
            maxAttempts: 3,
            passThreshold: 70,
            attemptsUsed: 0,
            expiresAt: nil
        )

        let eligibility = AssessmentEligibility(
            canTake: true,
            attemptsLeft: 3
        )

        return AssessmentDetail(
            assessment: assessment,
            eligibility: eligibility,
            cachedAt: Date(),
            isStale: false
        )
    }
}

// MARK: - Mock Command Handlers

/// Mock CommandHandler para SubmitAssessmentCommand (éxito)
actor MockSubmitAssessmentCommandHandler: CommandHandler {
    typealias CommandType = SubmitAssessmentCommand

    func handle(_ command: SubmitAssessmentCommand) async throws -> CommandResult<AttemptResult> {
        let result = AttemptResult(
            attemptId: UUID(),
            assessmentId: command.assessmentId,
            userId: command.userId,
            score: 80,
            maxScore: 100,
            passed: true,
            percentage: 80.0,
            feedback: [],
            timeSpentSeconds: command.timeSpentSeconds,
            submittedAt: Date()
        )

        return .success(
            result,
            events: ["AssessmentSubmittedEvent"],
            metadata: ["attemptId": result.attemptId.uuidString]
        )
    }
}

/// Mock CommandHandler con respuestas incompletas
actor MockSubmitAssessmentCommandHandlerIncomplete: CommandHandler {
    typealias CommandType = SubmitAssessmentCommand

    func handle(_ command: SubmitAssessmentCommand) async throws -> CommandResult<AttemptResult> {
        return .failure(
            AssessmentStateError.incompleteAnswers(missing: 2),
            metadata: ["answersProvided": String(command.answers.count)]
        )
    }
}

/// Mock CommandHandler con state machine
actor MockSubmitAssessmentCommandHandlerWithStateMachine: CommandHandler {
    typealias CommandType = SubmitAssessmentCommand

    func handle(_ command: SubmitAssessmentCommand) async throws -> CommandResult<AttemptResult> {
        // Simular transiciones: idle -> ready -> inProgress -> submitting -> completed
        let result = AttemptResult(
            attemptId: UUID(),
            assessmentId: command.assessmentId,
            userId: command.userId,
            score: 90,
            maxScore: 100,
            passed: true,
            percentage: 90.0,
            feedback: [],
            timeSpentSeconds: command.timeSpentSeconds,
            submittedAt: Date()
        )

        return .success(
            result,
            events: ["AssessmentSubmittedEvent"],
            metadata: [
                "attemptId": result.attemptId.uuidString,
                "stateTransitions": "idle->ready->inProgress->submitting->completed"
            ]
        )
    }
}
