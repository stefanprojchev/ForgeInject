//
//  MockService.swift
//  ForgeInject
//
//  Created by Stefan Projchev on 31.3.26.
//

import Foundation

protocol MockServiceProtocol: AnyObject {
    var id: String { get }
}

final class MockService: MockServiceProtocol {
    let id: String

    init(id: String = UUID().uuidString) {
        self.id = id
    }
}
