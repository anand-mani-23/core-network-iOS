//
//  NetworkManager.swift
//  NSCoreNetwork
//
//  Created by apple on 27/11/26.
//

import Foundation

public protocol MemoryCaching: Sendable {
    func value(forKey key: String) -> Data?
    func setValue(_ value: Data, forKey key: String)
    func removeValue(forKey key: String)
}

public final class MemoryCache: MemoryCaching, @unchecked Sendable {
    private let cache = NSCache<NSString, NSData>()

    public init(countLimit: Int = 100, totalCostLimit: Int = 0) {
        cache.countLimit = countLimit
        cache.totalCostLimit = totalCostLimit
    }

    public func value(forKey key: String) -> Data? {
        cache.object(forKey: key as NSString) as Data?
    }

    public func setValue(_ value: Data, forKey key: String) {
        cache.setObject(value as NSData, forKey: key as NSString)
    }

    public func removeValue(forKey key: String) {
        cache.removeObject(forKey: key as NSString)
    }
}
