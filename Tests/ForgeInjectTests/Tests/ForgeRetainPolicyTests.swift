//
//  ForgeRetainPolicyTests.swift
//  ForgeInject
//
//  Created by Stefan Projchev on 31.3.26.
//

import Testing
import Foundation
@testable import ForgeInject

@Suite("Retain Policies")
struct ForgeRetainPolicyTests {

    // MARK: - Transient

    @Suite("Transient")
    struct TransientPolicy {
        @Test("Creates a new instance on each resolve")
        func createsNewInstanceEachTime() throws {
            let container = ForgeContainer()
            container.register { _ in MockService() }

            let first: MockService = try container.resolve()
            let second: MockService = try container.resolve()

            #expect(first.id != second.id)
        }

        @Test("Registers with transient policy via convenience method")
        func convenienceMethod() throws {
            let container = ForgeContainer()
            container.register { _ in MockService() }

            let first: MockService = try container.resolve()
            let second: MockService = try container.resolve()

            #expect(first.id != second.id)
        }
    }

    // MARK: - Singleton

    @Suite("Singleton")
    struct SingletonPolicy {
        @Test("Returns the same instance on each resolve")
        func returnsSameInstance() throws {
            let container = ForgeContainer()
            container.register(with: .singleton) { _ in MockService() }

            let first: MockService = try container.resolve()
            let second: MockService = try container.resolve()

            #expect(first === second)
        }
    }

    // MARK: - Weak

    @Suite("Weak")
    struct WeakPolicy {
        @Test("Returns the same instance while a strong reference exists")
        func returnsSameInstanceWhileRetained() throws {
            let container = ForgeContainer()
            container.register(with: .weak) { _ in MockService() }

            let holder: MockService = try container.resolve()
            let second: MockService = try container.resolve()

            #expect(holder === second)
        }

        @Test("Creates a new instance after all strong references are released")
        func createsNewInstanceAfterRelease() throws {
            let container = ForgeContainer()
            let callCount = Mutex(0)
            container.register(with: .weak) { _ in
                let next: Int = callCount.withLock { count in
                    count += 1
                    return count
                }
                return MockService(id: "call-\(next)")
            }

            let firstId: String = try autoreleasepool {
                let holder: MockService = try container.resolve()
                #expect(holder.id == "call-1")
                return holder.id
            }

            let new: MockService = try container.resolve()
            #expect(new.id != firstId)
        }
    }
}
