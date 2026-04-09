//
//  ForgeContainerResolveTests.swift
//  ForgeInject
//
//  Created by Stefan Projchev on 31.3.26.
//

import Testing
@testable import ForgeInject

@Suite("Resolve")
struct ForgeContainerResolveTests {

    // MARK: - resolveWithType

    @Test("Resolves using explicit type parameter")
    func resolveWithType() throws {
        let container = ForgeContainer()
        container.register(with: .singleton) { _ in MockService(id: "typed") }

        let result = try container.resolveWithType(MockService.self)
        #expect(result.id == "typed")
    }

    // MARK: - resolveAll

    @Test("Returns all singleton instances conforming to a protocol")
    func resolveAllReturnsSingletonInstances() throws {
        let container = ForgeContainer()
        container.register(with: .singleton) { _ in MockService(id: "service") as MockServiceProtocol }

        let _: MockServiceProtocol = try container.resolve()

        let all = container.resolveAll(conforming: MockServiceProtocol.self)
        #expect(all.count == 1)
        #expect(all.first?.id == "service")
    }

    @Test("Returns empty array when no instances exist")
    func resolveAllReturnsEmptyWhenNoneExist() {
        let container = ForgeContainer()
        let all = container.resolveAll(conforming: MockServiceProtocol.self)
        #expect(all.isEmpty)
    }

    // MARK: - Multiple Types

    @Test("Resolves different types independently")
    func resolvesDifferentTypes() throws {
        let container = ForgeContainer()
        container.register(with: .singleton) { _ in MockService(id: "service") }
        container.register(with: .singleton) { _ in MockValueService(value: 42) }

        let service: MockService = try container.resolve()
        let another: MockValueService = try container.resolve()

        #expect(service.id == "service")
        #expect(another.value == 42)
    }
}
