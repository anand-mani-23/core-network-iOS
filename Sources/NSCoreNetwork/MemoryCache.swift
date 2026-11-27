//
//  NetworkManager.swift
//  NSCoreNetwork
//
//  Created by apple on 27/11/26.
//

import Foundation

public final class MemoryCache {
    public init(){}
    
    let cache = NSCache<AnyObject, AnyObject>()

    public func object(forKey key: AnyObject) -> AnyObject? {
        cache.object(forKey: key)
    }

    public func setObject(_ obj: AnyObject, forKey key: AnyObject) {
        cache.setObject(obj, forKey: key)
    }
}
