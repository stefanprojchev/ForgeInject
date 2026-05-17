/// Controls how the container manages resolved instances.
public enum ForgeRetainPolicy: Equatable, Sendable {
    /// Creates a new instance on every resolve.
    case transient

    /// Caches the instance for the container's lifetime.
    case singleton

    /// Caches the instance only while strong references exist.
    case weak
}
