//
//  ForgeContainerResetTests.swift
//  ForgeInject
//
//  Created by Stefan Projchev on 31.3.26.
//

import Testing
@testable import ForgeInject

@Suite("Reset")
struct ForgeContainerResetTests {

    @Test("Clears all singleton instances")
    func clearsSingletonInstances() throws {
        let container = ForgeContainer()
        container.register(with: .singleton) { _ in MockService() }

        let first: MockService = try container.resolve()

        container.reset(preserving: [])

        let second: MockService = try container.resolve()
        #expect(first !== second)
    }

    @Test("Preserves ignored dependencies during reset")
    func preservesIgnoredDependencies() throws {
        let container = ForgeContainer()
        container.register(with: .singleton) { _ in MockService(id: "keep-me") }

        let first: MockService = try container.resolve()

        container.reset(preserving: [MockService.self])

        let second: MockService = try container.resolve()
        #expect(first === second)
    }

    @Test("Clears weak instances on reset")
    func clearsWeakInstances() throws {
        let container = ForgeContainer()
        container.register(with: .weak) { _ in MockService() }

        let holder: MockService = try container.resolve()

        container.reset(preserving: [])

        let new: MockService = try container.resolve()
        #expect(holder !== new)
    }
}
