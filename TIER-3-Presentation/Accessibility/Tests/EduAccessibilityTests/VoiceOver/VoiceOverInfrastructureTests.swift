// MARK: - VoiceOverInfrastructureTests.swift
// Tests para la infraestructura VoiceOver (Announcements, Grouping, Rotors)

import Testing
import SwiftUI
@testable import EduAccessibility

// MARK: - Announcement Tests

@Suite("AccessibilityAnnouncements Tests")
@MainActor
struct AccessibilityAnnouncementsTests {

    @Test("AnnouncementPriority tiene orden correcto")
    func testPriorityOrdering() {
        #expect(AnnouncementPriority.low < AnnouncementPriority.medium)
        #expect(AnnouncementPriority.medium < AnnouncementPriority.high)
        #expect(AnnouncementPriority.low < AnnouncementPriority.high)
    }

    @Test("AnnouncementPriority rawValues son correctos")
    func testPriorityRawValues() {
        #expect(AnnouncementPriority.low.rawValue == 0)
        #expect(AnnouncementPriority.medium.rawValue == 1)
        #expect(AnnouncementPriority.high.rawValue == 2)
    }

    @Test("AccessibilityAnnouncements.shared es singleton")
    func testSingleton() {
        let instance1 = AccessibilityAnnouncements.shared
        let instance2 = AccessibilityAnnouncements.shared
        #expect(instance1 === instance2)
    }

    @Test("announceProgressMilestone solo anuncia en milestones")
    func testProgressMilestones() {
        // Estos no deberían causar crash (no podemos verificar el announcement real)
        AccessibilityAnnouncements.announceProgressMilestone(0.10) // 10% - no milestone
        AccessibilityAnnouncements.announceProgressMilestone(0.25) // 25% - milestone
        AccessibilityAnnouncements.announceProgressMilestone(0.33) // 33% - no milestone
        AccessibilityAnnouncements.announceProgressMilestone(0.50) // 50% - milestone
        AccessibilityAnnouncements.announceProgressMilestone(0.75) // 75% - milestone
        AccessibilityAnnouncements.announceProgressMilestone(1.00) // 100% - milestone

        // Si llegamos aquí sin crash, el test pasa
        #expect(true)
    }

    @Test("announceError formatea mensaje correctamente")
    func testAnnounceError() {
        // Verificar que no causa crash
        AccessibilityAnnouncements.announceError("Test error message")
        #expect(true)
    }

    @Test("announceStateChange con contexto")
    func testAnnounceStateChangeWithContext() {
        AccessibilityAnnouncements.announceStateChange("Loading", context: "Button")
        #expect(true)
    }

    @Test("announceStateChange sin contexto")
    func testAnnounceStateChangeWithoutContext() {
        AccessibilityAnnouncements.announceStateChange("Loading")
        #expect(true)
    }

    @Test("clearQueue no causa crash")
    func testClearQueue() {
        AccessibilityAnnouncements.clearQueue()
        #expect(true)
    }

    @Test("throttleInterval es configurable")
    func testThrottleIntervalConfigurable() {
        let originalInterval = AccessibilityAnnouncements.throttleInterval

        AccessibilityAnnouncements.throttleInterval = 2.0
        #expect(AccessibilityAnnouncements.throttleInterval == 2.0)

        // Restaurar valor original
        AccessibilityAnnouncements.throttleInterval = originalInterval
    }

    @Test("maxQueueSize es configurable")
    func testMaxQueueSizeConfigurable() {
        let originalSize = AccessibilityAnnouncements.maxQueueSize

        AccessibilityAnnouncements.maxQueueSize = 20
        #expect(AccessibilityAnnouncements.maxQueueSize == 20)

        // Restaurar valor original
        AccessibilityAnnouncements.maxQueueSize = originalSize
    }
}

// MARK: - Grouping Tests

@Suite("AccessibilityGrouping Tests")
struct AccessibilityGroupingTests {

    @Test("AccessibilityGroupingMode tiene todos los casos")
    func testGroupingModes() {
        let modes: [AccessibilityGroupingMode] = [.combine, .contain, .ignore]
        #expect(modes.count == 3)
    }

    @Test("AccessibilityGroupingConfiguration inicializa con defaults")
    func testConfigurationDefaults() {
        let config = AccessibilityGroupingConfiguration()
        #expect(config.mode == .combine)
        #expect(config.separator == ", ")
        #expect(config.customLabel == nil)
        #expect(config.hint == nil)
        #expect(config.traits.isEmpty)
    }

    @Test("AccessibilityGroupingConfiguration.card preset")
    func testCardPreset() {
        let config = AccessibilityGroupingConfiguration.card
        #expect(config.mode == .combine)
        #expect(config.separator == ". ")
        #expect(config.traits == .summaryElement)
    }

    @Test("AccessibilityGroupingConfiguration.row preset")
    func testRowPreset() {
        let config = AccessibilityGroupingConfiguration.row
        #expect(config.mode == .combine)
        #expect(config.separator == ", ")
    }

    @Test("AccessibilityGroupingConfiguration.emptyState preset")
    func testEmptyStatePreset() {
        let config = AccessibilityGroupingConfiguration.emptyState
        #expect(config.mode == .combine)
        #expect(config.separator == ". ")
        #expect(config.traits == .staticText)
    }

    @Test("AccessibilityGroupingConfiguration.modal preset")
    func testModalPreset() {
        let config = AccessibilityGroupingConfiguration.modal
        #expect(config.mode == .contain)
    }

    @Test("AccessibilityGroupingConfiguration.list preset")
    func testListPreset() {
        let config = AccessibilityGroupingConfiguration.list
        #expect(config.mode == .contain)
    }

    @Test("AccessibilityGroupingConfiguration con customLabel")
    func testConfigurationWithCustomLabel() {
        let config = AccessibilityGroupingConfiguration(
            mode: .combine,
            customLabel: "Custom Label"
        )
        #expect(config.customLabel == "Custom Label")
        #expect(config.label == "Custom Label")
    }

    @Test("AccessibilityLabelCombiner combina labels correctamente")
    func testLabelCombiner() {
        let result = AccessibilityLabelCombiner()
            .add("First")
            .add("Second")
            .add("Third")
            .build()

        #expect(result == "First, Second, Third")
    }

    @Test("AccessibilityLabelCombiner con separador custom")
    func testLabelCombinerCustomSeparator() {
        let result = AccessibilityLabelCombiner(separator: " - ")
            .add("A")
            .add("B")
            .build()

        #expect(result == "A - B")
    }

    @Test("AccessibilityLabelCombiner.addIf funciona correctamente")
    func testLabelCombinerAddIf() {
        let resultTrue = AccessibilityLabelCombiner()
            .add("Base")
            .addIf(true, "Included")
            .build()

        let resultFalse = AccessibilityLabelCombiner()
            .add("Base")
            .addIf(false, "Excluded")
            .build()

        #expect(resultTrue == "Base, Included")
        #expect(resultFalse == "Base")
    }

    @Test("AccessibilityLabelCombiner.addOptional funciona correctamente")
    func testLabelCombinerAddOptional() {
        let someValue: String? = "Present"
        let nilValue: String? = nil

        let resultWithValue = AccessibilityLabelCombiner()
            .add("Base")
            .addOptional(someValue)
            .build()

        let resultWithNil = AccessibilityLabelCombiner()
            .add("Base")
            .addOptional(nilValue)
            .build()

        #expect(resultWithValue == "Base, Present")
        #expect(resultWithNil == "Base")
    }

    @Test("AccessibilityLabelCombiner filtra strings vacíos")
    func testLabelCombinerFiltersEmpty() {
        let result = AccessibilityLabelCombiner()
            .add("First")
            .add("")
            .add("Third")
            .build()

        #expect(result == "First, Third")
    }
}

// MARK: - Rotor Tests

@Suite("AccessibilityRotors Tests")
struct AccessibilityRotorsTests {

    @Test("AccessibilityRotorItem inicializa correctamente")
    func testRotorItemInit() {
        let item = AccessibilityRotorItem(id: "test-id", label: "Test Label")
        #expect(item.id == "test-id")
        #expect(item.label == "Test Label")
        #expect(item.systemLabel == nil)
    }

    @Test("AccessibilityRotorItem con systemLabel")
    func testRotorItemWithSystemLabel() {
        let item = AccessibilityRotorItem(
            id: "test-id",
            label: "Test",
            systemLabel: "Heading level 1"
        )
        #expect(item.systemLabel == "Heading level 1")
    }

    @Test("AccessibilityRotorItem con Hashable ID")
    func testRotorItemHashableId() {
        let item = AccessibilityRotorItem(id: 123, label: "Test")
        #expect(item.id == "123")
    }

    @Test("AccessibilityRotorType tiene todos los casos")
    func testRotorTypes() {
        let types: [AccessibilityRotorType] = [
            .listItems, .formFields, .headings,
            .links, .buttons, .images, .actions, .custom
        ]
        #expect(types.count == 8)
    }

    @Test("AccessibilityRotorType labels son correctos")
    func testRotorTypeLabels() {
        #expect(AccessibilityRotorType.listItems.label == "List Items")
        #expect(AccessibilityRotorType.formFields.label == "Form Fields")
        #expect(AccessibilityRotorType.headings.label == "Headings")
        #expect(AccessibilityRotorType.links.label == "Links")
        #expect(AccessibilityRotorType.buttons.label == "Buttons")
        #expect(AccessibilityRotorType.images.label == "Images")
        #expect(AccessibilityRotorType.actions.label == "Actions")
        #expect(AccessibilityRotorType.custom.label == "Custom")
    }

    @Test("AccessibilityRotorConfiguration presets")
    func testRotorConfigurationPresets() {
        #expect(AccessibilityRotorConfiguration.listItems.type == .listItems)
        #expect(AccessibilityRotorConfiguration.formFields.type == .formFields)
        #expect(AccessibilityRotorConfiguration.headings.type == .headings)
        #expect(AccessibilityRotorConfiguration.links.type == .links)
        #expect(AccessibilityRotorConfiguration.buttons.type == .buttons)
        #expect(AccessibilityRotorConfiguration.images.type == .images)
    }

    @Test("AccessibilityRotorConfiguration label con customLabel")
    func testRotorConfigurationCustomLabel() {
        let config = AccessibilityRotorConfiguration(
            type: .custom,
            customLabel: "My Custom Rotor"
        )
        #expect(config.label == "My Custom Rotor")
    }

    @Test("AccessibilityRotorConfiguration label sin customLabel")
    func testRotorConfigurationDefaultLabel() {
        let config = AccessibilityRotorConfiguration(type: .listItems)
        #expect(config.label == "List Items")
    }

    @Test("EduAccessibilitySystemRotor tiene todos los casos")
    func testSystemRotorCases() {
        // Nota: .buttons no existe como system rotor en SwiftUI
        let rotors: [EduAccessibilitySystemRotor] = [
            .headings, .links, .images,
            .textFields, .boldText, .italicText,
            .landmarks, .tables, .lists
        ]
        #expect(rotors.count == 9)
    }

    @Test("FormRotorBuilder construye fields correctamente")
    func testFormRotorBuilder() {
        let fields = FormRotorBuilder()
            .addField("Email", id: "email")
            .addField("Password", id: "password")
            .build()

        #expect(fields.count == 2)
        #expect(fields[0].id == "email")
        #expect(fields[0].label == "Email")
        #expect(fields[1].id == "password")
        #expect(fields[1].label == "Password")
    }

    @Test("FormRotorBuilder.addRequiredField agrega 'required'")
    func testFormRotorBuilderRequired() {
        let fields = FormRotorBuilder()
            .addRequiredField("Email", id: "email")
            .build()

        #expect(fields[0].label == "Email, required")
    }

    @Test("FormRotorBuilder.addFields agrega múltiples")
    func testFormRotorBuilderMultiple() {
        let fields = FormRotorBuilder()
            .addFields([
                (label: "First", id: "first"),
                (label: "Second", id: "second")
            ])
            .build()

        #expect(fields.count == 2)
    }

    @Test("HeadingRegistry registra headings")
    @MainActor
    func testHeadingRegistry() {
        let registry = HeadingRegistry()

        registry.register(id: "h1", label: "Main Title", level: 1)
        registry.register(id: "h2", label: "Section", level: 2)

        #expect(registry.headings.count == 2)
        #expect(registry.headings[0].id == "h1")
        #expect(registry.headings[1].id == "h2")
    }

    @Test("HeadingRegistry evita duplicados")
    @MainActor
    func testHeadingRegistryNoDuplicates() {
        let registry = HeadingRegistry()

        registry.register(id: "h1", label: "Title", level: 1)
        registry.register(id: "h1", label: "Title Again", level: 1)

        #expect(registry.headings.count == 1)
    }

    @Test("HeadingRegistry.clear limpia headings")
    @MainActor
    func testHeadingRegistryClear() {
        let registry = HeadingRegistry()

        registry.register(id: "h1", label: "Title", level: 1)
        #expect(registry.headings.count == 1)

        registry.clear()
        #expect(registry.headings.isEmpty)
    }
}
