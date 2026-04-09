//
//  MockDependencyRegister.swift
//  ForgeInject
//
//  Created by Stefan Projchev on 31.3.26.
//

@testable import ForgeInject

struct MockDependencyRegister: ForgeRegisterProtocol {
    func registerDependencies(in container: ForgeContainerProtocol) {
        container.register(with: .singleton) { _ in MockService(id: "registered") }
    }
}
