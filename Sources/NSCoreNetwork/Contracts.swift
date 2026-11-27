//
//  Contracts.swift
//  NSCoreNetwork
//
//  Created by apple on 27/11/26.
//

import Foundation

protocol NetworkManaging {
    func fetchData(path: String) async throws -> Data
}

protocol MemoryCaching {
    func get(key: String) -> Any?
    func set(value: Any, key: String)
}
