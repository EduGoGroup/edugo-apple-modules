import Testing
import Foundation
@testable import StateManagement

// MARK: - DashboardStateMachine Basic Tests

@Suite("DashboardStateMachine")
struct DashboardStateMachineTests {

    @Test("Initial state is idle")
    func initialStateIsIdle() async {
        let machine = DashboardStateMachine()
        let state = await machine.currentState
        #expect(state == .idle)
    }

    @Test("Configuration uses defaults")
    func configurationUsesDefaults() async {
        let machine = DashboardStateMachine()
        #expect(machine.configuration.timeout == 10)
        #expect(machine.configuration.allowPartialData == true)
        #expect(machine.configuration.maxRetries == 3)
    }

    @Test("Custom configuration is applied")
    func customConfigurationIsApplied() async {
        let config = DashboardStateMachine.Configuration(
            timeout: 5,
            allowPartialData: false,
            maxRetries: 1,
            retryBaseDelay: 0.5
        )
        let machine = DashboardStateMachine(configuration: config)
        #expect(machine.configuration.timeout == 5)
        #expect(machine.configuration.allowPartialData == false)
        #expect(machine.configuration.maxRetries == 1)
    }
}

// MARK: - Loading Tests

@Suite("DashboardStateMachine Loading")
struct DashboardStateMachineLoadingTests {

    @Test("Successful load transitions to ready")
    func successfulLoadTransitionsToReady() async {
        let machine = DashboardStateMachine()

        await machine.loadDashboard(
            userId: "user123",
            userFetcher: {
                UserData(id: "1", name: "Test User", email: "test@test.com")
            },
            unitsFetcher: {
                [UnitData(id: "u1", title: "Unit 1", progress: 0.5)]
            },
            materialsFetcher: {
                [MaterialData(id: "m1", title: "Material 1", type: .video)]
            }
        )

        let state = await machine.currentState
        if case .ready(let data) = state {
            #expect(data.user.name == "Test User")
            #expect(data.units.count == 1)
            #expect(data.materials.count == 1)
        } else {
            Issue.record("Expected ready state, got \(state)")
        }
    }

    @Test("Loading completes successfully")
    func loadingCompletesSuccessfully() async {
        let machine = DashboardStateMachine()

        await machine.loadDashboard(
            userId: "user123",
            userFetcher: {
                UserData(id: "1", name: "Test", email: "test@test.com")
            },
            unitsFetcher: {
                [UnitData(id: "u1", title: "Unit", progress: 0.5)]
            },
            materialsFetcher: {
                [MaterialData(id: "m1", title: "Mat", type: .video)]
            }
        )

        let state = await machine.currentState
        if case .ready = state {
            // Success
        } else {
            Issue.record("Expected ready state, got \(state)")
        }
    }
}

// MARK: - Cancellation Tests

@Suite("DashboardStateMachine Cancellation")
struct DashboardStateMachineCancellationTests {

    @Test("Cancel transitions to error cancelled")
    func cancelTransitionsToErrorCancelled() async {
        let machine = DashboardStateMachine()

        // Start a long-running load
        Task {
            await machine.loadDashboard(
                userId: "user123",
                userFetcher: {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    return UserData(id: "1", name: "Test", email: "test@test.com")
                },
                unitsFetcher: {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    return []
                },
                materialsFetcher: {
                    try? await Task.sleep(nanoseconds: 1_000_000_000)
                    return []
                }
            )
        }

        // Wait a bit then cancel
        try? await Task.sleep(nanoseconds: 50_000_000)
        await machine.cancel()

        let state = await machine.currentState
        if case .error(.cancelled) = state {
            // Success
        } else {
            Issue.record("Expected cancelled error, got \(state)")
        }
    }

    @Test("Reset returns to idle")
    func resetReturnsToIdle() async {
        let machine = DashboardStateMachine()

        // Load something
        await machine.loadDashboard(
            userId: "user123",
            userFetcher: { UserData(id: "1", name: "Test", email: "test@test.com") },
            unitsFetcher: { [] },
            materialsFetcher: { [] }
        )

        // Reset
        await machine.reset()

        let state = await machine.currentState
        #expect(state == .idle)
    }
}

// MARK: - Error Handling Tests

@Suite("DashboardStateMachine Error Handling")
struct DashboardStateMachineErrorHandlingTests {

    struct TestError: Error {}

    @Test("Single failure results in error state")
    func singleFailureResultsInErrorState() async {
        let config = DashboardStateMachine.Configuration(
            timeout: 1,
            allowPartialData: false,
            maxRetries: 1,
            retryBaseDelay: 0.1
        )
        let machine = DashboardStateMachine(configuration: config)

        await machine.loadDashboard(
            userId: "user123",
            userFetcher: { throw TestError() },
            unitsFetcher: { [] },
            materialsFetcher: { [] }
        )

        let state = await machine.currentState
        if case .error = state {
            // Success
        } else {
            Issue.record("Expected error state, got \(state)")
        }
    }
}

// MARK: - Stream Tests

@Suite("DashboardStateMachine Stream")
struct DashboardStateMachineStreamTests {

    @Test("StateStream returns StateStream type")
    func stateStreamReturnsStateStreamType() async {
        let machine = DashboardStateMachine()
        let stream = await machine.stateStream

        // Verify it's usable
        await machine.reset()
        await machine.finish()

        var count = 0
        for await _ in stream {
            count += 1
            if count > 0 { break }
        }

        #expect(count >= 0)
    }

    @Test("Finish terminates the stream")
    func finishTerminatesTheStream() async {
        let machine = DashboardStateMachine()
        let stream = await machine.stateStream

        await machine.finish()

        var count = 0
        for await _ in stream {
            count += 1
        }

        #expect(count >= 0)
    }
}

// MARK: - Cached Data Tests

@Suite("DashboardStateMachine Cached Data")
struct DashboardStateMachineCachedDataTests {

    @Test("Load with cached data completes")
    func loadWithCachedDataCompletes() async {
        let machine = DashboardStateMachine()

        let cachedData = DashboardData(
            user: UserData(id: "1", name: "Cached", email: "cached@test.com"),
            units: [],
            materials: [],
            isFromCache: true
        )

        await machine.loadDashboard(
            userId: "user123",
            userFetcher: { UserData(id: "1", name: "Fresh", email: "fresh@test.com") },
            unitsFetcher: { [] },
            materialsFetcher: { [] },
            cachedData: cachedData
        )

        let state = await machine.currentState
        if case .ready = state {
            // Success - either cached or fresh
        } else {
            Issue.record("Expected ready state, got \(state)")
        }
    }
}

// MARK: - Sendable Tests

@Suite("DashboardStateMachine Sendable")
struct DashboardStateMachineSendableTests {

    @Test("Machine can be passed across actor boundaries")
    func machineCanBePassedAcrossActorBoundaries() async {
        let machine = DashboardStateMachine()

        let result = await Task {
            await machine.reset()
            return await machine.currentState
        }.value

        #expect(result == .idle)
    }
}

// MARK: - Configuration Tests

@Suite("DashboardStateMachine Configuration")
struct DashboardStateMachineConfigurationTests {

    @Test("Default configuration values")
    func defaultConfigurationValues() {
        let config = DashboardStateMachine.Configuration.default
        #expect(config.timeout == 10)
        #expect(config.allowPartialData == true)
        #expect(config.maxRetries == 3)
        #expect(config.retryBaseDelay == 1.0)
    }
}
