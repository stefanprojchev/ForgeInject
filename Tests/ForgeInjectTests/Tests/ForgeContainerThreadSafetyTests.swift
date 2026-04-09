//
//  ForgeContainerThreadSafetyTests.swift
//  ForgeInject
//
//  Created by Stefan Projchev on 31.3.26.
//

import Testing
@testable import ForgeInject

@Suite("Thread Safety")
struct ForgeContainerThreadSafetyTests {

    @Test("Concurrent resolves do not crash")
    func concurrentResolvesAreSafe() async throws {
        let container = ForgeContainer()
        container.register(with: .singleton) { _ in MockService(id: "shared") }

        await withTaskGroup(of: String.self) { group in
            for _ in 0..<100 {
                // Expected warning: SendingClosureRisksDataRace — intentional for thread safety testing
                group.addTask {
                    let service: MockService = try! container.resolve()
                    return service.id
                }
            }

            for await id in group {
                #expect(id == "shared")
            }
        }
    }

    @Test("Concurrent register and resolve do not crash")
    func concurrentRegisterAndResolveAreSafe() async {
        let container = ForgeContainer()
        container.register(with: .singleton) { _ in MockService(id: "initial") }

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                // Expected warnings: SendingClosureRisksDataRace — intentional for thread safety testing
                group.addTask {
                    container.register(with: .singleton) { _ in MockService(id: "iter-\(i)") }
                }
                group.addTask {
                    let _: MockService? = try? container.resolve()
                }
            }
        }
    }

    @Test("Concurrent resolveAll does not crash under register pressure")
    func concurrentResolveAllIsSafe() async {
        let container = ForgeContainer()
        container.register(with: .singleton) { _ in MockService(id: "a") }

        await withTaskGroup(of: Void.self) { group in
            for i in 0..<50 {
                group.addTask {
                    container.register(with: .singleton) { _ in MockService(id: "re-\(i)") }
                }
                group.addTask {
                    _ = container.resolveAll(conforming: MockServiceProtocol.self)
                }
            }
        }
    }
}
