//
//  CNLModelObjectPrimaryKey.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 23/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

public protocol CNLModelObjectPrimaryKey: class {
    associatedtype KeyType: Hashable
    var primaryKey: KeyType { get }
    init?(keyValue: String)
    var encodedPrimaryKey: String? { get }
}

public extension CNLModelObjectPrimaryKey {
    public var encodedPrimaryKey: String? { return "\(primaryKey)" }
}

