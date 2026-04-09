//
//  ForgeContainerErrorTests.swift
//  ForgeInject
//
//  Created by Stefan Projchev on 31.3.26.
//

import Testing
@testable import ForgeInject

@Suite("Error Handling")
struct ForgeContainerErrorTests {

    @Test("Throws missingFactoryMethod for unregistered type")
    func throwsForUnregisteredType() {
        let container = ForgeContainer()

        #expect(throws: ForgeContainerError.self) {
            let _: MockService = try container.resolve()
        }
    }

    @Test("Error description contains the type name")
    func errorDescriptionContainsTypeName() {
        let error = ForgeContainerError.missingFactoryMethod(String(reflecting: MockService.self))
        #expect(error.errorDescription?.contains("MockService") == true)
    }

    @Test("typeMismatch error description contains the type name")
    func typeMismatchDescriptionContainsTypeName() {
        let error = ForgeContainerError.typeMismatch(String(reflecting: MockService.self))
        #expect(error.errorDescription?.contains("MockService") == true)
        #expect(error.errorDescription?.contains("Type mismatch") == true)
    }

    @Test("Factory that throws during build propagates the error")
    func factoryThrowingPropagates() {
        struct FactoryError: Error, Equatable {}

        let container = ForgeContainer()
        container.register(with: .transient) { _ -> MockService in
            throw FactoryError()
        }

        #expect(throws: FactoryError.self) {
            let _: MockService = try container.resolve()
        }
    }

    @Test("Factory that throws does not cache a partial instance")
    func factoryThrowingDoesNotCache() {
        struct FactoryError: Error {}
        let attempts = Mutex(0)

        let container = ForgeContainer()
        container.register(with: .singleton) { _ -> MockService in
            attempts.withLock { $0 += 1 }
            throw FactoryError()
        }

        // Both attempts should invoke the factory because nothing was cached on failure.
        _ = try? container.resolve() as MockService
        _ = try? container.resolve() as MockService

        #expect(attempts.withLock { $0 } == 2)
    }
}
