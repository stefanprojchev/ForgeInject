//
//  InjectMacroTests.swift
//  ForgeInject
//
//  End-to-end tests for the @Inject, @Injectable, and #inject() macros.
//  All tests share the global `ForgeContainer.shared`, so the suite runs serially.
//

import Testing
import Foundation
@testable import ForgeInject

// MARK: - Test Fixtures

protocol TestServiceProtocol: AnyObject, Sendable {
    var label: String { get }
}

final class TestService: TestServiceProtocol, @unchecked Sendable {
    let label: String
    init(label: String = "default") {
        self.label = label
    }
}

final class TestRepository: @unchecked Sendable {
    let id = UUID().uuidString
}

@Suite("Inject Macros", .serialized)
struct InjectMacroTests {

    // MARK: - @Inject (lazy default)

    @Test("@Inject lazy: resolves on first access and caches the value")
    func lazyResolvesAndCaches() {
        let container = ForgeContainer()
        container.register(with: .transient) { _ in TestService(label: "lazy") }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        final class Holder: Sendable {
            @Inject var service: TestService
        }

        let holder = Holder()
        let first = holder.service
        let second = holder.service

        #expect(first.label == "lazy")
        // Even though the policy is .transient, @Inject caches after first access
        // — same instance returned on subsequent accesses.
        #expect(first === second)
    }

    @Test("@Inject lazy: independent properties resolve per instance")
    func lazyIndependentInstances() {
        let container = ForgeContainer()
        container.register(with: .transient) { _ in TestService() }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        final class Holder: Sendable {
            @Inject var service: TestService
        }

        let a = Holder()
        let b = Holder()
        #expect(a.service !== b.service)
    }

    @Test("@Inject lazy: concurrent first-accesses produce a single cached instance")
    func lazyThreadSafeFirstAccess() async {
        let container = ForgeContainer()
        container.register(with: .transient) { _ in TestService() }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        final class Holder: Sendable {
            @Inject var service: TestService
        }

        let holder = Holder()

        await withTaskGroup(of: ObjectIdentifier.self) { group in
            for _ in 0..<100 {
                group.addTask { ObjectIdentifier(holder.service) }
            }
            var ids: Set<ObjectIdentifier> = []
            for await id in group {
                ids.insert(id)
            }
            // Despite 100 concurrent accesses, only one instance should ever be cached.
            #expect(ids.count == 1)
        }
    }

    // MARK: - @Inject(lazy: false)

    @Test("@Inject eager: resolves at init time, not on first access")
    func eagerResolvesAtInit() {
        let container = ForgeContainer()
        let resolveCount = Mutex(0)
        container.register(with: .transient) { _ in
            resolveCount.withLock { $0 += 1 }
            return TestService(label: "eager")
        }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        final class Holder: Sendable {
            @Inject(lazy: false) var service: TestService
        }

        // Resolution happens during Holder.init, before we ever read .service
        let holder = Holder()
        let countAfterInit = resolveCount.withLock { $0 }
        #expect(countAfterInit == 1)

        // Subsequent accesses don't re-resolve
        _ = holder.service
        _ = holder.service
        let finalCount = resolveCount.withLock { $0 }
        #expect(finalCount == 1)
        #expect(holder.service.label == "eager")
    }

    // MARK: - @Injectable

    @Test("@Injectable: generated init resolves all let properties from container")
    func injectableResolvesFromContainer() {
        let container = ForgeContainer()
        container.register(with: .transient) { _ in TestService(label: "from-container") }
        container.register(with: .transient) { _ in TestRepository() }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        @Injectable
        final class ViewModel: Sendable {
            let service: TestService
            let repository: TestRepository
        }

        let vm = ViewModel()
        #expect(vm.service.label == "from-container")
        #expect(vm.repository.id.isEmpty == false)
    }

    @Test("@Injectable: generated init accepts overrides for testing")
    func injectableAcceptsOverrides() {
        let container = ForgeContainer()
        container.register(with: .transient) { _ in TestService(label: "production") }
        container.register(with: .transient) { _ in TestRepository() }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        @Injectable
        final class ViewModel: Sendable {
            let service: TestService
            let repository: TestRepository
        }

        let mockService = TestService(label: "mocked")
        let vm = ViewModel(service: mockService)
        #expect(vm.service.label == "mocked")
        // The other dep still resolves from the container
        #expect(vm.repository.id.isEmpty == false)
    }

    @Test("@Injectable: mutable vars are not included in the generated init")
    func injectableIgnoresVars() {
        let container = ForgeContainer()
        container.register(with: .transient) { _ in TestService() }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        @Injectable
        final class ViewModel {
            let service: TestService
            var counter: Int = 0
        }

        let vm = ViewModel()
        #expect(vm.counter == 0)
        vm.counter = 5
        #expect(vm.counter == 5)
    }

    // MARK: - #inject()

    @Test("#inject(): resolves the expected type from context")
    func injectExpressionResolves() {
        let container = ForgeContainer()
        container.register(with: .transient) { _ in TestService(label: "expression") }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        let service: TestService = #inject()
        #expect(service.label == "expression")
    }

    @Test("#inject(): works inside lazy var for opt-in laziness")
    func injectExpressionInsideLazyVar() {
        let container = ForgeContainer()
        container.register(with: .transient) { _ in TestService(label: "lazy-var") }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        final class Holder {
            lazy var service: TestService = #inject()
        }

        let holder = Holder()
        #expect(holder.service.label == "lazy-var")
    }

    // MARK: - @Injectable edge cases

    @Test("@Injectable: works on a struct")
    func injectableOnStruct() {
        let container = ForgeContainer()
        container.register(with: .transient) { _ in TestService(label: "struct") }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        @Injectable
        struct Container {
            let service: TestService
        }

        let c = Container()
        #expect(c.service.label == "struct")

        // Override still works
        let mock = TestService(label: "mocked-struct")
        let overridden = Container(service: mock)
        #expect(overridden.service.label == "mocked-struct")
    }

    @Test("@Injectable: works on an actor")
    func injectableOnActor() async {
        let container = ForgeContainer()
        container.register(with: .transient) { _ in TestService(label: "actor") }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        @Injectable
        actor Worker {
            let service: TestService

            func label() -> String {
                service.label
            }
        }

        let worker = Worker()
        let label = await worker.label()
        #expect(label == "actor")
    }

    @Test("@Injectable: generates empty init when no injectable properties exist")
    func injectableNoProperties() {
        @Injectable
        final class Empty {
            var counter: Int = 0
        }

        let empty = Empty()
        #expect(empty.counter == 0)
    }

    @Test("@Injectable: skips let properties with default values")
    func injectableSkipsPropertiesWithDefaults() {
        let container = ForgeContainer()
        container.register(with: .transient) { _ in TestService(label: "from-container") }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        @Injectable
        final class ViewModel: @unchecked Sendable {
            let service: TestService
            let threshold: Int = 42
        }

        // `threshold` should not be a parameter on the generated init.
        // If the macro tried to include it, this call would fail to compile.
        let vm = ViewModel()
        #expect(vm.service.label == "from-container")
        #expect(vm.threshold == 42)
    }

    @Test("@Injectable: coexists with @Inject in the same class")
    func injectableAndInjectTogether() {
        let container = ForgeContainer()
        container.register(with: .transient) { _ in TestService(label: "via-injectable") }
        container.register(with: .transient) { _ in TestRepository() }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        @Injectable
        final class ViewModel: @unchecked Sendable {
            // Constructor-injected
            let service: TestService
            // Lazy on-demand
            @Inject var repository: TestRepository
        }

        let vm = ViewModel()
        #expect(vm.service.label == "via-injectable")

        let repo1 = vm.repository
        let repo2 = vm.repository
        // @Inject still caches across accesses
        #expect(repo1.id == repo2.id)
    }

    // MARK: - ForgeContainer.shared concurrent access

    @Test("ForgeContainer.shared: concurrent getter reads observe a consistent value")
    func concurrentSharedGetterIsThreadSafe() async {
        let container = ForgeContainer()
        container.register(with: .singleton) { _ in TestService() }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        await withTaskGroup(of: Bool.self) { group in
            for _ in 0..<200 {
                group.addTask { ForgeContainer.shared != nil }
            }
            var seen: Set<Bool> = []
            for await present in group {
                seen.insert(present)
            }
            // All 200 concurrent reads should observe the same non-nil container.
            #expect(seen == [true])
        }
    }

    @Test("@Injectable: mock override does not call the container for that dependency")
    func injectableOverrideSkipsContainer() {
        let container = ForgeContainer()
        let resolveCount = Mutex(0)
        container.register(with: .transient) { _ -> TestService in
            resolveCount.withLock { $0 += 1 }
            return TestService(label: "should-not-be-called")
        }
        container.register(with: .transient) { _ in TestRepository() }
        ForgeContainer.shared = container
        defer { ForgeContainer.shared = nil }

        @Injectable
        final class ViewModel: @unchecked Sendable {
            let service: TestService
            let repository: TestRepository
        }

        let mock = TestService(label: "mocked")
        let vm = ViewModel(service: mock)

        #expect(vm.service.label == "mocked")
        // The container's TestService factory should NOT have been called —
        // default arguments only evaluate if the parameter is missing.
        #expect(resolveCount.withLock { $0 } == 0)
        // But the repository still comes from the container, so that one resolved.
        #expect(vm.repository.id.isEmpty == false)
    }
}
