//
//  NetworkManager.swift
//  NSCoreNetwork
//
//  Created by apple on 27/11/26.
//

import Foundation

final class MemoryCache {
    let cache = NSCache<AnyObject, AnyObject>()

    func object(forKey key: AnyObject) -> AnyObject? {
        cache.object(forKey: key)
    }

    func setObject(_ obj: AnyObject, forKey key: AnyObject) {
        cache.setObject(obj, forKey: key)
    }
}
