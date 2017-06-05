//
//  CNLModelError.swift
//  CNLDataProvider
//
//  Created by Igor Smirnov on 22/12/2016.
//  Copyright © 2016 Complex Numbers. All rights reserved.
//

import Foundation

import CNLFoundationTools

public enum CNLModelErrorAlertStyle {
    case info, error, warning
}

public struct CNLModelErrorAlertStruct {
    public var type: CNLModelErrorAlertStyle
    public var title: String?
    public var message: String
    
    public init?(type: CNLModelErrorAlertStyle, title: String?, message: String?) {
        guard let message = message else { return nil }
        self.type = type
        self.title = title
        self.message = message
    }
}

public protocol CNLModelErrorKind {
    var identifier: String { get }
}

public protocol CNLModelError {
    var alertStruct: CNLModelErrorAlertStruct? { get }
    var json: CNLDictionary? { get }
    var kind: CNLModelErrorKind { get }
    var success: Bool { get }
}
