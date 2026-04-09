//
//  ForgeContainerRegistrationTests.swift
//  ForgeInject
//
//  Created by Stefan Projchev on 31.3.26.
//

import Testing
@testable import ForgeInject

@Suite("Registration")
struct ForgeContainerRegistrationTests {

    @Test("Replaces previous registration for the same type")
    func replacesPreviousRegistration() throws {
        let container = ForgeContainer()
        container.register(with: .singleton) { _ in MockService(id: "first") }

        let first: MockService = try container.resolve()
        #expect(first.id == "first")

        container.register(with: .singleton) { _ in MockService(id: "second") }

        let second: MockService = try container.resolve()
        #expect(second.id == "second")
    }

    @Test("Clears cached singleton instance on re-register")
    func clearsCachedSingletonInstance() throws {
        let container = ForgeContainer()
        container.register(with: .singleton) { _ in MockService(id: "original") }

        let _: MockService = try container.resolve()

        container.register(with: .singleton) { _ in MockService(id: "replaced") }
        let result: MockService = try container.resolve()

        #expect(result.id == "replaced")
    }

    @Test("ForgeRegisterProtocol conformance registers dependencies")
    func registersViaProtocol() throws {
        let container = ForgeContainer()
        let register = MockDependencyRegister()
        register.registerDependencies(in: container)

        let service: MockService = try container.resolve()
        #expect(service.id == "registered")
    }
}
