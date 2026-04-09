//
//  ForgeContainer+TestHelpers.swift
//  ForgeInject
//
//  Created by Stefan Projchev on 31.3.26.
//

@testable import ForgeInject

extension ForgeContainer {
    /// Returns the internal key used by the container for a given type.
    /// Useful for testing `reset(ignoreDependencies:)`.
    static func key<T>(for type: T.Type) -> String {
        String(reflecting: type)
    }
}
