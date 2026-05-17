/// Allows a type to register its own dependencies with the container.
public protocol ForgeRegisterProtocol {
    /// Registers this type's dependencies in the given container.
    func registerDependencies(in container: ForgeContainerProtocol)
}
