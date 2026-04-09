@_exported import Synchronization
import Foundation
import os

/// Default `ForgeContainerProtocol` implementation.
///
/// Set `shared` once at app launch before any `@Inject` property is accessed:
/// ```swift
/// let container = ForgeContainer()
/// container.register(with: .singleton) { _ in MyService() }
/// ForgeContainer.shared = container
/// ```
///
/// Thread-safe via `OSAllocatedUnfairLock<ContainerState>`. We use `OSAllocatedUnfairLock` here
/// (instead of the standard library `Mutex`) because the container's state holds user-supplied
/// builder closures and `Any`-typed instances, which `Mutex`'s `sending` region analysis can't
/// validate. `OSAllocatedUnfairLock` provides the same thread-safety guarantees with looser
/// region semantics — appropriate for a DI container that intentionally erases types.
public final class ForgeContainer: ForgeContainerProtocol, Sendable {

    // MARK: - Shared

    private static let _shared = OSAllocatedUnfairLock<ForgeContainerProtocol?>(initialState: nil)

    /// Global container used by `@Inject`, `@Injectable`, and `#inject()`. Must be set once during
    /// app launch and cannot be replaced afterwards.
    public static var shared: ForgeContainerProtocol? {
        get {
            _shared.withLock { $0 }
        }
        set {
            _shared.withLock { current in
                precondition(
                    current == nil || newValue == nil,
                    "ForgeContainer.shared must only be set once."
                )
                current = newValue
            }
        }
    }

    // MARK: - Properties

    private let state = OSAllocatedUnfairLock<ContainerState>(initialState: ContainerState())

    // MARK: - Initialization

    public init() {}

    // MARK: - Implementation

    public func register<T>(
        with policy: ForgeRetainPolicy,
        builder: @escaping @Sendable (ForgeContainerProtocol) throws -> T
    ) {
        let key = String(reflecting: T.self)
        state.withLock { state in
            state.instances[key] = nil
            state.weakInstances.removeObject(forKey: key as NSString)
            state.factories[key] = Factory(policy: policy, build: builder)
        }
    }

    public func resolve<T>() throws -> T {
        let key = String(reflecting: T.self)
        // `withLockUnchecked` because `T` is intentionally unconstrained — the container must
        // support non-Sendable dependencies (UIKit objects, view models, etc.). The lock still
        // provides full mutual exclusion; we just opt out of the static Sendable check on the
        // closure return value.
        return try state.withLockUnchecked { state -> T in
            guard let factory = state.factories[key] else {
                throw ForgeContainerError.missingFactoryMethod(String(reflecting: T.self))
            }

            switch factory.policy {
            case .transient:
                guard let result = try factory.build(self) as? T else {
                    throw ForgeContainerError.typeMismatch(String(reflecting: T.self))
                }
                return result

            case .singleton:
                if let instance = state.instances[key] as? T {
                    return instance
                }
                guard let instance = try factory.build(self) as? T else {
                    throw ForgeContainerError.typeMismatch(String(reflecting: T.self))
                }
                state.instances[key] = instance
                return instance

            case .weak:
                let nsKey = key as NSString
                if let instance = state.weakInstances.object(forKey: nsKey) as? T {
                    return instance
                }
                let instance = try factory.build(self)
                guard let result = instance as? T else {
                    throw ForgeContainerError.typeMismatch(String(reflecting: T.self))
                }
                state.weakInstances.setObject(result as AnyObject, forKey: nsKey)
                return result
            }
        }
    }

    public func resolveWithType<T>(_: T.Type) throws -> T {
        try resolve()
    }

    public func resolveAll<T>(conforming _: T.Type) -> [T] {
        state.withLockUnchecked { state in
            let strong = state.instances.values.compactMap { $0 as? T }
            let weak = state.weakInstances.dictionaryRepresentation().values.compactMap { $0 as? T }
            return strong + weak
        }
    }

    public func reset(preserving types: [Any.Type]) {
        let keysToPreserve = Set(types.map { String(reflecting: $0) })
        state.withLock { state in
            let toReset = Set(state.instances.keys).subtracting(keysToPreserve)
            for key in toReset {
                state.instances[key] = nil
            }

            let allKeys = state.weakInstances.keyEnumerator().allObjects as? [NSString] ?? []
            for key in allKeys where !keysToPreserve.contains(key as String) {
                state.weakInstances.removeObject(forKey: key)
            }
        }
    }

    // MARK: - Private

    /// Aggregated mutable state, packed into a single struct so one lock protects everything.
    /// `@unchecked Sendable` because the enclosing `OSAllocatedUnfairLock` provides exclusive
    /// access — the type system can't prove it, but the runtime guarantees it.
    private struct ContainerState: @unchecked Sendable {
        var factories: [String: Factory] = [:]
        var instances: [String: Any] = [:]
        var weakInstances = NSMapTable<NSString, AnyObject>(
            keyOptions: [.copyIn],
            valueOptions: [.weakMemory]
        )
    }

    private struct Factory: Sendable {
        let policy: ForgeRetainPolicy
        let build: @Sendable (ForgeContainerProtocol) throws -> Any
    }
}
