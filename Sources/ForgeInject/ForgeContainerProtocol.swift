/// Dependency injection container interface.
public protocol ForgeContainerProtocol: Sendable {
    /// Registers a factory for type `T`.
    /// - Parameters:
    ///   - policy: Retain policy for the created instance.
    ///   - builder: Factory closure that creates the dependency. Must be `@Sendable` so it can
    ///     be invoked from any isolation domain.
    func register<T>(
        with policy: ForgeRetainPolicy,
        builder: @escaping @Sendable (ForgeContainerProtocol) throws -> T
    )

    /// Resolves a dependency by type inference.
    func resolve<T>() throws -> T

    /// Resolves a dependency by explicit type.
    func resolveWithType<T>(_ type: T.Type) throws -> T

    /// Returns all previously-resolved instances conforming to the given type.
    ///
    /// Only returns cached singletons and live weak references.
    /// Unresolved factories and transient registrations are excluded.
    func resolveAll<T>(conforming protocol: T.Type) -> [T]

    /// Clears cached instances, forcing re-creation on next resolve.
    ///
    /// Preserves factory registrations. Useful for scenarios like user logout.
    /// - Parameter types: Types whose cached instances should be preserved.
    func reset(preserving types: [Any.Type])
}

public extension ForgeContainerProtocol {
    /// Registers a dependency with `.transient` policy.
    func register<T>(builder: @escaping @Sendable (ForgeContainerProtocol) throws -> T) {
        register(with: .transient, builder: builder)
    }

    /// Registers a `@MainActor`-isolated dependency.
    ///
    /// The instance is created eagerly at registration time, then stored for future resolves.
    /// Requires `T: Sendable` because the resolved instance is captured in a `@Sendable` builder
    /// closure for future resolves across isolation domains.
    @MainActor
    func register<T: Sendable>(
        with policy: ForgeRetainPolicy,
        mainActorBuilder builder: @MainActor (ForgeContainerProtocol) throws -> T
    ) rethrows {
        let instance = try builder(self)
        register(with: policy) { _ in instance }
    }
}
