import Foundation

/// Errors thrown when resolving dependencies from the container.
public enum ForgeContainerError: LocalizedError {

    // MARK: - Cases

    /// No factory registered for the requested type.
    case missingFactoryMethod(_ type: String)

    /// Factory return value cannot be cast to the requested type.
    case typeMismatch(_ type: String)

    // MARK: - Implementation

    public var errorDescription: String? {
        switch self {
        case let .missingFactoryMethod(type):
            "Missing factory method for instance: \(type)"
        case let .typeMismatch(type):
            "Type mismatch when resolving instance: \(type)"
        }
    }
}
